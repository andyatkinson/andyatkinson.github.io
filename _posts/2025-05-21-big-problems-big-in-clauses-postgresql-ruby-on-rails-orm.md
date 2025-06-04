---
layout: post
permalink: /big-problems-big-in-clauses-postgresql-ruby-on-rails
title: 'Big Problems From Big IN lists with Ruby on Rails and PostgreSQL'
tags: [PostgreSQL, Ruby on Rails]
date: 2025-05-23 14:30:00
---

## Introduction
If you’ve created web apps with relational databases and ORMs like Active Record (part of Ruby on Rails), you've probably experienced database performance problems after a certain size of data and query volume.

In this post, we're going to look at a specific type of problematic query pattern that's somewhat common.

We'll refer to this pattern as "Big `IN`s," which are queries with an `IN` clause that has a big list of values. As data grows, the length of the list of values will grow. These queries tend to perform poorly for big lists, causing user experience problems or even partial outages.

We'll dig into the origins of this pattern, why the performance of it is poor, and explore some alternatives that you can use in your projects.

## IN clauses with a big list of values
The technical term for values are a *parenthesized list of scalar expressions*.

For example in the SQL query below, the `IN` clause portion is `WHERE author_id IN (1,2,3)` and the list of scalar expressions is `(1,2,3)`.
```sql
SELECT * FROM books
WHERE author_id IN (1, 2, 3);
```

The purpose of this clause is to perform filtering. Looking at a query execution plan in Postgres, we'll see something like this fragment below:
```sql
Filter: (author_id = ANY ('{1,2,3}'::integer[]))
```

This of course filters the full set of books down to ones that match on `author_id`.

Filtering is a typical database operation. Why are these slow?

## Parsing, planning, and executing
Remember that our queries are parsed, planned, and executed. A big list of values are treated like constants, and don't have associated statistics.

Queries with big lists of values take more time to parse and use more memory.

Without pre-collected table statistics for planning decisions, PostgreSQL is more likely to mis-estimate cardinality and row selectivity.

This can mean the planner chooses a sequential scan over an index scan, causing a big slowdown.

How do we create this pattern?

## Creating this pattern directly
In Active Record, a developer might create this query pattern by using `pluck(:id)` to collect some ids in a list, then pass that list as an argument to another query.

Here’s an example of that:
```sql
author_ids = Author.
  where("created_at >= ?", 1.year.ago).
  pluck(:id)
```

The `author_ids` are supplied as the argument querying `books` by `author_id` foreign key:
```sql
Book.where(author_id: author_ids)
```

Another scenario is when this query is created from ORM methods. What does that look like?

## Active Record ORM methods that create this pattern
This query pattern can happen when using eager loading methods like `includes()` or `preload()`.

