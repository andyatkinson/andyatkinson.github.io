---
layout: post
title: "Top Five PostgreSQL Surprises from Rails Devs"
tags: []
date: 2024-04-13
comments: true
---
Recently at [Sin City Ruby 2024](/blog/2024/03/25/sin-city-ruby-2024), I presented some advanced PostgreSQL topics to Ruby programmers, and took note of items from feedback that were new or prompted discussions.

Let's cover those items in this post! Here are the items:

- Covering Indexes
- Data stored in pages, and viewing how many (buffers) we accessed
- Topics related to ordering in queries and indexes
- Why `SELECT *` is not optimal, and how to enumerate all columns by default
- Using PostgreSQL over others for more types of work

Let's dive into the detail for each item.

## Covering Indexes

[Covering indexes](https://www.postgresql.org/docs/current/indexes-index-only-scans.html) are an indexing strategy in PostgreSQL, that brings the data from two or more columns of data from a table, into an index, to support a query. The PostgreSQL describes a covering index as:

> an index specifically designed to include the columns needed by a particular type of query that you run frequently.

[PostgreSQL Multicolumn indexes](https://www.postgresql.org/docs/current/indexes-multicolumn.html), which are indexes that include two or more columns in their definition, can act as a covering index by providing the data needed for a query and achieving an index only scan.

From PostgreSQL 12, a new type of covering index could be created by using the `INCLUDE` keyword when defining the index. Why might we do that?

The idea would be to include columns that aren’t being filtered on, for example they’re not part of `WHERE` clause conditions, but they are included in the SELECT clause portion of your query. Let’s look at an example index. Here is one I showed in the presentation that uses the Rideshare database from the book High Performance PostgreSQL for Rails:

```sql
CREATE INDEX idx_trips_driv_rat_completed_cov_part
ON trips (driver_id)
INCLUDE (rating)
WHERE completed_at IS NOT NULL;
```

The query that uses this index "searches" (also commonly called a "filter" operation) on the `driver_id` column, but performs an aggregation (an "average") on the `rating` column. The `rating` column is listed after the `INCLUDE` keyword, and is said to be a "payload" column. Besides being a covering index, looking at the next portion which is the `WHERE` clause portion, this index is said to be a "partial" index.

A partial index covers a portion of the rows, being scoped to those rows with a `WHERE` clause that's in the index (not the query).

Here the index definition is for only the rows with their `completed_at` timestamp set, in other words, "completed" trips.

There you have it. The index above is said to be a "covering, partial index," and these types of specialized indexes can yield the best possible performance by enabling efficient index only scans.

## Viewing Pages Accessed

Pages or buffers are storage concepts that most web application developers don’t tend to know about, as they are more of an implementation detail of how PostgreSQL stores table and index data. However, it’s useful to know this when working on performance optimization, because we can get insights into the amount of data we’re accessing, and whether it’s coming from internal caches or not.

Whether PostgreSQL is accessing one row or all rows stored in a page, when fetching the data needed for a query, PostgreSQL loads pages. We can see exactly how many were loaded. Why do we care? We care because loading pages incurs I/O latency, which lengthens the execution time of our queries. The less I/O latency our queries have, the faster they execute. At times it can be beguiling where latency is coming from in a query, so we can use observability information to look at the number of pages that are loaded.

To do that, we’ll use the `BUFFERS`. We add it as an argument to `EXPLAIN`. The full command is one we’d run from a SQL client like psql, as `EXPLAIN (ANALYZE, BUFFERS) <query>` replacing "\<query\>" with the SQL query.

PostgreSQL will show us whether the buffers accessed were in the buffer cache or not. The buffers are 8kb in size by default. PostgreSQL will show us whether 1 or 1000 buffers were accessed, and we can multiply that figure by the page size, to determine how much data we’re moving, perhaps converting it into megabytes to make it a more tangible quantity. This "movement" from loading pages has a latency penalty, which lengthens the execution time of our query.

## Ordering Topics

Developers had some questions about ordering, in part because in the presentation I describe a happy accident feeding the planner an explicitly ordered query, and experiencing a plan change that was much more efficient. There are more topics under the umbrella of ordering though. Why do we care? We care because databases heavily leverage ordering concepts when data is accessed, stored, and when queries are planned, among other reasons. As developers, we can benefit from providing ordered data in queries and indexes. 
An audience member pointed out that they’d seen benefits in ordering their indexes. Indeed, when we add columns to a B-Tree index, the column will be ordered ascending by default. What if our query wants that column in descending (`DESC`) order? We may want to set the column orderiing in the index definition. Here’s an example:

```sql
CREATE INDEX ON trips (completed_at DESC);
```

This index orders the `completed_at` column in descending order, which would better support a query that can use the pre-ordered index items to support the ORDER BY operation, especially when they’re already sorted in the desired direction (otherwise a "reverse sort" happens, which is ok).
Another concept wasn’t related to index design or query design, but more of a "convenience method" for developers. When writing SQL queries and using a ORDER BY clause and the column name, we can use "position arguments" to refer to a column in the `SELECT` clause based on the position (starting from 1) where it is. 
For example:

```sql
SELECT id, first_name
FROM users
ORDER BY 2;
```

This query orders the results by `first_name`, which appeared in the "2" position in the `SELECT` clause.

## Enumerating Columns vs. `SELECT *`

Active Record added a setting to enumerate all columns in a newer version of Ruby on Rails. Why do we care about this? Well, first we need to understand the problem with not specifying columns in our results, and relying on `SELECT *`, which is the default in Active Record.
Queries are generated with `SELECT *` meaning no explicit list of columns is sent to the query planner, meaning all columns need to be accessed.

If we wished to provide an explicit list of columns, we could do that in Active Record using the `.select()` or `pluck()` methods, with arguments of each column name as a symbol.

For example, `select(:id, :name)` would generate a SQL query `SELECT` clause like `SELECT id, name`.

The reason we care about this is the aforementioned possibility of an "index only scan." An index only scan is the most efficient and fastest execution type of scan. To achieve that, our query must specify a set of columns that exactly match the set of columns in the multicolumn or covering index.
Besides that reason, when we rely on `SELECT *`, the columns could be anything from tiny 2-byte `SMALLINT` columns up to 1GB of data stored in a JSONB column as "large texts" (or a text column). PostgreSQL allows us to do this. What is the cost of this?

The cost of this is we’re again pulling a lot of data, paying an I/O latency cost for those columns. If they aren’t needed by the client, then we’re unnecessarily slowing down our queries.
How does this new setting help us? While not directly helping, it adds visibility into this problem or opportunity, depending on how you see it. By enumerating all columns by default, we’ll no longer see queries running "SELECT *", but the full list of columns being accessed, possibly unnecessarily. With that information, the developer can more easily spot opportunities where they can add "select()" and "pluck()" to scope their queries down.

## Using PostgreSQL For More Types of Work

At lunch we discussed why Redis was always the "default" choice in Rails over the last decade for things like cache stores, session stores, or background jobs with Redis (also used as a message queue). What’s changed a lot in the last decade is that random access on SSDs has become far faster compared with the spinning ("rotational media") hard disk drives from 10 and more years ago. SSDs are now cost effective and with big capacity, offering much faster I/O.

This helps a ton for databases, where we’re frequently accessing random data!

What is the relevancy of this to PostgreSQL? Well, PostgreSQL can probably be used for that work that you might have been using Redis for, without a problem.

In part due to the physical storage being faster, and in part because the internals of PostgreSQL itself have gotten faster, whether it be for building indexes, query planning, or query execution.

A misconception developers may have is that PostgreSQL is doing disk-level operations all the time, when in fact most of the time operations that write and read data are being performed in various cache layers then flushed to durable storage. That being said, when we’re optimizing writes or reads, we may exploit different mechanisms to get the best performance.

For SSDs (the NVMe type), we want them to be locally-attached, not network-attached, to avoid network latency affecting our write and read operations. With locally attached NVMe SSD drives on modern hardware, PostgreSQL is a good choice for what you may have used Redis for before, like a general purpose cache store, small transient job data, message queue data, session stores, etc. We explore what that could look like in the last chapter "Advanced Uses" of High Performance PostgreSQL for Rails.
While PostgreSQL transactions and the MVCC mechanism (outside the scope of this section) are designed for concurrency and durability, which means they do have a latency penalty, the transactional guarantees we gain, the avoidance of possibly complex and error prone synchronization, and the ability to inspect and debug using SQL and common PostgreSQL observability tools, tip the scales towards [Just Using Postgres](https://www.amazingcto.com/postgres-for-everything/).


## Wrapping Up

I hope this list of the Top 5 PostgreSQL Topics from Ruby Developers was interesting.

Remember that if you use PostgreSQL, there are many powerful capabilities built-in that you may not know about or be using.

I hope you learned something here that you can put into practice for your applications and databases.

If these topics interest you and you’d like to learn more, please consider buying my book [High Performance PostgreSQL for Rails](https://pragprog.com/titles/aapsql/high-performance-postgresql-for-rails/).
