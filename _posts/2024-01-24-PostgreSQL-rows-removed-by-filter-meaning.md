---
layout: post
title: "What's the meaning of 'Rows Removed By Filter' in PostgreSQL Query Plans?"
tags: [PostgreSQL]
date: 2024-01-25
comments: true
---

I was recently conducting a training session on the query planner, looking at the bits of information, and we discussed the "Rows Removed by Filter."

I was seeing a value of one less than the total row count, which made sense, since the query had a `LIMIT` of 1.

However, as I changed the query parameter, the value from "Rows Removed by Filter" returned different values. I realized I didn’t fully understand the behavior, so I wanted to take that opportunity to strengthen my understanding of what was happening.

And as a special bonus, in this process, Michael Christofides,[^michael] founder of [PgMustard](https://www.pgmustard.com), was nice enough to read drafts of this post and even pair up. We had a live session exploring the data, queries, and planner output.

Let’s dive into the details!

## Digging Into "Rows Removed by Filter"

Let’s discuss the circumstances of our table, the queries, and the behavior.

- We queried a "users" table with 20210 total rows. The table uses an integer sequence starting from 1.
- New rows **are not** being inserted. We’re working with a static set of rows for this entire experiment session.
- Let’s assume that `VACUUM` has never run after the rows were inserted
- We used the same `WHERE` clause in the query, changing only the `name_code` string column, which holds a mostly-unique (but not guaranteed or enforced with a constraint) string "code" value for each row.
- We set a `LIMIT` of 1 on the queries, but no `ORDER BY`, and no `OFFSET`. In practice, a `LIMIT` would often be accompanied by an `ORDER BY`, but that wasn’t the case here.
- A Sequential Scan was accessed to access the row data, because there was no index. In a production system, an index on the `name_code` column supporting this type of query would be a good idea. However, in this post we’re aiming to understand the behavior without an index added.
- All data was accessed from shared buffers, confirmed by adding `BUFFERS` to `EXPLAIN (ANALYZE)` in front of the query, and seeing [`Buffers: shared hit` in the execution plan](https://www.pgmustard.com/docs/explain/buffers-shared-hit).

![Analyzing Rows Removed by Filter in psql](/assets/images/posts/query-code.jpg)
<small>Analyzing "Rows Removed By Filter" in psql</small>

Worth noting is that `name_code` values were generated from random numbers, and even with 1 million possibilities, there were collisions. From 10 million possibilities, then we did not have collisions in a set of around 20 thousand. This doesn’t really affect the outcomes, but was worth noting. We observed this when we tried to add either a Unique index or a Unique constraint to the table.

## Expectation versus reality

What I expected to see for the value of "Rows Removed by Filter" was for it to be one less than the total number of rows in the table.

With the initial values I used, that was the value returned. However, as I put in different `name_code` values, the "Rows Removed by Filter" had different values than what I expected. As we dug into why, I learned there are a lot of reasons for that. Let’s take a look!

## What was happening?

What was happening based on the LIMIT 1 being in the query, was as soon as PostgreSQL found any match, there was an "early return", or in other words no need for accessing additional pages of data.

Ok. With that in mind, how does that translate to the Rows Removed by Filter values?

When supplying `name_code` values from earlier inserted rows, in earlier pages, we’d see smaller values for Rows Removed by Filter. For `name_code` values "late" in the insertion order, many more rows were processed and discarded on the way towards matching the query condition, for a specific `name_code` value, with a `LIMIT` of 1. We could see this in the planner output, as many more pages/buffers were accessed.

We could estimate the number of rows stored in each 8kb page, which was about 28 rows per page in this case.

```sql
SELECT 8192 / avg_row_size AS rows_per_page
FROM
(SELECT
    pg_relation_size('users') / COUNT(*) AS avg_row_size
 FROM users
) AS sub;
 rows_per_page
---------------
            28
```


## Performance details

As stated, when prepending `EXPLAIN (ANALYZE, BUFFERS)` on the query, we saw fewer buffers accessed for these "early matches."

With fewer buffers accessed, there was less latency, and lower execution times. However, performance wasn’t the goal of this exercise. If it was, it would make more sense to add an index covering the `name_code` column to speed up the query, by making the `name_code` column accessible at a lower cost.

See: [EXPLAIN (ANALYZE) needs BUFFERS to improve the Postgres query optimization process](https://postgres.ai/blog/20220106-explain-analyze-needs-buffers-to-improve-the-postgres-query-optimization-process)

## Additional information about "Rows removed by filter"
One question I had was whether "Rows Removed by Filter" was an actual figure or an estimated figure.

The [PgMustard Glossary](https://www.pgmustard.com/docs/explain/rows-removed-by-filter) explains it as:

> This is a per-loop average, rounded to the nearest integer.

What does this mean? When more than one loop is used for the plan node (e.g. `loops=2` or greater), then "Rows Removed by Filter" is an average value of the "Rows Removed by Filter" per-loop.

For example, if one loop removed 10 rows, and another removed 30 rows, we'd expect to see a value of 20 as the average of the two.

When there’s one loop (`loops=1`), the figure is the actual number of rows processed and removed.

## Experiments with `OFFSET`

Michael suggested using `OFFSET` to find rows in the table towards the "end." Sure enough, when we grabbed the `name_code` from the first row with that offset, with the LIMIT 1, and re-ran the query, we don’t see Rows Removed by Filter at all, because in the default planner output format, when it’s zero, the message is not displayed.

When we choose the second row (using the default ordering, without an ORDER BY), we see a single shared hit, and we see a value of 1 for Rows Removed by Filter.

Let’s try going to the middle with an `OFFSET` of 10000.

Now we see Rows Removed by Filter: 10000, exactly matching the offset. 

## Other Tidbits
- The [PostgreSQL EXPLAIN documentation](https://www.postgresql.org/docs/current/using-explain.html) says "Rows Removed by Filter" appears only when `ANALYZE` is added to `EXPLAIN`.
- "Rows Removed by Filter" Applies for filter conditions like a `WHERE` clause, but can also be added for conditions on a `JOIN` node
- "Rows Removed by Filter" information appears when *at least one row is scanned for evaluation*, or a "potential join pair" (for join nodes) when rows were discarded by the filter condition. As we saw, it doesn’t show up in the default format when no rows are evaluated.
- Michael  noted that using `ORDER BY`, commonly used with `LIMIT`, can produce more predictable planning results. See this thread for more: <https://twitter.com/Xof/status/1413542818673577987>

## Takeaways
- When `LIMIT 1` is used, and no ordering or offset is specified, "Rows Removed by Filter" shows a value based on how PostgreSQL accesses the data, which could be insertion order, showing the number of rows filtered out from the pages/buffers it’s accessed.
- PostgreSQL tries to access as few pages/buffers as possible. When any match is found for the `LIMIT`, it’s done working.
- When analyzing "Rows Removed by Filter" figures, check out whether the plan node had more than one loop. In that case, the rows are an average of all loops, rounded to the nearest integer.
- For performance work, a high *proportion* of rows filtered out indicates an optimization opportunity. There's likely a helpful index that's missing that would require far less filtering. For the best performance, our goal is to access as few pages/buffers as possible.

[^michael]: A special thank you to Michael Christofides, founder of [PgMustard](https://www.pgmustard.com), for reviewing drafts of this post, and pairing up and helping me understand the planner behavior and output.

Thanks for reading!
