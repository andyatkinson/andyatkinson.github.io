---
layout: post
permalink: /copy-swap-drop-postgres-table-shrink
title: 'Shrinking Big PostgreSQL tables: Copy-Swap-Drop'
tags: []
comments: true
hidden: true
---

In this post, you'll learn a recipe you can use to effectively "shrink" any large table. This is a good fit when only a portion of the data is queried, without 

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

One tactic to do that is to `DELETE` rows, but this is a problem due to the multiversion row design of Postgres. We'll cover this in more detail in an upcoming post on massive delete operations.

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

I like to work in psql. Let's create a "testdb" database for this example, so it's separated. We'll create tables in "testdb" to show how this works.

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

Imagine the value was id `123456789`. With that `id` in hand, we can begin batch copying from there.

Consider making the batch size as large as possible, balanced against not causing too much CPU or IO operations usage. This means you'll need to closely monitor DB server metrics as you create an initial batch, then increase the batch size from there.

Run these operations during a low activity period for your application, such as after hours, weekends, etc. and add pauses in between batches.

Let's use a batch size of 1000 to start. The query below filters on the primary key, which means it will use the primary key index.

It starts from the id you found earlier and adds 1000 to it. If there are gaps, there won't be a full set of 1000 records.

```sql
-- Query in batches, up to 1000 at a time
INSERT INTO events_intermediate
OVERRIDING SYSTEM VALUE
SELECT * FROM events WHERE id >= 123456789
ORDER BY id ASC -- the default ordering
LIMIT 1000;
```

We're not automating this process here, but running it manually.

To make that easier, the statement below is copyable to perform the next batch copy.

The statement gets the max id value from the new `events_intermermediate` table. Using that id, the next copy operation can start from the next id value that’s greater.

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

We'll explore automation in a future post.

The goal is to fill the intermediate table up with copies from 30 days back to current.

In the last batch, since it will only know about committed rows, there will still be newer rows created after. We’ll get to those, don’t worry.

Once the batches are done, the table `events_intermediate` will have approximately 30 days of data, minus a few more rows.

We’re ready to swap the table names so that the new smaller table takes over the purpose of the original table.

## Preparing to swap the tables
We’ll create a single transaction that captures any uncopied rows, copies them, then performs two table rename operations. These renames "swap" the new table for the old one.

The original table is renamed with the "retired" suffix, also a naming convention borrowed from pgslice!

The new table drops the "_intermediate" suffix.

One other part is handling the table sequence. The original table used a sequence object `events_id_seq` for unique integer values. When you copied the table earlier, a new sequence was created.

We're adding a step to raise the sequence value by 1000 for the new sequence, to leave some space to copy in "missed" inserts.

The new table will become the replacement table and immediately begin receiving new write operations.

Make sure you’re prepared for that, meaning you've tested this in a pre-production environment where it's safe to make mistakes, experiment, and roll back.

Before we're ready to cut over for real, we want the indexes added back support the read queries.

## Adding indexes back
We intentionally left out indexes initially, so that row copying went as fast as possible.

Since the table is not yet "live" and offline, we can add the indexes back without using `CONCURRENTLY` when creating them, so they're created faster.

We can also add more resources to help with index creation.

From psql, add more memory to `maintenance_work_mem` for your session to help.

