---
layout: page
permalink: /pg-puny-powerful
title: PostgreSQL Puny to Powerful
---

Hello. This page contains additional resources for the presentation "Puny to Powerful PostgreSQL Rails Apps" given Wed. May 18, 2022 at RailsConf 2022 in Portland, OR.

Some of the examples below like lock contention, timing `alter table` DDLs on big tables, and the configuration of pgbouncer, are written up with the intent that the reader can try them out on their local development machines.

I also wrote a blog post [RailsConf 2022 Conference](/blog/2022/05/23/railsconf-2022) with more thoughts and reactions as a presenter.

<script async class="speakerdeck-embed" data-id="b9ac5608b0be4bb0ae01201e7fca7228" data-ratio="1.77777777777778" src="//speakerdeck.com/assets/embed.js"></script>

The additional resources and experiments below were items I developed while working on the content for the talk. In some cases the content was cut where it didn't quite fit in.

Roughly the following 5 major categories of the presentation are covered.

# RailsConf PostgreSQL Prep And Background

* I reviewed 6 past RailsConf talks about PostgreSQL
  * Phoenix (2017) [#1](https://www.youtube.com/watch?v=_wU2dglywAU)
  * Pittsburgh (2018) (1) [#2](https://www.youtube.com/watch?v=8gXdLAM6B1w)
  * Minneapolis (2019) (4) [#3](https://www.youtube.com/watch?v=a4OBp6edNaM)
  * [#4](https://www.youtube.com/watch?v=B-iq4iHLnJU), [#5](https://www.youtube.com/watch?v=vfiz1J8mWEs), [#6](https://www.youtube.com/watch?v=1VsSXRPEBo0)
* PostgreSQL is a general purpose database for a variety of workloads. This presentation is focused on `web applications` workloads ("online transaction processing" or OLTP).

The 5 topic areas were selected for being common, and gradually progressing from more common and with fewer trade-offs, to less common, more challenging to implement, with more significant benefits and trade-offs.


## Resources for "Migrations On Busy Databases"

* [PostgreSQL: How to update large tables](https://blog.codacy.com/how-to-update-large-tables-in-postgresql/)

### Example: Slow DDL changes with a volatile default

This is a way to simulate transactions contending for the same lock.

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


### Links for Lalso ocking, Blocking, Queueing

These are some pages I read to prepare for the talk with information about PostgreSQL pessimistic locking, MVCC, and the implications of lock contention.

* [Lock Queue](https://joinhandshake.com/blog/our-team/postgresql-and-lock-queue/)
* [PostgreSQL Explicit Locking](https://www.postgresql.org/docs/current/explicit-locking.html)
* [Postgres Locking Revealed](https://engineering.nordeus.com/postgres-locking-revealed/)
* [What Postgres SQL causes a Table Rewrite?](https://www.thatguyfromdelhi.com/2020/12/what-postgres-sql-causes-table-rewrite.html)
* [PostgreSQL Alter Table and Long Transactions](http://www.joshuakehn.com/2017/9/9/postgresql-alter-table-and-long-transactions.html)

### Example demonstrating locks and blocking

* Transaction never conflicts with itself
* We can create a made-up example that opens a transaction and creates a lock in one session, then tries an `alter table` in a second session

Using the [rideshare application database](https://github.com/andyatkinson/rideshare) and trips table

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

Setting `lock_timeout` will set an upper bound on how long the alter table transaction is in a blocked state.

We can see that the lock timeout is the reason that the transaction is canceled. PostgreSQL cancels the transaction when it reaches the lock timeout value.

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
* If the transaction is canceled, the transaction will need to be tried again at a less busy or contentious time
* A long running statement may be canceled by the statement timeout. Consider raising the statement timeout just for the migration duration. Strong Migrations gem does this by default, it sets a longer session-level statement timeout for the migration.

### Definition for "Table rewrites" triggered by some DDLs

Definition for table rewrites:

Roughly: A table rewrite is a behind-the-scenes copy of the table with a new structure, and all row data copied from the old structure to the new structure.

Discussion with [lukasfittl](https://twitter.com/LukasFittl) about that definition: "I think thats correct - I was trying to confirm whether alter table commands that require a rewrite actually make a full copy (as indicated by the documentation), and it does appear so, see here in the source: <https://github.com/postgres/postgres/blob/master/src/backend/commands/tablecmds.c#L5506>".


## Resources for Exhausting Database Connections

* How many have been idle for a long time?
* Assessing connection usage for application servers and background processes
* High Connections in PgHero. View the max configured connections: `show max_connections;`

## Notes on Forking the main PostgreSQL process

* Postmaster is first process that boots. Additional background processes are started: BG writer, Autovacuum launcher, Check pointer etc. and others. [See full list here](https://medium.com/nerd-for-tech/what-is-forking-in-postgresql-58e23458f026) or run `ps -ef | grep postgres` on a machine running postgres to view each of the processes.
* Resource consumption: [Memory used by connections](https://aws.amazon.com/blogs/database/resources-consumed-by-idle-postgresql-connections/)
  * PostgreSQL uses shared memory and process memory


## Database Connections Resources

* [Estimate database connections pool size for Rails application](https://docs.knapsackpro.com/2021/estimate-database-connections-pool-size-for-rails-application)
* [Concurrency and Database Connections in Ruby with Active Record](https://devcenter.heroku.com/articles/concurrency-and-database-connections)
* [What are advantages of using transaction pooling with pgbouncer?](https://stackoverflow.com/a/12189973/126688)
* [Be Prepared!](https://medium.com/@devinburnette/be-prepared-7768d1a111e1)

### Discussion of Prepared Statements

Prepared Statements are enabled by default in Rails, and are incompatible with transaction level pooling with pgbouncer. What are prepared statements?

Simple example below, manually taking a SQL statement and making it a prepared statement. Select a row by primary key id.

```
prepare loc (int) as select * from locations where id = $1;
execute loc(1);
```

What is the purpose of prepared statements?

> While providing a minimal boost in performance, this functionality also makes an application less vulnerable to SQL injection attacks.

> Active Record automatically turns your queries into prepared statements by default

`bundle exec rails console`
```
>> Location.find(1)
  Location Load (1.2ms)  SELECT "locations".* FROM "locations" WHERE "locations"."id" = $1 LIMIT $2  [["id", 1], ["LIMIT", 1]]
```

Exploring the prepared statement cache in Ruby on Rails:

```
ActiveRecord::Base.connection.execute('select * from pg_prepared_statements').values
```

> By default Rails will generate up to 1,000 prepared statements per connection

The prepared statement cache uses memory.

### Connection Pooling Example: PgBouncer

Default port is `6432` (a port number that is exactly 1000 higher than the default PostgreSQL port `5432`) :)

On Mac OS install with: `brew install pgbouncer`

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

Online restart (without disconnecting clients):

`pgbouncer -R` or send a `SIGHUP` signal

Commands:

- `show clients`
- `show databases`, review the `pool_size`, `pool_mode` etc.

- Pool modes (most aggressive and least compatible, to least aggressive, most compatible)

> Specifies when a server connection can be reused by other clients.

* session: Server is released back to pool after client disconnects. Default.
* transaction: Server is released back to pool after transaction finishes.
* statement: Server is released back to pool after query finishes. Transactions spanning multiple statements are disallowed in this mode.

Cannot use transaction pooling mode while also using prepared statements, which are enabled by default in Rails.

Limited to session mode. Alternately, disable prepared statements and then transaction mode may be used.


## Discussion points on High Performance SQL Queries

* [auto_explain](https://www.postgresql.org/docs/current/auto-explain.html)
* [pganalyze query slowness](https://pganalyze.com/docs/checks/queries/slowness)
* [Tip: Use `to_sql` to see what query ActiveRecord will generate](https://boringrails.com/tips/active-record-to-sql)


### Using PgHero: open source PostgreSQL Performance Dashboard

* Statistics about database size, table size, index size
* Work on high impact queries via statistics with `pg_stat_statements`
* High connections
* Foreign key constraints marked `NOT VALID` (still enforced for new inserts or updates)
* Parameter values


### PgHero Customizations

* Index Bloat Estimated Percentage (hidden index bloat page)
* Scheduled Jobs via `pg_cron`

## Discussing High Impact Database Maintenance

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

## Using PostgreSQL native Replication and Partitioning

### Using Multiple Databases with Replication for Rails Apps

* [Multiple Databases](https://guides.rubyonrails.org/active_record_multiple_databases.html)

* Concrete example with [andyatkinson/rideshare](https://github.com/andyatkinson/rideshare) TBD, in development
* Query trips table from replica


### Partitioning Example With Range Partitioning

* Example using [pgslice](https://github.com/ankane/pgslice) to range partition trips table on `created_at`
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


## Follow Up Questions

We had a few minutes for Q&A after the talk and there were some good questions. After some time passed I thought of additional answers for the questions and wanted to expand on them.

### Question: Why backfill in a migration?

Someone pointed out that the second potentially unsafe database migration was performing a backfill, and asked why not do that in a script or separate task?

That was a fair question and in practice typically we'd backfill in a rake task running via a Kubernetes job disconnected from the deployment process. I'd recommend that in a code review. However I've also seen folks backfill in a Rails migration.

The part we didn't discuss is that the migration mechanism is helpful if there are a lot of deployment environments. For example at Fountain we have over 10 environments to deploy to across shared multi-tenant and single tenant environments, each running their own instances of the applications, databases, and background processes.

Since we've already invested in migrating all environments from a single deployment mechanism, deployments are a mechanism to target all deployable environment databases at once, which may be useful for a backfill.

### Question: Why is throttling via sleep set at (`0.01` seconds)?

In the [Strong Migrations Backfilling](https://github.com/ankane/strong_migrations#backfilling-data) section there is an example of throttling a backfill by putting in a `0.01` sleep. Someone asked how that value was determined.

I jokingly responded to ask the project creator [Andrew Kane](https://github.com/ankane) because the example was from Strong Migrations and I didn't know :). Maybe I'll send Andrew an email? I did have some more thoughts about why to throttle in general in addition to what we discussed when I asked the audience for help.

The audience suggested slowing it down for letting index maintenance catch up from updates.

We also briefly discussed lock contention for rows being updated, leaving some time after updates for locks to be released on those rows on the chance there are transactions waiting on the same locks.

Another reason to throttle would be replication. All of those updates are replicated including updates to the indexes. Replication lag may be kept under 100ms but if it increases into the range of seconds, that could cause application errors reading from the replicas if there are queries on the rows being backfilled.

As far as why the value was set so low at `0.01`, perhaps it was set very low as a starting point and intended for the programmer to increase it to something based on their specific use cases.

### Question: Instead of dropping old partitions, why not delete old data?

This was a very reasonable question and one I should have anticipated. During the Q&A we talked about one reason being that with the partitions approach, we can retain the row data more easily. Technically deleting it from the database, the data could still exist in backups.

However when detaching a partition, the table becomes a regular table that can be dumped (e.g. [pg_dump](https://www.postgresql.org/docs/current/app-pgdump.html)) and encrypted, compressed, and archived to a form of "cold storage" like an S3 bucket. Versus trying to restore specific rows from a backup, we could restore the entire table later if needed. For example for legal reasons we may wish to retain data for a year, but for manual queries and not for application queries.

I failed to mention some other benefits of partitioning!

When deleting rows, because of MVCC design, the rows will cause table and index bloat for the single unpartitioned table. A partitioned table repeats the index across each partition, for the rows in that partition.

Table and index bloat can reduce performance over time. We can mitigate this with online index rebuilds. However with detaching a partition, no table or index bloat occurs to the parent table.

In other cases we may wish to retain the rows but because they are grouped as a table, they could be relocated to an "archive" table but left in the database. Or the table could be relocated to an archived schema. Schemas may have their own access. The table structure provides a lot of organization and administration options when the row data is valuable to retain.
