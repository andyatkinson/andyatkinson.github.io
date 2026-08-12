---
layout: post
permalink: /postgresql-18-uuidv7
title: PostgreSQL 18 v7 UUIDs
hidden: true
---

<div class="summary-box">
<strong>📌 Overview</strong>
<p>Average execution time for high calls/min insert queries dropped significantly after switching primary key columns to uuidv7() values on Postgres 18.4.</p>
</div>

We recently upgraded all databases to Postgres 18.4 and with that we gained the `uuidv7()` function that can generate v7 UUID values.

Since the system generally uses v1 and v4 UUIDs and the `uuid` data type for primary key column, we had plans to adopt v7 values to gain the insert efficiency advantages.

How did it go?

## History and trade-offs for UUIDs
The system uses UUIDs throughout. I have typically advocated for bigint and sequences over UUID values for primary keys, but I have softened my position on this as I worked on lots of client databases.

My main beef was the poor performance due to random IO from v4 UUIDs. The poor performance stemmed from reduced page density, more frequent page splits, and increased latency when inserting index entries.

Fortunately this system mostly uses v1 which are less efficient than v7 but do have a portion of bits corresponding to time and thus don't have as bad of latency as v4.

With that said, the system also used v4 in a couple of spots strategically, and in a couple of other spots unintentionally due to bad defaults. For example the default UUID type for newly generated was set to v4 unintentionally.

## Auditing where the UUIDs came from
First we went through and identified the current use.

For the UUID values they came from:
- The `uuid_generate_v1()` function from the [`uuid-ossp` module](https://www.postgresql.org/docs/current/uuid-ossp.html)
- The function `gen_random_uuid()` [added in Postgres 14](https://www.postgresql.org/docs/current/functions-uuid.html) that generates v4 UUIDs without the extension above
- UUID v4 values sent by a client application, which meant the column default function was not used

For nearly all instances, we wanted to replace these with the `uuidv7()` function in Postgres 18.

## How did the switch go?
One wrinkle was that modifying the column default generation function, while fast, requires an `access exclusive` lock.

This means the lock held conflicts with *everything* including regular `select` statements.

For our highest queried tables, this was a problem as there was almost never a "window" to perform this operation.

Let's look at the simpler case first.

In our migrations framework, we'd perform a transaction and use `set local` to set very short timeouts to try and perform the `alter table`:

From psql:
```sql
BEGIN;

SET LOCAL lock_timeout = '50ms';
SET LOCAL statement_timeout = '100ms';

ALTER TABLE my_table ALTER COLUMN id SET DEFAULT uuidv7();

COMMIT;
```

However, this didn't work for higher activity tables. For those we'd do the same thing from a psql session, but without a transaction:
```sql
SET lock_timeout = '50ms';
SET statement_timeout = '100ms';
ALTER TABLE my_table ALTER COLUMN id SET DEFAULT uuidv7();
```

The `alter table` would immediately commit if it grabbed the lock within 50ms, or we'd get an error that the `lock_timeout` was reached.

## Retrying the column modification
Sometimes one or two retries would do the job. We'd run the statement again and after a few tries it would work. Great, move on.

The most heavily queried table though was more tricky.

For that the strategy that worked was the same, retry until we got a "window". But we had to upgrade the machinery and try a lot more retries.

Claude helped me cook up the PL/pgSQL looping retry function below with these features:
- Try up to 50 times (configurable max attempts)
- Add a pause in between retries with a jittered backoff of 50-250ms

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

## Actively cancelling lock-holding queries
In cases where queries are holding the lock we need, we may need to actively monitor and cancel these queries to create a window.

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

We can identify queries holding locks:
```sql
SELECT
    blocked_locks.pid AS blocked_pid,
    blocking_locks.pid AS blocking_pid,
    blocked_activity.query AS blocked_statement,
    blocking_activity.query AS current_statement_in_blocking_process
FROM pg_catalog.pg_locks blocked_locks
JOIN pg_catalog.pg_stat_activity blocked_activity ON blocked_activity.pid = blocked_locks.pid
JOIN pg_catalog.pg_locks blocking_locks
    ON blocking_locks.locktype = blocked_locks.locktype
    AND blocking_locks.relation IS NOT DISTINCT FROM blocked_locks.relation
    AND blocking_locks.pid != blocked_locks.pid
JOIN pg_catalog.pg_stat_activity blocking_activity ON blocking_activity.pid = blocking_locks.pid
WHERE NOT blocked_locks.granted;
```


If we find them, we could cancel them to create a window to run our `alter table`. Hopefully they can be retried.
```sql
SELECT pg_cancel_backend(blocking_pid);
```

Fortunately I was able to avoid cancelling any queries using the looping retry function above.


## What kinds of improvements did we see?
I picked 5 tables where insert latency decreased significantly. The improvements were 8x, 9x, 20x, 23x, and 63x!

Below shows the tables for the 63x, 20x, and 9x reductions.
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

Showing graphs from tables A, B, C:

![](/assets/images/uuidv7-2-table-th-pganalyze.jpg)
<br/>
<small>Table A - 63x reduction. 0.50ms to 0.08ms, 9500/min</small>

![](/assets/images/uuidv7-4-table-do-pganalyze.jpg)
<br/>
<small>Table B - 23x reduction. 0.7ms to 0.03ms, 12000/min</small>

![](/assets/images/uuidv7-3-table-c-pganalyze.jpg)
<br/>
<small>Table C - 9x improvement. 0.6ms to 0.1ms, 2000/min</small>


## Wrap Up
We found significant insert latency reduction moving to `uuidv7()` primary key values from v1 or v4.

The only wrinkle is the exclusive lock for very busy tables, but that's solvable using the tactics above.

I would recommend moving any of the Postgres databases you maintain using uuid primary keys, to use `uuidv7()` to gain these advantages.

Thanks to the Postgres core team for creating this new capability.

Thanks for reading this post!