Additionally, allow Postgres to start more parallel maintenance workers ([capped](https://postgresqlco.nf/doc/en/param/max_parallel_maintenance_workers/) by max_worker_processes and max_parallel_workers) for index creation.
```sql
-- Speed up index creation, example of increasing it to 1GB of memory
SET maintenance_work_mem = '1GB';

-- Allow for more parallel maintenance workers
SET max_parallel_maintenance_workers = 4;
```

Given the index creations are on the smaller table, their build times will be much faster compared with being built on the large table.

However, there may be a `statement_timeout` in place that's too short. Try increasing this timeout so there's plenty of time to create indexes.

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

Index names need to be unique, so append "1" to create a unique index name, or do something else to your preference.

Change the table name from those statements to "events_intermediate".

Omit "USING btree" since Btree is the default type.

Run these DDL statements:
```sql
CREATE UNIQUE INDEX events_pkey1_idx ON events_intermediate (id);
CREATE INDEX events_data_idx1 ON events_intermediate (data);
```

## Primary key using the index
One tricky thing here is the primary key constraint isn't fully configured.

It's being enforced, try inserting a duplicate and verifying there's an error. However, the unique constraint doesn't have a supporting index.

Since the original table was set up with a unique constraint and index, we want the new table to be equivalent.

To do that, run this command:
```sql
ALTER TABLE events_intermediate
ADD CONSTRAINT events_pkey1 PRIMARY KEY
USING INDEX events_pkey1_idx;
```

You should see this:
```sql
NOTICE:  ALTER TABLE / ADD CONSTRAINT USING INDEX will rename index "events_pkey1_idx" to "events_pkey1"
```
This renames the index. The index name "events_pkey1" was chosen with the rename in mind.

At this point, if you compare both tables using "\d", they should be identical.

## Raising sequence values
Let's check the current sequence objects in testdb:
```sql
SELECT * FROM pg_sequences;
```

We should see:
- `events_id_seq`
- `events_intermediate_id_seq`

Let's use the last value from the sequence on the original table, plus that buffer of 1000 discussed earlier.

The buffer helps when we copy in missed inserts from the original table.

```sql
-- Capture the sequence value plus the raised, as NEW_MINIMUM
SELECT setval('events_intermediate_id_seq', nextval('events_id_seq') + 1000);
```

### Ready to swap
The subset of original tables rows are copied over. The replacement table structure is identical, including columns, data types, constraints, and indexes.

We're ready to swap.

Here's the 
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

Alright! The new smaller table has been swapped in. Let's do one more pass to make sure any inserted rows into the former table weren't missed.

This should find close-to-zero rows. There could be rows committed after the transaction started and weren't visible.

To do that, this statement copies from the retired table, "events_retired", into the newly renamed "events" table.
```sql
INSERT INTO events
OVERRIDING SYSTEM VALUE
SELECT * FROM events_retired
WHERE id > (SELECT MAX(id) FROM events);
```

With this design, there could be a brief period where rows aren't available that are queried. You'll have to determine if this trade-off is ok with your system.

Note that the sequence name will continue to be `events_intermediate_id_seq` reflecting the "intermediate" suffix even though we've renamed the table.

## Let's talk about rollback
If things go wrong, you may want to reverse the steps. Let's look at how to do that.

Optionally, raise the sequence again by 1000, perhaps using the gap as a marker of this activity, and to leave some space again for missed rows.

Remember the sequence is called "events_intermediate_id_seq" if you haven't renamed it.

```sql
SELECT setval('events_intermediate_id_seq', nextval('events_intermediate_id_seq') + 1000);
```

Swap the names again.
```sql
BEGIN;
-- the new events table should be sent backward
-- to be the "intermediate" table.
-- The current "retired" table should be promoted to be the main table.
ALTER TABLE events RENAME TO events_intermediate;

-- Make the original jumbo table the main table
ALTER TABLE events_retired RENAME TO events;

COMMIT;
```

Now rows are flowing into a new table, but we’ll need to grab any missed ones.

```sql
-- Now we'd need to select from rows inserted into "events_intermediate"
-- that were missed.
-- They should be brought back into "events"
INSERT into events
OVERRIDING SYSTEM VALUE
SELECT *
FROM events_intermediate
WHERE created_at >= (NOW() - INTERVAL '1 hour')
ORDER BY id
ON CONFLICT (id) DO NOTHING;
```

Ideally you won't have to roll the steps back. However, consider practicing a rollback in advance so that you know how to use it if needed.

## Drop the old table
Let's imagine you didn't need the rollback. New rows are being inserted into the new, smaller table. Queries are accessing the last 30 days of data without errors.

The former table can now be archived, perhaps by using `pg_dump` to select all rows into a data file (or in chunks) for file storage.

Once optional archival is completed and verified (outside the scope of this post), the original table can be dropped.

Dropping the table is the last step in this process

```sql
-- Warning: Please review everything above.
DROP TABLE events_retired;
```

## Wrapping up

We've reviewed a process to, Copy, Swap, and Drop an "events" table.

Feel free to practice these steps using your own local Postgres instance, and send feedback you have as comments on this post, or on the referenced set of SQL operations on GitHub.

Thank you to Shayon Mukherjee for reading an earlier version of this post.

## Resources

- Copy-swap-drop on GitHub

## Feedback and Follow-Ups

> What about exclusively locking the table during copying?

Shayon Mukherjee read an earlier version of this post, and knows a thing or two about this type of thing, as the author of [pg-osc](https://github.com/shayonj/pg-osc).

What about locking the "events" table with exclusive access while the copy runs? An exclusive table lock could mean that inserts would error (when they couldn't acquire the lock in time, and assuming a lock_timeout was set).

I chose not to lock the table, which means any commits not visibile at transaction start time, given the isolation level of "read committed", meant that we'd do one more pass to find inserts after that transaction started but before it was committed.

This trade-off means there will be a small period where those inserted rows aren't queryable since they haven't yet been copied.

That could produce "not found" types of errors for those rows.

If that trade-off isn't acceptable, then the table could be locked explicitly, with a locking statement like `LOCK TABLE events;` inside the transaction, creating an `AccessExclusiveLock` of the table.

> What about a greater isolation level?

Another option for the name swap and final copy transaction would be to use a [greater isolation level](https://www.postgresql.org/docs/current/transaction-iso.html). `SERIALIZABLE` would be the sensible one if that was the goal.

Using `SERIALIZABLE` for the transaction would mean that any other concurrent insert, update, or delete transactions would need to run after this transaction is committed or rolled back.

> How was 1000 chosen?

1000 was an example of the amount of possible inserts for the last batch. Since we're moving from 30 days ago up to current, then we'd only "miss" the inserts that weren't yet committed for the final batch.

Since the name swap transaction includes one more batch, this reduces the "missed" rows further. If there are expected to be a few hundred while the batched copy and name swap runs, then 1000 makes sense.

Measure how long the batch copy takes and then increase the "gap", e.g. 10,000 or 100,000, if more rows are inserted in your system in the duration of the last batch copy.

> What about Foreign Keys?

Shayon pointed out most significant databases will have foreign key constraints. I left that out of the example for simplicity.

With foreign key constraints, I'd follow a process like this.

1. Copy table as shown earlier. Initially the intermediate table would have the foreign key constraint
1. Drop the foreign key constraint on the intermediate table, before copying rows.
1. Once complete, get the constraint definition from the source table.
1. Recreate the foreign key constraint on the newly swapped table, but initially `NOT VALID`. This acquires a shared lock and can be added initially for new rows.

Then validate the constraint as soon as possible using `VALIDATE CONSTRAINT`. That process also involves a few steps and is beyond the scope of this post, but I'd be happy to write it up if there's interest.
