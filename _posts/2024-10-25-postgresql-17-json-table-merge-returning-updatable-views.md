---
layout: post
permalink: /postgresql-17-json-table-merge-returning-updatable-views
title: 'PostgreSQL 17: JSON_TABLE(), MERGE with RETURNING, and Updatable Views'
tags: []
comments: true
hidden: true
date: 2024-10-16
---

PostgreSQL 17 released a few weeks ago! As a mature database system with decades of innovation, new features are usually scoped narrowly, given reliability, stability, and backwards compatibility takes priority in Postgres, a good thing!

That means even promising enhancements like [Splitting and Merging Partitions](/blog/2024/04/16/postgresql-17-merge-split-partitions) will be reverted during the development cycle when the core team feels a new feature isn't ready.

The [Postgres 17 release notes](https://www.postgresql.org/docs/release/17.0/) cover a lot of small items worth taking a look at.

This post picks out three, and provides some commands that can be copied and pasted into a Postgres 17 instance.

Let's dive in!

## PostgreSQL 17 via Docker
To easily try out PostgreSQL 17, let's use Docker.
```sh
docker pull postgres:17

docker run --name my-postgres-container -e POSTGRES_PASSWORD=mysecretpassword -d postgres:17

docker exec -it my-postgres-container psql -U postgres
```

As an aside: for macOS, if you're interested in using [pg_upgrade](https://www.postgresql.org/docs/current/pgupgrade.html), please see the post [in-place upgrade from Postgres 14 to 15](https://andyatkinson.com/blog/2022/12/12/upgrading-postgresql-15-mac-os) as an example upgrade.

We'll assume you're now connected to a 17 instance and ready to try out these commands.

## SQL/JSON and JSON_TABLE
Postgres supports SQL/JSON, which is like a selector style expressional language, that provides methods to extract data from JSON formatted text.

> SQL/JSON path expressions specify item(s) to be retrieved from a JSON value, similarly to XPath expressions used for access to XML content.

I didn't write much XPath in the past, but the SQL/JSON syntax did remind me of writing CSS selectors.

When we combine SQL/JSON expressions with a new function JSON_TABLE(), we can do powerful transformations of JSON text data into query results that match what you'd get from a traditional table.

Let's take a look at an example!

Each of these examples will be on this [PostgreSQL 17 branch of my pg_scripts](https://github.com/andyatkinson/pg_scripts/pull/9) repo.

Create a table "books" and insert a row into it. We can use the default database here. Mainly we just want to be on 17 so that these functions are available.

The books table has a "data" column using the "jsonb" data type.

Create the table:
```sql
CREATE TABLE IF NOT EXISTS books (
    id integer NOT NULL,
    name varchar NOT NULL,
    data jsonb
);
```

Use the `json_build_object()` function to prepare JSON compatible attribute data for storage.

Insert a data row with json data:
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

Now comes the cool part. Use the new `JSON_TABLE` function as shown below to pull out the publisher, isbn, and author info from within the JSON stored in the data column.
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

The query result shows the attributes as if they were traditional columns in a regular table, even though they were stored within a jsonb field. Nice!
```sql
 id |      isbn      |                    publisher                     |     author
 ----+----------------+--------------------------------------------------+-----------------
   1 | 979-8888650387 | Pragmatic Bookshelf; 1st edition (July 23, 2024) | Andrew Atkinson
```

Read more about JSON_TABLE:
- <https://medium.com/@atarax/finally-json-table-is-here-postgres-17-a9b5245649bd>

There's even more JSON related functionality in the [PostgreSQL 17 Release Notes](https://www.postgresql.org/docs/release/17.0/), like  SQL/JSON constructors (JSON, JSON_SCALAR, JSON_SERIALIZE) and query functions (JSON_EXISTS, JSON_QUERY, JSON_VALUE).

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

`MERGE` gained support for the `RETURNING` clause in PostgreSQL 17. What's the `RETURNING` clause?

The `RETURNING` clause provides one or more fields in the result of DML statements: INSERT, UPDATE, DELETE, and now MERGE. These are all Data Manipulation Language (DML) statements.

`RETURNING` is helpful because it avoids the need for a second query to get back the inserted or updated values.

MERGE helps make upsert operations more declarative, and is based on a SQL standard with implementations in other database systems.

## MERGE with RETURNING
Let's try out MERGE first without `RETURNING`:
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
RETURNING *; -- <<<<<RETURNING CLAUSE HERE, returning all fields with "*"

 id | name | id | name
----+------+----+------
  1 | Andy |  1 | Andy
(1 row)
```

## Database Views and Materialized Views
Database views gained some enhancements in Postgres 17.

Let's briefly recap database views. There are two types: regular views and materialized views.

Regular views encapsulate a SQL query. The view definition becomes the queried item, instead of an underlying table.

When a view is queried, the underlying SQL query in the view definition runs, meaning there's no storage of results internally and thus no performance benefit for repeated access.

Materialized views are different. When they're called, they store their results. We'll focus on regular views though for this section.

Besides being defined and queried via SELECT, views can be "updated" (using an UPDATE statement). What does that mean?

Simple views are automatically updatable: the system will allow INSERT, UPDATE, DELETE, and MERGE statements to be used on the view in the same way as on a regular table.

Let's create an employees table where some employees are "admins" but most aren't. Admins can access all employee rows, while non-admins can access only non-admins.
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

What's new? Besides being updatable by INSERT, UPDATE, or DELETE, views can also be updated by triggers.

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

Run it:
```
SELECT * FROM non_admins;
```

Finally, we can run an `UPDATE` on non-admins (updating the view), and verify that the trigger calls the function, updating the underlying "employees" table.

We can even add on the `RETURNING` clause to see the result. After this update, querying non_admins no longer includes the user below, since it was updated to be an admin.
```sql
UPDATE non_admins SET is_admin = true where id = 2 RETURNING *;
```

That wraps up the hands-on items. What are some other noteworthy enhancements?

## Performance Improvements for IN clauses
A big one that's practical for Ruby on Rails apps, is internal improvements that will reduce latency for queries that use an `IN` clause, and a large list of values.

Internally, the Postgres core team was able to eliminate repeated scans, which has the effect of reducing query processing latency, improving performance.

The cool thing about this one is that no code changes are required for Postgres users.

Check out these blog posts:
- <https://dev.to/lifen/as-rails-developers-why-we-are-excited-about-postgresql-17-27nj>
- <https://www.crunchydata.com/blog/real-world-performance-gains-with-postgres-17-btree-bulk-scans>

## Lower memory consumption for VACUUM
The release notes state that PostgreSQL 17 introduces a new internal memory structure for vacuum that consumes up to 20x less memory.

This is great as it makes more server instance memory available for other operations.

## Resources
- [Postgres.fm PostgreSQL 17 episode](https://postgres.fm/episodes/postgres-17)
