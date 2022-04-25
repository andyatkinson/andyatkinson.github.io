---
layout: page
permalink: /pg-puny-powerful
title: PostgreSQL Puny to Powerful
---

## Migrations On Busy Databases

### Locking, Blocking, Queueing

* [Lock Queue](https://joinhandshake.com/blog/our-team/postgresql-and-lock-queue/)
* [PostgreSQL Explicit Locking](https://www.postgresql.org/docs/current/explicit-locking.html)
* [Postgres Locking Revealed](https://engineering.nordeus.com/postgres-locking-revealed/)

### Example

* Transaction never conflicts with itself
* We can create a made-up example that opens a transaction and creates a lock in one session, then tries an `alter table` in a second session

Using the rideshare database and trips table

```
-- first psql session
anatki@[local]:5432 rideshare_development# begin;
BEGIN
Time: 0.129 ms

anatki@[local]:5432* rideshare_development# lock trips in access exclusive mode;
LOCK TABLE
Time: 0.103 ms

# select mode, pg_class.relname, locktype, relation from pg_locks join pg_class ON pg_locks.relation = pg_class.oid AND pg_locks.mode = 'AccessExclusiveLock';
-[ RECORD 1 ]-----------------
mode     | AccessExclusiveLock
relname  | trips
locktype | relation
relation | 461492

--- in second psql session, attempt to migrate the database with an alter table
alter table trips add column city_id integer default 1;

-- now we can look at lock activity and see that it is blocked
# select wait_event_type,wait_event,query from pg_stat_activity where wait_event = 'relation' AND query like '%alter table%';
-[ RECORD 1 ]---+--------------------------------------------------------
wait_event_type | Lock
wait_event      | relation
query           | alter table trips add column city_id integer default 1;

-- lock timeout is 0 which means it is disabled
show lock_timeout;

```

If lock timeout is disabled entirely, setting it will set an upper bound on how long the alter table transaction is in a blocked state.

We can see that the lock timeout is the reason that the transaction is cancelled.

```
anatki@[local]:5432 rideshare_development# begin;
BEGIN
Time: 0.085 ms
anatki@[local]:5432* rideshare_development# SET LOCAL lock_timeout = '5s';
SET
Time: 0.078 ms
anatki@[local]:5432* rideshare_development# alter table trips add column city_id integer;
ERROR:  canceling statement due to lock timeout
Time: 5001.250 ms (00:05.001)
```

Recommendation:

* Set a lock timeout
* Set it high enough to allow some waiting, but not so long that transactions are blocked for a long time
* If lock timeout is exceeded, likely need to try again at a less busy time
* A long running statement may be cancelled by the statement timeout. Consider raising statement timeout just for the migration session.


## Exhausting Connections

* How many have been idle for a long time?
* Assessing connection usage for application servers and background processes
* High Connections in PgHero. `show max_connections;`


## High Performance SQL


### PgHero

* Statistics about database size, table size, index size
* Work on high impact queries via statistics with `pg_stat_statements`
* High connections
* Foreign key constraints marked `NOT VALID` (still enforced for new inserts or updates)
* Parameter values


### PgHero Customizations

* Index Bloat Estimated Percentage (hidden index bloat page)
* Scheduled Jobs via `pg_cron`

## High Impact Maintenance

* [Routing Reindexing](https://www.postgresql.org/docs/current/routine-reindex.html)
* <https://www.postgresql.org/docs/current/sql-reindex.html>

> It might be worthwhile to reindex periodically just to improve access speed.

* REINDEX requires ACCESS EXCLUSIVE
* Use with CONCURRENTLY option, which requires only a SHARE UPDATE EXCLUSIVE

```
andy@[local]:5432 rideshare_development# reindex index trips_intermediate_rating_idx;
REINDEX
Time: 13.556 ms
andy@[local]:5432 rideshare_development# reindex index concurrently trips_intermediate_rating_idx;
REINDEX
Time: 50.108 ms
```

## Replication and Partitioning


### Multiple Databases Replication Example

* Concrete example with rideshare
* Query trips table from replica


### Partitioning Example With Range Partitioning

* Concrete example with pgslice and trips table
