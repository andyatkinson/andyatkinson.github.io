---
layout: post
title: "PostgreSQL Indexes: Prune and Tune"
tags: [PostgreSQL, Databases, Programming]
date: 2021-07-30
comments: true
---

Indexes are data structures designed for fast retrieval speed, great for finding a needle in a haystack. Often, they go beyond great, and become critical to achieve good performance for queries on large tables.

Indexes have many purposes, but this post is focused on fast data retrieval usage, finding an exact match or filter a small set of rows as quickly as possible.

There can be a tendency to over index for application queries, meaning there are more indexes than necessary.

Indexes are not "free" in performance for writes, and in their disk usage. They need to be maintained for writes, can be large on disk adding time for backups, and index content needs to replicated between primary and replica databases.

Perhaps your application has some over indexing, and some maintenance and pruning is in order. Consider cleanups in these categories:

* Unused indexes
* Duplicate indexes (covering the same columns)
* Overlapping indexes
* Indexes with very high bloat
* Invalid indexes, built in background, failed before completion

### Causes of unnecessary indexes

Over indexing can occur:

* Adding an index before it's used, and then it is never used
* Adding an index to a foreign key column, not used by a query plan
* Scaling up memory or compute resources, small table, query plan changes from Index scan to Sequential Scan
* Indexing more columns than necessary
* Including rows with `NULL` column values intead of excluding them, when they're never queried.
* Only Multicolumn indexes, with when multiple single column indexes are adequate


### Unused Indexes

Fortunately, PostgreSQL tracks all index scans, so we can easily identify unused indexes. Unused indexes can be removed from your database, but some sanity checking and ceremony around removals is a good idea to prevent mistakes.

Unused indexes are indexes that were not used in any past queries, which would have otherwise resulted in an Index Scan. We can ignore special indexes like indexes that enforce a `UNIQUE` constraint, those are necessary for data integrity enforcement. Those are excluded below.

Our application being developed over several years, lots of different developers, a variety of feature queries that came and went, resulted in dozens of unused indexes.

Run a query below to [list unused indexes](https://github.com/andyatkinson/pg_scripts/blob/master/find_unused_indexes.sql).

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

Over months as time allowed, we verified each were safe to remove and gradually removed all of them, reclaiming over 300 GB of disk space in out > 1 TB database, a significant size reduction.

In addition to the query above, we adopted [PgHero](https://github.com/ankane/pghero) to make unused indexes more visible to all team members, helping establish better database maintenance hygiene.


### Bloated Indexes

In [MVCC](https://www.postgresql.org/docs/current/mvcc.html), when a row is updated even for a single column, the update creates a new row version, a tuple, and tuples are immutable. The former row becomes a dead tuple. This former row is invisible to new transactions. Tables always consist of "live" and dead tuples.

Dead tuples are referred to as "bloat". When tables and indexes for the table have high percentages of bloat, for example 40% or higher, query performance may be worsened.

The fix for heavily bloated indexes is to `REINDEX` the index, which performs a rebuild of the index. This is disruptive for other transactions, but can be performed online using `CONCURRENTLY`.

On newer versions of PostgreSQL, use `REINDEX` with `CONCURRENTLY`. On older versions (11 and older), a third-party tool like like [pg_repack](https://reorg.github.io/pg_repack/) may be used to conduct an online index rebuild.

The query I use for bloated indexes is [Database Soup: New Finding Unused Indexes Query](http://www.databasesoup.com/2014/05/new-finding-unused-indexes-query.html).

Working down from highest estimated bloat percentage to least, some were as high as 90% estimated bloat, we gradually rebuilt all high bloat indexes. Our goal now is to tune Autovacuum so that excessive bloat is less likely to occur.

By conducting this rebuild work, we also evaluated unused indexes, duplicates, overlaps, and in lieu of rebuilding an unused index, simply removed it. The end result was a much cleaner set of indexes that more accurately reflected the current query workload.


### Using pg_repack

`pg_repack` is a command line application. To use it with Amazon RDS PostgreSQL, install it and run it on an instance. Reference [Installing pg_repack on RDS](https://theituniversecom.wordpress.com/install-pg_repack-on-amazon-ec2-for-rds-postgresql-instances/) and install the appropriate version for the database.


## Summary of Rebuilds

I repacked 27 indexes on our primary database, reclaiming over 230 GB of space. In the most extreme cases with an estimated 90% bloat, the resulting rebuilt index was around 10% of the original size. This makes sense since 90% of the content no longer reflected live tuples.

### Removing Duplicate, Redundant, and Invalid Indexes

Duplicate indexes are two indexes with different names, but covering the same columns, in the same order.

Redundant indexes mean two indexes, with columns in common, where one index or the other could be used for a query.

PgHero helped us identify 13 duplicate indexes that could be removed. The process we followed was to drop the index on a detached database, analyze the table, compare the query plan and execution time, then perform the work on the primary database when it seemed the query plan would be no different. This was an extra cautionary approach and may be unnecessary.

Invalid indexes are indexes that failed to build properly, probably from having been built `CONCURRENTLY`, but not completing successfully. These may be dropped.

Another technique was to prepare the `CREATE INDEX` statement from the original definition in advance, if it was necessary to quickly rebuild an index. This was also an extra cautionary step. As you gain confidence in this process, you may feel more comfortable more regularly removing unused indexes.


#### Summary of Index Removals

* Find and removed unused, duplicate, and overlapping indexes
* Remove or rebuild invalid indexes
* Remove index bloat by rebuilding the index (use `pg_repack` or `REINDEX ... CONCURRENTLY`)
* Adjust Autovacuum settings, proportionally with your `UPDATE` workload, to run more frequently


#### PostgreSQL Unused Indexes (Internal lightning-style talk)

January 2021<br/>
Unused Indexes

<iframe class="speakerdeck-iframe" frameborder="0" src="https://speakerdeck.com/player/6644d7dd7380413ea19dce1955f41269" title="PostgreSQL Unused Indexes" allowfullscreen="true" mozallowfullscreen="true" webkitallowfullscreen="true" style="border: 0px; background-color: rgba(0, 0, 0, 0.1); margin: 0px; padding: 0px; border-radius: 6px; -webkit-background-clip: padding-box; -webkit-box-shadow: rgba(0, 0, 0, 0.2) 0px 5px 40px; box-shadow: rgba(0, 0, 0, 0.2) 0px 5px 40px; width: 560px; height: 314px;" data-ratio="1.78343949044586"></iframe>

December 2021<br/>
I covered bloat and how we addressed it in a talk given at [PGConf NYC 2021 Conference](/blog/2021/12/06/pgconf-nyc-2021).
