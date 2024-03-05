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

The table has exactly 20,210 rows when the data loaders are used.

The SQL scripts add a `name_code` column to the `rideshare.users` table, then populate it for all rows. From there, we analyze query planner results working with certain table rows.

## Why Part Two?

In part one, we started to scratch the surface of understanding query planner output and correlating that with data layout.

While I learned some things when writing that post, I still felt unsatisfied with my knowledge of the data layout in pages within PostgreSQL.

In this post, we’ll attempt to learn a bit more about how the data is laid out, which could help us reason through query performance problems.

## Early Returns

When we do a sequential scan on the table, with a LIMIT of 1, Postgres stops as early as it can when it finds a single match.

This means that the "Rows Removed by Filter" and the quantity of shared buffer hits we see could be quite low. When that happens, we can deduce that the row data we fetched came from either the first page loaded, or an "early" page.

## Introducing the pageinspect extension

Using the functions provided from the pageinspect extension, we can determine the amount of pages loaded when we access all 20,000 rows in the "users" table.

We can see there are around 350 pages accessed.

In Part Two we’ll look at the Tuple ID for the row, using the hidden ctid column. This gives us the block number (or page number). Although I think blocks and pages here are both accepted terms and refer to the same thing, we’ll use pages.

## Setting up pageinspect

Because I need to configure and work with pageinspect functions as a superuser, and in my Rideshare database I normally use the "owner" user which is not a superuser, I’ll connect as superusers "root" or "andy" I have locally, and enable pageinspect within the "rideshare" schema. We’ve removed the public schema from the rideshare database.

```sql
 psql -U andy -d rideshare_development
```

Since the extension is enabled within the rideshare schema, we’ll need to have schema-qualified function calls, like "rideshare.heap_page_items()".

```sql
CREATE EXTENSION IF NOT EXISTS pageinspect;
```

Alternatively, we can set the search_path as follows, which means we don’t need to prefix the schema, which is more convenient:

```sql
SET search_path = 'rideshare';
```

## The ctid or tuple identifier

The ctid column identifies a tuple, and has two numbers like (657,20). The first number is the "block id", and is what we’re after here.

Blocks and pages are used somewhat interchangeably to refer to the fixed size, usually 8KB bits of storage that’s allocated to store information in PostgreSQL.

We’ll main use the term "pages" although the ctid does use block ID. We’ll use the block ID to find a "page."


## Finding out the amount of blocks

When we’re looking at the performance of a query, one thing I’ve wondered about is how many pages in total are accessed if we were to scan through an entire set of table rows. Since we’re working with Sequential Scan type in Part One and Part Two of these blog posts, we’re interested in that figure of the total number of pages that hold all of our row data.

The query below uses functions from pageinspect to grabs the block ID portion of the ctid, then count all the distinct ones.

To keep things a little easier to follow, we’ll perform a manual "VACUUM (FULL, ANALYZE) rideshare.users;" on the table before running these queries. This is not a live system so it’s fine to fully compact the table this way. 

Running this on the 20K users rows, we got 342 distinct blocks (or pages) as of this query. The MIN() block id is "0" and the MAX() block id is 341. Note that these figures will change as operations happen for the table and it expands (or contracts).

```sql
SELECT COUNT(DISTINCT(sub.block)) FROM (
  SELECT (ctid::text::point)[0]::int AS block
  FROM rideshare.users
) sub;
```

## Looking into a specific page

Let’s consider a block ID from the ctid. We can use the `get_raw_page()` function to see the page contents. To do that for the `rideshare.users` table, and the block ID of 0, run the following query:

```sql
SELECT * FROM heap_page_items(get_raw_page('rideshare.users', 0));
```

The response rows are "line pointers." These are pointers to the tuples (rows), and the result columns are all tuple related things like their visibility, their attributes, and more.

Here is more information about line pointers:

They’re located in the disk page header
Their purpose is to point to the actual tuples within the page. They have an "offset" which is their distance from the beginning of the page.
All tuples are visible here, and is not subject to the normal visibility rules of MVCC (tuple versions, whether they are live or not)

That’s where we’ll stop on understanding the line pointers for now here.


For more information on the `heap_page_items()` function, check out the documentation:

<https://www.postgresql.org/docs/current/pageinspect.html#PAGEINSPECT-HEAP-FUNCS>

The documentation directs us into the source code for line pointer fields and tuple header details.

Line pointer fields on the GitHub mirror: <https://github.com/postgres/postgres/blob/master/src/include/storage/itemid.h>

Heap tuple header details:
<https://github.com/postgres/postgres/blob/master/src/include/access/htup_details.h>


David Zhang wrote this nice post "Heap file and page in details" which has helpful information I used to try and understand the basics.

<https://idrawone.github.io/2020/10/09/Heap-Page-in-details/>


