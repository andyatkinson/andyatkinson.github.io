---
layout: post
title: "What's 'Rows Removed By Filter' all about — Part Two"
tags: []
date: 2024-03-05
comments: true
---

We’re back for Part Two of diving into the "Rows Removed by Filter" information from the query planner.

Before reading this post, please check out [What's 'Rows Removed By Filter' in PostgreSQL Query Plans all about?](/blog/2024/01/25/PostgreSQL-rows-removed-by-filter-meaning), which has also been updated since originally written.

Part One now has SQL commands to set up the table data needed, using the Rideshare database "users" table.

The table has 20,210 rows, and two indexes, but they aren't used for the queries in this post series.

The SQL commands add a `name_code` column to `rideshare.users`, then populate it for all rows. From there, we analyze query plan results, focusing on Rows Removed by Filter, and the number of buffers accessed.

## Why Part Two?

In part one, we scratched the surface of understanding query planner output, correlated with how the data is laid out.

While I learned some things writing that post, I still felt unsatisfied with my understanding of the data pages and buffer information.

In this post, we’ll attempt to go a bit further.

## Early Returns

When we do a sequential scan on the table, with a `LIMIT` of 1, PostgreSQL stops as soon as it finds a single match.

This means "Rows Removed by Filter" and the quantity of shared buffer *could* be quite low. When that happens, the row data fetched came from either the first page loaded or an "early" page.

How can we verify some of that?

## Introducing the pageinspect extension

Using the functions provided from the pageinspect extension, we can determine the amount of pages loaded when we access all rows of the `rideshare.users` table.

We'll do that below, and discover there are around 350 pages containing the roughly 20,000 rows.

## Setting up pageinspect

Because I need to configure and work with pageinspect functions as a superuser, and in my Rideshare database I normally use the "owner" user which is not a superuser, I’ll connect as user `andy` which is a superuser, and enable the `pageinspect` extension within the `rideshare` schema.

In this database, we've removed the `public` schema.

```sql
 psql -U andy -d rideshare_development
```

Since the extension is enabled within the `rideshare` schema, we’ll need to have schema-qualified function calls, like `rideshare.heap_page_items()`, which is a pain.

```sql
CREATE EXTENSION IF NOT EXISTS pageinspect;
```

Alternatively, we can set the `search_path` to be assigned to (or include) the `rideshare` schema, saving us from having to schema-qualify the function calls.

```sql
SET search_path = 'rideshare';
```

With that in place, we can start to use the functions.

## The ctid or tuple identifier

The ctid is a "hidden" column we can get for any row, and helps us know where that row is stored.

The ctid column has two numbers like (657,20). The first number is the "block id", and that's what we're after here.

Blocks or "pages" here refer to a fixed size 8kB amount of storage, that stores table information within the PostgreSQL storage system. Although that part is outside the scope of this post, we can think of them as files stored within the PostgreSQL data directory.

We’ll main use the term "pages" here for "blocks", noting that the ctid first number is the block ID, but it will refer to a page. We’ll use the block ID to find a "page."

## Finding out the amount of blocks

When we’re looking at the performance of a query, one thing I’ve wondered about is how many pages in total are accessed if we were to scan through an entire set of table rows. Since we’re working with Sequential Scan type in Part One and Part Two of these blog posts, we’re know that we're scanning all table rows.

The query below uses functions from `pageinspect` to grab the block ID portion of the ctid for all rows, then counts the distinct values.

To keep things a little easier to follow, before we do that, let's perform a `VACUUM (FULL, ANALYZE) rideshare.users;`. This is not a live system so it’s fine to compact the table this way, and it means the page numbers will be easier to follow.

Running this we get 342 distinct blocks (or pages) for this query.

The `MIN()` block id is "0" and the `MAX()` block id is 341. Note that these figures will change as the table expands or contracts.

```sql
SELECT COUNT(DISTINCT(sub.block)) FROM (
  SELECT (ctid::text::point)[0]::int AS block
  FROM rideshare.users
) sub;
 count
-------
   342
```

## Looking into a specific page

Let’s consider a block ID from the ctid. We can use the `get_raw_page()` function to see the page contents. To do that for the `rideshare.users` table, and the block ID of 0, run the following query:

```sql
SELECT * 
FROM heap_page_items(get_raw_page('rideshare.users', 0));
```

The response rows are "line pointers." These are pointers to the tuples (rows), and the columns are all tuple related like their visibility, attributes, and more.

Here is more information about line pointers:

- They’re located in the disk page header
- Their purpose is to point to the actual tuples within the page. They have an "offset" which is their distance from the beginning of the page.
- All tuples are visible here, and is not subject to the normal visibility rules of MVCC (tuple versions, whether they are live or not)

That’s where we’ll stop for this post on understanding the details of line pointers, since it will be beyond the scope.

For more information on the `heap_page_items()` function, check out the documentation:
<https://www.postgresql.org/docs/current/pageinspect.html#PAGEINSPECT-HEAP-FUNCS>

The documentation directs us into the source code for line pointer fields and tuple header details.

Line pointer fields: <https://github.com/postgres/postgres/blob/master/src/include/storage/itemid.h>

Heap tuple header details:
<https://github.com/postgres/postgres/blob/master/src/include/access/htup_details.h>


David Zhang wrote this nice post "Heap file and page in details" which has helpful information I used to try and understand the basics.
<https://idrawone.github.io/2020/10/09/Heap-Page-in-details/>

## Basics of the contents of pages

Now that we have some idea of the pages that store the data, how many are needed to store the row data, what their numbers are, and how to access their contents, let's move on to the buffer information.

In the query plan output, we use `EXPLAIN (ANALYZE, BUFFERS)` to see how many buffers are accessed. This also shows us whether the buffers are from the buffer cache or not.

When pages are accessed, they’re placed into the "buffer cache" so that they can be served from cache on future accesses.

Since buffer accesses are "read" operations, contributing to storage read IO, we're trying to get a sense of how much read IO is happening in our queries, to understand how that contributes to latency.

## Sequential Scans, buffer accesses, page ordering

With the block ID from the ctid available, when we run a query with a `LIMIT` of 1, and no ordering, without any indexes that are used by the query, here are some details we've seen so far:

- A Sequential Scan type is used
- "Rows removed by filter" can be correlated with the number of pages accessed. The table row data is distributed in 342 pages, numbered from 0 to 341. When the first row in the first page is accessed (page 0), we may see no Rows Removed by Filter at all.
- The number of "buffers" accessed to be correlated with how the page data was accessed.

## Analyzing results for the first user

First, we’ll order the users by their insertion order, which is using the `created_at` timestamp in ascending order, grabbing the first one.

```rb
User.order(created_at: :asc).limit(1).select(:id, :name_code)
#=> KL3965
```

```rb
User.where(name_code: 'KL3965').limit(1).explain(:analyze, :buffers)
```

```sql
SELECT ctid FROM rideshare.users WHERE name_code = 'KL3965';
 ctid
-------
 (0,1)
```

Here we’re seeing no output at all from Rows Removed by Filter, which means we must be dealing with the first row in the first page.

We can see PostgreSQL accessed a single page, and the page came from the buffer cache, since we see a "shared hit=1".

```sql
 Buffers: shared hit=1
   ->  Seq Scan on users
```

## Analyzing results for the last user

How about the "last" User record inserted most recently. We'd expect the page that holds that data to be the last one, 341.

Let's invert the order from the earlier query, ordering the Users in descending order, then getting the first row's `name_code`.

```rb
User.order(created_at: :desc).limit(1).select(:id, :name_code)
#=> LT2795
```

Let’s look at the block ID for the ctid of that row:

```sql
SELECT ctid FROM rideshare.users WHERE name_code ='LT2795';
   ctid
----------
 (341,39)
```

We get the expected block ID of 341, nice.

The "Rows Removed by Filter" and the blocks/pages/buffers accessed make good sense here too.

For the query generated from this Active Record code (the same with or without a `LIMIT`):

```rb
User.where(name_code: 'LT2795').explain(:analyze, :buffers)
```

Here's the query plan:

```sql
                                               QUERY PLAN
---------------------------------------------------------------------------------------------------------
 Limit  (cost=0.00..594.62 rows=1 width=165) (actual time=5.324..5.325 rows=1 loops=1)
   Buffers: shared hit=342
   ->  Seq Scan on users  (cost=0.00..594.62 rows=1 width=165) (actual time=5.322..5.323 rows=1 loops=1)
         Filter: ((name_code)::text = 'LT2795'::text)
         Rows Removed by Filter: 20209
         Buffers: shared hit=342
 Planning Time: 0.099 ms
 Execution Time: 5.354 ms
```

With 20,210 total rows, from the plan we see 20,209 rows were removed, before the single matching row was located.

Those 20,209 rows were distributed in 342 pages that were loaded from the buffer cache.

How else can be explore what's in the buffer cache?

## Enabling pg_buffercache

Shared hits mean our results are coming from the buffer cache.

When we see a surprising number of shared buffers accessed, it might be helpful to look into the buffer cache directly.

We can do that by using the `pg_buffercache` extension.

Let’s enable it for Rideshare within the `rideshare` schema, using our same superuser from earlier. We’ll set the rideshare schema in the `search_path` as before.

```sql
CREATE EXTENSION IF NOT EXISTS pg_buffercache
SCHEMA rideshare;

SET search_path = 'rideshare';
```

Now we can query the buffer cache contents, and see the resuls as rows.

Let’s look at the first 3 buffers.

```sql
SELECT * FROM pg_buffercache where bufferid BETWEEN 0 and 3;
```

We now have some raw ingredients to look for `rideshare` schema objects, and see which blocks in which tables are placed in the buffer cache.

To do that, let’s run the following query which shows the `bufferid`, schema name (`rideshare`), table name (`relname`), and the block ID/page number.

Let’s order the results by their block ID in ascending order.

```sql
SELECT
    b.bufferid, n.nspname, c.relname, b.relblocknumber
FROM pg_buffercache b
JOIN pg_class c ON b.relfilenode = pg_relation_filenode(c.oid)
AND b.reldatabase IN (0, (
SELECT oid FROM pg_database WHERE datname = current_database()
))
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'rideshare'
ORDER BY b.relblocknumber ASC;
```

A results sample is shown:

```sql
bufferid |  nspname  |         relname          | relblocknumber
----------+-----------+--------------------------+----------------
     1636 | rideshare | users_pkey               |              0
     1635 | rideshare | index_users_on_last_name |              0
     1634 | rideshare | index_users_on_email     |              0
      992 | rideshare | users                    |              0
      991 | rideshare | users                    |              1
      990 | rideshare | users                    |              2
...
(345 rows)
```

Great! We see the expected 342 rows representing table row data, since the whole table has been scanned prior to this and placed in the buffer cache.

We see 345 total results. The three others correspond to one buffer for the primary key relation (`users_pkey`), and two others for the two existing users table indexes, `index_users_on_last_name` and `index_users_on_email`.

## Wrap Up

In Part Two of this post series, we dug a little more into how our table row data is stored in pages, and then placed into the buffer cache.

To do that, we looked at the basics of inspecting page content and the contents of the buffer cache.
