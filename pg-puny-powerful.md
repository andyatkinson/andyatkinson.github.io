---
layout: page
permalink: /pg-puny-powerful
title: PostgreSQL Puny to Powerful
---

# RailsConf Prep And Background

* Reviewed 6 past RailsConf PostgreSQL talks: Phoenix (2017) [#1](https://www.youtube.com/watch?v=_wU2dglywAU), Pittsburgh (2018) (1) [#2](https://www.youtube.com/watch?v=8gXdLAM6B1w) and Minneapolis (2019) (4) [#3](https://www.youtube.com/watch?v=a4OBp6edNaM) [#4](https://www.youtube.com/watch?v=B-iq4iHLnJU) [#5](https://www.youtube.com/watch?v=vfiz1J8mWEs) [#6](https://www.youtube.com/watch?v=1VsSXRPEBo0)
* PostgreSQL is a general purpose database for a variety of workloads. We care about 🕸️ `web applications`.
* Selected 5 Use Cases Around Scaling and Performance


## Migrations On Busy Databases

### Locking, Blocking, Queueing

* [Lock Queue](https://joinhandshake.com/blog/our-team/postgresql-and-lock-queue/)
* [PostgreSQL Explicit Locking](https://www.postgresql.org/docs/current/explicit-locking.html)
* [Postgres Locking Revealed](https://engineering.nordeus.com/postgres-locking-revealed/)
* [What Postgres SQL causes a Table Rewrite?](https://www.thatguyfromdelhi.com/2020/12/what-postgres-sql-causes-table-rewrite.html)
* [PostgreSQL Alter Table and Long Transactions](http://www.joshuakehn.com/2017/9/9/postgresql-alter-table-and-long-transactions.html)

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

### Table rewrites

Definition for table rewrites:
Something like "A table rewrite is a behind-the-scenes copy of the table with a new structure, and all row data copied from the old structure to the new structure"

> Via lukasfittl

I think thats correct - I was trying to confirm whether alter table commands that require a rewrite actually make a full copy (as indicated by the documentation), and it does appear so, see here in the source: <https://github.com/postgres/postgres/blob/master/src/backend/commands/tablecmds.c#L5506>


## Exhausting Connections

* How many have been idle for a long time?
* Assessing connection usage for application servers and background processes
* High Connections in PgHero. `show max_connections;`

## Forking Processes

* postmaster is first process. Additional background processes are started: BG writer, Autovacuum launcher, Check pointer etc. [See full list here](https://medium.com/nerd-for-tech/what-is-forking-in-postgresql-58e23458f026)
* [Memory used by connections](https://aws.amazon.com/blogs/database/resources-consumed-by-idle-postgresql-connections/)
  * PostgreSQL uses shared memory and process memory


## Connections Resources

* [Estimate database connections pool size for Rails application](https://docs.knapsackpro.com/2021/estimate-database-connections-pool-size-for-rails-application)


## High Performance SQL Queries

* [auto_explain](https://www.postgresql.org/docs/current/auto-explain.html)
* [pganalyze query slowness](https://pganalyze.com/docs/checks/queries/slowness)


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
* Use [pg_cron](https://www.citusdata.com/blog/2016/09/09/pgcron-run-periodic-jobs-in-postgres/)
* [pg_cron : Probably the best way to schedule jobs within PostgreSQL database.](https://fatdba.com/2021/07/30/pg_cron-probably-the-best-way-to-schedule-jobs-within-postgresql-database/)

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

* [Multiple Databases](https://guides.rubyonrails.org/active_record_multiple_databases.html)

* Concrete example with rideshare
* Query trips table from replica


### Partitioning Example With Range Partitioning

* Example using pgslice to range partition trips table on `created_at`
* [Partition Pruning](https://www.postgresql.org/docs/current/ddl-partitioning.html#DDL-PARTITION-PRUNING)
  * When the planner can prove a partition can be excluded, it excludes it.
* [Partitioning and Constraint Exclusion](https://www.postgresql.org/docs/current/ddl-partitioning.html#DDL-PARTITIONING-CONSTRAINT-EXCLUSION)

```
SET enable_partition_pruning = on;                 -- the default
SHOW constraint_exclusion;
SET constraint_exclusion = partition; -- the default, or "on"
```

* Constraint Exclusion

### Partitioning Resources

* [Partitioning Large Tables](https://gpdb.docs.pivotal.io/5270/admin_guide/ddl/ddl-partition.html)
