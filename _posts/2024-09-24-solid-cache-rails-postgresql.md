---
layout: post
permalink: /solid-cache-rails-postgresql
title: 'Solid Cache for Rails and PostgreSQL'
tags: [PostgreSQL, Ruby on Rails]
comments: true
date: 2024-09-23
---

[Solid Cache](https://github.com/rails/solid_cache) is a relatively new cache framework that's available as a Ruby gem for Ruby on Rails. In the next major version of Rails, version 8, it's becoming the default cache backend.

Solid Cache uses a relational database to store cache data, a noteworthy difference from alternatives that tend to use memory-based solutions like Redis. Why is that? What are the trade-offs?

In this post, we’ll set up Solid Cache, explore the schema, data, operations, discuss Postgres optimizations, and explore this solution.

Before we do that, let's discuss caching in relational vs. non-relational stores in general.

## Why use a relational DB for caching?
A big change in the last decade is that there are now fast SSD drives with huge capacities at low price points.

SSDs attached locally to an instance, not over the network, offer very fast read and write access.

Besides the hardware gains, PostgreSQL itself has improved its efficiency across many releases over the last decade since memory-stores have been popular.

Features like index deduplication cut down on index sizes, offering faster writes and reads.

Developers can optimize reads for their application by leveraging things like database indexes, materialized views, and denormalization. These tactics consume more space and add latency to write operations, but can greatly improve read access.

With Solid Cache, we’ll look at its single table `solid_cache_entries` and how it’s indexed. The indexes themselves contain cache entry data, and when they’re small enough to fit in available memory, offer very fast access via Postgres' internal buffer cache.

To recap: with faster hardware, abundant storage, and optimized indexes, cache data in relational databases is starting to make sense. Besides that, being able to reduce application dependencies on multiple data stores simplies operations and may reduce costs.

With all of that said, why might we not want to adopt a relational database backed cache store?

## Why to NOT use a relational DB?
A relational DB has more features than are needed for safely storing cache data. These features are critical for non-cache primary data, but add latency.

What are some examples? Postgres uses write ahead logging ([WAL](https://www.postgresql.org/docs/current/wal-intro.html)), offers ACID guarantees, and has concurrency guarantees using multiversion concurrency control ([MVCC](https://www.postgresql.org/docs/current/mvcc.html)), that are all a bit overkill for cache data.

This is because cache data can usually be lost entirely and repopulated, which impacts response times until the cache data is repopulated, but doesn't result in permanent data loss.

WAL logs and ACID guarantees, atomic operations, transactional consistency, isolated transactions, and durable storage, are all arguably unnecessary here.

Even when a user receives a stale cache item, that would be ok in a general sense, as cache data is “stale” by definition.

To mitigate latency from some of these features that aren't really needed, we can disable parts of Postgres for specific tables or transactions.

We'll dive into those in a later section.

Before we do that, let’s dive into Solid Cache.

## Trying out Solid Cache
We’ll use the [Rideshare app](https://github.com/andyatkinson/rideshare) on GitHub, and used throughout the book [High Performance PostgreSQL for Rails](https://andyatkinson.com/pgrailsbook). This will be a place to add the gem, kick the tires, and explore some of the features.

After adding the gem, run the migrations command below.
```sh
railties:install:migrations FROM=solid_cache
```

Since the migrations were deemed unsafe per Strong Migrations, but we knew they were safe to do locally, we used the standard method to skip that check by adding `safety_assured { }` to the generated migrations.

Then we could apply them:

```sh
bin/rails db:migrate
```

## Going under the hood
With the migrations applied, let’s open up the database (this opens psql on Postgres) and explore:
```sh
bin/rails db
```
```sql
\dt solid*
```

Solid Cache adds only a single table called `solid_cache_entries` with only a few fields, although the main `key` and `value` fields use what Active Record calls a “binary” data type, which maps to a `bytea` field data type in PostgreSQL.

All fields prevent nulls. There are indexes on the `byte_size` and `key_hash` columns as single column indexes, and there’s one multicolumn index on `(key_hash, byte_size)`. We’d hope to see the multicolumn index used as a covering index that matches the definition of a SELECT clause for cache entries, requesting the same two columns in the same order.

What are the optional features?

## Solid Cache Options
Here are some options for Solid Cache:

- Max age: by default, it keeps cache entries for 1 week
- Max size: by default, up to 256MB size per entry
- Namespace: the default is the Rails environment name, for example “development”

There are a lot of additional options, so check them out.


## Basic Usage
Let’s cache something, then look in the `solid_cache_entries` table. We’ll use the style that the Rails Guides refer to as [low level caching](https://guides.rubyonrails.org/caching_with_rails.html#low-level-caching).

Use `fetch()` to write a value when it doesn’t exist:

```rb
irb(main):001> Rails.cache.fetch("foo-123"){ Trip.first.id }
  SolidCache::Entry Load (2.2ms)  SELECT "solid_cache_entries"."key", "solid_cache_entries"."value" FROM "solid_cache_entries" WHERE "solid_cache_entries"."key_hash" = $1  [[nil, 4421380845266846514]]
  Trip Load (2.7ms)  SELECT "trips".* FROM "trips" ORDER BY "trips"."id" ASC LIMIT $1  [["LIMIT", 1]]
  SolidCache::Entry Upsert (2.0ms)  INSERT INTO "solid_cache_entries" ("key","value","key_hash","byte_size","created_at") VALUES ('\x646576656c6f706d656e743a666f6f2d313233', '\x001101000000000000f0bfffffffff04086907', 4421380845266846514, 178, CURRENT_TIMESTAMP) ON CONFLICT ("key_hash") DO UPDATE SET "key"=excluded."key","value"=excluded."value","byte_size"=excluded."byte_size" RETURNING "id"
=> 2
```

It just works! If you’re familiar with the Rails cache API, then using Solid Cache to create a cache entry is straightforward.

Here’s how to read the key that was just set:

```rb
irb(main):002> Rails.cache.fetch("foo-123")
  SolidCache::Entry Load (0.8ms)  SELECT "solid_cache_entries"."key", "solid_cache_entries"."value" FROM "solid_cache_entries" WHERE "solid_cache_entries"."key_hash" = $1  [[nil, 4421380845266846514]]
=> 2
```

Let’s pop back over to SQL and use `EXPLAIN` to get a query plan. Since we’re running Postgres 16, we can use the `GENERIC_PLAN` option with `EXPLAIN`, which does not require specific parameter values for the numbered parameters.

With the generic plan and when accessing even a single row, we can see the query planner chose an index scan using the multicolumn index `index_solid_cache_entries_on_key_hash_and_byte_size`.

This makes sense because the `SELECT` query we see above matches the index definition columns exactly. This should result in an efficient index scan or index only scan, keeping latency as low as possible.


```sql
owner@localhost:5432 rideshare_development# EXPLAIN (GENERIC_PLAN) SELECT "solid_cache_entries"."key", "solid_cache_entries"."value" FROM "solid_cache_entries" WHERE "solid_cache_entries"."key_hash" = $1;
                                                           QUERY PLAN
--------------------------------------------------------------------------------------------------------------------------------
 Index Scan using index_solid_cache_entries_on_key_hash_and_byte_size on solid_cache_entries  (cost=0.15..8.17 rows=1 width=64)
   Index Cond: (key_hash = $1)
(2 rows)
```

What else might we consider looking into with Postgres?


## PostgreSQL Optimizations
As discussed earlier, we could disable write ahead logging (WAL) for the `solid_cache_entries` table to reduce write IO operations. If Postgres were to crash or have an "unclean shutdown", and `solid_cache_entries` was unlogged, the table [will be truncated](https://www.postgresql.org/docs/current/sql-createtable.html) on startup. If that's not acceptable, keep the table "logged," which is the default.

With that said, to change the table from the default of "logged" to unlogged, run:
```sql
ALTER TABLE solid_cache_entries SET UNLOGGED;
```

In addition to that and WAL related, Postgres uses the WAL to guarantee durability of the data. However, there are levels. If we accept less guarantees on durability, we can reduce write IO.

We can do that by changing the default value for `synchronous_commit` at a transaction level. Review the [synchronous_commit Modes](https://postgresqlco.nf/doc/en/param/synchronous_commit/) table to see all the options. The default value is `on`.

If we change the value to `local`, we're still guaranteed local durability, but aren't guaranteed commits to the table will make it all the way through replication (when replication is enabled).

At the transaction level, changing `synchronous_commit` would look like this:

```sql
BEGIN;

SET LOCAL synchronous_commit TO 'local';

INSERT INTO "solid_cache_entries" ("key","value","key_hash","byte_size","created_at")
VALUES ('\x646576656c6f706d656e743a666f6f2d313233', '\x001101000000000000f0bfffffffff04086907',
4421380845266846514, 178, CURRENT_TIMESTAMP)
ON CONFLICT ("key_hash")
DO UPDATE SET "key"=excluded."key","value"=excluded."value",
"byte_size"=excluded."byte_size" RETURNING "id";

COMMIT;
```

PostgreSQL runs the Checkpoint process every 5 minutes by default. We're not recommending changing that here since it's server-wide, and can't be scoped to the `solid_cache_entries` table or specific transactions. However, checkpoints can be performed manually using the `CHECKPOINT` command.

Another optimization area besides WAL is Autovacuum for `solid_cache_entries`. In Postgres, since `solid_cache_entries` will have updates and deletes, we may want to make more Autovacuum resources available for this table.

Consider reducing the autovacuum scale factor so that vacuum is triggered earlier.

To do that, run the following statement in psql:
```sql
ALTER TABLE solid_cache_entries SET (
    autovacuum_vacuum_scale_factor = 0.01,
    autovacuum_vacuum_cost_delay = 10,
    autovacuum_vacuum_cost_limit = 200
);
```

## Faster reads and writes, same database server instance
Use the [pg_prewarm](https://www.postgresql.org/docs/current/pgprewarm.html) extension to load the entire contents of `solid_cache_entries` into the buffer cache. However, we’d still keep the buffer cache at 25-40% of system memory following guidelines. Buffer cache consumes limited server instance memory.

```sql
SELECT pg_prewarm('solid_cache_entries');
```

Adjust `random_page_cost` for query planning purposes. The default value was created in the era of rotating hard disks, not modern fast SSDs. Some folks recommend adjusting the value to be equal to `seq_page_cost`.

Note that this is a database wide value. The goal is to increase the proportion of index scans.
```sql
ALTER SYSTEM SET random_page_cost = 1.1;
```

Over time, if `solid_cache_entries` reaches more than 100 gigabytes, for example if you’ve greatly increased the max size of cache data, and perhaps are running a dedicated cache server, it may be worth exploring migrating the row data into a partitioned table with an equivalent structure.

To minimize changes to the application code, a HASH partition type could be used and calculated based on the bigint primary key. This would help distribute read and write operations into more tables. This could be 4, 8, 16 or some number of partitions in the structure. For write operations, there could be reduced contention as cache entries are inserted into multiple tables, and for index page writes as each partition has its own indexes. 

The benefit to read operations with [partition_pruning](https://www.postgresql.org/docs/current/ddl-partitioning.html#DDL-PARTITION-PRUNING) enabled is that Postgres has enough information to access only specific, needed partitions.

## Faster reads on a dedicated server instance
If we run Solid Cache and the `solid_cache_entries` on a dedicated server instance, we can tune even more things.

Normally a Postgres instance might allocate 25% of the available system memory to the buffer cache (the `shared_buffers`) param. However, for a dedicated cache instance, we could crank this way up. We could gradually move this up to 50, 60, 70% of system memory, and populate the whole `solid_cache_entries` into the buffer cache using the `pg_prewarm` extension on startup.

After adjusting `shared_buffers`, increase `effective_cache_size` to keep the planner up to date.

With Write Ahead Logging disabled, write IO spikes from `CHECKPOINT` operations are avoided. Besides disabling it entirely, another option is to set the `wal_level` to `minimal` which provides durability guarantees, but reduces the logging level to one that's too low for replication.

What about transactions? All Postgres operations from Active Record are wrapped in an implicit transaction. Active Record provides a way to explicitly control the transaction, including providing options to the transaction.

One option would be to use a lower transaction isolation level than the default of “read committed”. That level means that only committed data is read. The lower level means data that’s not yet committed can be read. This is unlikely to be much of an improvement, and reading uncommitted data may cause surprising results. However, it’s possible to achieve a higher level of transactions per second (TPS) throughput by reading uncommitted data. If you’re exploring this level of optimization, hopefully you’re using [pgbench](https://www.postgresql.org/docs/current/pgbench.html) to conduct some benchmarks.

```rb
irb(main):009> ActiveRecord::Base.transaction(isolation: :read_uncommitted){ Trip.first }
  TRANSACTION (3.5ms)  BEGIN ISOLATION LEVEL READ UNCOMMITTED
  Trip Load (6.4ms)  SELECT "trips".* FROM "trips" ORDER BY "trips"."id" ASC LIMIT $1  [["LIMIT", 1]]
  TRANSACTION (0.3ms)  COMMIT
=>
#<Trip:0x000000010bdfb0b8
 id: 2,
 trip_request_id: 2,
 driver_id: 10020064,
 completed_at: Fri, 02 Aug 2024 09:33:26.652909000 CDT -05:00,
 rating: 5,
 created_at: Wed, 31 Jul 2024 23:55:59.297526000 CDT -05:00,
 updated_at: Wed, 31 Jul 2024 23:55:59.297526000 CDT -05:00>
```

Another transaction option is a read only transaction, which again is fairly uncommon, and does not seem to be supported by Active Record. The idea would be that a real only transaction allows Postgres to avoid overhead associated with locking resources, so a theoretically higher level of TPS is possible. This should again be benchmarked using [pgbench](https://www.postgresql.org/docs/current/pgbench.html).

In SQL, a read only transaction is created like this: 
```sql
BEGIN TRANSACTION READ ONLY;
SELECT * FROM trips LIMIT 1;
COMMIT;
```

Active Record supports transaction isolation levels, but does not support read only transactions at this time.

To try this out, let’s add a small patch that overrides the transaction code in Rails at runtime, allowing us to create a read only type of transaction. This should be taken purely as a demonstration. A file `lib/patches/active_record_patches.rb` was added to [Rideshare PR #213](https://github.com/andyatkinson/rideshare/pull/213). It looks like this:

```rb
module Patches::ActiveRecordPatches
  module ::ActiveRecord::ConnectionAdapters::PostgreSQL::DatabaseStatements
    def begin_db_transaction
      # Replaces:
      # internal_execute("BEGIN", "TRANSACTION", allow_retry: true, materialize_transactions: false)
      internal_execute("BEGIN", "TRANSACTION READ ONLY", allow_retry: true, materialize_transactions: false)
    end
  end
end
```

With that override in place, run `bin/rails console`. Open a transaction and verify a `READ ONLY` transaction was created:
 
```rb
irb> require Rails.root.join('lib', 'patches', 'active_record_patches')

irb> Trip.transaction{ Trip.first }
  TRANSACTION READ ONLY (0.2ms)  BEGIN
  Trip Load (0.3ms)  SELECT "trips".* FROM "trips" ORDER BY "trips"."id" ASC LIMIT $1  [["LIMIT", 1]]
  TRANSACTION (0.2ms)  COMMIT
```

## Cache Entry Expiration
What if we want something in cache only for a short time?

```rb
Rails.cache.fetch(
    "foo-123456",
    expires_in: 10.seconds
){ "bar" }
```

Accessing the above entry `Rails.cache.fetch("foo-123456")` more than 10 seconds later returns nil as expected. Since Postgres doesn’t offer any kind of expiring entry, this is implemented by deleting the `solid_cache_entries` record before returning a result. Since there isn’t a separate database field for the duration, the 10 seconds figure above becomes part of the key that’s stored.

There are a lot more interesting features in Solid Cache, but we’ll have to save those for another post. Next time we’ll cover how older entries are cycled out when limits are reached, sharding the cache store and the Maglev scheme, and storing and retrieving multiple entries at once.

## Wrapping Up
We covered background jobs with Ruby on Rails, and why and why not to store their job data in a relational database.

We tried out the basics of Solid Cache, storing and retrieving cached content, and how to configure cache entries to expire at a certain time.

See an earlier post on [Solid Queue background jobs](/solid-queue-mission-control-rails-postgresql), another new default coming to Ruby on Rails 8.

Thanks for reading!

- Updates: Thanks [@PikachuEXE](https://github.com/PikachuEXE) for clarifications and additions.
