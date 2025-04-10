---
layout: post
title: "Bulk Inserts, RETURNING, and UNLOGGED Tables"
tags: [PostgreSQL, Databases, Tips]
date: 2021-09-29
comments: true
---

By using [`UNLOGGED`](https://www.postgresql.org/docs/current/sql-createtable.html) tables, we can insert rows at a higher rate when compared with a logged table (the default). But there's a trade-off.

Activity for regular logged tables receives all changes from the Write-Ahead Log (WAL). `UNLOGGED` tables do not use the WAL, which means there is the possibility of data loss for these tables if PostgreSQL unexpectedly restarts.

The post [How to test UNLOGGED tables for performance in PostgreSQL](https://www.enterprisedb.com/postgres-tutorials/how-test-unlogged-tables-performance-postgresql) shows how an `UNLOGGED` table can be truncated during a shut down.

Using an Unlogged table for primary data that's not stored elsewhere, is not recommended. However, for secondary data that can be re-created, crash protection is worth losing because of the improved write speed.

What does that look like?

## `RETURNING` Clause
Before jumping into that, let's look at the RETURNING clause, to put together an example with an unlogged table.

The [`RETURNING` clause](https://www.postgresql.org/docs/current/dml-returning.html) returns an explicit list of field data following an Insert, Update, or Delete, or all fields using `RETURNING *`.

Let's test this out. You'll explore the `UNLOGGED` keyword, `RETURNING *` clause, and populate 10 million rows into a table.

Create a table called `tbl` that has a single integer column, then use the `GENERATE_SERIES()` function to help populate values.

Run the SQL below to load a regular logged table with 10 million items. You should see it taking around 10 seconds (tested on a M1 Macbook Air).

```sql
\timing -- toggle timing so that it's enabled
CREATE SCHEMA IF NOT EXISTS temp;
CREATE TABLE IF NOT EXISTS temp.tbl (col INTEGER);
INSERT INTO temp.tbl (col) VALUES (GENERATE_SERIES(1,10000000));
```

What about Unlogged tables?

Try dropping the current table, creating a new one as unlogged, and performing the same load of 10 million items.

```sql
DROP TABLE temp.tbl;
CREATE UNLOGGED TABLE temp.tbl (col INTEGER);
INSERT INTO temp.tbl (col) VALUES (GENERATE_SERIES(1,10000000));
```

This ran considerably faster, completing in under 2 seconds.

## Inserting In Bulk
We know that inserting multiple rows at once is faster compared with single row Inserts, because there isn't a transaction per insert.

Using these techniques, we could design a system to store rows in an `UNLOGGED` table as a staging area, then move them to a logged table as bulk Insert statements at some point later.

To avoid the rows being in two places at once, we'll delete them from the `UNLOGGED` table and use `RETURNING *` to gather all the field data, then insert that field data as new rows effectively moving a row from one table to the other.

This is a "transactional copy" since the statement runs as an implicit transaction, and if it failed, the row would only be in one table.

Try running the following statements:

```sql
-- Use existing temp.tbl loaded with 10 million rows

-- Create normal logged table
CREATE TABLE IF NOT EXISTS temp.logged_tbl (col INTEGER);

-- Copy the rows over
WITH deleted AS (
  DELETE from temp.tbl
  RETURNING *
)
INSERT INTO temp.logged_tbl (col)
SELECT * FROM deleted;

-- temp.logged_tbl should now have all 10 million rows,
-- and temp.tbl should be empty
```

The statement moves all 10 million rows from the `UNLOGGED` table to the logged table in a single statement, taking around 15 seconds.

This could be done in batches of rows at a time by using ranges of values, or a LIMIT clause.

The purpose here was to show the basics of performing higher speed copies or moves of data between tables.

## Summary
In this post we covered `UNLOGGED` tables, the `RETURNING ` clause, and how to use a transactional copying bulk insert operation.
