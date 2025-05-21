---
layout: post
permalink: /generating-short-alphanumeric-public-id-postgres
title: 'Big Problems From Big IN Clauses with Ruby on Rails and PostgreSQL'
---

## Introduction
If you’ve created Ruby on Rails web applications with a database before, or have used other similar frameworks ORMs, you’ve likely had the kind of problematic query pattern we’re discussing in this post.

The pattern we’re looking at is where SQL queries that IN clauses to perform some filtering, but the list of values is huge. This means there could be dozens, hundreds, or even thousands of values, filtering among a large set.

These kinds of queries can be very slow!

The technical term for the right-hand size list of values is *parenthesized list of scalar expressions*.

In the example below it's the clause `author_id IN (1,2,3)`.

Example:
```sql
SELECT * FROM books
WHERE author_id IN (1, 2, 3);
```

How does it happen?

## How does it happen?
A straightforward way is when using the `pluck` method in Active Method to select only the primary key values for a particular object.

This produces a list of values for the `id` column, typically a list of integers. The typical use is to feed the list into another query.

Here’s an example of getting author primary key ids with `pluck`:
```sql
author_ids = Author.where("created_at >= ?", 1.year.ago).pluck(:id)
```

Then they can be fed in to query books:
```sql
Book.where(author_id: author_ids)
```

Perhaps the application started out with a few authors, but has grown to thousands.

Image that even with the authors query filtering to authors created in the last year, you're still left with thousands of values.

This means the second query for books will have a big list of values for the `IN` clause, and this type of filtering has been a known class of performance problem.

Since you're in direct control of the query here, you could restructure it to filter down the authors further.

However, what about indirect instances of big IN lists coming from ORM queries. How do those happen?

## How does it happen in Active Record ORM?
One way is by using Eager loading using the `includes` or `preload` methods.

