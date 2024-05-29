---
layout: post
title: "Top Five PostgreSQL Surprises from Rails Devs"
tags: []
date: 2024-05-29
comments: true
---
At [Sin City Ruby 2024](/blog/2024/03/25/sin-city-ruby-2024) earlier this year, I presented advanced PostgreSQL topics to Ruby programmers, and had some great feedback afterwards!

I took notes about feedback items that were new or noteworthy for Rails programmers.

Let's cover the items in no particular order.

1. Covering Indexes
1. How PostgreSQL stores data in pages, and how we can see how many are accessed
1. Topics related to ordered data in queries and indexes
1. Why `SELECT *` is not optimal, and how to enumerate all table columns in queries by default
1. Using PostgreSQL over other databases, for more types of work

Let's dive into the details of each item.

## 1. Covering Indexes

[Covering indexes](https://www.postgresql.org/docs/current/indexes-index-only-scans.html) are an index design tactic to bring in the data from two or more columns into the index. This type of index provides a targeted data source that supports a query. PostgreSQL describes a covering index as:

> An index specifically designed to include the columns needed by a particular type of query that you run frequently.

[PostgreSQL Multicolumn indexes](https://www.postgresql.org/docs/current/indexes-multicolumn.html), which are indexes that include two or more columns in their definition, can act as a covering index by "covering" all the column data needed for one or more queries, ideally achieving an efficient "index only scan."

When the planner can choose an index only scan, all the data needed for the query is supplied by the index itself.

From PostgreSQL 12, we gained another covering index option. The keyword `INCLUDE` was added. How do we use it?

The idea is to specify columns with `INCLUDE` that aren’t being filtered on, but are requested in the `SELECT` clause portion. Let’s look at an example.

Here is the covering index definition I showed in the presentation, supporting a query for the [Rideshare](https://github.com/andyatkinson/rideshare) database, the example app from the book [High Performance PostgreSQL for Rails](https://pragprog.com/titles/aapsql/high-performance-postgresql-for-rails/):

```sql
CREATE INDEX idx_trips_driv_rat_completed_cov_part
ON trips (driver_id)
INCLUDE (rating)
WHERE completed_at IS NOT NULL;
```

The query that uses this index *filters* on the `driver_id` column, but performs an aggregation (an `AVG()`) on the `rating` column.

The `rating` column is listed after the `INCLUDE` keyword, making it a "payload" column.

In addition to being a covering index, this index uses a `WHERE` clause, limiting the included rows, making it a [partial index](https://www.postgresql.org/docs/current/indexes-partial.html).

Here the index selects only rows with their `completed_at` timestamp set, in other words, the "completed" trips. Besides benefitting read performance, using a partial index also lessens the write latency by lessening the rows needing to be maintained in the index.

There you have it. The index above is a "covering, partial index," and these types of specialized indexes combine multiple indexing tactics, yielding powerful results that minimize write latency and greatly reduce read latency with efficient index scans and index only scans.

## 2. Viewing Pages Accessed
Pages (or *buffers*) are storage concepts that most web application developers don’t tend to know about, as they are more of an implementation detail of how PostgreSQL stores table and index data. However, it’s beneficial to understand pages because we can get insights into query performance by studying the number of pages accessed.

Whether PostgreSQL is accessing one row or all rows stored in a page, when fetching the data needed for a query, PostgreSQL loads full pages. For a given query, we can see exactly how many pages are loaded.

Why do we care? We care because loading pages incurs I/O latency, which lengthens the execution time of our queries. The less I/O latency our queries have, the faster they execute. We can use PostgreSQL observability tools to look at the number of pages being loaded.

How do we do that? To do that, we’ll use the `BUFFERS` parameter with `EXPLAIN`.

The full command is one we’d run from a SQL client like psql, as `EXPLAIN (ANALYZE, BUFFERS) <query>` replacing "\<query\>" with the SQL query.

Besides the quantity of pages, PostgreSQL shows us whether the buffers were from the buffer cache or not. The buffers are 8kb in size by default. PostgreSQL will show us whether 1 or 1000 buffers were accessed, and we can multiply that figure by the page size to determine how much data is being accessed.

Converting the pages into megabytes helps make it a more familiar measurement unit. For example, by accessing 10,000 pages at an 8kb page size, we're accessing 80MB of data. If our disk accessed 10MB/second, that means it would take at least 8 seconds! Modern drives are much faster, but this approach helps to relate pages (or *buffers*) to storage access speed.

## 3. Ordering Topics
Developers had questions about different topics related to ordering queries and columns in indexes.

Databases work well with ordered data when its accessed, stored, and for query planning. As developers, we can benefit by providing ordered data in queries and indexes.

An audience member pointed out ordering columns in their indexes. Indeed, when we add columns to a B-Tree index, columns are ordered ascending by default. What if the query wants that column in descending (`DESC`) order?

We may want to set the column order in descending order in the index definition. Here’s an example:

```sql
CREATE INDEX ON trips (completed_at DESC);
```

Another concept related to ordering unrelated to index design or query design is using positional arguments.

When writing SQL queries and using `ORDER BY`, we can use positional arguments to refer to a column in the `SELECT` clause based on the position starting from 1, where the column is.

For example:

```sql
SELECT id, first_name
FROM users
ORDER BY 2;
```

Here the query orders results by `first_name`, which appeared in the "2" position in the `SELECT` clause.

## 4. Enumerating Columns vs. SELECT *
Active Record added a setting that [enumerates all columns](https://www.bigbinary.com/blog/rails-7-adds-setting-for-enumerating-columns-in-select-statements) in newer versions of Ruby on Rails.

Why do we care about this? Well, having a narrow and explicit set of columns is important. Why?

When relying on `SELECT *`, which is the default in Active Record, meaning all columns are accessed.

If we wished to provide an explicit list of columns, we can do that in Active Record using the `.select()` or `pluck()` methods with explicit column names.

For example, `select(:id, :name)` would generate a SQL `SELECT` clause like `SELECT id, name`.

The reason we care about this is it helps increase the chances for an efficient "index only scan."

To achieve that, our query must specify a set of columns that exactly match the set of columns in a multicolumn or covering index.

Besides the possibility of index only scans, when we rely on `SELECT *`, the columns could be anything from tiny 2-byte `SMALLINT` columns up to 1GB of data stored in a JSONB column as "large texts" (or a text column).

The problem there is we're again pulling a lot of data, adding I/O latency to our query.

When columns aren't needed by the client, then we’re unnecessarily slowing down our queries.

This setting increases our chances of spotting unnecessary columns, where we can use `select()` and `pluck()` to reduce the columns being accessed.

## 5. Using PostgreSQL For More Types of Work
At lunch we discussed why Redis was always the "default" choice in Rails over the last decade for things like cache stores, session stores, or background jobs (Sidekiq).

What’s changed a lot in the last decade is that random access on SSDs has become far faster compared with the spinning ("rotational media") hard disk drives from 10 years ago. SSDs are now cost effective and with big capacities.

This helps a ton for databases, where we’re frequently accessing random data!

What is the relevancy of this to PostgreSQL? Well, PostgreSQL can probably be used for more work than you realize, where you might have brought in Redis before.

Besides physical storage getting faster, PostgreSQL versions have increased performance for building indexes (e.g. de-duplication), [query planning optimizations](https://www.citusdata.com/blog/2024/02/08/whats-new-in-postgres-16-query-planner-optimizer/), and parallel query execution.

A misconception developers may have is that PostgreSQL is doing disk-level operations all the time, when in fact many operations that write and read data are being performed in memory flushed (slower) to disk.

That being said, when we’re optimizing writes or reads, we may exploit different mechanisms to get the best performance.

For SSDs (the NVMe type), we want them to be locally-attached, not network-attached, to avoid network latency affecting our write and read operations. With locally attached NVMe SSD drives on modern hardware, PostgreSQL is a good choice for what you may have used Redis for before, like a general purpose cache store, small transient job data, message queue data, session stores, etc.

We explore less common uses for PostgreSQL in the last chapter "Advanced Uses" of [High Performance PostgreSQL for Rails](https://pragprog.com/titles/aapsql/high-performance-postgresql-for-rails/), inspired by [Just Use Postgres](https://www.amazingcto.com/postgres-for-everything/).

## Wrapping Up
I hope this list of the Top 5 PostgreSQL Topics from Rails developers was interesting and useful for you!

Remember that if you use PostgreSQL, there are many powerful capabilities you may not be using. There are also lots of ways to inspect the running operations, getting valuable insights you can use to improve performance and scalability.

If these topics interest you and you’d like to learn more, please consider buying my book [High Performance PostgreSQL for Rails](https://pragprog.com/titles/aapsql/high-performance-postgresql-for-rails/).

Thanks for reading!
