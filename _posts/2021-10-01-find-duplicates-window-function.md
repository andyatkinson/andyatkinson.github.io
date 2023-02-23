---
layout: post
title: "Find Duplicate Records Using ROW_NUMBER Window Function"
tags: [PostgreSQL, Databases, Tips]
date: 2021-10-01
comments: true
---

Duplicate rows can happen when a database unique constraint is missing. Once found, finding and deleting duplicates in a fast way is necessary before the constraint can be added.

In this post, you'll find and delete the rows in a single query. The query will be complex, but you will build it up in pieces that are more simple.

Recently I found a SQL solution to this problem that uses the `ROW_NUMBER` window function.


#### How Duplicates Happen

Duplicate rows happen occasionally due to application bugs. 2 threads may create the same item at the same time. Without a database unique constraint these rows are created.

Typically after removing duplicates, we'd add the constraint to ensure it doesn't happen again.


#### Duplicate Web Links

Create a links table that tracks a `url` and a `name`. Give it an integer primary key. Having a primary key is important because it is used to identify rows for deletion.

Insert some rows, deliberately inserting duplicate rows for the `google` entry with a duplicate URL. This table was meant to have unique URLs, but the creator didn't add a unique constraint to enforce that.

```sql
-- create DB
CREATE table links (id SERIAL PRIMARY KEY, url VARCHAR);

-- insert rows
INSERT INTO links (url) VALUES ('microsoft.com');
INSERT INTO links (url) VALUES ('google.com');
INSERT INTO links (url) VALUES ('facebook.com');
INSERT INTO links (url) VALUES ('google.com');
INSERT INTO links (url) VALUES ('netflix.com');
INSERT INTO links (url) VALUES ('google.com');
```

Try and add the unique constraint on the URL column now.

```sql
ALTER TABLE links ADD CONSTRAINT unique_url UNIQUE (url);

ERROR:  could not create unique index "unique_url"
DETAIL:  Key (url)=(google.com) is duplicated.
Time: 4.145 ms
```

The duplicates will need to be removed first.

The goal is to keep 1 of the google rows and delete the other 2.

The technique will select the ids for only the duplicate rows, and pass those ids into a `DELETE` statement.

To achieve that, you'll use the ROW_NUMBER() window function.

First, have a look at the ROW_NUMBER() window function.

```sql
SELECT
  id,
  url,
  ROW_NUMBER() OVER (order by id)
FROM links;
```

[`ROW_NUMBER`](https://www.postgresqltutorial.com/postgresql-row_number/) is a window function.

> ROW_NUMBER() is a window function that assigns a sequential integer to each row in a result set.

In the example above, ROW_NUMBER() gives each row a number. Rows can be ordered within the window function, and the outer query can have an ordering as well.

In the next example, the same GROUP BY as above is the second query, and now the query is aliased as "b".

The first query "a" performs a non-grouped query of the links using ROW_NUMBER() to give each row a number.

Then "a" is joined to "b" on the url which is in both the non-grouped and grouped queries. Now there is a list of each of the duplicate links, and they each have a number.

The first item will be number 1. Using this information, a DELETE query can delete any item with a number > 1.

```sql
SELECT
    a.id,
    a.url,
    ROW_NUMBER() OVER (
        ORDER BY a.url, a.id
    )
FROM links a
JOIN
(
SELECT
    url,
    count(*)
FROM links
GROUP BY url
HAVING COUNT(*) > 1
) b
ON a.url = b.url;
```

#### Deleting Duplicates

Now you can put it all together.

Using the row number, for any numbers > 1, the primary key id values for those rows can be passed into a DELETE statement.

Putting that all together looks like below. The below query modifies the query above and filters it down to select only the ids.

All of that is wrapped in a DELETE statement that deletes by id.

```sql

DELETE FROM links WHERE id IN (

-- select only the ids to delete (will return 2 items)
SELECT
    id
FROM (
SELECT
    a.id,
    a.url,
    ROW_NUMBER() OVER (
        ORDER BY a.url, a.id
    )
FROM links a
JOIN
(
SELECT
    url,
    count(*)
FROM links
GROUP BY url
HAVING COUNT(*) > 1
) b
ON a.url = b.url
) c
WHERE row_number > 1

);
```

Query the links again and hooray, no duplicates!

Adding a unique constraint to the `url` column to prevent this from happening again.

```sql
ALTER TABLE links ADD CONSTRAINT unique_url UNIQUE (url);
```


#### Version History

* 2022-11-19: Overhaul, fixed problems, simplified the post
* 2021-10-01: Original publish date
