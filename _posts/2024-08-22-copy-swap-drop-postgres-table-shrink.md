---
layout: post
permalink: /copy-swap-drop-postgres-table-shrink
title: 'Shrinking Big PostgreSQL tables: Copy-Swap-Drop'
date: 2024-10-02
tags: [PostgreSQL]
comments: true
---

In this post, you'll learn a recipe you can use to effectively "shrink" any large table, when only a portion of the data is queried.

You can use this recipe for tables with billions of rows, and *without* taking Postgres offline. How does it work?

## Postgres details
These steps were tested on:

- PostgreSQL 16
- Transactions use the default isolation level of `READ COMMITTED`
- Steps were performed using the psql client

## A few big tables
Let's discuss some context.

Application databases commonly have a few tables that are much larger in size than the others. These jumbo tables have data for data-intensive features, granular information captured at a high frequency.

Because of that, the table row counts can grow into the hundreds of millions, or billions. Depending on the size of rows, the table size can be hundreds of gigabytes or even terabytes in size.

## Problems with big tables
While PostgreSQL [supports tables up to 32TB](https://www.postgresql.org/docs/current/limits.html) in size, working with large tables of 500GB or more can be problematic and slow.

Query performance can be poor, adding indexes or constraints is slow. Backup and restore operations slow down due to these large tables.

Large tables might force a need to scale the database server instance vertically to provision more CPU and memory capacity unnecessarily, when only more storage is needed.

When the application queries only a portion of the rows, such as recent rows, or rows for active users or customers, there's an opportunity here to move the unneeded rows out of Postgres.

One tactic to do that is to `DELETE` rows, but this is a problem due to the multiversion row design of Postgres. We'll cover this in an more detail in an upcoming post on massive delete operations.

Another option would be to migrate data into partitioned tables.

We aren’t going to cover table partitioning in this post, but let's assume that option is out as well, primarily because of the unknown impacts to the application working with Postgres.

While a partitioned table is mostly the same as a regular table, there are some differences related to primary keys and other structural elements.

Imagine that we don't want to delete rows, and we don't yet want to migrate to a partitioned replacement table.

Are there other options?

## Introducing Copy-Swap-Drop
Without taking Postgres down, without migrating to a partitioned table, an approach we'll discuss here effectively shrinks the table, using a set of steps I'm calling "copy, swap, and drop."

Here are the steps in a little more detail:

1. Clone the original table definition, creating an equivalent table with a new name
2. Copy a subset of the rows into the new table
3. Swap the table names
4. Drop the original table

This pattern is based on the [one-off tasks section of pgslice](https://github.com/ankane/pgslice?tab=readme-ov-file#one-off-tasks), a Ruby gem that helps facilitate partitioned table migration.

We'll focus on the SQL operations though, borrow some conventions, and expand a bit further on the concept including rollback steps.

## Caveats
This process doesn't shrink the original table in-place. We're creating an intermediate table that becomes the replacement.

This process still involves a table row data migration. However, a benefit over a partitioned table migration is that the replacement table has the exact same structure, so we can avoid any application incompatibilities.

Where do we start?

## SQL process steps
Let's use a table called "events". Imagine "events" was set up years ago and currently receives hundreds of thousands, or millions of new rows every day.

Imagine "events" is around 500GB in size and has 500 million rows.

When looking at queries for "events", the application queries access the last 30 days of data. Imagine this is the sole access of the data from the application.

This means data older than 30 days isn’t reachable, and thus, not needed within Postgres.

While we may want to archive this data to keep it around, we could store it in lower cost file storage, or relocate it to an analytical data store.

If the events table grows at 1 million rows per day, to keep 30 days of data we'd expect to keep around 30 million rows.

That means around 470 million rows could be removed, or in other words, 94% of the total row content!

That's a substantial win, so with that context in mind, let's get started.

# Clone the table
First, create an intermediate table to copy rows into.

I like to work in psql. Let's create a "testdb" database for this example, so it's separated. We'll create tables in "tesdb" to show how this works.

You can run through these examples, then adapt them to your specific database and table names.
```
psql> CREATE DATABASE testdb;

\c testdb -- connect to "testdb"
```

We'll set up "events" to have a primary key which is automatically indexed, and a single user-created index:
```sql
CREATE TABLE events (
id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
data TEXT,
created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX ON events (data);
```

Example rows:
```sql
INSERT INTO events (data) VALUES ('data');
INSERT INTO events (data) VALUES ('more data');
```

First we’ll clone the events table and give the new table a new name.

Use the naming convention of "_intermediate" as a suffix on the original name.

This naming convention is borrowed from pgslice.
```sql
-- Step 1: Clone the table structure
CREATE TABLE events_intermediate (
    LIKE events INCLUDING ALL EXCLUDING INDEXES
);
```
The command above excludes indexes. However, we'll want the primary key index and this form still includes the primary key constraint, but not the index.

We'll look at how to grab the index definition statements for "events" later on, so that they can be added back.

Since we’re copying rows over, we want to defer creating indexes until after row copying has completed, to make the row copying as fast as possible.

## Copy a subset of the rows
With the empty table created, we’ll determine how far back to start copying from the events table.

Let's find the first `id` that’s listed for rows with a `created_at` value that’s 30 days old.

```sql
-- 2. Copy a subset of rows
-- Find the first primary key id that's newer than 30 days ago
SELECT id, created_at
FROM events
WHERE created_at > (CURRENT_DATE - INTERVAL '30 days')
LIMIT 1;
```

Imagine the value was id `123456789`. With that `id` in hand, we can begin batched copying from there.

Consider making the batch size as large as possible, balanced against not causing too much CPU or IO operations usage that takes away from primary application work. This means you'll want to closely monitor DB server metrics.

Plan to run these operations during a low activity period for your application, and add pauses in between batches.

Let's use a batch size of 1000 to start. The query below filters on the primary key, which means it will use the primary key index.

```sql
-- Query in batches of 1000 at a time from that point forward, there might be gaps but that's ok.
INSERT INTO events_intermediate
OVERRIDING SYSTEM VALUE
SELECT * FROM events WHERE id >= 123456789
ORDER BY id ASC -- the default ordering
LIMIT 1000;
```

Let's imagine you’re manually running batches. The statement below is copyable to perform the next batch copy. The statement gets the max id value from the new `events_intermermediate` table. Using that id, the next copy operation can start from the next id value that’s greater.

```sql
WITH t AS (
  SELECT MAX(id) AS max_id
  FROM events_intermediate
)
INSERT INTO events_intermediate
OVERRIDING SYSTEM VALUE
SELECT *
FROM events
WHERE id > (SELECT max_id FROM t)
ORDER BY id
LIMIT 1000;
```

For brevity of this post, we’ll avoid making this snippet above re-runnable automatically. We could explore that in a future post.

Assume you’re running successive batches of this manually for this post. For example, from a psql session, copying and pasting this same command repeatedly, which will select batches of 1000.

The goal now is to fill forward up to the current rows, from 30 days back up to the current time.

Note that in your last batch, there will still be newer rows created outside of the snapshot that your last `INSERT` transaction saw. We’ll get to those though, don’t worry.

The table `events_intermediate` should now have approximately 30 days of data, minus a few more rows. We’re ready to swap the table names so that the new smaller table takes over the original table name.

## Preparing to swap the tables
We’ll create a single transaction that captures any uncopied rows, copies them, then performs two table rename operations. These renames will "swap" the new table in for the old one.

The original table is renamed to have the "retired" suffix. This is another naming convention borrowed from pgslice!

With the original table name "available," rename the intermediate table to be the original table. In other words, drop the "_intermediate" suffix.

One other part is handling the table sequence. The table uses a sequence object `events_id_seq` to hand out unique integer values.

This is optional, but we're deliberately raising the next sequence value by 1000 as a precaution for a possible rollback, which we'll cover shortlty.

Finally, we've arrived to the "exciting" step. The new table will become the replacement table and immediately begin receiving new write operations. Make sure you’re ready for that, meaning you've tested this extensively in a pre-production environment where it's safe to make mistakes.

However, before we do that, let's look at adding the indexes back to support our read queries.

## Adding indexes back
We intentionally wanted to create indexes at the end, compared with creating them in advance adding more latency to each `INSERT`.

Since the table is not yet "live," we can add the indexes without the `CONCURRENTLY` option, meaning they'll be added as fast as possible.

We can also juice up the resources a bit for adding indexes.

From psql, raise the `maintenance_work_mem` to higher value to temporarily allocate more system memory in this session for index creation.

Start *up to* more parallel maintenance workers ([capped](https://postgresqlco.nf/doc/en/param/max_parallel_maintenance_workers/) by max_worker_processes and max_parallel_workers) for Btree index creation.
```sql
-- Speed up index creation, example of increasing it to 1GB of memory
SET maintenance_work_mem = '1GB';

-- Raise from default of 2, to 4
SET max_parallel_maintenance_workers = 4;
```

Given the table size is smaller now, the index builds will be much faster compared with the same builds on the original table.

However, there may be a `statement_timeout` in effect that's too short. Try raising it for this session to something like two hours.

```sql
-- Add time, e.g. 2 hours to provide plenty of time
SET statement_timeout = '120min';
```

Next, get the index definitions as `CREATE INDEX` statements from the original table. You'll add all of them, including indexes for primary keys, and any user-created indexes.

This can also be an opportunity to abandon unused indexes from the old table, but not bringing them forward.

```sql
SELECT indexdef
FROM pg_indexes
WHERE tablename = 'events';
```

Results:
```sql
                             indexdef
-------------------------------------------------------------------
 CREATE UNIQUE INDEX events_pkey ON public.events USING btree (id)
 CREATE INDEX events_data_idx ON public.events USING btree (data)
```

With those definitions, adapt them slightly.

We can remove the "public" schema for this example. Use the schema for your database.

Index names need to be unique, so append "1" on or do something else to create a unique index name.

Change the table name to "events_intermediate" since we're creating the indexes there.

We can omit "USING btree" since btree is the default type.

```sql
CREATE UNIQUE INDEX events_pkey1_idx ON events_intermediate (id);
CREATE INDEX events_data_idx1 ON events_intermediate (data);
```

## Primary key using the index
One tricky thing here is that the primary key constraint is being enforced (try inserting a duplicate) but the unique constraint is not supported with an index at the moment.

That's now how the table was originally set up, and we want the new one to be equivalent.

To do that, we have to run one more command:
```sql
ALTER TABLE events_intermediate
ADD CONSTRAINT events_pkey1 PRIMARY KEY
USING INDEX events_pkey1_idx;
```

You should see this:
```sql
NOTICE:  ALTER TABLE / ADD CONSTRAINT USING INDEX will rename index "events_pkey1_idx" to "events_pkey1"
```
This renames the index as well, and the name "events_pkey1" was chosen with the rename in mind.

At this point, if you compare both tables using "\d", they should be identical in structure.


## Raising sequence values
Let's check the current sequence objects in testdb:
```sql
SELECT * FROM pg_sequences;
```

We should see:
- `events_id_seq`
- `events_intermediate_id_seq`

Let's use the last value from the original table, to raise the value plus some buffer amount for the intermediate table sequence:

```sql
-- Capture the sequence value plus the raised, as NEW_MINIMUM
SELECT setval('events_intermediate_id_seq', nextval('events_id_seq') + 1000);
```

### Ready to swap
We're ready to swap. The subset of data will be in place on the new table structure, with an equivalent definition, including columns, data types, constraints, and indexes.

Here's the swap transaction:
```sql
BEGIN;

-- Rename original table to be "retired"
ALTER TABLE events RENAME TO events_retired;

-- Rename "intermediate" table to be original table name
ALTER TABLE events_intermediate RENAME TO events;

-- Grab one more batch of any rows committed
-- just before this transaction
WITH t AS (
  SELECT MAX(id) AS max_id
  FROM events_intermediate
)
INSERT INTO events_intermediate
OVERRIDING SYSTEM VALUE
SELECT *
FROM events
WHERE id > (SELECT max_id FROM t)
ORDER BY id
LIMIT 1000;


COMMIT;
```

Alright! The new smaller table has been swapped in. Let's do one more pass to make sure any inserted rows into the former table weren't missed. Technically, this should find zero rows.

This means we’re copying from the retired table, "events_retired", into the new table "events".
```sql
INSERT INTO events
OVERRIDING SYSTEM VALUE
SELECT * FROM events_retired
WHERE id > (SELECT MAX(id) FROM events);
```

For new inserts, we should see that their primary key `id` values reflect that gap created earlier, creating a space of 1000 values.

Note that the sequence name will continue to be `events_intermediate_id_seq` even though the table name was changed.

## Bonus Steps
If things go wrong, you may want to reverse the steps. Create

Optionally raise the sequence again by 1000, perhaps using the gap as a marker of this activity.

```sql
SELECT setval('events_intermediate_id_seq', nextval('events_intermediate_id_seq') + 1000);
```

Swap the names again.
```sql
BEGIN;
-- the new events table should be sent backward
-- to being the "intermediate" table.
-- The current "retired" table should be promoted to be the main table.
ALTER TABLE events RENAME TO events_intermediate;

-- Make the original jumbo table the main table
ALTER TABLE events_retired RENAME TO events;

COMMIT;
```

Now rows are flowing into a new table, but we’ll need to grab any missed ones.

```sql
-- Now we'd need to select from rows inserted into "events_intermediate"
-- in the last hour that were missed.
-- They should be brought back into "events"
INSERT into events
OVERRIDING SYSTEM VALUE
SELECT *
FROM events_intermediate
WHERE created_at >= (NOW() - INTERVAL '1 hour')
ORDER BY id
ON CONFLICT (id) DO NOTHING;
```

## Drop the old table
Now the new smaller table has all the rows needed from the original table, has indexes to support the read operations and constraints, and is receiving new rows.

The former table can now be archived, perhaps by using `pg_dump` to select all rows into a data file that can be backed up and restored.

Once that's done, the table can be dropped entirely, reclaiming the space from the table data and index data.
