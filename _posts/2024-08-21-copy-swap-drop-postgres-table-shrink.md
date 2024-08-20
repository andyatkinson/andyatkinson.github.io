---
layout: post
title: 'Shrinking Big PostgreSQL tables: Copy-Swap-Drop'
tags: []
date: 2024-08-21
comments: true
---

In this post, we’ll look at a strategy for managing large tables with high row counts.

## A few big tables
Commonly, a few big tables are much larger in size than the other tables in a database. These jumbo tables contain high frequency or the data data-intensive features, capturing granular information. These tables can grow into the hundreds of gigabytes or terabytes in size.

While Postgres supports tables up to 32TB in size, working with large tables of 500GB or more can be problematic. Adding indexes or constraints is slow. Backups and restores slow down. Large tables might force a need to scale an instance solely for space consumption, but not compute.

Further, the application may need to access only a portion of the rows, such as recent rows. When that happens, the majority of the rows are unneeded for the application, and become more of an operational liability as opposed to a data asset.

How can we fix this situation?

## Making large tables easier to work with
One option in Postgres is to migrate table data into a replacement partitioned table. We aren’t going to cover table partitioning in this post, but for now we’ll assume that there are a set of benefits and trade-offs with partitioned tables. Let's look at the challenges of operating partitioned tables. Partitions need to be created in advance. The application code likely needs to change a bit to work with partitioned tables. Partitioned tables typically have a different primary key structure.

Let's imagine the hindrances to migrating to a partitioned table are significant. What other options are there?

## Introducing Copy-Swap-Drop
Without migrating to a replacement partitioned table, one tactics I’ve used is to create a replacement table with a cloned structure, and copy a portion of the rows over.

Here are the steps:

1. Clone the table structure
2. Copy a subset of the rows
3. Swap the table names
4. Drop the original table

This tactic is what’s used in the pgslice gem, and described in the one-off task section. In this post we’ll focus just on the SQL operations.

This process won’t shrink the original table in-place, but the end result is that the original table will effectively be "shrunk."

## SQL process steps
Let's try this on an imaginary table called "events". Imagine the events table was set up years ago and currently receives hundreds of thousands of rows or even millions of rows, every day. Let’s imagine it’s currently around 500GB in size and has more than 500 million rows.

When looking into the queries for the application, the application only shows up to the last 30 days of event data. This means event data older than 30 days isn’t needed by the application. While we may wish to archive the older row data and populate it in a different data store, by removing it from the application database, we can avoid some of the pain points listed above.

If the events table grows at 1 million rows per day, that’s around 30 million rows that we’d need to keep. That means about 470 million rows, which would be 94% of the total are rows that aren’t needed that can be removed.

Let's start the process.

# Clone the table
Let's use this structure for the examples:

```sql
CREATE TABLE events (
id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
col1 TEXT,
created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO events (col1) VALUES ('data');
INSERT INTO events (col1) VALUES ('more data');
```

First we’ll clone the table. Use the naming convention of "intermediate" added to the original table name. This is what’s done in pgslice. Since we’re going to copy rows over, we want to defer creating the indexes until after the row copying has completed, then add the indexes. The insert operations will be faster without indexes.

```sql
-- Step 1: Clone the table structure
CREATE TABLE events_intermediate (LIKE events INCLUDING ALL EXCLUDING INDEXES);
```

## Copy a subset of the rows
With the empty table created, we’ll determine how far back to start copying from the events table.

Let's find the first `id` that’s listed for rows with a `created_at` value that’s 30 days old.

```sql
-- 2. Copy a subset of rows
-- Find the first primary key id that's newer than 30 days ago SELECT id, created_at
FROM events
WHERE created_at > (CURRENT_DATE - INTERVAL '30 days')
LIMIT 1;
```

Imagine this id: `123456789`

With the id available, we can begin batched copying. Consider increasing the batch size as large as is possible without causing too much CPU or IO operations usage that takes away from the primary workload. It’s best to run this in a low activity time period, and add some pauses in between batched copies.

Let's use batch sizes of 1000 rows to start.  The query below filters on the primary key which will use the primary key index.

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

For brevity of this post, we’ll avoid making this re-runnable automatically. Assume you’re running successive batches of this manually for this post.

The goal now is to fill forward up to the current rows, from 30 days back up to the current time. Note that in your last batch, there will still be newer rows being created outside of the snapshot that your last `INSERT` transaction could see. We’ll get those though, don’t worry.

Now the `events_intermediate` has approximately 30 days of data, minus a few more that were missed. We’re ready to swap the table names so that the new smaller table takes over the original table name.

## Swap the tables

We’ll create a single transaction that captures any last rows, then performs two table rename operations. We’ll rename the original table and call it "retired," which is another naming convention that pgslice uses. Now that the original table name is available, we’ll rename the intermediate table to be the original table name.

Imagine the table primary key uses a sequence object called `events_id_seq`. We’re adding 1000 to the sequence value to as a buffer, to avoid primary key conflicts in the event of a rollback. 

This step is the "exciting" part as the new table will become the replacement table and immediately begin receiving the new writes. Make sure you’re ready for that.

```sql
BEGIN;

-- Rename original table to be "retired"
ALTER TABLE events RENAME TO events_retired;

-- Rename "intermediate" table to be original table name
ALTER TABLE events_intermediate RENAME TO events;

-- Since they're sharing the same sequence object, create some space.
-- Raise the current sequence value by 1000. This is not nececssary but is
-- a precaution to add some space in the event a rollback is needed

-- Capture the sequence value plus the raised, as NEW_MINIMUM
SELECT setval('events_id_seq', nextval('events_id_seq') + 1000);

COMMIT;
```

Alright! Now that the table’s swapped, there still could have been a few rows that were missed. Let's do one more pass to make sure they’re copied over. 

Now we’re copying from the retired table into the main table.

```sql
INSERT INTO events
OVERRIDING SYSTEM VALUE
SELECT * FROM events_retired
WHERE id > (SELECT MAX(id) FROM events);
```

## Drop the old table

Now the new smaller table is receiving writes, it has all the rows needed from the original table. The former table now can be archived, perhaps by using `pg_dump` to select all rows into a data file that can be backed up and restored. 

## Bonus Steps

If things go wrong, we may want to reverse the steps.

```sql
BEGIN;
-- the new events table should be sent backward
-- to being the "intermediate" table.
-- The current "retired" table should be promoted to be the main table.
ALTER TABLE events RENAME TO events_intermediate;

-- Make the original jumbo table the main table
ALTER TABLE events_retired RENAME TO events;

-- Raise sequence again by 1000, perhaps using the gap created as
-- a "marker" 
SELECT setval('events_id_seq', nextval('events_id_seq') + 1000);

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

## Changing sequence ownership
Sequence object ownership.


```sql
ALTER SEQUENCE events_id_seq OWNED BY events.id;
```

## More space reductions
We create indexes at the end, so the index pages only contain entries for current row versions, free of references to dead rows. This makes the indexes smaller and adds some nominal speed traversal speed boost for writes and reads.

This can also be a way to remove any unused indexes, by abandoning them on the old table. When that table is dropped, it takes the indexes along with it.

```sql
SELECT indexdef
FROM pg_indexes
WHERE tablename = 'users'
AND indexdef NOT LIKE '%UNIQUE%';
```


```sql
CREATE INDEX idx_users_sin_cov_partial
ON rideshare.users USING btree (id)
INCLUDE (first_name, last_name)
WHERE ((type)::text = 'Driver'::text)
```
