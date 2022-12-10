---
layout: page
permalink: /postgresql-tips
title: PostgreSQL Tips, Tricks, and Tuning
---

{% include tag-pages-loop.html tagName='PostgreSQL' %}

## Learning Resources

* <https://postgres.fm>
* <https://www.pgcasts.com>
* <https://www.youtube.com/c/ScalingPostgres>
* <https://sqlfordevs.io>

## My Typical Workloads

My tips operating high scale PostgreSQL databases primarily with Ruby on Rails web applications. OLTP, high quantity of short lived transactions.

OLAP workload. Using application databases as the data source for a data warehouse or ETL process.

## Queries

I keep queries in a GitHub repository here: [pg_scripts](https://github.com/andyatkinson/pg_scripts).

### Query: Approximate Count

A `count(*)` query on a large table may be too slow. If an approximate count is acceptable use this:

```sql
SELECT relname, relpages, reltuples::numeric, relallvisible, relkind, relnatts, relhassubclass, reloptions, pg_table_size(oid) FROM pg_class WHERE relname='table';
```

### Query: Get Table Stats

```sql
SELECT attname, n_distinct, most_common_vals, most_common_freqs
FROM pg_stats
WHERE tablename = 'table';
```

Look for columns with few values, and indexes on those few values with low selectivity. Meaning, most values in the table are the same value. In index on that column would not be very selective, and given enough memory, PG would likely not use that index, preferring a sequential scan.

### Cancel or Kill by Process ID

Get a PID with `select * from pg_stat_activity;`

Try to cancel the pid first, more gracefully, or terminate it:

```
select pg_cancel_backend(pid); 
select pg_terminate_backend(pid);
```

### Query: 10 Largest Tables

```sql
select schemaname as table_schema,
    relname as table_name,
    pg_size_pretty(pg_total_relation_size(relid)) as total_size,
    pg_size_pretty(pg_relation_size(relid)) as data_size,
    pg_size_pretty(pg_total_relation_size(relid) - pg_relation_size(relid))
      as external_size
from pg_catalog.pg_statio_user_tables
order by pg_total_relation_size(relid) desc,
         pg_relation_size(relid) desc
limit 10;
```
<https://dataedo.com/kb/query/postgresql/list-10-largest-tables>

## Tuning Autovacuum

PostgreSQL runs an autovacuum process in the background. Dead tuples are also called dead rows or "bloat". Bloat can also exist for indexes.

Two parameters may be used to trigger the AV process: "scale factor" and "threshold". These can be configured DB-wide or per-table.

In [routine vacuuming](https://www.postgresql.org/docs/9.1/routine-vacuuming.html), the two options are listed:

- scale factor (a percentage) [`autovacuum_vacuum_scale_factor`](https://www.postgresql.org/docs/9.1/runtime-config-autovacuum.html#GUC-AUTOVACUUM-VACUUM-SCALE-FACTOR)
- threshold (a specific number) [`autovacuum_vacuum_threshold`](https://www.postgresql.org/docs/9.1/runtime-config-autovacuum.html#GUC-AUTOVACUUM-VACUUM-SCALE-FACTOR)

The scale factor defaults to 20% (`0.20`). To optimize for our largest tables we set it lower at 1% (`0.01`).

To opt out of scale factor, set the value to 0 and set the threshold, e.g. 1000, 10000 etc. depending on workload.

```sql
ALTER TABLE bigtable SET (autovacuum_vacuum_scale_factor = 0);
ALTER TABLE bigtable SET (autovacuum_vacuum_threshold = 1000);
```

If after experimentation you'd like to reset, use the `RESET` option.

```sql
ALTER TABLE bigtable RESET (autovacuum_vacuum_threshold);
ALTER TABLE bigtable RESET (autovacuum_vacuum_scale_factor);
```

<https://www.postgresql.org/docs/current/sql-altertable.html>


### AV Tuning

Set `log_autovacuum_min_duration` to `0` to log all autovacuums. A logged AV run includes a lot of information.


### AV Parameters

- `autovacuum_max_workers`
- `autovacuum_max_freeze_age`
- `maintenance_work_memory`


## Indexes Management

Check out my blog post on [Index Maintenance: Prune and Tune](blog/2021/07/30/postgresql-index-maintenance)

### Specialized Index Types

The most common type is B-Tree. Specialized Index types are:

* Multicolumn
* Covering (Multicolumn stype, and newer `INCLUDES` style)
* Partial
* GIN
* GiST
* BRIN
* Expression
* Unique
* Multicolumn (a,b) for a only, a & b, but not for b
* Indexes for sorting

### Removing Unused Indexes


Ensure these are set to `on`

```sql
SHOW track_activities;
SHOW track_counts;
```

<iframe class="speakerdeck-iframe" frameborder="0" src="https://speakerdeck.com/player/6644d7dd7380413ea19dce1955f41269" title="PostgreSQL Unused Indexes" allowfullscreen="true" mozallowfullscreen="true" webkitallowfullscreen="true" style="border: 0px; background-color: rgba(0, 0, 0, 0.1); margin: 0px; padding: 0px; border-radius: 6px; -webkit-background-clip: padding-box; -webkit-box-shadow: rgba(0, 0, 0, 0.2) 0px 5px 40px; box-shadow: rgba(0, 0, 0, 0.2) 0px 5px 40px; width: 560px; height: 314px;" data-ratio="1.78343949044586"></iframe>

Now we can take advantage of tracking on whether indexes have been used or not. We can look for zero scans, and also very infrequent scans.

Cybertec blog post with SQL query to discover unused indexes: [Get Rid of Your Unused Indexes!](https://www.cybertec-postgresql.com/en/get-rid-of-your-unused-indexes/)

On our very large production database where this process had never been done, we had dozens of indexes that could be eliminated, taking of 100s of gigabytes of space.

```sql
SELECT s.schemaname,
       s.relname AS tablename,
       s.indexrelname AS indexname,
       pg_relation_size(s.indexrelid) AS index_size
FROM pg_catalog.pg_stat_user_indexes s
   JOIN pg_catalog.pg_index i ON s.indexrelid = i.indexrelid
WHERE s.idx_scan = 0      -- has never been scanned
  AND 0 <>ALL (i.indkey)  -- no index column is an expression
  AND NOT i.indisunique   -- is not a UNIQUE index
  AND NOT EXISTS          -- does not enforce a constraint
         (SELECT 1 FROM pg_catalog.pg_constraint c
          WHERE c.conindid = s.indexrelid)
ORDER BY pg_relation_size(s.indexrelid) DESC;
```

## Remove Duplicate and Overlapping Indexes

<https://wiki.postgresql.org/wiki/Index_Maintenance>

Query that finds duplicate indexes, meaning using the same columns etc. Recommends that usually it is safe to delete one of the two.

### Remove Seldom Used Indexes on High Write Tables

[New Finding Unused Indexes Query](http://www.databasesoup.com/2014/05/new-finding-unused-indexes-query.html)

This is a great guideline.

> As a general rule, if you're not using an index twice as often as it's written to, you should probably drop it.

In our system on our highest write table we had 10 total indexes defined and 6 were classified as Low Scans, High Writes. These indexes may not be worth keeping.

## Partial Indexes

[How Partial Indexes Affect UPDATE Performance in PostgreSQL](https://medium.com/@samokhvalov/how-partial-indexes-affect-update-performance-in-postgres-d05e0052abc)

Partial indexes weigh significantly less, but this article uses pgbench to show how they may benefit SELECT TPS, but negatively impact UPDATE TPS.

## Timeout Tuning

- `statement_timeout`: The maximum time a statement can execute before it is terminated

## Connections Management

[A connection forks the OS process (creates a new process)](https://azure.microsoft.com/en-us/blog/performance-best-practices-for-using-azure-database-for-postgresql-connection-pooling/) and is thus expensive.

Using a connection pool reduces the amount of connection establishment overhead and thus reduces the latency involved with connections, which can increase TPS at a certain scale.

- PgBouncer. [Running PgBouncer on ECS](https://www.revenuecat.com/blog/pgbouncer-on-aws-ecs)
- RDS Proxy. [AWS RDS Proxy](https://aws.amazon.com/rds/proxy/)
- [Managing Connections with RDS Proxy](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/rds-proxy.html)

Connection issues could benefit from changing:

- `connect_timeout`
- `read_timeout`
- `checkout_timeout` (Rails, default `5s`): maximum time Rails will spend trying to check out a connection from the pool before raising an error. [checkout_timeout API documentation](https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/ConnectionPool.html)
- `statement_timeout`. In Rails/Active Record, set in `config/database.yml` under a `variables` section with a value in milliseconds. This becomes a session variable which is set like this:

`SET statement_timeout = 5000` (in milliseconds) and be displayed like this: `SHOW statement_timeout`

```yml
production:
  variables:
    statement_timeout: 5000
```

When serving Rails apps with Puma and using Sidekiq, carefully manage the connection pool size and total connections for the database.

[The Ruby on Rails database connection pool](https://maxencemalbois.medium.com/the-ruby-on-rails-database-connections-pool-4ce1099a9e9f). We also use a proxy in between the application and PG.

This allows the application to allocate many more client connections (for example doubling during a zero downtime deploy) but not exceed the max supported connections/resource usage on the DB server.

## PgBouncer

* [PostgreSQL Connection Pooling With PgBouncer](https://dzone.com/articles/postgresql-connection-pooling-with-pgbouncer)

Install pgbouncer on OS X with `brew install pgbouncer`. Create the `.ini` config file as the article mentions, point it to a database, accept connections, and track the connection count.


## H.O.T. Updates

HOT ("heap only tuple") updates, are updates to tuples not referenced from outside the table block.

[HOT updates in PostgreSQL for better performance](https://www.cybertec-postgresql.com/en/hot-updates-in-postgresql-for-better-performance/)

2 requirements:

- there must be enough space in the block containing the updated row
- there is no index defined on any column whose value is modified (big one)

## `fillfactor`

[What is fillfactor and how does it affect PostgreSQL performance?](https://www.cybertec-postgresql.com/en/what-is-fillfactor-and-how-does-it-affect-postgresql-performance/)

- Percentage between 10 and 100, default is 100 ("fully packed")
- Reducing it leaves room for "HOT" updates when they're possible. Set to 90 to leave 10% space available for HOT updates.
- "good starting value for it is 70 or 80" [Deep Dive](https://dataegret.com/2017/04/deep-dive-into-postgres-stats-pg_stat_all_tables/)
- For tables with heavy updates a smaller fillfactor may yield better write performance
- Set per table or per index (b-tree is default 90 fillfactor)
- Trade-off: "Faster UPDATE vs Slower Sequential Scan and wasted space (partially filled blocks)" from [Fillfactor Deep Dive](https://medium.com/nerd-for-tech/postgres-fillfactor-baf3117aca0a)
- No index defined any column whose value it modified

Limitations: Requires a `VACUUM FULL` after modifying (or pg_repack)

```sql
ALTER TABLE foo SET ( fillfactor = 90 );
VACUUM FULL foo;

-- or
```

Or invoke pg_repack from the command line as follows.

```sh
pg_repack --no-order --table foo
```

[Installing pg_repack on EC2 for RDS](https://theituniversecom.wordpress.com/install-pg_repack-on-amazon-ec2-for-rds-postgresql-instances/)

Note: use `-k, --no-superuser-check`


## Locks Management

[Lock Monitoring](https://wiki.postgresql.org/wiki/Lock_Monitoring)

- `log_lock_waits`
- `deadlock_timeout`

> "Then slow lock acquisition will appear in the database logs for later analysis."

## Lock Types

Exclusive locks, and shared locks. Prefer shared locks.

`AccessExclusiveLock` - Locks the table, queries are not allowed.

## Tools

## Tools: Query Planning

## EXPLAIN (ANALYZE, BUFFERS)

This article [5 Things I wish my grandfather told me about ActiveRecord and PostgreSQL](https://medium.com/carwow-product-engineering/5-things-i-wish-my-grandfather-told-me-about-activerecord-and-postgres-93416faa09e7) has a nice translation of EXPLAIN ANLAYZE output written more in plain English.

## [pgMustard](https://www.pgmustard.com/)

[YouTube demonstration video](https://www.youtube.com/watch?v=v7ef4Fpn2WI)

Nice tool and I learned a couple of tips. Format `EXPLAIN` output with JSON, and specify some additional options. Handy SQL comment to have hanging around on top of the query to study:

Verbose invocation:

```sql
explain (analyze, buffers, verbose, format text)` or specify `format json`
```


## Using pgbench

Repeatable method of determining a transactions per second (TPS) rate.

Useful for determining impact of tuning parameters like `shared_buffers` with a before/after benchmark. Configurable with a custom SQL queries.

Could also be used to test the impact of ramping up connections.

- Initialize database example with scaling option of 50 times the default size:

```sh
pgbench -i -s 50 example`
```

- Benchmark with 10 clients, 2 worker threads, and 10,000 transactions per client:

```sh
pgbench -c 10 -j 2 -t 10000 example`
```

I created [PR #5388 adding pgbench to tldr](https://github.com/tldr-pages/tldr/pull/5388)!

## pgtune

PGTune is a website that tries to suggest values for PG parameters that can be tuned and may improve performance for a given workload.

<https://pgtune.leopard.in.ua/#/>

## PgHero

PgHero brings a bunch of operational concerns into a dashboard format. It is built as a Rails engine and provides a nice interface on top of queries related to the PG catalog tables.

We are running it in production and some immediate value has been helping clarify unused and duplicate indexes we can remove.

[Fix Typo PR #384](https://github.com/ankane/pghero/pull/384)

<https://github.com/ankane/pghero>

## pgmonitor

<https://github.com/CrunchyData/pgmonitor>

Have not yet tried this out but it looks helpful.

## postgresqltuner

Perl script to analyze a database. Do not have experience with this. Has some insights like the shared buffer hit rate, index analysis, configuration advice, and extension recommendations.

<https://github.com/jfcoz/postgresqltuner>

## pg_test_fsync

[pg_test_fsync](https://www.postgresql.org/docs/10/pgtestfsync.html)

## pgmetrics

[pgmetrics](https://pgmetrics.io/)

## pgcli

`brew install pgcli`

An alternative to `psql` with syntax highlighting, autocomplete and more.

## Write Ahead Log (WAL) Tuning

Can cause a significant I/O load

* `checkpoint_timeout` - in seconds, default checkpointing every 5 minutes
* `max_wal_size` - if max wal size is about to be exceeded, default 1 GB

Reducing the values causes checkpoint to run more frequently.

`checkpoint_warning` parameter
`checkpoint_completion_target`

General Recommendation (not mine): "On a system that's very close to maximum I/O throughput during normal operation, you might want to increase `checkpoint_completion_target` to reduce the I/O load from checkpoints."

Parameters

* `commit_delay` (0 by default)
* `wal_sync_method`
* `wal_debug`


## Extensions and Modules

## Foreign Data Wrapper (FDW)

Native Foreign data wrapper functionality in PostgreSQL allows connecting to a remote table and treating it like a local table.

The table structure may be specified when establishing the foreign table or it may be imported as well.

A big benefit of this for us at work is that for a recent backfill. We were able to avoid the need for any intermediary data dump files.

We used a `temp` schema to isolate any temporary tables away from the main schema (`public`).

Essentially the process is:

  1. Create a server
  1. Create a user mapping
  1. Create a foreign table (optionally importing the schema)

Let's say we had 2 services, one for managing inventory items for sale, and one for managing authentication.

We wanted to connect to the authentication database from the inventory database.

In the case below, the inventory database is connected to with the `root` user so there is privileges to create temporary tables, foreign tables etc.

```sql
create EXTENSION postgres_fdw;

CREATE SCHEMA temp;

CREATE SERVER temp_authentication;
FOREIGN DATA WRAPPER postgres_fdw
OPTIONS (host 'authentication-db-host', dbname 'authentication-db-name', port '5432'); -- set the host, name and port

CREATE USER MAPPING FOR root
SERVER temp_authentication
OPTIONS (user 'authentication-db-user', password 'authentication-db-password'); -- map the local root user to a user on the remote DB

IMPORT FOREIGN SCHEMA public LIMIT TO (customers)
    FROM SERVER temp_authentication INTO temp; -- this will make a table called temp.customers
```

Once this is established, we can issue queries as if the foreign table was a local table:

```sql
select * from temp.customers limit 1;
```

On Amazon RDS type `show rds.extensions` to view available extensions.

## `uuid-ossp`

Generate universally unique identifiers (UUIDs) in PostgreSQL. [Documentation link](https://www.postgresql.org/docs/10/uuid-ossp.html)


## `pg_stat_statements`

Tracks execution statistics for all statements and made available via a view. Requires reboot (static param) on RDS on PG 10 although `pg_stat_statements` is available by default in `shared_preload_libraries` in PG 12.

```sql
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
```

<https://www.virtual-dba.com/blog/postgresql-performance-enabling-pg-stat-statements/>

## `pgstattuple`

> The pgstattuple module provides various functions to obtain tuple-level statistics.

<https://www.postgresql.org/docs/9.5/pgstattuple.html>

## `citext`

Case insensitive column type

[citext](https://www.postgresql.org/docs/9.3/citext.html)

## `pg_cron`

Available on PG 12.5+ on RDS, pg_cron is an extension that can be useful to schedule maintenance tasks, like manual vacuum jobs.

See: [Scheduling maintenance with the PostgreSQL pg_cron extension](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/PostgreSQL_pg_cron.html)

## `pg_timetable`

[pg_timetable: Advanced scheduling for PostgreSQL](https://github.com/cybertec-postgresql/pg_timetable)

## `pg_squeeze`

[pg_squeeze](https://www.cybertec-postgresql.com/en/products/pg_squeeze/)

Replacement for pg_repack, automated, without needing to run a CLI tool.

## `auto_explain`

[PG 10 auto_explain](https://www.postgresql.org/docs/10/auto-explain.html)

Adds explain plans to the query logs. Maybe start by setting it very high so it only logged for extremely slow queries, and then lessening the time if there is actionable information.

## Percona pg_stat_monitor

[pg_stat_monitor: A cool extension for better monitoring using PMM - Percona Live Online 2020](https://www.percona.com/resources/videos/pgstatmonitor-cool-extension-better-monitoring-using-pmm-percona-live-online-2020)

## pganalyze Index Advisor

This is not an extension but looks like a useful tool. [A better way to index your PostgreSQL database: pganalyze Index Advisor](https://pganalyze.com/blog/introducing-pganalyze-index-advisor)


## Bloat

## Overview

How does bloat (table bloat, index bloat) affect performance?

* "When a table is bloated, PostgreSQL's ANALYZE tool calculates poor/inaccurate information that the query planner uses.". Example of 7:1 bloated/active tuples ratio causing query planner to skip.
* Queries on tables with high bloat will require additional IO, navigating through more pages of data.
* Bloated indexes, such as indexes that reference tuples that have been vacuumed, requires unnecessary seek time. Fix is to reindex the index.
* Index only scans slow down with outdated statistics. Autovacuum updates table statistics. Minimize table bloat to improve performance of index only scans. [PG Routing vacuuming docs](https://www.postgresql.org/docs/9.5/routine-vacuuming.html).
* [Cybertec: Detecting Table Bloat](https://www.cybertec-postgresql.com/en/detecting-table-bloat/)
* [Dealing with significant PostgreSQL database bloat — what are your options?](https://medium.com/compass-true-north/dealing-with-significant-postgres-database-bloat-what-are-your-options-a6c1814a03a5)


## Upgrades

We are currently running PG 10, so I had a look at some upgrades in 11 and 12.

This is also a really cool [Version Upgrade Comparison Tool: 10 to 12](https://why-upgrade.depesz.com/show?from=10.17&to=12.7&keywords=)

## PG 11

Release announcement October 2018

* Improves parallel query performance and parallelism of B-tree index creation. Source: [Release announcement](https://www.postgresql.org/about/news/postgresql-11-released-1894/#:~:text=PostgreSQL%2011%20improves%20parallel%20query,are%20unable%20to%20be%20parallelized.)
* Adds partitioning by hash key
* Significant partitioning improvements
* Adds "covering" indexes via `INCLUDE` to add more data to the index. Docs: [Index only scans and Covering indexes](https://www.postgresql.org/docs/11/indexes-index-only-scans.html)

## PG 12

[Release announcement](https://www.postgresql.org/about/news/postgresql-12-released-1976/). Released October 2019.

* Partitioning performance improvements
* Re-index concurrently

## PG 13

Released September 2020

* Parallel vacuum

## PG 14

## PG 15

## RDS

Amazon RDS is hosted PostgreSQL. RDS is regular single-writer primary PostgreSQL, and AWS has a variation called Aurora with a different storage model.

## Aurora PG



### AWS RDS Parameter Groups

[Working with RDS Parameter Groups](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_WorkingWithParamGroups.html)

* Try out parameter changes on a test database prior to making the change. Potentially create a backup before making the change as well.
* Parameter groups can be restored to their defaults (or they can be copied to create an experimental group). Groups can be compared with each other to determine differences.
* Parameter values can process a formula. RDS provides some formulas that utilize the instance class CPU or memory available to calculate a value.



### Database Constraints

[Blog: A Look at PostgreSQL Foreign Key Constraints](/blog/2018/08/22/postgresql-foreign-key-constraints)

* Check
* Not-null
* Unique
* Primary keys
* Foreign keys
* Exclusion


## Native Replication

## PostgreSQL Logical Replication

[Crunchydata Logical Replication in PostgreSQL](https://learn.crunchydata.com/pg-administration/courses/postgresql-features/logical-replication/)

* Create a `PUBLICATION` and a counterpart `SUBSCRIPTION`.
* All operations like `INSERT` and `UPDATE` etc. are enabled by default, or fewer can be configured
* Logical replication available since PG 10.
* `max_replication_slots` should be set higher than number of replicas
* A role must exist for replication
* Replication slot is a replication object that keeps track of where the subscriber is in the WAL stream
* Unlike normal replication, writes are still possible to the subscriber. Conflicts can occur if data is written that would conflict with logical replication.

## Delclarative Partitioning

* Range (time-based)
* List
* Hash

[Crunchydata Native Partitioning Tutorial](https://learn.crunchydata.com/pg-administration/courses/postgresql-features/native-partitioning/)

## Partition Pruning

Default is `on` or `SET enable_partition_pruning = off;` to turn it off.

<https://www.postgresql.org/docs/13/ddl-partitioning.html#DDL-PARTITION-PRUNING>

## Uncategorized Content

* Use `NULL`s instead of default values when possible, cheaper to store and query. Source: [Timescale DB blog](https://blog.timescale.com/blog/13-tips-to-improve-postgresql-insert-performance/)

## Stored Procedures

Stored Procedures are User Defined Functions (UDF).

Using PL/pgSQL, functions can be added to the database directly. Procedures and functions can be written in other languages as well.

[Stored procedures](https://github.com/andyatkinson/db-stuff)

To manage these functions in a Ruby app, use the [fx gem](https://github.com/teoljungberg/fx) (versioned database functions)!

## PostgreSQL Monitoring

* `pg_top` On Mac OS: `brew install pg_top` and run it `pg_top`

## Uncategorized Resources

* [The Unexpected Find That Freed 20GB of Unused Index Space](https://hakibenita.com/postgresql-unused-index-size)
* [Some SQL Tricks of an Application DBA](https://hakibenita.com/sql-tricks-application-dba)

This is an amazing article full of nuggets.

* The idea of an "Application DBA"
* Things I liked: Usage of intermediate table for de-duplication. Column structure is elegant, clearly broken out destination ID and nested duplicate IDs.
* Working with arrays
  * `ANY()` for an array of items to compare against
  * `array_remove(anyarray, anyelement)` to build an array but remove an element
  * `array_agg(expression)` to build up list of IDs and `unnest(anyarray)` to expand it
* Avoidance of indexes for low selectivity, and value of partial indexes in those cases (activated 90% v. unactivated users 10%)
* Tip on confirming index usage by removing index in a transaction with `BEGIN` and rolling it back with `ROLLBACK`.

* [Generalists/specialists: Application DBA and Performance Analyst](https://www.dbta.com/Columns/DBA-Corner/What-Type-of-DBA-Are-You-121146.aspx)
* [PostgreSQL Connection Pooling: Part 1 – Pros & Cons](http://highscalability.com/blog/2019/10/18/postgresql-connection-pooling-part-1-pros-cons.html)

## PostgreSQL Presentations

* [PostgreSQL Indexing : How, why, and when.](https://2018.pycon-au.org/talks/42913-postgresql-indexing-how-why-and-when)
* [Tuning PostgreSQL for High Write Workloads](https://www.youtube.com/watch?v=xrMbzHdPLKM)


## PostgreSQL Tuning

[Annotated.conf](https://github.com/jberkus/annotated.conf)

`shared_buffers`. RDS default is around 25% of system memory. Recommendations say up to 40% of system memory could be allocated, at which point there may be diminishing returns beyond that.

The unit is 8kb chunks, and requires some math to change the value for. Here is a formula:

<https://stackoverflow.com/a/42483002/126688>

| Parameter | Unit | Default RDS | Tuned | Link |
| --- | ----------- | ---- |||
| `shared_buffers` | 8kb | 25% mem |||
| `autovacuum_cost_delay` | ms | 20 | 2 ||
| `autovacuum_vaccum_cost_limit` | | 200 | 2000 | [Docs](https://www.postgresql.org/docs/10/runtime-config-autovacuum.html) |
| `effective_cache_size` | 8kb ||||
| `work_mem` | MB | 4 | 250||
| `maintenance_work_memory` |  ||||
| `checkpoint_timeout` |  ||||
| `min_wal_size` | MB | 80 | 4000 | [High write log blog](https://blog.crunchydata.com/blog/tuning-your-postgres-database-for-high-write-loads) |
| `max_wal_size` | MB | 4000 | 16000 ||
| `max_worker_processes` | | 8 | 1x/cpu ||
| `max_parallel_workers` | | 8 | 1x/cpu ||
| `max_parallel_workers_per_gather` | | 2 | 4 ||


## PostgreSQL Backups

* <https://torsion.org/borgmatic/>
* <https://restic.net/>
