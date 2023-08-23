---
layout: post
title: "Bulk Inserts, RETURNING, and UNLOGGED Tables"
tags: [PostgreSQL, Databases, Tips]
date: 2021-09-29
comments: true
---

By using [`UNLOGGED`](https://www.postgresql.org/docs/12/sql-createtable.html) tables we can insert rows at a higher rate compared with a normal table. But there is a trade-off.

Activity for normal tables is logged to the write-ahead log (WAL). `UNLOGGED` tables do not use the WAL which means there is the possibility of data loss in the event of an unplanned restart.

In the article [How to test UNLOGGED tables for performance in PostgreSQL](https://www.enterprisedb.com/postgres-tutorials/how-test-unlogged-tables-performance-postgresql) they demonstrate how a database could shut down and Truncate an `UNLOGGED` table.

Using an Unlogged table as a primary data store is not recommended. But what about as a secondary data store where the data is primary from another source?

### RETURNING Clause With Inserts

The [`RETURNING` clause](https://www.postgresql.org/docs/9.5/dml-returning.html) will return the specified fields or all fields with `RETURNING *`. This works for Inserts, Updates and Deletes.

In this post we'll combine `UNLOGGED` tables and `RETURNING *` populating 10 million rows to work with.

Create a table "tbl" that has a single integer column. Use `GENERATE_SERIES` to populate values.

Creating a normal table and inserting 10 million items takes around 33 seconds.

Connect to an available database but create this test table in a "temp" schema.

Run the following from psql.

```sql
\timing -- toggle timing so that it's enabled
CREATE SCHEMA IF NOT EXISTS temp;

CREATE TABLE IF NOT EXISTS temp.tbl (col INTEGER);

INSERT INTO temp.tbl (col) VALUES (GENERATE_SERIES(1,10000000));
INSERT 0 10000000
```

This took around 10 seconds.

Now try the same thing but make the table `UNLOGGED` to see if it is faster. 

```sql
DROP TABLE temp.tbl;
CREATE UNLOGGED TABLE temp.tbl (col INTEGER);

INSERT INTO temp.tbl (col) VALUES (GENERATE_SERIES(1,10000000));
```

This ran considerably faster, in around 2 seconds compared with 10 seconds.

Next we'll combine this with bulk inserts.

### Inserting In Bulk

We know that inserting multiple rows at once is faster compared with Inserts for single rows, because there isn't a transaction per insert.

We could store rows temporarily in an `UNLOGGED` table and then periodically flush them to a logged table in bulk.

In order to avoid the rows existing in both places, we'll delete them from the `UNLOGGED` table and use `RETURNING *` to access the row contents for the Insert.

The statement would look as follows.

```sql
CREATE TABLE IF NOT EXISTS temp.logged_tbl (col INTEGER);

WITH deleted AS (
  DELETE from temp.tbl
  RETURNING *
  )
INSERT into temp.logged_tbl (col) SELECT * FROM deleted;
```

The statement above inserts all 10 million rows from the `UNLOGGED` table into the logged table in a single statement, taking around 15 seconds.

### Summary

In this post we covered `UNLOGGED` tables, the `RETURNING ` clause and bulk inserts, and how these could be used together to create a staging area unlogged table that could be copied from.
