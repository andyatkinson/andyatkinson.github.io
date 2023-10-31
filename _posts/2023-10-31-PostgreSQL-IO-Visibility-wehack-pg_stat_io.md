---
layout: post
title: "PostgreSQL IO Visibility: #wehack PostgreSQL Internals and pg_stat_io"
tags: []
date: 2023-10-31
comments: true
---

This week I’m participating in a virtual social learning experiment run by [Phil Eaton](https://eatonphil.com) / <https://twitter.com/eatonphil>, called "#wehack PostgreSQL Internals".

The purpose is to get more people hacking on PostgreSQL. Individuals can choose their level of engagement and the topics they wish to explore. The hoped-for output is learning, sharing, and possibly contributions to PostgreSQL!

Announcement blog post: #wehack Postgres Internals <https://eatonphil.com/2023-10-wehack-postgres.html>

For the last several *years*, I always have a running list of topics to learn in PostgreSQL. To start the week, I wanted to dive into the new system view in PostgreSQL 16 called `pg_stat_io`.[^pgstatio] My goal was to understand what information it provides, and how I could use it for performance analysis.

First up, what is it?

## What is it?

`pg_stat_io` is a new system view added in PostgreSQL 16, that adds observability for IO operations. IO operations can come from different types of operations such as client queries, like `SELECT` or inserts, or updates, or IO can be an effect of backend operations like Autovacuum. Another source would be one-time imports or exports of data.

Some of the community folks involved in this are Melanie Plageman and Lukas Fittl. I'll link to their content in this post.

Lukas Fittl points out that IO is split into writes to the WAL stream, or writes to the data directory in this post: <https://pganalyze.com/blog/pg-stat-io> It's worth noting that writes into a storage device don’t happen right away.

What are writes anyway?

## What “writes” are in the context of files and blocks

In this context, “writes” in PostgreSQL are different from what we might think of client-level INSERT, UPDATE, DELETE (DML) or SELECT operations.

Melanie points out in her Citus Con presentation,[^cituscon] how writes in PostgreSQL relate to files that store data in blocks. Writes happen when flushes of this data from blocks happens to disk (or the storage device, which could be network attached storage).

More generally: when data is stored in PostgreSQL, it needs to go into a block. Existing blocks are checked. When blocks have data in them already, they’re considered “dirty”, which means they need to be flushed. After dirty blocks are flushed, they're available for use.

As discussed earlier, writes can occur from different types of operations. What are those?


## Distinguishing backend types

Melanie points outs[^cituscon] how there are at least these three backend types:

* Client backend
* Background writer
* Checkpointer

These backend types report their IO activity in `pg_stat_io`. For web applications, we're mostly interested in `Client backend` types. When analyzing performance, we want to make sure that there isn't excessive or unnecessary IO occurring while client backend queries are being handled.

What does the view look like?


## What does it look like?

Like other system views, this view contains a lot of field data related to IO activity, backend types, operations, and more.

This post <https://www.dbi-services.com/blog/postgresql-16-more-i-o-statistics/> describes the result rows:

> What you see is one row per backend type, context and object.

As you saw in the last section, there will be a row per backend type. You may be interested in querying the view for specific backend types, depending on what you're investigating.

After initializing PostgreSQL, the view won't present much data. To generate some data, the post above shows how `pgbench` can be used. For example, run: `pgbench -i -s 10 postgres`

<https://www.postgresql.org/docs/current/monitoring-stats.html#MONITORING-PG-STAT-IO-VIEW>

## Who created it?

Melanie Plageman is helping lead the creation and education around this new capability. I had the privilege of meeting Melanie Plageman at PGConf NYC (check out my recap blog post here: [PGConf NYC 2023 Recap 🐘](/blog/2023/10/10/pgconf-nyc-2023)) and even was able to discuss `pg_stat_io` a bit in person.

Melanie recorded a presentation for Citus Con this year that introduced the new view. As someone learning about `pg_stat_io` for the first time, I found Melanie’s presentation to be very helpful! Check out: "Additional IO Observability in Postgres with `pg_stat_io`" - Citus Con 2023 <https://www.youtube.com/watch?v=rCzSNdUOEdg>

## Why does IO matter?

As Lukas Fittl says:

> PostgreSQL doesn’t load individual rows, it always loads full pages.

<https://pganalyze.com/blog/5mins-postgres-io-basics>

Because of this design, for OLTP environments where we want very fast queries, the IO can be a significant contributor to query latency.

Often data is not optimally stored, densely packed in PostgreSQL pages. Pages may be scattered around. `pg_stat_io` helps us analyze the IO for our client backends and see how pages are put into shared buffers.

Who is this view useful for?

## Who is it for?

Any PostgreSQL user wishing to gain more insight into the IO of their PostgreSQL installation, whether for from client application queries or other backend operations like Autovacuum, can benefit from the information presented in the view. Note that the information is system wide (or cluster-wide), which means that the statistics are from *all* databases. If you run multiple databases on an instance, keep this in mind.

Let's look at more use cases.

## What are the use cases?

With the additional IO visibility, Melanie suggests some use cases for the information in `pg_stat_io`.

For example, tuning Shared Buffers (Check out: [Resource Consumption](https://www.postgresql.org/docs/current/runtime-config-resource.html)) is one use case.

Shared buffers may be undersized. Since query performance is optimal when the working set fits into shared buffers, we could use `pg_stat_io` to see if there's a lot of IO from client backends that are outside of shared buffers. This could indicate Shared Buffers is too small.

PostgreSQL query execution plans show "shared hits", which means pages (or blocks) are coming from shared buffers. On the other hand, since shared buffers are "shared", as a limited resource they could be being used up by other backend types, like Autovacuum or bulk operations. When analyzing client backend application queries, we want to determine whether shared buffers is used as much as possible for client backends.

Understanding IO on cloud hosted PostgreSQL could also help with cost analysis, where IO is priced separately. IO on some cloud providers has a quota, and when IO is used beyond the quote, additional costs are incurred.

For deeper analysis of the content in shared buffers, enable the `pg_buffercache` extension to explore the buffer cache. With `pg_buffercache`, you’re able to determine which tables and indexes are in the cache.

## System Wide IO visibility

Lukas points out how prior to `pg_stat_io`, we could analyze the impact of IO from Vacuum jobs that were logged to `postgresql.log`, on a per-job basis.

With `pg_stat_io`, we can look at the impact of *all* Vacuum jobs on IO across the whole system, by querying the `context` = `vacuum`.

This query shows 3 result rows for `backend type` = `autovacuum worker` for contexts `bulkread`, `normal`, and `vacuum`.

```sql
SELECT * FROM pg_stat_io
WHERE backend_type = 'autovacuum worker'
OR (context = 'vacuum' AND (
    reads <> 0 OR writes <> 0 OR extends <> 0
    )
);
```

The post describes how this information could be analyzed to help explain an unexplained IO spike. These kinds of IO spikes are something I've seen in practice, so having this additional mechanism to explore what happened will be very useful.

## COPY operations

`pg_stat_io` gives us visibility for COPY operations.

By using the  `bulkread` and `bulkwrite` values for `io_context` in the view, we can explore the IO impact of bulk operations.


## What are the fields

To quickly see the fields, if you don’t have a psql client session handy, check out this pgPedia page:
<https://pgpedia.info/p/pg_stat_io.html>


## Identifying unintentional IO from the main transactional workload

What are flushes? Flushes happen when PostgreSQL data is written to durable storage.

For client backend types, we want to minimize flushes during client queries because the flushes add latency.

## Extends

`pg_stat_io` also shows information on “Extends” operations. What are those?

Melanie describes how Extends are a special kind of write operation. `extends` are displayed separately in the view from `reads` and `writes`.

The following post has a nice example starting from an empty table with no rows, that gets a row added to it.

The sizes within PostgreSQL and on the file system are compared. Extend operations happens when there's no page to store data, and a new page is allocated.

Check out the post: PostgreSQL 16: Playing with `pg_stat_io` (1) – extends <https://www.dbi-services.com/blog/postgresql-16-playing-with-pg_stat_io-1-extends/>

## Writebacks

Another concept in `pg_stat_io` are "Writebacks". What are they?

Hans-Jürgen Schönig from Cybertec provides some context and an explanation. Normally, "writes" to a storage device go through the OS file system cache. *writebacks* are when that process is skipped, and writes go from PostgteSQL directly to permanent storage.

## Let's dive in

To explore the `pg_stat_io` data locally, let's reset the stats and then generate some client activity.

To do that, I'll use the [Rideshare Rails app](https://github.com/andyatkinson/rideshare) which I've got set up locally, connected to a PostgreSQL 16 database. I'll start the Rails Server, then run the [`simulate_app_activity.rake`](https://github.com/andyatkinson/rideshare/blob/master/lib/tasks/simulate_app_activity.rake) Rake task.

Connect to PostgreSQL 16 (or newer) as a superuser:

```sh
psql -U postgres -d rideshare_development
```

Once connected, run the following function to reset the `io` statistics:

```
SELECT pg_stat_reset_shared('io');
```

The `stats_reset` column will reflect the recent reset timestamp.

Setting up Rideshare is beyond the scope of this post, but if you'd like to follow along, here's a brief peak at the steps:

* Clone the repository linked above, install Ruby and all system dependencies. Set up the `rideshare_development` database on PostgreSQL 16.
* Start the Rails Server (`bin/rails server`)
* Run the Rake task: `bin/rails simulate:app_activity`

Once the simulation task has completed, let's go back to `psql` and review the `client backend` rows in `pg_stat_io`:

```sql
SELECT * FROM pg_stat_io
WHERE backend_type = 'client backend';
```

This is a small 2GB development database with around 20k rows in the largest table.

Although the results aren't posted here, below I'll analyze the results I'm seeing, and note some details in the view, that have been discussed in this post:

- `bulkread` and `bulkwrite` are zero, which makes sense
- `context` value of `normal` shows 993 read operations, and no write operations, which makes sense. The simulation script is running queries.
- I'm seeing a `hits` value of `11616` which is great, this means the data being queried is served from shared buffers. Evictions, reuses, and fsyncs all start out at zero.
- The `backend type` = `checkpointer` has performed 45 operations. Later on we see it performs `fsync` operations.

In a real running system with more activity, there will be much more interesting data! In this section we looked at the bare bones data in a otherwise idle system, for a small database with data that fits in memory, and no other client activity besides client activity we explicitly generated.

## Wrap Up

This post was an introduction to the new `pg_stat_io` system view in PostgreSQL 16, helping show the IO visibility it adds that PostgreSQL users can leverage for performance analysis and more.

Please share how you're using `pg_stat_io` in PostgreSQL 16 to gain more visibility into your database IO.

Thanks for reading!


## Links


- Waiting for Postgres 16: Cumulative I/O statistics with pg_stat_io <https://pganalyze.com/blog/pg-stat-io>
- pgPedia pg_stat_io: <https://pgpedia.info/p/pg_stat_io.html>
- PostgreSQL 16: More I/O statistics <https://www.dbi-services.com/blog/postgresql-16-more-i-o-statistics/>
- PostgreSQL 16: Playing with pg_stat_io (1) – extends <https://www.dbi-services.com/blog/postgresql-16-playing-with-pg_stat_io-1-extends/>
- PG_STAT_IO AND POSTGRESQL 16 PERFORMANCE <https://www.cybertec-postgresql.com/en/pg_stat_io-postgresql-16-performance/>
- Waiting for PostgreSQL 16 – Add pg_stat_io view, providing more detailed IO statistics <https://www.depesz.com/2023/02/27/waiting-for-postgresql-16-add-pg_stat_io-view-providing-more-detailed-io-statistics/>
- Understanding Postgres IOPS: Why They Matter Even When Everything Fits in Cache <https://www.crunchydata.com/blog/understanding-postgres-iops>
- Postgres I/O Basics, and how to efficiently pack table pages <https://pganalyze.com/blog/5mins-postgres-io-basics>


[^pgstatio]: <https://www.postgresql.org/docs/current/monitoring-stats.html#MONITORING-PG-STAT-IO-VIEW>
[^cituscon]: Additional IO Observability in Postgres with pg_stat_io - Citus Con 2023 <https://www.youtube.com/watch?v=rCzSNdUOEdg>