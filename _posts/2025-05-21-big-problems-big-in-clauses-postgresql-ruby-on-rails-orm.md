---
layout: post
permalink: /big-problems-big-in-clauses-postgresql-ruby-on-rails
title: 'Big Problems From Big IN Clauses with Ruby on Rails and PostgreSQL'
hidden: true
---

## Introduction
If you’ve created Ruby on Rails web applications with a database before, or have used other similar frameworks ORMs, you’ve likely had the kind of problematic query pattern we’re discussing in this post.

This pattern is IN clauses in SQL queries that perform filtering, and have a huge list of values. It's not unheard of to have dozens, hundreds, or even thousands of values for large databases with millions of records. These lists are used to filter within a even larger set.

The technical term for the right-hand size list of values is *parenthesized list of scalar expressions*.

In the SQL query below, an example IN clause is `author_id IN (1,2,3)` and the list of scalar expressions is `(1,2,3)`.
```sql
SELECT * FROM books
WHERE author_id IN (1, 2, 3);
```

When looking at a query execution plan, we'll see something like this in PostgreSQL (note the `ANY` keyword discussed later on):
```sql
Filter: (author_id = ANY ('{1,2,3}'::integer[]))
```

Imagine you're working with a new codebase. How do you find instances of these types of queries?

## How does it happen?
In Active Record, the Ruby on Rails ORM, this type of query pattern could be created explicitly by using the `pluck()` method. This method is used to select specific fields for a model, for example only the `id` primary key values.

Here’s an example of getting those and assigning them to an `author_ids` variable:
```sql
author_ids = Author.where("created_at >= ?", 1.year.ago).pluck(:id)
```

Then the values are supplied as input to query for `books` and filter them down to matching authors:
```sql
Book.where(author_id: author_ids)
```

Besides explicitly creating this pattern, this pattern can be created implicitly by ORM methods. What do those look like?

## How does it happen in Active Record ORM?
One way for this query pattern to emerge is to use using Eager Loading methods in Ruby on Rails like `includes` or `preload`.

