---
layout: post
title: "Top Five PostgreSQL Surprises from Rails Devs"
tags: [PostgreSQL, Ruby on Rails]
date: 2024-05-28
comments: true
---
At [Sin City Ruby 2024](/blog/2024/03/25/sin-city-ruby-2024) earlier this year, I presented a series of advanced PostgreSQL topics to Rails programmers. Afterwards, a number of people provided feedback on surprising or interesting things from the presentation.

Let's cover the top five items in no particular order.

1. *Covering indexes* and how to use them
1. PostgreSQL data storage in pages and the relationship to query performance
1. Topics related to storing and accessing ordered data
1. Why `SELECT *` is not optimal, and how to enumerate all table columns in queries to help spot opportunities to reduce the columns
1. Using PostgreSQL for more types of work

## 1. Covering Indexes
[Covering indexes](https://www.postgresql.org/docs/current/indexes-index-only-scans.html) add column data from two or more columns, supporting one or more queries. Having the column data predefined in an index can significantly reduce the query cost. PostgreSQL describes a covering index as:

> An index specifically designed to include the columns needed by a particular type of query that you run frequently.

In PostgreSQL we can create covering indexes using [multicolumn indexes](https://www.postgresql.org/docs/current/indexes-multicolumn.html). Multicolumn indexes cover all of the columns needed for a query, meaning PostgreSQL could use an efficient index-only scan accessing the data using only the index.

From PostgreSQL 12, we gained an additional option to create covering indexes by using the `INCLUDE` keyword. How do we do that?

The idea for `INCLUDE` is to list columns that aren't being filtered on, but are requested in the `SELECT` clause. Let's look at an example.

Here is the covering index definition I showed in the presentation, supporting a query for the [Rideshare](https://github.com/andyatkinson/rideshare) database, the example app from the book [High Performance PostgreSQL for Rails](https://pragprog.com/titles/aapsql/high-performance-postgresql-for-rails/):

```sql
CREATE INDEX idx_trips_driv_rat_completed_cov_part
ON trips (driver_id)
INCLUDE (rating)
WHERE completed_at IS NOT NULL;
```

This index supports a query that filters on the `driver_id` column. The Rideshare query also performs an aggregation (an `AVG()`) on the rating column.

The `rating` column is not used for filtering, but is needed in the `SELECT` clause. The index uses `INCLUDE` then specifies `rating`, making it a payload column, and making this index usable as a covering index.

Besides being a covering index, this index also uses a `WHERE` clause that limits the rows that are included, making it a [partial index](https://www.postgresql.org/docs/current/indexes-partial.html).

How does that work? The index definition selects rows with their `completed_at` timestamp set, in other words, the *completed* trips. This reduces the total set of rows that need to be processed.

Besides benefitting read performance with a smaller index that's faster to access, the partial index reduces write latency by limiting the rows that need to be maintained as index entries.

There you have it. We've used a covering, partial index to support our query. These types of specialized indexes combine multiple tactics to minimize write and read latency, allowing the planner to choose efficient index scans and index-only scans.

## 2. Viewing Pages Accessed
Pages (or buffers) are storage concepts related to how PostgreSQL stores table and index data within fixed size units on disk. Understanding pages and buffers is a critical part of reducing the latency for our queries.

As users, we think of table rows as data. Within PostgreSQL, data rows are stored in fixed size units called pages. When we access even a single row of data, PostgreSQL loads the whole page where that row is stored. When rows exist in different pages, PostgreSQL needs to load all of the pages for all of the rows that the query needs.

Loading pages of data from the file system contributes to the latency of our queries. The less I/O latency our queries have, the faster they execute.

You might have guessed it, but our goal then is to understand how many pages are being accessed, and see if we can make query or index changes so that fewer pages are accessed.

How do we find the number of pages accessed? We can do that by exploring how our query is planned, using the `BUFFERS` parameter with `EXPLAIN`.

To try that out, use a SQL client like psql and run `EXPLAIN (ANALYZE, BUFFERS) <query>` replacing "<query>" with your SQL query. The `BUFFERS` parameter shows the number of buffers (or pages) accessed and where they are coming from. Buffers can be accessed from an internal memory buffer cache, or outside of it.

Buffers are 8kb in size by default. How do we translate this into a more familiar unit for disk drives like megabytes per second? To calculate that, we can multiply the number of buffers by the 8kb page size. Technically it's not precisely kilobytes, but we can use kilobytes and megabytes for a very close approximation.

Interpreting the number of pages accessed as " megabytes moved" makes the data movement a little more tangible, especially if we know the MB/s speeds of our hard drives or SSDs.

For example, for a query that accesses 10,000 pages, using an 8kb page size, we known  approximately 80MB of data is being accessed or "moved." To keep things simple, imagine our disk access speed is 10MB/second. This means it would be at least 8 seconds to access the data for our query.

Fortunately modern drives are much faster than 10MB/second. However, the takeaway here is to translate pages accessed into megabytes/second, to help understand storage access latency. Remember that we want to access as few pages as possible!

Learn more about inspecting pages in ['Rows Removed By Filter', Inspecting Pages, Buffer Cache — Part Two](http://andyatkinson.com/blog/2024/03/05/PostgreSQL-rows-removed-by-filter-part-2).

## 3. Ordering Topics
Databases work better when data is stored and accessed with a sort order, and when the orderings match. It's beneficial to use data types that support ordering like integers and characters.

An audience member asked about setting a column order in indexes. A B-Tree index in PostgreSQL orders the column data in ascending order by default. However, we can flip this, which can help when columns want data in descending (`DESC`) order.

To do that, we might create an index that sets descending order for the `completed_at` column like below.

```sql
CREATE INDEX ON trips (completed_at DESC);
```

Another concept related to order, but for writing SQL queries, is using positional arguments.

For SQL queries with an `ORDER BY` clause, we can use positional arguments to refer to the column in the `SELECT` clause by its position rather than its name. The first position is 1 (not 0). Let's consider the example below.

```sql
SELECT id, first_name
FROM users
ORDER BY 2;
```

The query above lists `id` then `first_name` in the `SELECT` clause. The `first_name` column appears in position "2." Instead of referencing the column in the `ORDER BY` clause by name, we used the position.


## 4. Enumerating Columns vs. SELECT *
Active Record added a setting called `enumerate_columns_in_select_statements` that lists out all columns by default instead of using a `SELECT *`.

For better query performance, having an explicit and narrow set of columns is ideal.

To create an explicit list of columns in Active Record, we can use the `.select()` or `pluck()` methods. For example, `select(:id, :name)` generates `SELECT id, name`.

With just two columns needed, we can index id and name, creating an index PostgreSQL can use for an index-only scan.

Imagine we knew only id and name columns were needed, but since `SELECT *` was used, we missed the opportunity to restrict the columns and design a supporting index. This new setting might help us spot those opportunities.

Another reason to use this setting is to help spot places where large columns are accessed unnecessarily. When we rely on `SELECT *` we could be pulling tiny 2-byte `SMALLINT` columns up to 1GB of text stored in `jsonb` or `text` columns.

By using `enumerate_columns_in_select_statements`, we are increasing our chances of spotting columns that aren't needed, then adding those restrictions using `select()` and `pluck()`.

## 5. Using PostgreSQL For More Types of Work
At a lunch group, we discussed why Redis has been the default choice in Rails over the last decade for things like cache stores, session stores, and background jobs (Sidekiq). Mostly it's due to the in-memory storage speed benefits.

On modern hardware combined with advancements in PostgreSQL itself, it might be worth reconsidering this default choice and using PostgreSQL for more types of work.

In the last decade, random access speed for SSDs has become much faster compared with spinning (rotational media) hard disk drives from ten years ago. Locally attached NVMe SSDs are now cost-effective and offer large capacities.

Fast storage is a great fit for databases, where we're frequently accessing random data!

Besides physical storage getting faster, PostgreSQL itself has maintained and increased performance for things like building indexes (deduplication), added query planning optimizations, and parallel query execution. These enhancements add up to better performance that you get by upgrading your PostgreSQL major version.

A common misconception is that PostgreSQL is always performing slower disk-level operations compared with faster in-memory operations.

In fact, many operations in PostgreSQL that write and read data are performed in memory.  Since disk operations are costly, they're deferred and minimized. For in-memory reads, this might mean designing indexes and having enough available memory so that queries use index only scans for indexes that fit in memory. For write operations, take a look into the details of the `CHECKPOINT` process and how it minimizes disk access.

Modern NVMe SSDs that are locally-attached - not network-attached - avoid network latency and offer fast write and read access, including sequential and random access.

With locally attached NVMe SSD drives and big memory, PostgreSQL may be worth a look in place of work you'd normally perform using Redis.

Having a less complex tech stack of tools can help your team move faster with less complexity.

For more information about less common uses for PostgreSQL, explore the last chapter of High Performance PostgreSQL for Rails, "Advanced Uses," inspired by [*Just Use Postgres*](https://www.amazingcto.com/postgres-for-everything/).

## Wrapping Up
I hope this list of the top five surprising and interesting things about PostgreSQL from Rails developers was useful for you!

Remember that if you use PostgreSQL, a powerful and extensible open source database, there are many advanced capabilities to explore within the core software and in the extensions ecosystem.

If these topics interest you and you'd like to learn more, please consider buying my book [High Performance PostgreSQL for Rails](https://pragprog.com/titles/aapsql/high-performance-postgresql-for-rails/).

Thanks for reading!

Also published at [Top Five PostgreSQL Surprises from Rails Developers](https://medium.com/pragmatic-programmers/top-five-postgresql-surprises-from-rails-developers-36d2b8734909) on the Pragmatic Programmers blog on Medium.
