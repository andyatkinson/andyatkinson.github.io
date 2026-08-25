---
layout: post
permalink: /postgresql-18-uuidv7
title: 63x Faster Inserts With PostgreSQL 18 v7 UUIDs
hidden: true
---

<div class="summary-box">
<strong>📌 Overview</strong>
<p>Execution time for INSERT queries on some high calls/min tables dropped significantly after switching their UUID primary keys from v4 and v1 to v7.</p>
<p>The databases are running Postgres 18.4 with uuid data type for primary keys and foreign keys.</p>
<p>To make the change, the alter column DDL while fast, required an access exclusive lock. While short, this blocks everything including selects. We used a short lock timeout and lots of retries to successfully perform the operation without downtime.</p>
</div>

We recently upgraded all databases to Postgres 18.4 and with that gained the `uuidv7()` function.

Since the system generally used v1 and v4 UUIDs with the `uuid` data type, and since we'd read about execution time reductions from others with v7, we were eager to try it out and see if we could achieve the same benefits.

How did it go?

## History and trade-offs for UUIDs
The system uses UUID primary keys throughout, v1 and v4 prior to this change. I have typically advocated for bigint and sequences over [UUID v4 primary keys](avoid-uuid-version-4-primary-keys). Fortunately this database used v1 which wasn't as bad as v4 due to having less randomness, which means insert performance wasn't as bad. However some key tables did use v4.

One of the main performance problems with v4 primary key UUIDs is how their randomness harms insert performance. As new rows are inserted and their keys need to be maintained in the b-tree index, their first bytes are compared to determine where to insert the new index entry.

Given the values are random, they will not nicely fill in from the right but could be sorted ahead of or behind any random value on any of the pages for the index.

Postgres caches index entry pages into buffer cache, which is DB instance memory allocated for caching. The host OS for Postgres also has a page cache.

When an index:
- has millions or billions of entries, and its size exceeds allocated buffer cache memory
- After Postgres sorts the index entry and determines the page for where to place it, it must load the page that holds that index entry
- This may be a cold page, outside of buffer cache, outside of page cache, and this means increased IO latency due to disk access

Since v4 index entries are scattered to more pages compared with filling in from the right, this means there will also be more "page splits" when index pages are full. Page splits cause more latency and also increase WAL, causing more IO.

Besides all of the concerns on inserts, v1 and v4 indexes use more space, and are slower to access for point lookups and range lookups.

