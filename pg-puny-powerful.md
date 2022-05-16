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

###

* [PostgreSQL: How to update large tables](https://blog.codacy.com/how-to-update-large-tables-in-postgresql/)

### Example: Slow DDL changes with a volatile default

```sql
create database if not exists pup_tracker_production;

-- create pups
create table pups (id bigserial, name varchar);

-- create locations
create table locations (
  id bigserial primary key, -- or omit `primary key` to create without PK index
  latitude NUMERIC(14, 11),
  longitude NUMERIC(14, 11)
);

-- generate 1 million pups
-- around 3s
INSERT INTO pups (name) select substr(md5(random()::text), 0, 6) from generate_series(1,1000000);

-- generate 10 million locations
-- around 38s, or 1m 10s with a primary key
INSERT INTO locations (latitude, longitude) SELECT
  (random() * (52.477040512464626 - 52.077090052913654)) + 52.077090052913654 AS lat,
  (random() * (52.477040512464626 - 52.077090052913654)) + 52.077090052913654 AS lng
FROM generate_series(1,10000000);

-- add column with default value
-- 5ms with default, 2ms without, non-volatile value
-- repeated runs the difference is too small to notice
alter table locations add column city_id integer default SELECT floor(random()*25);

-- DDL to add column but with a "volatile" value, a random integer between 0 and 25
-- takes around 25s! This would be bad if the table is locked with `ACCESS EXCLUSIVE` in this time period
alter table locations add column city_id integer default floor(random()*25);
```


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
* [Concurrency and Database Connections in Ruby with ActiveRecord](https://devcenter.heroku.com/articles/concurrency-and-database-connections)
* [What are advantages of using transaction pooling with pgbouncer?](https://stackoverflow.com/a/12189973/126688)
* [Be Prepared!](https://medium.com/@devinburnette/be-prepared-7768d1a111e1)

### Prepared statements SQL

Simple example, select a row by primary key id.

```
prepare loc (int) as select * from locations where id = $1;
execute loc(1);
```

### Example: PgBouncer

Default port is `6432` or 1000 higher than default PostgreSQL port `5432`

On Mac OS install with `brew install pgbouncer`

PgBouncer config: [pgbouncer.ini](https://pgbouncer.github.io/config.html)

- `brew services restart pgbouncer`
- `brew services info pgbouncer`

Or run manually:

`/usr/local/opt/pgbouncer/bin/pgbouncer -q /usr/local/etc/pgbouncer.ini`

Existing DB connection:
`psql "postgresql://andy:@localhost:5432/pup_tracker_production"`


```sql
-- Make a test app user
CREATE USER app_user WITH PASSWORD 'jw8s0F4';
```

[PgBouncer Quick Start](https://www.pgbouncer.org/usage.html)

Set up `app_user` as an admin for simplicity

```
[pgbouncer]
 listen_port = 6432
 listen_addr = localhost
 auth_type = md5
 auth_file = /usr/local/etc/userlist.txt
 logfile = pgbouncer.log
 pidfile = pgbouncer.pid
 admin_users = app_user
```

Now we can connect using psql via pgbouncer:

`psql "postgresql://app_user:jw8s0F4@localhost:6432/pup_tracker_production"`

View some information:

`psql -p 6432 -U app_user -W pgbouncer` (Use password from above)

[PgBouncer Cheat Sheet](https://lzone.de/cheat-sheet/PgBouncer)

Online restart (without disconnecting clients)

`pgbouncer -R` or send a `SIGHUP` signal

Commands:

- `show clients`
- `show databases`, review the `pool_size`, `pool_mode` etc.

- Pool modes (most aggressive and least compatible, to least aggresive, most compatible)

> Specifies when a server connection can be reused by other clients.

* session: Server is released back to pool after client disconnects. Default.
* transaction: Server is released back to pool after transaction finishes.
* statement: Server is released back to pool after query finishes. Transactions spanning multiple statements are disallowed in this mode.

Cannot use transaction pooling mode while also using prepared statements, which are enabled by default in Rails.

Limited to session mode. Alternately, disable prepared statements and then transaction mode may be used.


## High Performance SQL Queries

* [auto_explain](https://www.postgresql.org/docs/current/auto-explain.html)
* [pganalyze query slowness](https://pganalyze.com/docs/checks/queries/slowness)
* [Tip: Use `to_sql` to see what query ActiveRecord will generate](https://boringrails.com/tips/active-record-to-sql)


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
