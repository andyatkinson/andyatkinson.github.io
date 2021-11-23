---
layout: post
title: "PostgreSQL Indexes: Prune and Tune"
tags: [PostgreSQL, Databases, Programming]
date: 2021-07-30
comments: true
---

Indexes on tables are great for finding a needle (or a few needles) in a haystack.

Indexes can be utilized to avoid slow sequential scans (scanning all rows) in high row count tables when querying a small filtered set of rows.

However there can be a tendency to over-index applications and indexes are not "free" in terms of their impact to storage and disk IO. I know I had a tendency to over-index in my past experience.

So perhaps your application has some over-indexing, and some maintenance and pruning is in order. Let's look at cleanups in these categories:

* Unused indexes
* Bloated indexes
* Duplicate and invalid indexes

## Causes of unnecessary indexes

Some of the over-indexing might be:

* Adding an index before it is used as part of a query plan (speculative)
* Adding an index to a foreign key column when it's not used by a query plan (speculative)
* Adding an index without testing on production hardware. Production may have considerably more memory available and not use the index. (check the query plan)
* Scaling up memory or system resources on a DB server dramatically and PG changing the query execution plan
* Indexing multiple columns when a single column is adequate
* Indexing NULL values when they are not part of query conditions (a partial index can exclude `NULL` column rows)
* PG can combine multiple single column indexes as part of query planning


## Unused Indexes

Fortunately PG tracks index scans so we can easily identify unused indexes. Unused indexes can likely be removed entirely from your database, reclaiming disk space and improving operational efficiency.

Unused indexes are indexes that simply have no scans (it may also be beneficial to look at low scans, and high writes). We can ignore special indexes like indexes that enforce a unique constraint from our unused indexes cleanup considerations.

Our application being developed over several years had quite a few unused indexes, started with over 110 of them.

Finding unused indexes:

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

Over months as time allowed and in batches, we verified each were safe to remove and gradually removed all of them, reclaiming over 300 GB of disk space in the process!

In addition to this query, we adopted [PgHero](https://github.com/ankane/pghero) to make unused indexes more visibile to all team members. Easier to spot, easier to remove.


## Bloated indexes

By design in the MVCC implementation PG, when a row is updated even for a single column, the former row becomes a dead row/dead tuple (invisible). Tables always consist of "live" and dead tuples.

The dead tuples are referred to as "bloat" and a table with 20% of its tuples (rows) being bloat is acceptable, but 50% or more is bad and can impact performance.

Due to the nature of web application workloads bloat is common. Perhaps this is due to a UPDATE heavy workload.

The fix for bloated indexes is to `REINDEX` the index, thus removing any references to dead tuples. On newer versions of PG, `REINDEX` can be done in the background (`CONCURRENTLY`) however on PG 10 that is not supported. To reindex concurrently, we used a tool called [pg_repack](https://reorg.github.io/pg_repack/) which supports repacking tables and indexes concurrently. This is a third-party tool that has some downsides (heavy disk IO, `ACCESS EXCLUSIVE` lock for table repack) so make sure to test usage of it on your pre-production systems.

The query I use for bloated indexes is [Database Soup: New Finding Unused Indexes Query](http://www.databasesoup.com/2014/05/new-finding-unused-indexes-query.html).

Working down from bloat percentage (some indexes as high as (estimated) 90% bloat!) we gradually repacked all high bloat indexes. Our goal now is to tune Autovacuum appropriately so that this excessive bloat does not recur.

Keep track of the indexes and tables and determine whether any indexes can be removed, or AV can be made more aggressive for tables for which tables or indexes are heavily bloated.


## Using pg_repack

Pg_repack is a command line application. To use it with Amazon RDS PostgreSQL, install it and run it on an instance. Reference [Installing pg_repack on RDS](https://theituniversecom.wordpress.com/install-pg_repack-on-amazon-ec2-for-rds-postgresql-instances/) and install the appropriate version for the database.

I repacked 27 indexes on our primary database, reclaiming over 230 GB of space. In the most extreme cases with 90% bloat, the resulting repacked (new) index size was around 10% of the original size. This makes sense since 90% of the bloat was removed.

## Duplicate, Redundant and Invalid indexes

Duplicate indexes mean that two indexes have different names, but index the same columns.

Redundant indexes mean another index serves the same purpose for the query execution plan.

PgHero helped us identify 13 duplicate indexes that could be dropped. The process was to drop the index on a detached datatabase, analyze the table, compared the query plan and execution time before and after removing the index.

If the query plan and execution time looked the same, the index could be dropped in production!

Invalid indexes are indexes that failed to build properly. To fix this, drop the index if not needed, or rebuild the index (concurrently).


## Summary

* Find and removed unused and duplicate indexes that don't impact queries
* Remove or rebuild invalid indexes
* Remove index bloat by re-indexing (use pg_repack or `reindex concurrently`)
* Adjust Autovacuum settings proportional to UPDATE workload


If you have any other index maintenance tips, I'd love to hear them. Thanks for reading.

#### PostgreSQL Unused Indexes (Internal lightning-style talk)

January 2021<br/>
Why unused indexes are bad and how to remove them

<script async class="speakerdeck-embed" data-id="6644d7dd7380413ea19dce1955f41269" data-ratio="1.77777777777778" src="//speakerdeck.com/assets/embed.js"></script>

