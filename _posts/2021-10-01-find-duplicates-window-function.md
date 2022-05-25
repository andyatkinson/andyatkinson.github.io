---
layout: post
title: "Find Duplicate Records Using ROW_NUMBER Window Function"
tags: [PostgreSQL, Databases, Tips]
date: 2021-10-01
comments: true
---

Finding duplicate rows following an application bug can be tricky to do in a performant way. One way to improve the speed and simplicity of identifying the duplicate rows is doing both the find and delete all in SQL, as opposed to mixing usage of a separate script.

Recently I found and adapted a SQL solution to this problem which uses the `ROW_NUMBER` window function. This post is a generic version of the solution with a made-up table structure, records, and write-up to set the context for when to apply this technique.

#### How does this happen?

Duplicate rows like this happen occasionally due to application bugs. 2 threads may create the same item at the same time. Without any application uniqueness enforcement, or database constraint, these rows are created.

Typically after cleaning up the duplicate data, we'd add a database unique constraint to prevent the issue from happening again.


#### The Setup

Lets create a links table that tracks a `url` and a `name` and give it an integer primary key. Having a primary key is important because we will use it to identify rows for deletion.

We will insert some rows, deliberately inserting duplicate rows for the `google` entry.

```
CREATE table links (id serial primary key, url VARCHAR(255), name VARCHAR(255));
```

```
INSERT INTO links (url, name) VALUES ('google.com', 'google');
INSERT INTO links (url, name) VALUES ('google.com', 'google');
INSERT INTO links (url, name) VALUES ('microsoft.com', 'microsoft');
INSERT INTO links (url, name) VALUES ('facebook.com', 'facebook');
INSERT INTO links (url, name) VALUES ('google.com', 'google');
INSERT INTO links (url, name) VALUES ('google.com', 'google');
```

Notice how google rows are the same and appear 4 times.

Let's group by url and name, and count the rows.

```sql
select url, name, count(*) as cnt
from links
group by url, name
having count(*) > 1;
```

We can see that google appears 4 times in total. Each row has a distinct primary key ID.

Our goal is to preserve 1 of those rows while removing the other 3 duplicate rows.

Once we are able to select only those 3 rows, we can issue a single `DELETE` statement to delete them by ID.

First let's look at the IDs for all of the rows that have a name of `google`.

```
select * from links where name = 'google';
 id |    url     |  name
----+------------+--------
  1 | google.com | google
  2 | google.com | google
  5 | google.com | google
  6 | google.com | google
```

So our query results should match IDs `2`, `5`, and `6`. Running the query, that is exactly what we get.

By running the following query, we are intending to only select those rows.

```sql
select c.id,c.url, c.name
select c.id,c.url, c.name
FROM links c
JOIN
(select a.id, a.url, a.name,
ROW_NUMBER() OVER(ORDER BY a.url,a.name,a.id) AS row_rank
from links a
JOIN (

select url, name, count(*) as cnt
from links
group by url, name
having count(*) > 1) b ON a.url = b.url AND a.name = b.name
) dt ON dt.id = c.id
AND dt.row_rank != 1;
FROM links c
JOIN
(select a.id, a.url, a.name,
ROW_NUMBER() OVER(PARTITION BY a.url,a.name ORDER BY a.url,a.name,a.id) AS row_rank
from links a
JOIN (

select url, name, count(*) as cnt
from links
group by url, name
having count(*) > 1) b ON a.url = b.url AND a.name = b.name
) dt ON dt.id = c.id
AND dt.row_rank != 1;
```

And we can see that the results are only rows 2, 5, 6 which is what we were looking for.

```
 id |    url     |  name
----+------------+--------
  2 | google.com | google
  5 | google.com | google
  6 | google.com | google
(3 rows)
```

What is happening in this query?


#### Window Functions

[`ROW_NUMBER`](https://www.postgresqltutorial.com/postgresql-row_number/) is a window function.

The documentation describes ROW_NUMBER() as "a window function that assigns a sequential integer to each row in a result set."

We are also creating a partition by `url` and `name` and ordering by primary key `id`. Do we need to create the partition?

No, in this case removing the partition will use a single partition and produce the same query result. We can also remove the ordering and the natural ordering works the same.

Adding the partition and ordering helps make the intentions explicit, to consider the url, name combination to be the uniqueness dimension, and to order by primary key descending.


#### Deleting the duplicates

Now that we're able to isolate just the rows that are the duplicates, we can issue a single delete statement by ID.

```sql
DELETE from links where id IN (
select c.id--We only need to select the `id` field from the original query
--same query as above
);
```

Running this, we can confirm that 3 items are deleted, and all that is remaining are the unique entries for `google`.

```
DELETE 3
Time: 5.493 ms
# select * from links;
 id |      url      |   name
----+---------------+-----------
  1 | google.com    | google
  3 | microsoft.com | microsoft
  4 | facebook.com  | facebook
(3 rows)
```