This [Crunchy Data post](https://www.crunchydata.com/blog/real-world-performance-gains-with-postgres-17-btree-bulk-scans) covers ORM methods like `includes` and `preload` that produce IN clause SQL queries.

The post links to the [Eager Loading Associations documentation](https://guides.rubyonrails.org/active_record_querying.html#eager-loading-associations) for Ruby on Rails.

Let's take a look.
```rb
books = Book.includes(:author).limit(10)

books.each do |book|
  puts book.author.last_name
end
```

```sql
SELECT books.* FROM books LIMIT 10;

SELECT authors.* FROM authors
  WHERE authors.id IN (1,2,3,4,5,6,7,8,9,10);
```

The key detail above is that the `includes(:author)` portion while possibly fixing an N+1, loading all the authors for a book instead of repeatedly querying the authors table for one row in the loop, still has downsides.

The `includes` ends up generating an IN clause SQL query . While Active Record uses an `IN()` clause here, you may also see the use of `ANY()`, which is a variation that still has the same performance challenges.

## Eager loading with eager_load
Unlike `includes` or `preload` which produce IN clause queries as a second query, `eager_load` produces a single query that uses a `LEFT OUTER JOIN`.

Examples from Active Record documentation:
```sql
books = Book.eager_load(:author).limit(10)

books.each do |book|
  puts book.author.last_name
end

SELECT "books"."id" AS t0_r0, "books"."title" AS t0_r1, ... FROM "books"
  LEFT OUTER JOIN "authors" ON "authors"."id" = "books"."author_id"
  LIMIT 10
```

Instead of `authors` being queried by their primary key “id” column using the IN clause list, query results here are picked when they match either side of the relationship, either the `authors.id` primary key column or the `books.author_id` foreign key column.

As a `LEFT OUTER JOIN`, a result row is produced whether both sides have a match or not. In this case, we could possibly use an `INNER JOIN` instead, which would only include result rows when there are matches between the primary and foreign keys. When we try this, the query results are different, they are ordered differently.

Postgres may choose a different query execution plan, which would affect the join algorithm picked, and the join order of the resulting rows. Postgres does not guarantee an ordering without an explicit `ORDER BY` clause.

When we change the query to include an IN clause and an author id value, then the ordering of the output rows becomes the same.

What are our options then to improve performance?

## Alternatives approaches by adding JOINs
Could be an inner join or outer join like above, depending on how the database is designed.

```sql
SELECT
    *
FROM
    transactions t
    JOIN organizations o ON t.organization_id = o.id
WHERE
    o.id = ('1','2','3'...); -- and so on
```

Does this result in a different query execution plan?

## Alternative approaches using ANY or SOME
Crunchy Data's post [Postgres Query Boost: Using ANY Instead of IN](https://www.crunchydata.com/blog/postgres-query-boost-using-any-instead-of-in).

A nice post showing how to bind an array of values using `ANY` instead of `IN`, which requires an equivalent sized list to the number of parameters.
<https://www.crunchydata.com/blog/postgres-query-boost-using-any-instead-of-in>

What about the query performance of ANY over IN in an equivalent scenario?

For the tested scenario the equivalent performance and query execution plans are identical. In particular, they both rely on an index only scan for the primary key index for authors, which makes sense.

IN requires only the `=` operator, and we can't use `>` or `<`, but we can with `ANY`.

Handling NULL values

Since Active Record generates IN clause queries, to generate ANY() queries while sticking with Active Record, consider using the [ActiveRecordExtended](https://github.com/GeorgeKaraszi/ActiveRecordExtended) gem.

## Query restructuring, working in smaller sets
If we're working with thousands or tens of thousands of values, we likely want to limit the set further that’s loaded. With an IN list of scalar expressions, a smaller set will provide better query performance.

We could look to restructure the query. We could write it ourselves, or use the Active Record form above that uses `eager_load` to generate a `LEFT OUTER JOIN` query.

With the outer join single query, we can then add limitations like additional filtering, or a LIMIT clause.

While this approach might perform multiple queries, by reducing the working set, we can improve performance for each iteration and even try to keep it consistent in resource usage.

Join clause with `=` or `IN` (equivalent here):
```sql
SELECT
    *
FROM
    transactions t
    JOIN organizations o ON t.organization_id = o.id
WHERE
    o.id = ('1','2'...); -- etc.
```

Left outer join variation using `ANY`:
```sql
SELECT
    books.id,
    books.title,
    authors.name
FROM
    "books"
    LEFT OUTER JOIN "authors" ON "authors"."id" = "books"."author_id"
WHERE
    authors.id = ANY (
        SELECT
            id
        FROM
            authors
        WHERE
            id <= 500)
LIMIT 10;
```

## Improvements in Postgres 17
When we can’t or don’t want to restructure the SQL query, for Postgres, there’s some good news on newer versions. From Postgres 17, the Postgres developers made internal improvements to more efficiently use the scalar expressions and compare then to an index, with fewer scans.

This improves query performance by reducing the index scans, IO, and associated latency.

The difference can be noteworthy!

<https://www.crunchydata.com/blog/real-world-performance-gains-with-postgres-17-btree-bulk-scans>

To find out if this will benefit your application, check your collection query stats using `pg_stat_statements`.

Search within the query field using a regular expression, and find queries that have an IN clause.

## Identifying problematic query groups using pg_stat_statements
Problem is it doesn’t collapse entries with different numbers of scalar array expressions, IN (‘1’) will be duplicated with IN (‘1’,’2’)

Rails generates these queries. Sean Linsley working on a fix for Rails by replacing the usage of IN with ANY https://github.com/rails/rails/pull/49388#issuecomment-2680362607

## Postgres 18 - VALUES within IN
Vlad and Sean point out Convert 'x IN (VALUES ...)' to 'x = ANY ...' then appropriate

Note the VALUES clause within the IN clause

<https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=c0962a113d1f2f94cb7222a7ca025a67e9ce3860>

## Postgres 18 - VALUES within IN
Squash query list jumbling
<https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=62d712ecfd940f60e68bde5b6972b6859937c412>

Remove query_id_squash_values GUC
<https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=9fbd53dea5d513a78ca04834101ca1aa73b63e59>
