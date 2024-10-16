---
layout: post
permalink: /postgresql-17-json-table-merge-returning-updatable-views
title: 'PostgreSQL 17: JSON_TABLE(), MERGE with RETURNING, and Updatable Views'
tags: []
comments: true
hidden: true
date: 2024-10-15
---

PostgreSQL 17 released a few weeks ago! As a mature database system with decades of innovation, bear in mind that new features must defer to reliability and backwards compatibility despite how cool they are.

Even promising enhancements like Splitting and Merging Partitions (previous blog post) will be reverted when the core team identifies issues.

With that in mind, the release notes still describe lots of small things to take a look at, some of which you may be able to put into practice in SQL you write going forward.

Let's dive in!

## Running PostgreSQL 17
To try out PostgreSQL 17, we can grab an instance via Docker.

```sh
docker pull postgres:17

docker run --name my-postgres-container -e POSTGRES_PASSWORD=mysecretpassword -d postgres:17

docker exec -it my-postgres-container psql -U postgres
```

Alternatively, if you're on macOS and prefer to use the built-in [pg_upgrade](https://www.postgresql.org/docs/current/pgupgrade.html) tool, please see a past post walking through an [in-place upgrade from Postgres 14 to 15](https://andyatkinson.com/blog/2022/12/12/upgrading-postgresql-15-mac-os).

If you're on macOS, note that Homebrew is still providing Postgres 14 as of this writing. For new installations I recommend [Postgres.app](https://postgresapp.com), which was updated and provides 17.

Whether you've upgraded your local instance, or are running 17 via Docker, we'll assume you've connected to a 17 instance and are ready to test these new capabilities.

### SQL/JSON and JSON_TABLE
Postgres supports SQL/JSON, which is like an selector style expressional language, that provides methods to extract data from JSON formatted text.

> SQL/JSON path expressions specify item(s) to be retrieved from a JSON value, similarly to XPath expressions used for access to XML content.

I didn't write much XPath, but I did write CSS selectors back in my full-stack developer era, and SQL/JSON reminds of that a bit.

When we combine SQL/JSON expressions with a new function JSON_TABLE(), we can do powerful transformations of JSON text data into query results that match what you'd get from a traditional table.

Let's take a look at an example!

Each of these examples will be on this [PostgreSQL 17 branch of my pg_scripts](https://github.com/andyatkinson/pg_scripts/pull/9) repo.

Let's create a table called "books" and insert some books into it. We'll have a "data" column with the jsonb data type. We'll use the `json_build_object()` function to more easily prepare JSON compatible attribute data for storage.

Create the table:
```sql
CREATE TABLE IF NOT EXISTS books (
    id integer NOT NULL,
    name varchar NOT NULL,
    data jsonb
);
```

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

Now comes the cool part. We can use the `JSON_TABLE` function as below to pull out the publisher, isbn, and author info, and when structured in this way, the result appears as if this row came from a regular table.
```sql
SELECT
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

- <https://medium.com/@atarax/finally-json-table-is-here-postgres-17-a9b5245649bd>


The release notes describe even more:

"There's more support for SQL/JSON constructors (JSON, JSON_SCALAR, JSON_SERIALIZE) and query functions (JSON_EXISTS, JSON_QUERY, JSON_VALUE), giving developers other ways of interfacing with their JSON data."


## MERGE with RETURNING

Let's make two tables, people and employees.
```sql
-- MERGE in Postgres 15
create table people (id int, name text);
create table employees (id int, name text);
```

Insert a person:
```sql
insert into people (id, name) VALUES (1, 'Andy');
```

Now we can use the MERGE keyword for an "Upsert" operation. MERGE was added in PostgreSQL 15 but enhanced in 17. What was added?

MERGE gained support for the RETURNING clause. What's that? The RETURNING clause provides one or more fields back from the INSERT or UPDATE that was performed.

This is helpful because it saves having to run a second query to get back the values. MERGE can keep the code clean for Upserts when you aren't sure what data exists.

```sql
MERGE INTO employees e
USING people p
ON e.id = p.id
WHEN MATCHED THEN
    UPDATE SET name = p.name
WHEN NOT MATCHED THEN
    INSERT (id, name)
    VALUES (p.id, p.name)
;
-- RETURNING *; 

--  id | name | id | name
-- ----+------+----+------
--   1 | Andy |  1 | Andy
-- (1 row)
```


## Updatable Views
Let's briefly recap database views. There are two types: regular views and materialized views.

Regular views encapsulate a SQL query. The view becomes the query interface, then the SQL query within the view is executed. Since the query within the view definition is executed, there's no performance advantage to database views.

They do have security benefits though which we'll cover. The other type, materialized views, execute the query when they're defined and store the result. The result is stored until the materialized view is refreshed. Materialized views are super cool, but we'll stick with regular views here.

Regular views can be "updated" which is interesting. What does that mean? Well, besides being able to SELECT from a view, we can issue an UPDATE statement for a view, even though it's not a real table.

Simple views are automatically updatable: the system will allow INSERT, UPDATE, DELETE, and MERGE statements to be used on the view in the same way as on a regular table.

- Security barrier
- Leak proof
- Security invoker
- Recursive view using union

## Performance Improvements for IN clauses

Internal performance improvement for queries with an IN list of values, no changes needed

- <https://dev.to/lifen/as-rails-developers-why-we-are-excited-about-postgresql-17-27nj>
- <https://www.crunchydata.com/blog/real-world-performance-gains-with-postgres-17-btree-bulk-scans>

## Better Autovacuum
PostgreSQL 17 introduces a new internal memory structure for vacuum that consumes up to 20x less memory.

## BRIN indexes parallel builds

## Resources
- [Postgres.fm PostgreSQL 17 episode](https://postgres.fm/episodes/postgres-17)
