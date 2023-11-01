---
layout: post
title: "PostgreSQL IO Visibility: #wehack PostgreSQL Internals and pg_stat_io"
tags: []
date: 2023-11-01
comments: true
---

This week I’m participating in a virtual social learning experiment run by [Phil Eaton](https://eatonphil.com) / <https://twitter.com/eatonphil>, called "#wehack PostgreSQL Internals".

The purpose is to get more people hacking on the internals of PostgreSQL or exploring PostgreSQL topics.

Check out the Announcement blog post here: #wehack Postgres Internals <https://eatonphil.com/2023-10-wehack-postgres.html>

Since I always have a running list of topics to learn in PostgreSQL, and since I have some available time, I jumped at the chance to pick up some topics to learn. To start, I wanted to dive into the new `pg_stat_io`[^pgstatio] system view in PostgreSQL 16. My goal was to understand the information it provides, and how I could use it for performance analysis.

Terminology note: The terms *blocks* and *pages* are often used interchangeably[^phystor] when discussing physical storage in PostgreSQL. The PostgreSQL Glossary[^glossary] uses *data pages* or *pages* when talking about storage, so this post will use *pages*. The use of *pages* in the scope of this post, can be thought of as equivalent to *blocks*. Please contact me for clarifications or corrections. For general context, we're talking about the `8kb` files (by default) in the data directory on disk, where data is stored. For the purposes of analyzing IO latency, since PostgreSQL accesses the *whole page* for even one row, we want to know how many pages we're working with to understand the IO in kilobytes or megabytes being accessed.

Let's get started. First up, what is `pg_stat_io`?

## What is it?

`pg_stat_io` is a system view added in PostgreSQL 16 that adds additional observability to IO operations.

IO operations come from multiple sources, such as client queries like `SELECT` or `INSERT`, or other "backend types" like Autovacuum or bulk operations.

## Who created it?

Melanie Plageman helped lead the creation, and has given presentations to help educate others on this capability. I met Melanie Plageman at PGConf NYC (check out my recap blog post: [PGConf NYC 2023 Recap 🐘](/blog/2023/10/10/pgconf-nyc-2023)), and she was gracious enough to give me an in-person intro to `pg_stat_io` there.

To understand what the view offers, I watched Melanie's Citus Con presentation "Additional IO Observability in Postgres with `pg_stat_io`".[^cituscon] As an introduction, I found it very helpful.

While there are many more contributors to `pg_stat_io`, I wanted to highlight one more person in particular.

Lukas Fittl of PgAnalyze helped review and contributed to earlier work on this capability before PostgreSQL was released. Lukas and team wrote the post "Waiting for Postgres 16: Cumulative I/O statistics with pg_stat_io".[^waiting] In the post, Lukas explains how IO is split into writes to the WAL stream, or writes to the data directory. Writes don't happen into a storage device right away, as they can be buffered in PostgreSQL or the Operating System.

Wait a minute, what are writes from the perspective of PostgreSQL?

## What “writes” are in the context of files and pages

In PostgreSQL, “writes” are different from what we might think of as client-level operations like `INSERT`, `UPDATE`, or `DELETE` (`DML`).

Melanie explains this in the Citus Con presentation.[^cituscon]

> writes in PostgreSQL relate to files that store data in pages/blocks.

These pages are held in memory. Writes are the process of flushing data to durable storage, or from memory to disk (or more generally, the "storage device").

When data is stored in PostgreSQL, it's placed into pages. Existing pages are checked at storage time. When pages contain data they’re considered “dirty”, which means they need to be flushed. After dirty pages are flushed, they're available for use.

We want to understand when these writes occur. As discussed earlier, writes can occur from different types of operations. What are those?


## Distinguishing backend types

Melanie points outs[^cituscon] these three backend types:

* `client backend`
* `background writer`
* `checkpointer`

These backend types report their IO activity in `pg_stat_io`. For web applications, we're mostly interested in `client backend` types. When analyzing performance, we want to check for excessive or unnecessary writes during `client backend` queries, because those writes are adding latency.

What other data does the view have?


## What does it look like?

Like other system views, this view contains a lot of fields. If you don’t have a PostgreSQL 16 psql client session handy, check out this pgPedia[^pgped] page which shows the fields. The field data is related to IO activity across the whole database, showing backend types, operations, and more.

This post "PostgreSQL 16: More I/O statistics"[^moreio] describes results:

> What you see is one row per backend type, context and object.

You may be interested in querying the view for specific `backend type` rows.

After initializing PostgreSQL, the view won't have much data. To generate data, the post above shows how to run `pgbench` as follows: `pgbench -i -s 10 postgres`

<https://www.postgresql.org/docs/current/monitoring-stats.html#MONITORING-PG-STAT-IO-VIEW>


## Why does IO matter?

As Lukas Fittl says in "Postgres I/O Basics":[^iobasics]

> PostgreSQL doesn’t load individual rows, it always loads full pages.

For OLTP environments where we want fast queries, IO can add latency to queries.

Often stored data is not stored optimally, densely packed in pages. Pages may be scattered. `pg_stat_io` helps us analyze the IO happening during `client backend` operations. We can see how data is placed into and accessed in shared buffers.

Who is this view useful for?

## Who is it for?

This view is useful for any PostgreSQL user wishing to gain more insight into the IO of their PostgreSQL installation. Users may wish to explore `client backend` operations, or other backend operation types like Autovacuum. The statistics presented are from *all* databases. If you run multiple databases on an instance, keep this in mind.

Let's look at more use cases.

## What are the use cases?

Melanie suggests some use cases for the information in `pg_stat_io`:

For example, tuning Shared Buffers (Check out: [Resource Consumption](https://www.postgresql.org/docs/current/runtime-config-resource.html)).

Shared buffers may be undersized. Query performance is optimal when the working data set fits into shared buffers. We could use `pg_stat_io` to see if there's a lot of IO from client backends that are outside of shared buffers. This could indicate that more memory should be allocated to shared buffers.

PostgreSQL query execution plans show "shared hits", which means pages are coming from shared buffers. Shared buffers are filled with what's currently happening, which could be from other backend types like Autovacuum or bulk operations.

Understanding IO on cloud hosted PostgreSQL could also help with cost analysis. When IO is priced separately, or when usage exceeds IO quotas, it can be helpful to have additional visibility into what operations are contributing to IO.

## Extensions

For deeper analysis of the content in shared buffers, enable the `pg_buffercache`[^pgbc] extension. `pg_buffercache` allows you to determine which tables and indexes are in the cache.

Run the sample query on the page to see the tables and indexes with buffers in the cache.

## System Wide IO visibility

Lukas points out how prior to `pg_stat_io`, we could analyze the impact of IO from Vacuum jobs that were logged to `postgresql.log` on a per-job basis.

With `pg_stat_io`, we're able to look at the impact of *all* Vacuum jobs across the whole system, by querying `pg_stat_io` for `context` = `vacuum`.

The query below shows 3 result rows for `backend type` = `autovacuum worker` for contexts `bulkread`, `normal`, and `vacuum`.

```sql
SELECT * FROM pg_stat_io
WHERE backend_type = 'autovacuum worker'
OR (context = 'vacuum' AND (
    reads <> 0 OR writes <> 0 OR extends <> 0
    )
);
```

The post mentions that this information could be used to help analyze an unexplained IO spike.

## COPY operations

`pg_stat_io` gives us visibility for bulk load (`COPY`) operations.

To do that, query the view for `bulkread` and `bulkwrite` values in the `io_context` column.


## Extends

`pg_stat_io` also shows information on “Extends” operations. What are those?

Melanie describes how *Extends* are a special kind of write operation. `extends` are displayed separately from `reads` and `writes`.

The following post "PostgreSQL 16: Playing with `pg_stat_io` (1) – extends"[^playing] has nice examples comparing sizes with an empty table, and showing how the size expands when rows are added. Extend operations happen when there's no page to store data, and a new page is allocated.

## Writebacks

Another concept in `pg_stat_io` are "Writebacks". What are they?

Hans-Jürgen Schönig from Cybertec provides some context and an explanation. Normally, "writes" to a storage device go through the OS file system cache. *writebacks* are when that process is skipped, and writes go directly from PostgreSQL to permanent storage.

## Let's dive in

Let's explore `pg_stat_io` locally. Let's reset the stats and generate some client activity.

To do that, I'll use the [Rideshare Rails app](https://github.com/andyatkinson/rideshare) which is set up locally with PostgreSQL 16. I'll start the Rails Server, then run the [`simulate_app_activity.rake`](https://github.com/andyatkinson/rideshare/blob/master/lib/tasks/simulate_app_activity.rake) Rake task which sends queries to the server and database.

Connect to PostgreSQL 16 (or newer) as a superuser:

```sh
psql -U postgres -d rideshare_development
```

Once connected, run the following function to reset the `io` statistics:

```
SELECT pg_stat_reset_shared('io');
```

The `stats_reset` column shows the timestamp that was just set.

Setting up Rideshare is beyond the scope of this post, but if you'd like to follow along, here's a brief overview of the steps:

* Clone the repository. Install Ruby and all the system dependencies. Set up the `rideshare_development` database on PostgreSQL 16.
* Start the Rails Server (`bin/rails server`)
* Run the Rake task: `bin/rails simulate:app_activity`

Once the activity simulation task completes, let's go back to `psql` and review the `client backend` rows in `pg_stat_io`:

```sql
SELECT * FROM pg_stat_io
WHERE backend_type = 'client backend';
```

This is a small 2GB development database with around 20k rows in the largest table.

Below I'll analyze some of the results:

- `bulkread` and `bulkwrite` are zero, which makes sense since no bulk operations were performed
- The `context` value of `normal` shows 993 read operations, and no write operations. This makes sense since the simulation only ran read only queries.
- I'm seeing a `hits` value of `11616`. This is good because it means the data was served from shared buffers. Evictions, reuses, and fsyncs were all initially zero.
- The `backend type` = `checkpointer` performed 45 operations. Initially no `fsync` operations are performed, but later we see them.

In a real system, there will be much data!

## Wrap Up

This post was an introduction to the new `pg_stat_io` system view in PostgreSQL 16. This view adds additional IO visibility into what's happening with PostgreSQL, as it reads and writes data to physical storage, whether the IO is from client activity or other backend activity. PostgreSQL users can use this information to gain more knowledge on what the contributors are to IO and when the IO operations are happening.

That's all for now. Please let me know if you spot any technical issues or errors. Leave a comment about how you're using `pg_stat_io` in PostgreSQL 16.

Thanks for reading!


## Links






- PG_STAT_IO AND POSTGRESQL 16 PERFORMANCE <https://www.cybertec-postgresql.com/en/pg_stat_io-postgresql-16-performance/>
- Waiting for PostgreSQL 16 – Add pg_stat_io view, providing more detailed IO statistics <https://www.depesz.com/2023/02/27/waiting-for-postgresql-16-add-pg_stat_io-view-providing-more-detailed-io-statistics/>
- Understanding Postgres IOPS: Why They Matter Even When Everything Fits in Cache <https://www.crunchydata.com/blog/understanding-postgres-iops>


[^pgstatio]: <https://www.postgresql.org/docs/current/monitoring-stats.html#MONITORING-PG-STAT-IO-VIEW>
[^cituscon]: Additional IO Observability in Postgres with pg_stat_io - Citus Con 2023 <https://www.youtube.com/watch?v=rCzSNdUOEdg>
[^waiting]: Waiting for Postgres 16: Cumulative I/O statistics with pg_stat_io <https://pganalyze.com/blog/pg-stat-io>
[^glossary]: <https://www.postgresql.org/docs/current/glossary.html>
[^phystor]: <https://www.linkedin.com/pulse/postgres-physical-storage-tarun-annapareddy/>
[^moreio]: PostgreSQL 16: More I/O statistics <https://www.dbi-services.com/blog/postgresql-16-more-i-o-statistics/>
[^iobasics]: Postgres I/O Basics, and how to efficiently pack table pages <https://pganalyze.com/blog/5mins-postgres-io-basics>
[^pgbc]: <https://www.postgresql.org/docs/current/pgbuffercache.html>
[^pgped]: pgPedia pg_stat_io: <https://pgpedia.info/p/pg_stat_io.html>
[^playing]: PostgreSQL 16: Playing with pg_stat_io (1) – extends <https://www.dbi-services.com/blog/postgresql-16-playing-with-pg_stat_io-1-extends/>