This [Crunchy Data post](https://www.crunchydata.com/blog/real-world-performance-gains-with-postgres-17-btree-bulk-scans) mentions how eager loading methods produce large IN clause SQL queries.

The post links to the [Eager Loading Associations documentation](https://guides.rubyonrails.org/active_record_querying.html#eager-loading-associations) for Ruby on Rails where we can see examples in Active Record and the resulting SQL.

## Fixing N+1s
Let's study the examples here. Here's some Active Record for books and authors:
```rb
# N+1
books = Book.limit(10)

books.each do |book|
   puts book.author.last_name
end
```

The issue above is that there's an N+1 query pattern, where the authors are repeatedly queried while books are looped through.

To fix the N+1, we could use `includes(:author)` to bulk load them.

<pre><code>
books = Book.<strong>includes(:author)</strong>.limit(10)

books.each do |book|
   puts book.author.last_name
end
</code></pre>

## Eager loading with includes or preload
What we may not realize is that the `includes(:author)` fix for the N+1 ends up using an IN clause in the resulting SQL query.

Here's the example from the documentation:
```sql
SELECT books.* FROM books LIMIT 10
SELECT authors.* FROM authors
  WHERE authors.id IN (1,2,3,4,5,6,7,8,9,10)
```

With 10 values in the IN clause, the performance will be fine. However, we'll start to run into problems when we have thousands of values.

How else can these emerge?

## Eager loading using eager_load
Unlike `includes` or `preload` which produce IN clause SQL queries as a second query, `eager_load` produces a single query that uses a `LEFT OUTER JOIN`.

Active Record documentation example:
```rb
books = Book.eager_load(:author).limit(10)

books.each do |book|
  puts book.author.last_name
end
```

This produces the following single SQL query:
```sql
SELECT "books"."id" AS t0_r0, "books"."title" AS t0_r1, ... FROM "books"
  LEFT OUTER JOIN "authors" ON "authors"."id" = "books"."author_id"
  LIMIT 10
```

Instead of `authors` being found by their `id` in the IN clause, query results here are produced by joining the two tables when they match either side of the relationship.

A result is included for matches of the `authors.id` primary key or the `books.author_id` foreign key.

As a `LEFT OUTER JOIN`, a result row is produced whether both sides have a match or not.

We could instead try an `INNER JOIN` , but in this case that produces results that are ordered differently.

Postgres does not guarantee an ordering without an explicit `ORDER BY` clause which we're not using here.


What are our options then to improve performance?

## Alternative approaches using ANY or SOME
Crunchy Data's post [Postgres Query Boost: Using ANY Instead of IN](https://www.crunchydata.com/blog/postgres-query-boost-using-any-instead-of-in) describes how `IN` is more restrictive on the input.

A more usable alternative can be `ANY` or `SOME` in place of `IN`, given it's flexibility in handling the list of input values.

However, that's not the type of query that Active Record eager loading will generate.

One option would be to reach for the [ActiveRecordExtended](https://github.com/GeorgeKaraszi/ActiveRecordExtended) gem to generate that type of query.

Besides usability, is the performance of ANY / SOME any better than IN?

Both leverage index only scans for the primary key index for authors, which makes sense, making their performance about the same.

The IN clause only works with the `=` operator, meaning we can't use the greater than (`>`) or less than (`<`) operators with it, but we can use those operators with `ANY`.

```sql
EXPLAIN (ANALYZE, BUFFERS, COSTS OFF)
WITH author_ids AS (
SELECT
    id
FROM
    authors
)
select title from books
where author_id < ANY(select id from author_ids where id <= 10); -- <- ANY
```

## Query performance improvement by working in smaller sets
Our general approach should be to work with smaller sets of data, to avoid having IO intensive queries.

We may achieve that by using the `eager_load` eager loading method which uses multiple queries and a `LEFT OUTER JOIN`, or we may achieve that by replacing `IN` with `ANY` or `SOME`.

With more direct SQL query control, we can add more where clause filters or a `LIMIT` clause to work with batches, and filter on indexed columns for predictable performance.


## Improvements in Postgres 17
For Postgres, there’s some good news on this problematic query pattern.

As part of the PostgreSQL 17 release in 2024, the developers made internal improvements to more efficiently use the scalar expressions and compare then to an index, with fewer re-scans.

This improved query performance by reducing the index scans, IO, and associated latency, for all Postgres users, without requiring any changes to their SQL queries!

To find out if this will benefit your application, check your `pg_stat_statements` results, querying the `query` field for instances of the `IN` clause pattern discussed in this post.

While it would be nice if these were all grouped up, unfortunately there can be duplicates or near duplidates that don't group well, so you may have lots of PGSS result rows to sift through.

Here's a basic query filtering on the `query` field and looking for `'%IN \(%'`:
```sql
SELECT
    query
FROM
    pg_stat_statements
WHERE
    query LIKE '%IN \(%';

                   query
------------------------------------------------------
select * from trips where id IN ($1,$2)
```


## Identifying problematic query groups using pg_stat_statements
One problem is that similar groupable entries aren't collapsed with different numbers of scalar array expressions, e.g. `IN ('1')` will not be grouped with `IN ('1','2')`.

Rails generates these queries. Sean Linsley is working on a fix for Rails by replacing the use of `IN` with `ANY` in part for better grouping.

Pull Request: <https://github.com/rails/rails/pull/49388#issuecomment-2680362607>

## Postgres 18: VALUES within IN
Vlad and Sean point the benefits of converting `x IN (VALUES ...)` to `x = ANY ...`.

Note the `VALUES` clause within the `IN` clause. See commit:
<https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=c0962a113d1f2f94cb7222a7ca025a67e9ce3860>

Commit: Squash query list jumbling
<https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=62d712ecfd940f60e68bde5b6972b6859937c412>

Commit: Remove query_id_squash_values GUC
<https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=9fbd53dea5d513a78ca04834101ca1aa73b63e59>
