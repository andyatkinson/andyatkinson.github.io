---
layout: post
permalink: /postgresql-beta-testing-docker
title: Beta Testing PostgreSQL 19 With Docker
date: 2026-06-05 20:15:00
tags: [PostgreSQL, Databases]
---

The Postgres community releases Beta versions, and with Docker it's been easier than ever to configure pre-release versions to use and test.

With the [recent announcement of PostgreSQL 19 Beta 1](https://www.postgresql.org/about/news/postgresql-19-beta-1-released-3313/), it's a great time to do that. Let's get an instance up and running and test some of the new capabilities in Postgres 19.

## Pre-Release Versions of Postgres with Docker
First, you'll need to install [Docker](https://www.docker.com) for your OS! Grab the version needed for your OS and processor architecture, for example ARM or AMD/Intel/x86.

On MacOS run `uname -m` or `sw_vers` in your Terminal to learn more about your hardware details.

For Windows check [Install Docker Desktop on Windows](https://docs.docker.com/desktop/setup/install/windows-install/)

## Building and Running
[Official Postgres images](https://hub.docker.com/_/postgres) for Docker Postgres are limited to fully released versions.

Fortunately [@yosifkit](https://github.com/yosifkit) created a PR to add 19 Beta 1 (merged by @[tianon](https://github.com/tianon)) with instructions for how to use `docker buildx` to build pre-release versions.

This command downloads and builds `postgres:19beta1-trixie`:
```sh
docker buildx build -t postgres:19beta1-trixie \
    'https://github.com/infosiftr/postgres.git#19-rc:19/trixie'
```

With that built, I could invoke `docker run` with `postgres:19beta1-trixie`. I named mine `pg19`.

I also passed the env vars below based on how I run other Docker Postgres containers (these options may not be necessary).

The final command:
```sh
docker run \
--name pg19 \
--env POSTGRES_USER=postgres \
--env POSTGRES_PASSWORD=postgres \
--detach postgres:19beta1-trixie
```

To check if it's running, I run `docker ps -a`. For logs I'd run: `docker logs -f postgres:19beta1-trixie`.

## Released Versions
Shortly after writing the initial post on June 5th, the `postgres:beta1` image became available for download without any special steps:
```sh
docker run --detach postgres:19beta1
```

## Connect via psql
The container is running and the logs have what we want: "database system is ready to accept connections".

Let's connect to the `postgres` database using psql on the container:
```sh
docker container exec -it pg19 psql -U postgres
```

We should see output like showing version 19:
```
psql (19beta1 (Debian 19~beta1-1.pgdg13+1))
Type "help" for help.
```

## New Feature Testing in 19
Great. Let's try out some things in 19.

19 Added a new system view for checking out locks. Let's try it out:
```sql
postgres=# select * from pg_stat_lock;
```

We get a lot of new data like `waits` counts, `wait_time` and more.


What about the new `pg_plan_advice` extension? First let's load it and then create a table `t` to experiment with:
```sql
postgres=# LOAD 'pg_plan_advice';
postgres=# create table t (id int);
```

With that in place we can show the output via `EXPLAIN` with a new `PLAN_ADVICE` parameter:
```sql
postgres=# EXPLAIN (PLAN_ADVICE) SELECT * FROM t;
                     QUERY PLAN
-----------------------------------------------------
 Seq Scan on t  (cost=0.00..35.50 rows=2550 width=4)
 Generated Plan Advice:
   SEQ_SCAN(t)
   NO_GATHER(t)
(4 rows)
```

I wonder why the rows estimate is 2550 by default? Let's run `analyze t;`.

After doing that, it looks more sensible with a `rows` estimate of 1:
```sql
postgres=# EXPLAIN (PLAN_ADVICE) SELECT * FROM t;
                   QUERY PLAN
-------------------------------------------------
 Seq Scan on t  (cost=0.00..0.00 rows=1 width=4)
 Generated Plan Advice:
   SEQ_SCAN(t)
   NO_GATHER(t)
(4 rows)
```

## Additions to pg_stat_statements
The extension `pg_stat_statements` gained new capabilities in 19.

Let's try it out:
```sql
postgres=# select * from pg_stat_statements;
ERROR:  relation "pg_stat_statements" does not exist
```

Oops, we need to add it to `shared_preload_libraries` first. We can see that's currently not the case:
```sql
postgres=# show shared_preload_libraries;
 shared_preload_libraries
--------------------------

(1 row)
```

One way to do that with `docker run` is the `-c` parameter as follows:
```sh
docker run \
--name pg19 \
--env POSTGRES_USER=postgres \
--env POSTGRES_PASSWORD=postgres \
--detach postgres:19beta1-trixie \
-c shared_preload_libraries=pg_stat_statements
```

Now we see what we want in `shared_preload_libraries`:
```sql
postgres=# show shared_preload_libraries;
 shared_preload_libraries
--------------------------
 pg_stat_statements
(1 row)
```

We have not yet enabled the extension though given `\dx` doesn't list it. Let's do that:
```sql
psql> create extension if not exists pg_stat_statements;
```
Now `\dx` shows it, and we're ready to query it.

One of the additions is tracking the use of prepared statements. Let's create a basic table and prepared statement.

Create table again if needed:
```sql
create table if not exists t (id int);
```

Create a simple prepared statement `get_t` and execute it. The goal here is for `pg_stat_statements` to increment the `generic_plan_calls` field.
```sql
PREPARE get_t AS
SELECT *
FROM t;
```

Now let's execute it:
```sql
EXECUTE get_t;
```

Did it work?
```sql
postgres=# select left(query,100),generic_plan_calls from pg_stat_statements limit 1;
       left       | generic_plan_calls
------------------+--------------------
 PREPARE get_t AS+|                  1
 SELECT *        +|
 FROM t           |
```

It worked! We see `generic_plan_calls` was incremented.

This looks very useful to monitor the use of prepared statements.

## Repack Concurrently for Tables
We've had the ability to use `reindex concurrently` to rebuild indexes since Postgres 12, but have lacked the ability to rebuild tables.

That changes in 19, with the introduction of `repack concurrently` for tables.

Let's try it out quick and bloat a table by updating every row. We'll compare the size before and after repacking it.

Run these examples using psql:
```sql
create table bloat (id int primary key);
CREATE TABLE

insert into bloat (id) select i from generate_series(1, 1_000_000) as t(i);
INSERT 0 1000000

SELECT pg_size_pretty(pg_total_relation_size('bloat'));
 pg_size_pretty
----------------
 56 MB

analyze bloat;
ANALYZE

-- Update every row
update bloat set id = id;
UPDATE 1000000

analyze bloat;
ANALYZE

-- The table size has doubled
SELECT pg_size_pretty(pg_total_relation_size('bloat'));
 pg_size_pretty
----------------
 112 MB

repack (concurrently, verbose) bloat;
INFO:  repacking "public.bloat" in physical order
INFO:  "public.bloat": found 0 removable, 1000000 nonremovable row versions in 8850 pages
DETAIL:  0 dead row versions cannot be removed yet.
CPU: user: 0.21 s, system: 0.04 s, elapsed: 0.28 s.
REPACK

-- Returns to original table size
SELECT pg_size_pretty(pg_total_relation_size('bloat'));
 pg_size_pretty
----------------
 56 MB
```

Very useful! Check out the [repack](https://www.postgresql.org/docs/19/sql-repack.html) documentation for more info.

## Wrapping Up
Please give this a shot and experiment with new features in Postgres 19!

- [Add 19.x builds (currently beta 1)](https://github.com/docker-library/postgres/pull/1415)
