---
layout: post
permalink: /postgresql-18-uuidv7
title: Up To 23x Faster Inserts With PostgreSQL 18 v7 UUIDs
hidden: true
---

<div class="summary-box">
<strong>📌 Overview</strong>
<p>We recently adopted v7 uuids for table primary keys, and for a handful of tables we saw a significant drop in execution time for insert queries.</p>
<p>The databases were running Postgres 18.4 and using mostly v1 uuids with some v4 for primary keys.</p>
<p>Changing the column default is straightforward and fast, but does require an access exclusive lock on the table which blocks everything including selects. To solve that we used a short lock timeout and lots of retries.</p>
<p>In the best case we saw a 23x improvement in average execution time for inserts at 12000 calls/min on a table with billions of rows.</p>
</div>

## History and trade-offs with UUIDs
The system uses UUID primary keys throughout. I typically recommend starting with bigint and sequences over [UUID v4 primary keys](avoid-uuid-version-4-primary-keys), although here uuid v1 was used and this format does not have as bad of performance as v4.

Still though, v7 brings better performance for inserts, and can result in more compact and with less CPU and IO from page splits.

What makes v4 and to a lesser extent v1, bad for insert performance? Let's do a quick refresher. As new table rows are inserted and a primary key is defined, primary key values are maintained in sorted order in a b-tree index. The first bytes of values are compared to determine which index page to place the new index entry.

For v4 new values are random, they aren't monotonically increasing (they lack "monotonicity"), they could be sorted earlier or later, it's random.

When Postgres inserts the index entry into a page, and the page was recently accessed, it's "hot" in the buffer cache, this is a cache hit and means the latency is minimal.

With v4 and to a lesser extent v1, what happens is Postgres is not using the most recently used index page much or most of the time, meaning the page access can be "cold", outside of buffer cache, possibly out of OS cache, meaning a slow disk read with high latency.

Besides the worse insert performance, since v4 values are scattered to more pages, this means there are more "page splits" when the target page is full. Page splits cause more latency and also increase WAL, which also causes more IO.

We experimented and benchmarked with [v1, v4, and v7 uuid formats](https://github.com/andyatkinson/pg_scripts/tree/main/uuid_experiments) and we leveraged the research and write-ups from external sources like the ones below.

1. [How Sequential UUIDv7 Boosts Ingestion Performance](https://www.tigerdata.com/blog/how-sequential-uuidv7-boosts-ingestion-performance)
1. [Simplicity and power of UUID v7](https://alan.is/insights/simplicity-and-power-of-uuid-v7/)
1. [PostgreSQL UUID Performance: Benchmarking Random (v4) and Time-based (v7) UUIDs](https://www.umangsinha.in/blog/postgresql-uuid-performance-benchmark)

Besides the insert-performance concerns, post #3 above shows that v1 and v4 indexes can use more space for equivalent content, which can make point and range lookups slower.

With v7, we're looking to preserve the collision avoidance without any central coordination benefits, but also leverage the timestamp portion for monotonicity and hot index page page access, greatly reducing latency.

What kinds of results did we see?

## What kinds of improvements did we see?
Note that we performed the `alter table alter column` DDL operation (covered later) with the tables online during normal daytime activity. No other changes affected these results apart from this singular change.

After all tables were changed, I began going through the insert queries for each one looking at results. For many of the tables, there wasn't an obvious reduction in insert execution times.

However, for a handful of the, there was an immediate and significant reduction. I picked 5 with reductions of 6x, 8x, 9x, 20x, and 23x. Three tables have their main insert query graphs from PgAnalyze shown below.

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
      <td>12000</td>
      <td>0.7ms</td>
      <td>0.03ms</td>
      <td>📉 23x</td>
    </tr>
    <tr>
      <td>Table B</td>
      <td>2000</td>
      <td>0.6ms</td>
      <td>0.07ms</td>
      <td>📉 9x</td>
    </tr>
    <tr>
      <td>Table C</td>
      <td>9500</td>
      <td>0.50ms</td>
      <td>0.08ms</td>
      <td>📉 6x</td>
    </tr>
  </tbody>
</table>

Showing PgAnalyze insert query graphs for tables A, B, C:
![](/assets/images/uuidv7-4-table-do-pganalyze.jpg)
<br/>
<small>Table A - 23x reduction. 0.7ms to 0.03ms, 12000 calls/min</small>

![](/assets/images/uuidv7-3-table-c-pganalyze.jpg)
<br/>
<small>Table B - 9x reduction. 0.6ms to 0.07ms, 2000 calls/min</small>

![](/assets/images/uuidv7-2-table-th-pganalyze.jpg)
<br/>
<small>Table C - 6x reduction. 0.50ms to 0.08ms, 9500 calls/min</small>

Now that we've seen the results, let's talk about how this was done and the challenges.

## Auditing where the UUIDs came from
First we went through and identified the current use.

In almost all cases, the values came from the column default which was the uuid generation function.

- The `uuid_generate_v1()` function from the [`uuid-ossp` module](https://www.postgresql.org/docs/current/uuid-ossp.html)
- The function `gen_random_uuid()` [added in Postgres 13](https://www.postgresql.org/docs/current/functions-uuid.html) that generates v4 UUIDs without the extension above
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

## Downsides of uuid v7
Since uuid v7 values use a timestamp in their first bits, this timestamp can be easily decoded. This can be viewed as "leaking" or exposing the creation time, where v4 does not have this property.

## Wrap Up
We found some significant execution time reductions after switching to `uuidv7()` primary keys when replacing v1 and v4 values.

The only wrinkle in performing the switch was the exclusive lock required for the `alter table alter column` DDL for very actively queried tables. That was solvable using a very short lock timeout and retrying a bunch of times until the fast DDL operation could run.

Although this didn't benefit 100% of our tables, the gains for some tables after switching to `uuidv7()` have been significant enough that this has become the new default choice for uuid columns.

Thanks to the Postgres core team for creating this new capability within Postgres, which made it easier to adopt for AWS RDS with limited extension support.

Thanks for reading and until next time.