This [Crunchy Data post](https://www.crunchydata.com/blog/real-world-performance-gains-with-postgres-17-btree-bulk-scans) mentions how eager loading methods produce `IN` clause SQL queries.

The post links to the [Eager Loading Associations documentation](https://guides.rubyonrails.org/active_record_querying.html#eager-loading-associations) which has examples in Active Record and the resulting SQL that we'll use here.

Let's first discuss N+1 with these examples.

## Fixing N+1s
Let's study the examples here. Here's some Active Record for books and authors:
```rb
# N+1
books = Book.limit(10)

books.each do |book|
   puts book.author.last_name
end
```

The issue above is the undesirable N+1 query pattern, where a table is repeatedly queried in a loop, instead of bulk loading a set of rows.

To fix the N+1, we'll add the `includes(:author)` eager loading method to the code above.

That looks like this:
<pre><code>
books = Book.<strong style="background-color:yellow;">includes(:author)</strong>.limit(10) 👈

books.each do |book|
   puts book.author.last_name
end
</code></pre>

We've now eliminated the N+1 queries, but we've opened ourselves up to a new possible problem.

## Eager loading with includes or preload
While the `includes(:author)` fixed the N+1 queries, Active Record is now creating two queries, with the second one having an `IN` clause.

Here's the example from above as SQL:
```sql
SELECT books.* FROM books LIMIT 10;

SELECT authors.* FROM authors
  WHERE authors.id IN (1,2,3,4,5,6,7,8,9,10);
```

Here we only have 10 values for the `IN` clause, so performance will be fine. However, once we've got hundreds or thousands of values, we will run into the problems described above.

Performance will tank if the `authors.id` primary key index isn't used for this filtering operation.

Are there alternatives for eager loading?

## Eager loading using eager_load
Besides `includes()` and `preload()` which create two queries with the second having an `IN` clause, there's another way to do eager loading in Active Record.

An alternative method `eager_load` works a little bit differently. It produces a single SQL query that uses a `LEFT OUTER JOIN`.

Here's an example of `eager_load` from the Active Record documentation:
```rb
books = Book.eager_load(:author).limit(10)

books.each do |book|
  puts book.author.last_name
end
```

The following single SQL query is produced. Note that it has no `IN` clause.
```sql
SELECT
    "books"."id" AS t0_r0,
    "books"."title" AS t0_r1
FROM
    "books" LEFT OUTER JOIN "authors"
    ON "authors"."id" = "books"."author_id"
LIMIT 10;
```

Since we're now using a join operation, we've got statistics available from both tables. This makes it much more likely PostgreSQL can correctly estimate selectivity and cardinality.

The planner also isn't needing to parse and store a large list of constant values.

While `IN` clauses might perform fine with smaller inputs, e.g. 100 values or fewer,[^1] for large lists we should try and restructure the query to use a join operation instead.

Besides restructuring the queries into joins, are there other alternatives?

## Alternative approaches using ANY or SOME
Crunchy Data's post [Postgres Query Boost: Using ANY Instead of IN](https://www.crunchydata.com/blog/postgres-query-boost-using-any-instead-of-in) describes how `IN` is more restrictive on the input.

A more usable to `IN` can be using `ANY` or `SOME`, which has more flexibility in handling the list of values.

Here's A CTE example using `ANY`:
```sql
WITH author_ids AS (
  SELECT id FROM authors
)
SELECT title
FROM books
WHERE author_id = ANY (
      SELECT id
      FROM author_ids);
```

However, `ANY` is not generated by Active Record. What if we want to generate these queries using Active Record?

One option is to use the `any` method provided by the [ActiveRecordExtended](https://github.com/GeorgeKaraszi/ActiveRecordExtended) gem.

Let's talk at another alternative approach using a `VALUES` clause.

## A VALUES clause
In the comments in the PR above, Vlad and Sean discussed an alternative for `IN` using a `VALUES` clause.

Let's look at an example with a CTE and `VALUES` clause:
```sql
WITH ids(author_id) AS (
  VALUES(1),(2),(3)
)
SELECT title
FROM books
JOIN ids USING (author_id);
```

Or we can write this as a subquery:
```sql
SELECT title
FROM books
WHERE author_id IN (
  SELECT id
  FROM (VALUES(1),(2),(3)) AS v(id)
);
```

This is better because the `IN` list is a big list of scalar expressions, where the `VALUES` clause is treated like a relation (or table). This can help with join strategy selection.

## A temporary table of ids
Yet another option for big lists of values is to put these into a temporary table for the session. The temporary table can even index the ids.
```sql
CREATE TEMP TABLE temp_ids (author_id int);
INSERT INTO temp_ids(author_id) VALUES (1),(2),(3);
CREATE INDEX ON temp_ids(author_id);

SELECT title
FROM books b
JOIN temp_ids t ON t.author_id = b.author_id;
```

## Using ANY and an ARRAY of values
Another form is using `ANY` with an ARRAY:
```sql
SELECT title
FROM books
WHERE author_id = ANY (ARRAY[1, 2, 3]);
```

The `ANY` form can perform better. With an `IN` list, the values are parsed like a chain of OR operations, with the planner handling one branch at a time.

`ANY` is treated like a single functional expression.

This form also supports prepared statements. With prepared statements, the statement is parsed and planned once and then can be reused.

Here's an example of fetching books by author:
```sql
PREPARE get_books_by_author(int[]) AS
SELECT title
FROM books
WHERE author_id = ANY ($1);

EXECUTE get_books_by_author(ARRAY[1,2,3,4,5]);
```

## Testing the alternative query structures
Unfortunately generic guidelines here won't guarantee success in your specific database. Row counts, data distributions, cardinality, or correlation are just some of the factors that affect query execution.

My recommended process is to test on production-like data, work in the SQL layer, then try out restructured queries using these tactics, and study their query execution plans collected using `EXPLAIN (ANALYZE, BUFFERS)`.

Query plan collection and analysis is outside the scope of this post, but in brief, you'll want to compare the plans and look to access fewer buffers, at lower costs, with fewer rows evaluated, fewer loops, for more efficient execution.

If you're working in Active Record, you'd then translate your SQL back into the Active Record source code location where the queries were generated.

How do we find problematic `IN` queries that ran earlier in Postgres?

## Finding IN clause queries in pg_stat_statements
To find out if your query stats include the problematic `IN` queries, let's search the results of `pg_stat_statements` by querying the `query` field.

Unfortunately these don't always group up well, so there can be duplicates or near-duplicates. You may have lots of PGSS results to sift through.

Here's a basic query to filter on `query` for `'%IN \(%'`:
```sql
SELECT
    query
FROM
    pg_stat_statements
WHERE
    query LIKE '%IN \(%';
```
See the [linked PR](https://github.com/andyatkinson/pg_scripts/pull/16) for a reproduction set of commands to create these tables, queries, and then inspect the query statistics using PGSS.

While you can find and restructure your queries towards more efficient patterns, are there any changes coming to Postgres itself to better handle these?

## Improvements in Postgres 17
As part of the PostgreSQL 17 release in 2024, the developers made improvements to more efficiently work with scalar expressions and indexes, resulting in fewer repeated scans, and thus faster execution.

This reduces latency by reducing IO, and the benefits are available to all Postgres users without the need to change their SQL queries or ORM code!

## Grouping similar query groups in pg_stat_statements
There are more usability improvements coming for Postgres users, pg_stat_statements, an `IN` clause queries.

One problem with these has been that similar entries aren't collapsed together when they have a different numbers of scalar array expressions.

For example `IN ('1')` was not grouped with `IN ('1','2')`. Having the statistics for nearly identical entries split across multiple results makes them less useful.

Fortunately, fixes are coming. On the Ruby on Rails side, Sean Linsley is working on a fix by replacing the use of `IN` with `ANY` which solves the grouping problem.

Here's the PR: <https://github.com/rails/rails/pull/49388#issuecomment-2680362607>

On the PostgreSQL side, there are fixes coming for PostgreSQL 18.

## Improvements in PostgreSQL 18
Related improvements are coming to PostgreSQL 18 for 2025.

This commit[^1] implements the automatic conversion of `x IN (VALUES ...)` into ScalarArrayOpExpr.

Another noteworthy commit is: "Squash query list jumbling" from Álvaro Herrera.[^2]

pg_stat_statements produces multiple entries for queries like `SELECT something FROM table WHERE col IN (1, 2, 3, ...)` depending on the number of parameters, because every element of ArrayExpr is individually jumbled.
Most of the time that's undesirable, especially if the list becomes too large.

This commit[^3] mentions the original design was for a GUC query_id_squash_values, but that was removed in favor of making this the default behavior.

## Conclusion
In this post, we looked at a problematic query pattern, big `IN` lists. You may have instances of this pattern in your codebase from direct means or from using some ORM methods.

This type of query performs poorly for big lists of values, as they take more resources to parse, plan, and execute. There are fewer indexing options compared with an alternative structured as a join operation. Join queries provide two sets of table statistics from both tables being joined, that help with query planning.

We learned how to find instances of these using pg_stat_statements for PostgreSQL. The post then considers several alternatives.

Our main tactics are to convert these queries to joins when possible. Outside of that, we could consider using the `ANY` operator with an array of values, a `VALUES` clause, and consider using a prepared statement.

The next time you see big `IN` lists causing database performance problems, hopefully you feel more prepared to restructure and optimize them!

Thanks for reading this post. I'd love to hear about any tips or tricks you have for these types of queries!


[^1]: <https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=c0962a113d1f2f94cb7222a7ca025a67e9ce3860>
[^2]: <https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=62d712ecfd940f60e68bde5b6972b6859937c412>
[^3]: <https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=9fbd53dea5d513a78ca04834101ca1aa73b63e59>
