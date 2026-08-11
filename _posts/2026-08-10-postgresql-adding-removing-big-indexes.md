---
layout: post
permalink: /postgresql-big-indexes
title: Adding and Removing Big Indexes in PostgreSQL
hidden: true
---

In this post we'll look at a recipe for adding and removing big indexes on big tables. The create operation can take hours, so it's helpful to have a plan in place for this to run in the background and to monitor progress.

We'll assume these operations take place at the same time as the client application queries, which means they run `concurrently` and we'll need to monitor the resources being used.

### Using a lock timeout
Without using concurrently, `create index` takes a ShareLock (<https://pglocks.org/?pgcommand=CREATE%20INDEX>) lock on the table and other important write operations require this same lock level, which means they conflict.

This conflict means that operations that hold the same lock type are put into a queue and wait until the lock they require is available. This is a problem on a live system! This means that queued write operations requiring the same lock type are blocked until the lock is available.

That means we want to add a safeguard against this. What we're guarding is the time taken to acquire the lock for our own operation. Without this guard, our own operation would keep waiting and waiting to acquire the lock, causing a pile up of conflicting operations behind it.

A reasonable value for this is 2 seconds.

This is among the first things I'll set:

From psql:
```sql
set lock_timeout='2s;'
```

I also will set `\timing` which is a metacommand that will print out how long the statement took.

### Statement timeout
The next thing we may run into is our create index statement will take a long time. From psql run `show statement_timeout` to see the current statement timeout value.

I have typically extended this to a long time to allow enough time like 20 minutes, 1 hour, 2 hours, but it's always a guess, and it's really painful if you guess too low and your statement is ended prematurely the timeout you've set.

Recently I learned to simply disable it for my session which avoids that problem. Alternatively we could set this to be an excessively long time like 24 hours, but we should also be monitoring progress and systems should alert for long running statements. If you don't have this kind of system then it may make more sense to set a very high value.

For our recipe we'll disable it from psql like this:

```sql
set statement_timeout=0;
```

## Why not create the index while the table is offline?
Creating indexes concurrently does take longer, so is it worth it?

> When this option is used, PostgreSQL must perform two scans of the table, and in addition it must wait for all existing transactions that could potentially modify or use the index to terminate. 

Right off the bat, we're in for 2x the scans of our huge table, so we know this will take longer, but given it will take hours it’s really the only option as the alternative of preventing writes to this table while the index is created non-concurrently is too severe of a downside. We don’t even know how long that would take (we could test it on a snapshot-restored detached instance), but it would likely be 2 hours.

The concurrent index build then allows other operations on the table like updates to occur concurrently. This means it runs outside of any transaction. The index build process happens through a series of phases that occur serially. The state of the index is initially entered “invalid” which is also the state it will be in if one of the phases fails.
<https://www.postgresql.org/docs/current/sql-createindex.html>


## Run in the background
We want to perform this operation from a psql client we've detached from. This means we can disconnect from the host where the client program is running, and connect again later without disrupting it.

To do that I use either screen or tmux.

I typically use screen on a host I'm connected to as I use tmux locally, so it's less confusing to only use screen on remote hosts for me.

```sh
screen -S andrew-index-maintenance
psql <connection-string>
```

Then detach:
```
ctrl-a d
```

To list sessions, reattach, and other tips check out my [dotfiles screen section](https://github.com/andyatkinson/dotfiles#screen).


## Monitor progress
From a second psql session connected to the same database, we can run a special query to monitor the progress of the concurrent index build.

Run query [`concurrent_index_build_progress.sql`](https://github.com/andyatkinson/pg_scripts/blob/main/concurrent_index_build_progress.sql).

Concurrently, multiple phases

Scanning heap phase is IOPS intensive, we typically exceed our max provisioned IOPS amount. This seems to be allowed by RDS but there is a penalty then of increased disk queue which can then cascade into increased disk latency.

Sorting live tuples phase is CPU intensive

Many more phases:

- Loading tuples in tree phase

Reduces the big burn on IOPS 
Reduces the CPU use
Still takes a long time.

We get `% tuples done` progress from the query.

Run the query

Run `\watch 2` to repeat it every 2 seconds. I use `\x` in psql to format the query results vertically.

Here's an example with a fictional table `my_tbl` and a fictional unique index.

This example has completed 66.67% of the "building index: loading tuples in tree" phase.

```sql
-[ RECORD 1 ]------+------------------------------------------------------------------
duration           | 03:43:04.180631
query              | create unique index concurrently idx_my_tbl_field1_field2 +
                   | on my_tbl (field1)                                     +
                   | include (field2);
phase              | building index: loading tuples in tree
% blocks done      |
blocks_total       | 0
blocks_done        | 0
% tuples done      | 66.76
tuples_total       | 4968812906
tuples_done        | 3317340601
command            | CREATE INDEX CONCURRENTLY
lockers_total      | 0
lockers_done       | 0
current_locker_pid | 0
index_name         | idx_my_tbl_field1_field2
table_name         | my_tbl
table_size         | 1613 GB
pid                | 30399
```


## Setting maintenance_work_mem
We can set this up to 25% of system memory if that memory is available, using a a session variable. Run `show maintenance_work_mem;` to see the current value.

For a 128GB memory instance we could set:

```sql
SET maintenance_work_mem = '32GB';
```

## Setting max_parallel_maintenance_workers
The system is normally set to have 2 parallel workers for maintenance.

The param `max_parallel_workers` dictates the max value for *all* parallel workers, not just maintenance. This was set to 8 so we could use them all by taking 8 for the big index build:

```sql
SET max_parallel_maintenance_workers = 8;
```


## Some timing
For a recent very large index the total duration was around 6 hours.

Some of the timings from the concurrent build phases I jotted down were:

- ~ 1 hr scanning heap
- ~ 3 hrs sorting tuples
- (~ 1 hr ?) index validation: scanning index
- Fast, e.g. 5 minutes: index validation: sorting tuples  (sorting tuples again!) (fast - 5 mins)
- ~ 1 hr index validation: scanning table   


## What if building the index fails
There are different reasons the operation can be aborted and fail.

Although this means we'll need to try again, fortunately the remnants are not difficult to clean up.


We're left with an "Invalid index". If the query is cancelled and an invalid index is left over, clean it up by dropping it concurrently:
```sql
drop index concurrently idx_my_tbl_field1_field2;
```

## Uniqueness quirks
Also, if a failure does occur in the second scan, the "invalid" index continues to enforce its uniqueness constraint afterwards.


## Limitations
Only one concurrent index build can occur on a table at time. Besides creating an index, the one-at-a-time restriction applies to rebuilding an index using `reindex concurrently`.

Non-concurrent index builds or rebuilds can occur.

Concurrent index builds for partitioned tables are not supported as of Postgres 18.

The concurrent index documentation covers how to achieve an equivalent result. <https://www.postgresql.org/docs/current/sql-createindex.html> That’s beyond the scope of this post though as it works with an unpartitioned table.


## Final Recipe
```sql
\conninfo -- sanity check connected to correct DB
\d my_table -- sanity check "my_index" does not exist for "my_table"

\timing
set lock_timeout='2s';
set statement_timeout=0;

create index concurrently if not exists my_index on my_table (my_field);

-- sanity check when complete, make sure it's not invalid
-- the index should start immediately being scanned
\d my_table
```

If I need to drop an invalid index or an unused index:
```sql
-- sanity checks
\conninfo
\d my_table -- confirm index "my_index" exists for my table

\timing
set lock_timeout='2s';
set statement_timeout=0;
drop index concurrently if exists my_index;
```

## Wrap Up
Thanks for reading.
