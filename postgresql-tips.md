i---
layout: page
permalink: /postgresql-tips
title: PostgreSQL Tips, Tricks, and Tuning
---

Hello! This page is a semi-organized (mostly a mess) of notes while learning PostgreSQL.

This chaotic learning and cycle of applying what I learned, turned into me writing a book!

{% if site.mailchimp_url %}
{% include newsletter-box.html %}
{% endif %}

Below are my PostgreSQL-tagged blog posts:

{% include tag-pages-loop.html tagName='PostgreSQL' %}

## Recommended Learning Resources

* <https://postgres.fm>
* <https://www.pgcasts.com>
* <https://www.youtube.com/c/ScalingPostgres>
* <https://sqlfordevs.io>
* The `EXPLAIN` Glossary from PgMustard <https://www.pgmustard.com/docs/explain>
* [Optimizing Postgres for write heavy workloads](https://www.youtube.com/watch?v=t8rAOgDdH1U)

## Queries

I keep queries in a GitHub repository: [pg_scripts](https://github.com/andyatkinson/pg_scripts)

## Query: Approximate Count

Since a `COUNT(*)` query can be slow, try an approximate count:

```sql
SELECT reltuples::numeric AS estimate
FROM pg_class WHERE relname = 'table_name';
```

## Query: Get Table Stats

```sql
SELECT
    attname,
    n_distinct,
    most_common_vals,
    most_common_freqs
FROM pg_stats
WHERE tablename = 'table';
```

Consider cardinality for columns, and selectivity for indexes and queries, when designing indexes.

## Cancel or Kill by Process ID

Get a PID with `SELECT * FROM pg_stat_activity;`

Try to cancel the query first, otherwise terminate the backend:

```sql
SELECT pg_cancel_backend(pid); 
SELECT pg_terminate_backend(pid);
```

## Tuning Autovacuum

PostgreSQL runs a scheduler Autovacuum process when PostgreSQL starts up. This process looks at configurable thresholds for all tables and determines whether a `VACUUM` worker should run, per table.

Thresholds can be configured per table. A good starting place for tables that have a large amount of UPDATE and DELETE queries, is to perform that per-table tuning.

The goal is to make VACUUM run more regularly and for a longer period of time, to stay on top of the accumulation of bloat from dead tuples, so that operations are reliable and predictable.

In [Routine Vacuuming](https://www.postgresql.org/docs/current/routine-vacuuming.html), the two options are listed:

- [`autovacuum_vacuum_scale_factor`](https://www.postgresql.org/docs/current/runtime-config-autovacuum.html)
- `autovacuum_vacuum_threshold`

The scale factor defaults to 20% (`0.20`). For large tables with a high amount of updates and deletes, we lowered the value to 1% (`0.01`). With the lowered threshold, vacuum will run more frequently in proportion to how much it’s needed.

Set the value for a table:

```sql
ALTER TABLE bigtable SET (autovacuum_vacuum_scale_factor = 0.1);
```

Can be reset:

```sql
ALTER TABLE bigtable RESET (autovacuum_vacuum_threshold);
```

## Autovacuum Tuning

* Set `log_autovacuum_min_duration` to `0` to log all Autovacuum. A logged AV run includes a lot of information.
* [pganalyze: Visualizing & Tuning Postgres Autovacuum](https://pganalyze.com/blog/visualizing-and-tuning-postgres-autovacuum)
- `autovacuum_max_workers`
- `autovacuum_max_freeze_age`
- `maintenance_work_memory`

## Specialized Index Types

The most common type is B-Tree. Specialized index types are:

* Multicolumn
* Covering (Multicolumn or newer `INCLUDES` style)
* Partial
* GIN
* GiST
* BRIN
* Expression
* Unique
* Hash

## Removing Unused Indexes

Ensure these are set to `on`

```sql
SHOW track_activities;
SHOW track_counts;
```

<iframe class="speakerdeck-iframe" frameborder="0" src="https://speakerdeck.com/player/6644d7dd7380413ea19dce1955f41269" title="PostgreSQL Unused Indexes" allowfullscreen="true" mozallowfullscreen="true" webkitallowfullscreen="true" style="border: 0px; background-color: rgba(0, 0, 0, 0.1); margin: 0px; padding: 0px; border-radius: 6px; -webkit-background-clip: padding-box; -webkit-box-shadow: rgba(0, 0, 0, 0.2) 0px 5px 40px; box-shadow: rgba(0, 0, 0, 0.2) 0px 5px 40px; width: 560px; height: 314px;" data-ratio="1.78343949044586"></iframe>

Cybertec blog post with SQL query to discover unused indexes: [Get Rid of Your Unused Indexes!](https://www.cybertec-postgresql.com/en/get-rid-of-your-unused-indexes/)


## Remove Duplicate and Overlapping Indexes

<https://wiki.postgresql.org/wiki/Index_Maintenance>


## Remove Seldom Used Indexes on High Write Tables

[New Finding Unused Indexes Query](http://www.databasesoup.com/2014/05/new-finding-unused-indexes-query.html)

This is a great guideline.

> As a general rule, if you're not using an index twice as often as it's written to, you should probably drop it.

In our system on our highest write table we had 10 total indexes defined and 6 were classified as Low Scans, High Writes. These indexes may not be worth keeping.

## Partial Indexes

[How Partial Indexes Affect UPDATE Performance in PostgreSQL](https://medium.com/@samokhvalov/how-partial-indexes-affect-update-performance-in-postgres-d05e0052abc)

## Timeout Tuning

- `statement_timeout`: The maximum time a statement is allowed to run before being canceled
- `lock_timeout`

## Connections Management

[A connection forks the OS process (creates a new process)](https://azure.microsoft.com/en-us/blog/performance-best-practices-for-using-azure-database-for-postgresql-connection-pooling/) and is thus expensive.

Use a connection pooler to reduce overhead from connection establishment

- PgBouncer (see below). [Running PgBouncer on ECS](https://www.revenuecat.com/blog/pgbouncer-on-aws-ecs)
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

For Rails with Puma and Sidekiq, carefully manage the connection pool size and total connections.

[The Ruby on Rails database connection pool](https://maxencemalbois.medium.com/the-ruby-on-rails-database-connections-pool-4ce1099a9e9f). We also use a proxy in between the application and PG.

## PgBouncer

* [PostgreSQL Connection Pooling With PgBouncer](https://dzone.com/articles/postgresql-connection-pooling-with-pgbouncer)

Install PgBouncer on macOS with `brew install pgbouncer`. Create the `.ini` config file as the article mentions, point it to a database, accept connections, and track the connection count.


## Heap Only Tuple (HOT) Updates

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
- Set per table or per index (B-Tree defaults to 90 fillfactor)
- Trade-off: "Faster UPDATE vs Slower Sequential Scan and wasted space (partially filled blocks)" from [Fillfactor Deep Dive](https://medium.com/nerd-for-tech/postgres-fillfactor-baf3117aca0a)
- No index defined on any column whose value is modified

Limitations: Requires a `VACUUM FULL` after modifying (or pg_repack)

```sql
ALTER TABLE foo SET ( fillfactor = 90 );
VACUUM FULL foo;
```

Or use `pg_repack`

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

Exclusive locks, and shared locks.

`AccessExclusiveLock` - Locks the table, queries are not allowed.

Table locks and row locks.

## Tools

## Tools: Query Planning

## EXPLAIN (ANALYZE, BUFFERS)

This article [5 Things I wish my grandfather told me about ActiveRecord and PostgreSQL](https://medium.com/carwow-product-engineering/5-things-i-wish-my-grandfather-told-me-about-activerecord-and-postgres-93416faa09e7) has a nice translation of EXPLAIN ANLAYZE output written more in plain English.

## [pgMustard](https://www.pgmustard.com/)

[YouTube demonstration video](https://www.youtube.com/watch?v=v7ef4Fpn2WI)

Format `EXPLAIN` output with JSON, and specify additional options.

```sql
EXPLAIN (ANALYZE, BUFFERS, VERBOSE, FORMAT text) --<sql-query>
```


## Using pgbench

Repeatable method of determining a transactions per second (TPS) rate.

Useful for determining impact of parameter tuning. Configurable with custom SQL queries.

Could be used to test the impact of increasing concurrent connections.

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

PGTune is a website that tries to suggest values for PG parameters.

<https://pgtune.leopard.in.ua/#/>

## PgHero

PgHero brings operational concerns into a web dashboard. Built as a Rails engine.

We’re running it in production and saw immediate value in identifying unused and duplicate indexes to remove.

[Fix Typo PR #384](https://github.com/ankane/pghero/pull/384)

<https://github.com/ankane/pghero>

## pgmonitor

<https://github.com/CrunchyData/pgmonitor>

## postgresqltuner

Perl script to analyze a database. Has some insights like the shared buffer hit rate, index analysis, configuration advice, and extension recommendations.

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

Reducing the value causes more frequent checkpoint operations.

`checkpoint_warning` parameter
`checkpoint_completion_target`

General Recommendation (not mine)

> "On a system that's very close to maximum I/O throughput during normal operation, you might want to increase `checkpoint_completion_target` to reduce the I/O load from checkpoints."

Parameters

* `commit_delay` (0 by default)
* `wal_sync_method`
* `wal_debug`

## Extensions and Modules

## Foreign Data Wrapper (FDW)

Native Foreign Data Wrapper (FDW) functionality in PostgreSQL allows connecting to remote sources

The table structure may be specified when establishing the foreign table

We were able to avoid the need for any intermediary data dump files.

We used a `temp` schema to isolate temporary tables away from the main schema (`public`).

The process is:

  1. Create a server
  1. Create a user mapping
  1. Create a foreign table (optionally importing the schema)

Let's say we had 2 services, one for managing inventory items for sale, and one for managing authentication.

Connect as a superuser

```sql
create EXTENSION postgres_fdw;

CREATE SCHEMA temp;

CREATE SERVER temp_authentication;
FOREIGN DATA WRAPPER postgres_fdw
OPTIONS (host 'authentication-db-host', dbname 'authentication-db-name', port '5432'); -- set the host, name and port

CREATE USER MAPPING FOR postgres
SERVER temp_authentication
OPTIONS (user 'authentication-db-user', password 'authentication-db-password'); -- map the local postgres user to a user on the remote DB

IMPORT FOREIGN SCHEMA public LIMIT TO (customers)
    FROM SERVER temp_authentication INTO temp; -- this will make a table called temp.customers
```

## `uuid-ossp`

Generate universally unique identifiers (UUIDs) in PostgreSQL.

[Documentation link](https://www.postgresql.org/docs/current/uuid-ossp.html)


## `pg_stat_statements`

Tracks execution stats for all statements. Stats made available from view. Requires reboot (static param) on RDS on PG 10 although `pg_stat_statements` is available by default in `shared_preload_libraries` in PG 12.

```sql
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
```

<https://www.virtual-dba.com/blog/postgresql-performance-enabling-pg-stat-statements/>

## `pgstattuple`

> The pgstattuple module provides various functions to obtain tuple-level statistics.

<https://www.postgresql.org/docs/current/pgstattuple.html>

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

Adds explain plans to the PostgreSQL log.

## Percona pg_stat_monitor

[pg_stat_monitor: A cool extension for better monitoring using PMM - Percona Live Online 2020](https://www.percona.com/resources/videos/pgstatmonitor-cool-extension-better-monitoring-using-pmm-percona-live-online-2020)

## pganalyze Index Advisor

[A better way to index your PostgreSQL database: pganalyze Index Advisor](https://pganalyze.com/blog/introducing-pganalyze-index-advisor)

## pgbadger

`brew install pgbadger`


## Bloat

## Overview

How does bloat (table bloat, index bloat) affect performance?

* "When a table is bloated, PostgreSQL's `ANALYZE` tool calculates poor or inaccurate information that the query planner uses.". Example of 7:1 bloated/active tuples ratio causing query planner to skip.
* Queries on tables with high bloat will require additional IO, navigating through more pages of data.
* Bloated indexes, such as indexes that reference tuples that have been vacuumed, add IO. Rebuild the index `REINDEX ... CONCURRENTLY`
* Index only scans slow down with outdated statistics. Autovacuum updates table statistics. Minimize table bloat to improve performance of index only scans. [PG Routing vacuuming docs](https://www.postgresql.org/docs/current/routine-vacuuming.html).
* [Cybertec: Detecting Table Bloat](https://www.cybertec-postgresql.com/en/detecting-table-bloat/)
* [Dealing with significant PostgreSQL database bloat — what are your options?](https://medium.com/compass-true-north/dealing-with-significant-postgres-database-bloat-what-are-your-options-a6c1814a03a5)

## Upgrades

This is also a really cool [Version Upgrade Comparison Tool: 10 to 12](https://why-upgrade.depesz.com/show?from=10.17&to=12.7&keywords=)

## PG 11

October 2018

* Improves parallel query performance and parallelism of B-tree index creation.
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

* More of [`query_id`](https://blog.rustprooflabs.com/2021/10/postgres-14-query-id)
* [Multi-range types](https://www.crunchydata.com/blog/better-range-types-in-postgres-14-turning-100-lines-of-sql-into-3)

## PG 15

- SQL `MERGE`

## PG 16

Released September 2023

- pg_stat_io
- Replication based  followers

## RDS

Amazon RDS hosts PostgreSQL (with customizations). RDS is a regular single-writer primary instance model for PostgreSQL.

## Aurora PostgreSQL

- Separates storage and compute

## AWS RDS Parameter Groups

[Working with RDS Parameter Groups](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_WorkingWithParamGroups.html)

* Try out parameter changes on a test database prior to making the change. Create a snapshot before making the change.
* Parameter groups can be restored to their defaults (or they can be copied to create an experimental group). Groups can be compared with each other to determine differences.
* Parameter values can process a formula. RDS provides some formulas that use the instance class CPU or memory available to calculate a value.

## Database Constraints

[Blog: A Look at PostgreSQL Foreign Key Constraints](/blog/2018/08/22/postgresql-foreign-key-constraints)

* `CHECK`
* `NOT NULL`
* `UNIQUE`
* `PRIMARY KEY`
* `FOREIGN KEY`
* `EXCLUSION`

## Native Replication

- Physical Replication
- Logical Replication

## PostgreSQL Logical Replication

[Crunchydata Logical Replication in PostgreSQL](https://learn.crunchydata.com/pg-administration/courses/postgresql-features/logical-replication/)

* Create a `PUBLICATION`, counterpart `SUBSCRIPTION`.
* All operations like `INSERT` and `UPDATE` are enabled by default, fewer can be configured
* Logical replication available since PG 10.
* `max_replication_slots` should be set higher than number of replicas
* A role must exist for replication
* Replication slot is a replication object that keeps track of where the subscriber is in the WAL stream
* Unlike normal replication, writes are still possible to the subscriber. Conflicts can occur if data is written that would conflict with logical replication.

## Declarative Partitioning

* `RANGE`(time-based)
* `LIST`
* `HASH`

- [Crunchydata Native Partitioning Tutorial](https://learn.crunchydata.com/pg-administration/courses/postgresql-features/native-partitioning/)
- [pgslice](https://github.com/ankane/pgslice)
- [pg_partman](https://github.com/pgpartman/pg_partman)
- [pg_party](https://github.com/rkrage/pg_party)

## Partition Pruning

Default is `on` or `SET enable_partition_pruning = off;` to turn it off.

<https://www.postgresql.org/docs/13/ddl-partitioning.html#DDL-PARTITION-PRUNING>

## Uncategorized Content

* Use `NULL`s instead of default values when possible, cheaper to store and query. Source: [Timescale DB blog](https://blog.timescale.com/blog/13-tips-to-improve-postgresql-insert-performance/)

## Stored Procedures

Stored Procedures are User Defined Functions (UDF).

Using PL/pgSQL, functions can be added to the database directly. Procedures and functions can be written in other languages.

[Stored procedures](https://github.com/andyatkinson/db-stuff)

To manage these functions in a Ruby app, use the [fx gem](https://github.com/teoljungberg/fx) (versioned database functions)!

## PostgreSQL Monitoring

* `pg_top` On Mac OS
* `brew install pg_top` and run it `pg_top`

## Uncategorized Resources

* [The Unexpected Find That Freed 20GB of Unused Index Space](https://hakibenita.com/postgresql-unused-index-size)
* [Some SQL Tricks of an Application DBA](https://hakibenita.com/sql-tricks-application-dba)

This is an amazing article full of nuggets.

* The idea of an "Application DBA"
* Things I liked: Using an intermediate table for de-duplication. Column structure is elegant, clearly broken out destination ID and nested duplicate IDs.
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

## Sequences

* `TRUNCATE` and reset: `TRUNCATE <table name> RESTART IDENTITY` <https://brianchildress.co/reset-auto-increment-in-postgres/>
* `ALTER SEQUENCE <seq-name> RESTART WITH 1;` (e.g. `users_id_seq`)
* Serial and BigSerial are special types that use Sequences

## Identity Columns

* Identity columns are recommended for primary keys, over using Sequences (with Serial or BigSerial)

## Scaling Web Applications

- [My GOTO Postgres Configuration for Web Services](https://tightlycoupled.io/my-goto-postgres-configuration-for-web-services/)

## Full Text Search (FTS)

- [Postgres full-text search is Good Enough!](http://rachbelaid.com/postgres-full-text-search-is-good-enough/)
- [Postgres Full Text Search vs the rest](https://supabase.com/blog/postgres-full-text-search-vs-the-rest)
- [Full Text Search in Milliseconds with Rails and PostgreSQL](https://pganalyze.com/blog/full-text-search-ruby-rails-postgres)
