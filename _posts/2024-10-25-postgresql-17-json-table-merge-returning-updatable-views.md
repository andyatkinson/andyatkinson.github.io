---
layout: post
permalink: /postgresql-17-json-table-merge-returning-updatable-views
title: 'PostgreSQL 17: JSON_TABLE(), MERGE with RETURNING, and Updatable Views'
tags: [PostgreSQL]
comments: true
date: 2024-10-17
---

It's time for a new Postgres release! PostgreSQL 17 shipped a few weeks ago, with lots of new features to explore.

As a mature database system, prized for reliability, stability, and backwards compatibility, new features aren't often the most splashy. However, there are still goodies that could become new tools in the toolboxes of data application builders.

The [Postgres 17 release notes](https://www.postgresql.org/docs/release/17.0/) is a good starting point, as it covers a breadth of items.

In this post, we'll pick out three items, and create some runnable examples with commands that can be copied and pasted into a Postgres 17 instance.

Let's dive in!

## PostgreSQL 17 via Docker
To easily try out PostgreSQL 17, let's use Docker.
```sh
docker pull postgres:17

docker run --name my-postgres-container -e POSTGRES_PASSWORD=mysecretpassword -d postgres:17

docker exec -it my-postgres-container psql -U postgres
```

As an aside: for macOS, if you're interested in using [pg_upgrade](https://www.postgresql.org/docs/current/pgupgrade.html), please see the post [in-place upgrade from Postgres 14 to 15](https://andyatkinson.com/blog/2022/12/12/upgrading-postgresql-15-mac-os) as an example on how to upgrade your locally installed, earlier version.

From here, we'll assume you're connected to a 17 instance, ready to run commands.

## SQL/JSON and JSON_TABLE
Postgres supports SQL/JSON, which is like a selector style expressional language that provides methods to extract data from JSON.

> SQL/JSON path expressions specify item(s) to be retrieved from a JSON value, similarly to XPath expressions used for access to XML content.

When we combine SQL/JSON expressions with a new function JSON_TABLE(), we can do powerful transformations of JSON text data into query results that match what you'd get from a traditional table.

Let's take a look at an example!

Each of these examples will be on this [PostgreSQL 17 branch of my pg_scripts](https://github.com/andyatkinson/pg_scripts/pull/9) repo.

We'll create a table "books" and insert a row into it. The books table has a "data" column with the "jsonb" data type.

Create the table:
```sql
CREATE TABLE IF NOT EXISTS books (
    id integer NOT NULL,
    name varchar NOT NULL,
    data jsonb
);
```

Use the `json_build_object()` function to prepare JSON data for storage:
```sql
INSERT INTO books (id, name, data)
    VALUES (
      1,
      'High Performance PostgreSQL for Rails',
      jsonb_build_object(
        'publisher', 'Pragmatic Bookshelf; 1st edition (July 23, 2024)',
        'isbn', '979-8888650387',
        'author','Andrew Atkinson'));
```

Now comes the cool part. Use the new `JSON_TABLE` function as shown below to pull out attribute data from the JSON.

This pulls the publisher, isbn, and author properties from within the JSON. If you've used other methods to achieve this before, this syntax hopefully looks much clearer.
```sql
SELECT
    id,
    isbn,
    publisher,
    author
FROM
    books,
    JSON_TABLE (data, '$' COLUMNS (
        publisher text PATH '$.publisher',
        isbn text PATH '$.isbn',
        author text PATH '$.author'
    )) AS jt;
```

The nice part is the query result presents these attributes as if they were traditional columns in a table.
```sql
 id |      isbn      |                    publisher                     |     author
 ----+----------------+--------------------------------------------------+-----------------
   1 | 979-8888650387 | Pragmatic Bookshelf; 1st edition (July 23, 2024) | Andrew Atkinson
```

Read more about [JSON_TABLE](https://medium.com/@atarax/finally-json-table-is-here-postgres-17-a9b5245649bd).

There's more JSON functionality mentioned in the [PostgreSQL 17 Release Notes](https://www.postgresql.org/docs/release/17.0/).

SQL/JSON constructors (JSON, JSON_SCALAR, JSON_SERIALIZE) and query functions (JSON_EXISTS, JSON_QUERY, JSON_VALUE).

What's next?

## MERGE Command Basics
Although the `MERGE` keyword was added in Postgres 15, it was enhanced in 17. Let's try it out.

Make two tables, "people" and "employees".
```sql
CREATE TABLE people (
    id int,
    name text
);

CREATE TABLE employees (
    id int,
    name text
);
```

Insert a person:
```sql
INSERT INTO people (id, name)
    VALUES (1, 'Andy');
```

We can use the `MERGE` keyword to perform an "upsert" operation, meaning data is inserted when it doesn't exist, or updated when it does.

`MERGE` gained support for the [`RETURNING` clause](https://www.postgresql.org/docs/current/dml-returning.html) in PostgreSQL 17. What's the `RETURNING` clause?

The `RETURNING` clause provides one or more fields in the result of INSERT, UPDATE, DELETE, and now MERGE statements, all classified as Data Manipulation Language (DML).

`RETURNING` avoids a SELECT query following a modification to get the inserted or updated values.

`MERGE` operations are arguably more declarative than using the `ON CONFLICT` clause, and `MERGE` is based on a SQL standard with implementations in other database systems.

## MERGE with RETURNING
Let's try out `MERGE` *without* `RETURNING`:
```sql
MERGE INTO employees e
USING people p ON e.id = p.id
WHEN MATCHED THEN
    UPDATE SET
        name = p.name
WHEN NOT MATCHED THEN
    INSERT (id, name)
        VALUES (p.id, p.name);
```

Now we can try it with `RETURNING`, and include the result:
```sql
MERGE INTO employees e
USING people p
ON e.id = p.id
WHEN MATCHED THEN
    UPDATE SET name = p.name
WHEN NOT MATCHED THEN
    INSERT (id, name)
    VALUES (p.id, p.name)
RETURNING *; -- RETURNING CLAUSE HERE, returning all fields with "*"

 id | name | id | name
----+------+----+------
  1 | Andy |  1 | Andy
(1 row)
```

## Database Views and Materialized Views
Database views gained some enhancements in Postgres 17.

There are both regular views, and materialized views. We'll focus on regular views for this section.

Besides being defined and queried using `SELECT`, views can be updated using an `UPDATE` statement.

Simple views are automatically updatable: the system will allow `INSERT`, `UPDATE`, `DELETE`, and `MERGE` statements to be used with a view.

What's new? Besides being updatable using statements, views can also now be updated indirectly by triggers.

Let's create an example.

Create an employees table where some employees are "admins" and some aren't. Non-admins can access only non-admins.
```sql
DROP TABLE IF EXISTS employees;
CREATE TABLE employees (
    id int,
    name text,
    is_admin boolean
);
INSERT INTO employees (id, name, is_admin)
    VALUES (1, 'Andy', TRUE);

INSERT INTO employees (id, name, is_admin)
    VALUES (2, 'Jane', FALSE);

INSERT INTO employees (id, name, is_admin)
    VALUES (3, 'Jared', FALSE);
```

Let's create a view for non-admins:
```sql
CREATE VIEW non_admins AS
SELECT
    *
FROM
    employees
WHERE
    is_admin = FALSE;
```

What would it look like to perform an update using a trigger?

## Trigger-Updatable Views
Let's create an `update_employee()` function that's called from a trigger.

Function:
```sql
CREATE OR REPLACE FUNCTION update_employee ()
    RETURNS TRIGGER
    AS $$
BEGIN
    UPDATE
        employees
    SET
        is_admin = NEW.is_admin
    WHERE
        id = OLD.id;
    RETURN NEW;
END;
$$
LANGUAGE plpgsql;
```

Now a trigger that calls the function:
```sql
CREATE TRIGGER trigger_update_non_admins
INSTEAD OF UPDATE ON non_admins
FOR EACH ROW
EXECUTE FUNCTION update_employee();
```

Now we can run an `UPDATE` on non-admins (updating the view), and verify that the trigger calls the function, updating the underlying "employees" table.

We can even add the `RETURNING` clause.

After this update, querying non_admins no longer includes user id=2, since they were turned into an admin via the update.
```sql
UPDATE non_admins SET is_admin = true where id = 2 RETURNING *;
```

That wraps up the hands-on items. What are some other noteworthy enhancements?

## Performance Improvements for IN clauses
A big one that's practical for Ruby on Rails apps, is internal improvements for queries with `IN` clauses and many values.

The Postgres core team was able to eliminate repeated unnecessary index scans, reducing query execution latency, and improving performance.

The cool thing about this one will be that no code changes are required, and the real-world benefits are looking promising.

Check out these blog posts for more info:
- <https://dev.to/lifen/as-rails-developers-why-we-are-excited-about-postgresql-17-27nj>
- <https://www.crunchydata.com/blog/real-world-performance-gains-with-postgres-17-btree-bulk-scans>

## Lower memory consumption for VACUUM
The release notes explain that PostgreSQL 17 uses a new internal memory structure for vacuum that consumes up to 20x less memory.

This is great because it means that there will be more server memory available for other purposes.

## Postgres.fm
For audio coverage, check out the [Postgres.fm PostgreSQL 17 episode](https://postgres.fm/episodes/postgres-17).

## Wrapping Up
Thanks for checking this out! If you spot any SQL issues, please send a [Pull Request](https://github.com/andyatkinson/pg_scripts/pull/9).
