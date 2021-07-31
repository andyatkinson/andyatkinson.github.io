---
layout: post
title: "PostgreSQL Index Maintenance"
tags: [PostgreSQL, Databases, Programming]
date: 2021-07-30
comments: true
featured_image_thumbnail:
featured_image: /assets/images/pages/andy-atkinson-California-SF-Yosemite-June-2012.jpg
featured_image_caption: Yosemite National Park. &copy; 2012 <a href="/">Andy Atkinson</a>
featured: true
---

Indexes on tables when used sparingly, are great for finding a needle (or a few needles) in a haystack.

Indexes are perfect when a sequential scan is happening (scanning all rows) in a high row count table (e.g. > 100K rows) and there are queries for a small filtered set of those rows (high selectivity). In that case, an index can be added to the column that is part of the filter conditions (`WHERE` clause) and the job is likely done. Matching the index conditions to that query will result in a very efficient lookup.

However there is a tendency to over-index applications. I know I am guilty of this in my past working experience.

We are going to look at:

* Unused indexes
* Bloated indexes
* Duplicate and invalid indexes

## Causes of unnecessary indexes

Some of the over-indexing might be:

* Adding an index before it is necessary (speculative)
* Adding an index to a foreign key column thinking it will be used (speculative)
* Adding an index without realizing the DB server has so much memory, the query planner will prefer a sequential scan to your index (check the query plan)
* Scaling up memory on a DB server that used an index before, and now the query planner chooses to no longer use the index
* Indexing multiple columns when a single column will do
* Indexing NULL values when it's unnecessary (use a partial index with a condition like `WHERE column IS NOT NULL`)

When this happens, unused indexes can likely be removed entirely from your database, reclaiming disk space and improving operational efficiency.

We're also going to talk about bloated indexes which are slightly different.

## Unused indexes

When PostgreSQL executes queries that use an index, PG keeps track of those index scans. Unused indexes are indexes that simply have no scans. We can exclude special indexes like indexes that enforce a unique constraint.

Our application being developed over several years and never having attempted to remove unused indexes, started with over 120 unused indexes.

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

Over many months and in batches, we removed all of them, reclaiming over 300 GB of disk space in the process!

## Bloated indexes

When even a single column on a row is updated, due to the MVCC implementation of PG, the entire row becomes a dead row/dead tuple. Thus tables are always made up of "live" tuples and dead tuples. This is by design in PG. The dead tuples are referred to as "bloat", and a table having 20% bloat is fine, but 50% is bad.

Due to the nature of typical web application workloads frequently updating rows, bloat is common. Autovacuum is designed to run periodically in the background and remove this bloat.

Sometimes Autovacuum doesn't remove all the bloat. Sometimes bloated rows are removed but the indexes on those tables remain bloated.

The fix for bloated indexes is to simply `REINDEX` the index. On newer versions of PG, this can be done in the background using the `CONCURRENTLY` option. However our system is running on PG 10 and so we are going to use a tool called pg_repack.

The query I use is for bloated indexes is [Database Soup: New Finding Unused Indexes Query](http://www.databasesoup.com/2014/05/new-finding-unused-indexes-query.html). I sort by bloat percentage and work down the list from the most bloated, to the least.

Keep track of the indexes and tables and determine whether any indexes can be removed, or AV can be made more aggressive for tables for which tables or indexes are heavily bloated.


[pghero](https://github.com/ankane/pghero)

## Enter pg_repack

[Install pg_repack on RDS](https://theituniversecom.wordpress.com/install-pg_repack-on-amazon-ec2-for-rds-postgresql-instances/)



I repacked 27 indexes on our primary database, reclaiming over 230 GB of space. In the most extreme cases with 90% bloat, the resulting repacked (new) index was around 10% the size of the former bloated index.

## Duplicate and Invalid indexes

Duplicate indexes mean that an index is redundant. The redundant index could be deleted and queries will still utilize a different index.

An invalid index was an index that likely failed to build properly. To fix this, drop and rebuild the index.
