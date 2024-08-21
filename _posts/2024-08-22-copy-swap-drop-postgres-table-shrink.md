---
layout: post
title: 'Shrinking Big PostgreSQL tables: Copy-Swap-Drop'
tags: []
date: 2024-08-22
comments: true
---

In this post, we’ll look at a strategy that effectively shrinks a large table, when only a portion of the data is needed.

## Postgres testing details
- PostgreSQL 16
- Default transaction isolation level `READ COMMITTED`
- Run steps from the psql command line client

## A few big tables
Application databases commonly have a few tables that are much larger in size than all the other tables. These jumbo tables contain that data for data-intensive features, capturing granular information at a high frequency.

These tables can grow into the hundreds of gigabytes or even terabytes in size.

While PostgreSQL [supports tables up to 32TB](https://www.postgresql.org/docs/current/limits.html) in size, working with large tables of 500GB or more can be problematic in my experience.

Query performance can be poor, adding indexes or constraints is slow. Backups and restores slow down. Large tables might force a need to scale up a database server instance due to the space it's consuming, but not the compute it needs.

For these tables, the application may access only a small portion of the total rows, such as recent rows, or rows based on active users or customers.

When that's the case, this creates an opportunity to remove the majority of the rows from the table since they're not needed by the application. One tactic would be to `DELETE` the rows, but this is a problem and we'll cover this in an upcoming post on massive delete operations.

If we can't delete the rows, how can we remove them from the table without bringing Postgres down?

## Making large tables easier to work with
One option in PostgreSQL when working with large tables, is to migrate the table data into a replacement partitioned table. We aren’t going to cover table partitioning in this post, but for now we’ll assume that there are a set of benefits and trade-offs with partitioned tables.

Let's look at the challenges of operating partitioned tables. Partitions need to be created in advance. The application code likely needs to change a bit to work with partitioned tables. Partitioned tables typically have a different primary key structure.

Given the adoption of partitioned tables for application code changes, and the required data migration, what other options are there?

## Introducing Copy-Swap-Drop
Without taking Postgres down, without migrating to partitioned tables, one pragmatic tactic is to effectively shrink a table, using a set of steps I'm calling copy, swap, and drop.

Here are the steps:

1. Clone the table structure
2. Copy a subset of the rows
3. Swap the table names
4. Drop the original table

This pattern is based on the [one-off tasks section of pgslice](https://github.com/ankane/pgslice?tab=readme-ov-file#one-off-tasks), a Ruby gem that provides SQL commands that are part of migrating to partitioned tables. Wee'll focus on the SQL operations and expand a bit further to show rollbacks.

## Objections
This process doesn't shrink the original table in-place. The end result is that the original table is effectively "shrunk" though since we're creating an intermediate table that becomes its replacement.

This also does involve a row data migration. However, no application code changes or primary key definition changes are required, which reduces the risk.

## SQL process steps
Let's use a table called "events". Imagine "events" was set up years ago and currently receives hundreds of thousands or millions of rows, every day. Let’s imagine it’s currently around 500GB in size and has more than 500 million rows.

When looking into the queries for the application, the application only queries up to 30 days of event data for display.

This means event data older than 30 days isn’t reachable by the application, and thus not needed by the application.

While we may want to archive row data to lower cost file storage, or populate it in a different data store, by pruning unneeded row data from the application database we can avoid some of the pain points associated with jumbo sized tables.

If the events table grows at 1 million rows per day, to keep 30 days of data we'd expect to keep around 30 million rows.

That leaves 470 million rows or about 94% of the total that could be removed.

Let's start the process.

# Clone the table
First we'll create an intermediate table to copy the rows we're keeping into.

I like to work in psql, and using a fresh "testdb" that we'll create tables in:
```sql
CREATE DATABASE testdb;

\c testdb
```

Imaging this simplified original "events" table, with a primary key index, and one user-created index:
```sql
CREATE TABLE events (
id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
col1 TEXT,
created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX ON events (col1);
```

Example rows:
```sql
INSERT INTO events (col1) VALUES ('data');
INSERT INTO events (col1) VALUES ('more data');
```

First we’ll clone the events table and give the new table a new name.

Use the naming convention of "_intermediate" as a suffix on the original name.

This is the naming convention in pgslice.
```sql
-- Step 1: Clone the table structure
CREATE TABLE events_intermediate (LIKE events INCLUDING ALL EXCLUDING INDEXES);
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

From psql, raise the `maintenance_work_mem` to higher value to temporarily allocate more system memory to this session for index creation.
```sql
-- Speed up index creation, example of increasing it to 1GB of memory
SET maintenance_work_mem = '1GB';
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
 CREATE INDEX events_col1_idx ON public.events USING btree (col1)
```

With those definitions, adapt them slightly.

We can remove the "public" schema for this example. Use the schema for your database.

Index names need to be unique, so append "1" on or do something else to create a unique index name.

Change the table name to "events_intermediate" since we're creating the indexes there.

We can omit "USING btree" since btree is the default type.

```sql
CREATE UNIQUE INDEX events_pkey1_idx ON events_intermediate (id);
CREATE INDEX events_col1_idx1 ON events_intermediate (col1);
```

## Primary key using the index
One more tricky little thing here is that the primary key constraint is being enforced (try inserting a duplicate) but the unique constraint is not supported with an index at the moment.

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
