---
layout: post
title: "Bulk Inserts, Returning, and Unlogged Tables"
tags: [PostgreSQL, Databases, Tips]
date: 2021-09-29
comments: true
---

By using [unlogged](https://www.postgresql.org/docs/12/sql-createtable.html) tables we can insert rows at a higher rate compared with a normal table. But there is a trade-off.

Activity for normal tables is logged to the write-ahead log (WAL). Creating a table as `unlogged` and skipping the WAL process means rows can generally be inserted at a higher rate, but with the possibility of data loss if the database crashes or shuts down without a full shutdown.

In the article [How to test unlogged tables for performance in PostgreSQL](https://www.enterprisedb.com/postgres-tutorials/how-test-unlogged-tables-performance-postgresql) they demonstrate how the database can be shutdown and truncate an unlogged table.

Unlogged tables are normal tables, but with an `UNLOGGED` option supplied at creation time.

#### Returning data from a query

The [`returning` clause](https://www.postgresql.org/docs/9.5/dml-returning.html) will return the selected rows from a query, all fields with `returning *`, whether it's an update or in this case a `DELETE` query.

So combining unlogged tables, `returning *`, with the intention of inserting items in bulk, we can insert 10 million rows in a single statement as follows below.

#### Benchmarks

How about a simple benchmark?

Let's create a links table that has a url and name but just use numbers with `generate_series` as the values.

Creating a normal logged table like this and inserting 10 million items takes around 33 seconds on my laptop.

```
CREATE table links (url VARCHAR(255), name VARCHAR(255));

INSERT INTO links (url, name) VALUES (generate_series(1,10000000), 1);
INSERT 0 10000000
Time: 32998.938 ms (00:32.999)
```

Now let's do the same thing with an unlogged table. After trying this a few times, it's around 2x faster to insert the same amount of items this way.

```
CREATE UNLOGGED table unlogged_links (id serial, url VARCHAR(255), name VARCHAR(255));

INSERT INTO unlogged_links (url, name) VALUES (generate_series(1,10000000), 1);
INSERT 0 10000000
Time: 18566.592 ms (00:18.567)
```

So we can reproduce the insert rate benefits in a simple table, at least one with no auto incrementing primary key or any indexes.

How about the bulk insert?


#### Inserting in bulk

We know that inserting multiple rows at once is faster than inserting single rows because we are saving the overhead of a transaction per insert.

However if we plan to insert in bulk, we need an intermediate place to store the items. We can use the unlogged table.

We could store the rows in the unlogged table and then periodically flush them all of them out in a bulk insert.

In order to avoid the rows existing in both places, we can delete from the unlogged table and use `returning *` to access the row contents.

So the process could look like this.


```
WITH deleted AS (
  DELETE from unlogged_links
  RETURNING *
  )
INSERT into links (url, name)  SELECT url, name from deleted;
```

Running this, we can actually insert all 10 million rows from the unlogged table into the normal table in a single statement.

```
INSERT 0 10000000
Time: 67158.109 ms (01:07.158)
```

This statement ran in a little over a minute on my machine.

#### Summary

In this post we covered unlogged tables, the `returning` clause, and bulk inserts.

This strategy may not actually be useful in practice, but I thought it was interesting to learn more about unlogged tables and think about how they might be used as a temporary store.

Alternative approaches might be to temporarily store data in a non-relational database like Redis and then periodically flush it to PostgreSQL.

Also, if the requirements are to insert bulk data at the outset, using `\copy` and reading from a file will be even faster and is more common. Check out [Faster bulk loading in PostgreSQL with copy](https://www.citusdata.com/blog/2017/11/08/faster-bulk-loading-in-postgresql-with-copy/).
