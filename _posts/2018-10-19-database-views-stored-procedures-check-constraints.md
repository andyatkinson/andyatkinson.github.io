---
layout: post
title: "Views, Stored Procedures, and Check Constraints"
date: 2018-10-19
comments: true
tags: [PostgreSQL, SQL, Databases, Tips]
---

This post will take a quick look at views, stored procedures, and check constraints in PostgreSQL. What are they and what are their use cases?

## Database Views

A database view is kind of a virtual table based on a `SELECT` query. How are they used? One use case would be for security, limiting access to a table for a particular user to read only access or to a subset of the rows.

This would be achieved by creating a view and then granting permission to the view for that user (role).

## Basic View Example

We'll put together a table "earnings" in a temp schema for storing earnings by hour. Each record belongs to an employee.

Insert some records with `employee_id` values between 1 and 5. We'll call the employees with IDs of 3 or less "special". [Views are currently read only](https://www.postgresql.org/docs/9.2/static/sql-createview.html).

```sql
CREATE SCHEMA IF NOT EXISTS temp;
CREATE TABLE temp.earnings (employee_id INTEGER, hour TIMESTAMPTZ, total INTEGER);

INSERT INTO temp.earnings (employee_id, hour, total) VALUES (1, date_trunc('hour', now()), 10);
INSERT INTO temp.earnings (employee_id, hour, total) VALUES (1, date_trunc('hour', now() + INTERVAL '1 hour'), 10);
INSERT INTO temp.earnings (employee_id, hour, total) VALUES (2, date_trunc('hour', now() + INTERVAL '2 hours'), 10);
```

Now create the view. The view will be called `special_employee_earnings` and limits access to earnings only to employee_id = 1;

```sql
CREATE VIEW temp.limited_earnings AS SELECT * from temp.earnings WHERE employee_id = 1;
```

Run the query `SELECT * FROM temp.limited_earnings;` taking note that the rows with employee_id = 2 are not included in the results.


## Stored Procedures

> "The stored procedures define functions for creating triggers or custom aggregate functions."

Why store logic in the database? One advantage is re-use across client applications.

Stored Procedures are called Functions (or Procedures) in PostgreSQL and they can be written in SQL or a procedural language.

## Check constraints

Check constraints are one of the constraint types supported in PostgreSQL. They are a way to constraint the allowed types of data characteristics for a field.

The following CREATE TABLE example is from the PostgreSQL documentation. The statement creates a table and adds a Check Constraint as part of the definition of the table.

The constraint is applied to the price field and makes sure that it's greater than zero.

```sql
CREATE TABLE IF NOT EXISTS temp.products (
  price NUMERIC CHECK (price > 0)
);
```

Try Inserting a row that violates the constraint, with a price that's less than zero.

```sql
INSERT INTO temp.products (price) VALUES (-1);
```

The following error is printed.

```sql
ERROR:  new row for relation "products" violates check constraint "products_price_check"
DETAIL:  Failing row contains (-1).
```

## Summary

This post took a very quick look at the following concepts.

- Database Views
- Stored Procedures (Functions)
- Check Constraints