Ok, we’ve now got some idea of the pages that store the data, how many there are, their numbers, and how to access their contents.

In the query planner output, we can use `EXPLAIN (ANALYZE, BUFFERS)` to see how many buffers are accessed, whether they’re coming from the buffer cache or not.

Once pages are accessed once, they’re placed into the "buffer cache." When looking at the number of pages accessed whether from the buffer cache or not, we’re trying to get a sense of the amount of memory or storage access happening. For performance optimization, we’re always trying to minimize the storage access.

Given what we learned above, let’s try to understand a little more about the buffer information.

## Sequential Scans and buffer accesses

With the block ID from the ctid available, when we run a query with a LIMIT of 1, and no ordering, without any indexes that are used by the query, we see:

- A Sequential Scan type is used
- "Rows removed by filter" is correlated with the number of pages accessed. The table row data is distributed in 342 pages.
- The number of "buffers" accessed to be correlated with how the page data was accessed

Let’s look at some examples.

## Analyzing results for the first user

First, we’ll order the users by their insertion order, which is using the "created_at" timestamp field ordered ascending, and grabbing the first one. 

Using the  "name_code" value as an Active Record code query from that first row, we see:

We can’t clear the buffer cache. Although, there was no other activity on the system, and PostgreSQL was restarted before running these queries.


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

Here we’re seeing no output at all from Rows Removed by Filter, which means we must be dealing with the first row in the page.

We can see PostgreSQL accessed a single page, and the page came from the buffer cache, since we see a "shared hit=1".

```sql
 Buffers: shared hit=1
   ->  Seq Scan on users
```

## Analyzing results for the last user

How about the User record that might appear in the "last" page, and have the highest or last primary key value?

We can find that user by flipping the ordering on the original query:

```rb
User.order(created_at: :desc).limit(1).select(:id, :name_code)
#=> LT2795
```

Let’s get the block ID from their ctid:

```sql
SELECT ctid FROM rideshare.users WHERE name_code ='LT2795';
   ctid
----------
 (341,39)
```

Comparing that with the block ID of 0 from the first value, knowing we have 342 blocks, we get the expected block ID of 341.

The "Rows Removed by Filter" and the blocks/pages/buffers accessed make good sense here too.

For the query generated from this Active Record code, which is the same with or without a `LIMIT`:

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

With 20,210 total rows, a single row that matches this name_code, we see all rows were accessed, filtering through 20,209, located in 342 pages, before we found the single row match.

## Enabling pg_buffercache

Shared hits come from the buffer cache. When we see a number of buffer cache buffers accessed, if the number is surprising, it might be interesting to look into the buffer cache directly and see what’s in there.

We can do that by using the pg_buffercache extension.

Let’s enable it in the Rideshare database, within the rideshare schema, using our same superuser from earlier. We’ll set the rideshare schema in the search_path so we don’t have to schema-qualify the function calls.

```sql
CREATE EXTENSION IF NOT EXISTS pg_buffercache SCHEMA rideshare;

SET search_path = 'rideshare';
```

By viewing all rows in the buffer cache using the function call below, we see result rows that start with a "bufferid" column, and show the information in that buffer.

Let’s look at the first 3 buffers.

```sql
SELECT * FROM pg_buffercache where bufferid BETWEEN 0 and 3;
```

We now have some raw ingredients to look for "rideshare" schema objects, and see which blocks in which tables are placed in the buffer cache.

To do that, let’s run the following query which shows the bufferid, schema name ("rideshare"), table name ("relname), and the block ID/page number. Let’s order the results by their block ID in ascending order.

```sql
SELECT b.bufferid, n.nspname, c.relname, b.relblocknumber
FROM pg_buffercache b
JOIN pg_class c ON b.relfilenode = pg_relation_filenode(c.oid) AND
b.reldatabase IN (0, (SELECT oid FROM pg_database WHERE datname = current_database()))
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'rideshare'
ORDER BY b.relblocknumber ASC;
```

Great! We see the expected 342 rows for table row relation data, since the whole table has been scanned prior to this and placed in the buffer cache.

We see 345 result rows though. The three others correspond to one buffer for the primary key relation (users_pkey), and two others for the two existing users table indexes, "index_users_on_last_name" and "index_users_on_email". 


## Takeaways

In Part Two of this post series, we dug a little more info page data for our tables, and what that page data looks like when it’s stored in the buffer cache (shared_buffers).

To do that, we looked at the basics of inspecting pages and inspecting the buffer cache content.

For sequential scans, using the insertion order of the users ("created_at" timestamp), *WHEN* we set an order on our query that matches the insertion order, we access fewer pages to find the rows, so there are fewer rows filtered, and few pages accessed.

Note that this can change over time though as the table data is modified, objects are added, edited, and removed.