We experimented and benchmarked with [v1, v4, and v7 uuid formats](https://github.com/andyatkinson/pg_scripts/tree/main/uuid_experiments) and we leveraged the research and write-ups from external sources like the ones below.

- [How Sequential UUIDv7 Boosts Ingestion Performance](https://www.tigerdata.com/blog/how-sequential-uuidv7-boosts-ingestion-performance)
- [Simplicity and power of UUID v7](https://alan.is/insights/simplicity-and-power-of-uuid-v7/)
- [PostgreSQL UUID Performance: Benchmarking Random (v4) and Time-based (v7) UUIDs](https://www.umangsinha.in/blog/postgresql-uuid-performance-benchmark)

Once ready to make the switch, how did we get started?

## Auditing where the UUIDs came from
First we went through and identified the current use.

In almost all cases, the values came from the column default which was the uuid generation function.

- The `uuid_generate_v1()` function from the [`uuid-ossp` module](https://www.postgresql.org/docs/current/uuid-ossp.html)
- The function `gen_random_uuid()` [added in Postgres 14](https://www.postgresql.org/docs/current/functions-uuid.html) that generates v4 UUIDs without the extension above
- UUID v4 values sent by a client application, which meant the column default function was not used

For nearly all instances, we wanted to replace these with the `uuidv7()` function in Postgres 18.

## How did the switch go?
One wrinkle we found was that modifying the column default while fast, required an `access exclusive` lock.

This lock type conflicts with *every* read and write operation including regular `select` statements.

For our highest queried tables, it's queried constantly, so this was a problem as there was almost never a "window" to perform this operation.

Before we get to how we solved that, let's look at a less complicated case.

In our migrations framework (Active Record in Ruby on Rails), we could perform the `alter table` using a regular old migration.

We did create an explicit transaction and used `set local` to control timeout values. We'd set very short timeouts for the `alter table` to give up quickly if it didn't work or ran too long.

From psql:
```sql
BEGIN;

SET LOCAL lock_timeout = '50ms';
SET LOCAL statement_timeout = '100ms';

ALTER TABLE my_table ALTER COLUMN id SET DEFAULT uuidv7();

COMMIT;
```

This worked for the majority of tables. For the higher activity tables, we'd need some retries. We'd use a manual psql session:
```sql
SET lock_timeout = '50ms';
SET statement_timeout = '100ms';
ALTER TABLE my_table ALTER COLUMN id SET DEFAULT uuidv7();
```

The `alter table` would commit if it grabbed the lock within 50ms, or we'd get an error that the `lock_timeout` was reached.

This way we could manually retry until successful and backfill a Rails migration to keep everything in sync.

However, for our most heavily queried tables, changing the PK column default there required an upgraded approach to retries.

## Bringing in the big retry machinery
Sometimes one or two retries would do the job. Great, we'd move on.

However, for our most heavily queried table that didn't work.

What ended up working was using the same strategy of retries, but just adding more sophistication with looping and backoffs.

Claude helped me cook up the PL/pgSQL looping retry function below with these features:
- Try up to 50 times (max attempts is configurable)
- Add a pause in between retries, with a jittered backoff of 50-250ms

From psql:
```sql
SET statement_timeout = 0;
SET lock_timeout = '100ms';

DO $$
DECLARE
  attempt      INT := 0;
  max_attempts INT := 50;
BEGIN
  LOOP
    attempt := attempt + 1;
      BEGIN
        EXECUTE 'ALTER TABLE my_table ALTER COLUMN id SET DEFAULT uuidv7()';
        RAISE NOTICE 'Succeeded on attempt %', attempt;
        EXIT;
      EXCEPTION WHEN lock_not_available THEN
        IF attempt >= max_attempts THEN
          RAISE EXCEPTION 'Failed to acquire lock after % attempts', attempt;
        END IF;
      PERFORM pg_sleep(0.05 + random() * 0.2);  -- jittered backoff, 50-250ms
    END;
  END LOOP;
END $$;
```

By using the function above, we were able to find a small window to perform the `alter table` after a burst of a couple of dozen retries.

## Actively cancelling lock-holding queries
In cases where even that doesn't work, and we don't want downtime, we may be left with needing to actively monitor and cancel queries holding the lock.

Thanks to Ants Aasma from the community PostgreSQL Slack for this idea.

We can inspect live queries:
```sql
SELECT
  pid, state, left(query,100), xact_start, state_change,
  age(clock_timestamp(), xact_start) AS tx_duration
FROM
  pg_stat_activity
WHERE
  state != 'idle'
ORDER BY xact_start;
```

And identify queries holding locks:
```sql
SELECT
  blocked_locks.pid AS blocked_pid,
  blocking_locks.pid AS blocking_pid,
  blocked_activity.query AS blocked_statement,
  blocking_activity.query AS current_statement_in_blocking_process
FROM
  pg_catalog.pg_locks blocked_locks
JOIN
  pg_catalog.pg_stat_activity blocked_activity
  ON blocked_activity.pid = blocked_locks.pid
JOIN pg_catalog.pg_locks blocking_locks
  ON blocking_locks.locktype = blocked_locks.locktype
  AND blocking_locks.relation IS NOT DISTINCT FROM blocked_locks.relation
  AND blocking_locks.pid != blocked_locks.pid
JOIN pg_catalog.pg_stat_activity blocking_activity
  ON blocking_activity.pid = blocking_locks.pid
WHERE NOT blocked_locks.granted;
```

If we find them, we could cancel them to create a window to run our `alter table`. Hopefully they can be retried.
```sql
SELECT pg_cancel_backend(blocking_pid);
```

We'd likely want to stack up our `alter table` immediately after. I didn't end up needing to do this.

With all of the tables modified, what did our results look like?

## What kinds of improvements did we see?
I began going through each table looking for the effect. For many of the tables, there wasn't an obvious reduction in insert execution times.

However, I picked 5 tables where execution times dropped significantly and the graphs were fun to see. The biggest gains were 8x, 9x, 20x, 23x, and even 63x! A few are shown below.

<table class="styled-table">
  <thead>
    <tr>
      <th></th>
      <th>Calls/min</th>
      <th>Original time</th>
      <th>New</th>
      <th>Reduction</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>Table A</td>
      <td>9500/min</td>
      <td>0.50ms</td>
      <td>0.08ms</td>
      <td>📉 63x</td>
    </tr>
    <tr>
      <td>Table B</td>
      <td>12000/min</td>
      <td>0.7ms</td>
      <td>0.03ms</td>
      <td>📉 23x</td>
    </tr>
    <tr>
      <td>Table C</td>
      <td>2000/min</td>
      <td>0.6ms</td>
      <td>0.07ms</td>
      <td>📉 9x</td>
    </tr>
  </tbody>
</table>

Showing PgAnalyze insert graphs from tables A, B, C:
![](/assets/images/uuidv7-2-table-th-pganalyze.jpg)
<br/>
<small>Table A - 63x reduction. 0.50ms to 0.08ms, 9500/min</small>

![](/assets/images/uuidv7-4-table-do-pganalyze.jpg)
<br/>
<small>Table B - 23x reduction. 0.7ms to 0.03ms, 12000/min</small>

![](/assets/images/uuidv7-3-table-c-pganalyze.jpg)
<br/>
<small>Table C - 9x reduction. 0.6ms to 0.07ms, 2000/min</small>


## Wrap Up
We found some significant execution time reductions after switching to `uuidv7()` primary keys when replacing v1 and v4 values.

The only wrinkle in performing the switch was the exclusive lock required for the `alter table alter column` DDL for very actively queried tables. That was solvable using a very short lock timeout and retrying a bunch of times until the fast DDL operation could run.

Although this didn't benefit 100% of our tables, the gains for some tables after switching to `uuidv7()` have been significant enough that this has become the new default choice for uuid columns. This post also looked at average execution times, but we expect even better gains with inserts for the high tail latencies.

Thanks to the Postgres core team for creating this new capability within Postgres, which made it easier to adopt for AWS RDS with limited extension support.

Thanks for reading and until next time.
