---
layout: post
title: "PostgreSQL Indexes: Prune and Tune"
tags: [PostgreSQL, Databases, Programming]
date: 2021-07-30
comments: true
---

Indexes are data structures designed for fast retrieval. For databases with high row counts, Indexes that match queries well are critical to achieving good performance.

Indexes have other purposes like sorting or Constraint enforcement, but this post is focused on Indexes for fast data retrieval.

When unfamiliar with Indexes, there can be a tendency to "over index". This means that you might create Indexes that aren't needed. Is that a problem?

## Indexes Aren't "Free"

Indexes aren't "free" in that they trade-off space consumption for fast retrieval, and add some write time latency.

Indexes need to be maintained for all writes (Inserts, Updates, Deletes) and can consume a lot of space on disk. This trade-off is completely worth it when an Index is used. When an Index is not used though, it's just taking up space!

Big unused indexes slow things down like taking snapshots and restoring them.

Unnecessary Indexes can take several forms.

* Unused indexes
* Duplicate indexes (that cover the same columns)
* Duplicate indexes (Exact duplicate definitions with different names)
* Indexes with very high bloat that might be skipped over for use
* Invalid indexes that failed during creation CONCURRENTLY

## Causes of Unnecessary Indexes

Over indexing can occur for some of the following reasons.

* Adding an index before it's used that never becomes used
* Adding an index to a foreign key column that duplicates an automatic index
* Unused indexes when table scans are adequate for small tables or large result set sizes, or for smaller partitions
* Indexing columns that aren't necessary for a query
* Indexing rows with `NULL` values or other non-live rows (not using Partial Indexes)
* Only using Multicolumn indexes and not taking advantage of multiple single column indexes being used

How can we identify Unused Indexes?

### Unused Indexes

Fortunately, PostgreSQL tracks all index scans. Using the Index Scan information, we can identify unused indexes.

The system catalog `pg_catalog.pg_stat_user_indexes` tracks `idx_scan` and it will be zero when there are no Index Scans from queries.

We can ignore special indexes like indexes that enforce a `UNIQUE` constraint.

Run a query like this one ["List Unused Indexes"](https://github.com/andyatkinson/pg_scripts/blob/master/find_unused_indexes.sql) to find them.

```sql
SELECT
  s.schemaname,
  s.relname AS tablename,
  s.indexrelname AS indexname,
  pg_relation_size(s.indexrelid) AS index_size
FROM pg_catalog.pg_stat_user_indexes s
JOIN pg_catalog.pg_index i ON s.indexrelid = i.indexrelid
WHERE s.idx_scan = 0      -- has never been scanned
AND 0 <>ALL (i.indkey)    -- no index column is an expression
AND NOT i.indisunique     -- is not a UNIQUE index
AND NOT EXISTS            -- does not enforce a constraint
  (SELECT 1 FROM pg_catalog.pg_constraint c
   WHERE c.conindid = s.indexrelid)
ORDER BY pg_relation_size(s.indexrelid) DESC;
```

## Removal Process

Where I worked on a long lived monolithic codebase with lots of churn, we found loads of Unused Indexes that could be removed.

We gradually removed all of them, reducing space consumption by more than 300 GB for a > 1 TB database (a significant proportion!).

How could we keep a better eye on this going forward?

We added [PgHero](https://github.com/ankane/pghero) which helps make unused indexes more visible to team members by showing an Unused label in the UI.

Can Indexes become bloated?

## Bloated Indexes

In [MVCC](https://www.postgresql.org/docs/current/mvcc.html) when a row is updated, a new row version (called a *tuple*) is created behind the scenes.

The former row version becomes a "dead tuple" when no transactions reference it. This is part of the concurrency design of PostgreSQL. Tables always consist of "live" and dead tuples.

Dead tuples then can be considered "bloat" at the table level and in Indexes.

When tables and indexes for the table have high percentages of bloat, space consumption becomes unnecessarily high and query performance can even worsen in extreme cases at least on older versions of PostgreSQL.

The fix for heavily bloated indexes is to `REINDEX` the index. This rebuilds the index and it's initially free of dead tuples.

This is a disruptive operation though for queries using the index so make sure to use the `CONCURRENTLY` keyword when it's available.

On newer versions of PostgreSQL do that by using `REINDEX` with `CONCURRENTLY`.

## Bloat management with pg_repack

On older versions (<11) of PostgreSQL, use a third-party tool like [pg_repack](https://reorg.github.io/pg_repack/) to rebuild your indexes online.

Another index bloat query to use is [Database Soup: New Finding Unused Indexes Query](http://www.databasesoup.com/2014/05/new-finding-unused-indexes-query.html) which displays a great variety of Index information.

There may be seldom used Indexes that don't help much that you may wish to remove as well.

Besides removing unused indexes, our team gradually rebuilt all indexes with very high estimated bloat.

To help things on a going forward basis, we also looked to add more resources to Autovacuum for the heavily updated tables to reduce accumulation of excessive bloat.

The end result was a much cleaner set of indexes that more accurately reflected current queries and were free of excessive bloat.

`pg_repack` is a command line application. To use it with Amazon RDS PostgreSQL, install it and run it on an instance.

Reference [Installing pg_repack on RDS](https://theituniversecom.wordpress.com/install-pg_repack-on-amazon-ec2-for-rds-postgresql-instances/) and install the appropriate version for the database.


## Summary of Rebuilds

Using pg_repack, I rebuilt 27 indexes on our primary database reclaiming over 230 GB of space.

In the most extreme cases with an estimated 90% bloat, the resulting rebuilt index was around 10% of the original size.


## PostgreSQL Unused Indexes

This was a presentation I gave internally on the team on Unused Indexes Maintenance in January 2021.

<iframe class="speakerdeck-iframe" frameborder="0" src="https://speakerdeck.com/player/6644d7dd7380413ea19dce1955f41269" title="PostgreSQL Unused Indexes" allowfullscreen="true" mozallowfullscreen="true" webkitallowfullscreen="true" style="border: 0px; background-color: rgba(0, 0, 0, 0.1); margin: 0px; padding: 0px; border-radius: 6px; -webkit-background-clip: padding-box; -webkit-box-shadow: rgba(0, 0, 0, 0.2) 0px 5px 40px; box-shadow: rgba(0, 0, 0, 0.2) 0px 5px 40px; width: 560px; height: 314px;" data-ratio="1.78343949044586"></iframe>

I covered bloat and how we addressed it in a talk given at [PGConf NYC 2021 Conference](/blog/2021/12/06/pgconf-nyc-2021).


## Summary of Index Removals

* Find and removed unnecessary Indexes like unused, duplicate, or overlapping
* Remove and rebuild `INVALID` Indexes
* Remove index bloat by rebuilding Indexes Concurrently or by using `pg_repack`
* Adjust Autovacuum settings (add resources) for high `UPDATE` tables so that it runs more frequently to keep up

Thanks! 👋
