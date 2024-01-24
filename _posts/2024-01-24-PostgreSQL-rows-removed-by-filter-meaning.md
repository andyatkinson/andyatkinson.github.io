---
layout: post
title: "What's the meaning of 'Rows Removed By Filter' in PostgreSQL Query Plans?"
tags: []
date: 2024-01-24
comments: true
---

Recently I was discussing "Rows Removed by Filter" with a team during a training session, and realized I didn’t fully understand it.

Sometimes the values were very sensible, and other times they weren't.

For example, when selecting one row based on a unique column value, the "Rows Removed by Filter" value was "one less" than the total row count. Very sensible. None of the other rows matched the filter condition.

However, for *different* unique values, "Rows Removed by Filter" might be "slightly" less than the total, *significantly less* (e.g. < 1%), or some value in between.

What's going on there? In the example below, from 20210 total rows, matching one row, we see 20187 were evaluated and discarded. How was 20187 calculated?

![Analyzing Rows Removed by Filter in psql](/assets/images/posts/query-code.jpg)
<small>Analyzing "Rows Removed By Filter" in psql</small>

## Digging Into "Rows Removed by Filter"
Here are the details:

- We’re working on a table with 20210 rows
- We queried for a single row, based on a unique column value.
- For all queries, a Sequential Scan was used to access the row data.
- All data was accessed from shared buffers, confirmed by adding `BUFFERS` to `EXPLAIN (ANALYZE)` and observing `Buffers: shared`.
- All queries set a `LIMIT 1`. We weren't treating the data like it was unique, so we added this `LIMIT` because we wanted just one match.

The difference was that for some column values, nearly *all* rows were processed and discarded, while for other values *hardly any* needed to be processed before a match was found.

This was an "early match", and seems to be correlated with insertion order for the records.

In other words, accessing the `name_code` column values for earlier `id` range rows accessed fewer pages/buffers compared with `name_code` values towards the "end", confirmed with `name_code` values appearing when using `ORDER BY id DESC`.

By prepending `EXPLAIN (ANALYZE, BUFFERS)` onto the query, when early matches happened, we saw fewer buffers accessed. By accessing less data, there was less latency which resulted in a lower execution time.

See: [EXPLAIN (ANALYZE) needs BUFFERS to improve the Postgres query optimization process](https://postgres.ai/blog/20220106-explain-analyze-needs-buffers-to-improve-the-postgres-query-optimization-process)

## Additional information about "Rows removed by filter"
Is this figure an exact value? Well, it could be.

The [PgMustard Glossary](https://www.pgmustard.com/docs/explain/rows-removed-by-filter) explains it as:

> This is a per-loop average.

What does this mean? If more than one loop was used for the plan node (e.g. `loops=2` or greater), for example like in the Seq Scan node here, then "Rows Removed by Filter" is an average value among the loops. Michael C.[^michael] noted that this average is also rounded to the nearest integer.

For example, if one loop removed 10 rows, and another removed 30 rows, we'd expect to see a value of 20 as the average of the two loops.

However, when there’s one loop (`loops=1`), the figure is the average of *one* loop, meaning it's the exact number of rows that were processed and removed.

## Other Tidbits
- The [PostgreSQL EXPLAIN documentation](https://www.postgresql.org/docs/current/using-explain.html) describes how "rows removed by filter" appears only when `ANALYZE` is added to `EXPLAIN`.
- "Rows Removed by Filter" Applies for filter conditions like a `WHERE` clause, but can also be added for conditions on a `JOIN` node
- "Rows Removed by Filter" information appears when *at least one row is scanned for evaluation*, or a "potential join pair" (for join nodes) when rows were discarded by the filter condition
- Michael C. notes that using `ORDER BY`, commonly used with `LIMIT`, can produce more predictable planning results. See this thread for more: <https://twitter.com/Xof/status/1413542818673577987>

## Takeaways
- For Sequential Scans when `LIMIT 1` is used, "Rows Removed by Filter" *may* be "one less" than the total row count or it may not. Since there's a `LIMIT 1`, there may be an "early match" resulting in fewer "Rows Removed by Filter" than expected.
- When viewing "Rows Removed by Filter" check whether the plan node had more than one loop. When there’s more than one loop, the number that’s returned is an average from all loops.
- When working on performance optimization, a high *proportion* of rows removed indicates an optimization opportunity. There's likely a helpful index that's missing, or an existing index could be made more selective with an expression. Generally the goal is to access fewer pages/buffers, reducing latency, and achieving a faster execution time.

[^michael]: A special thank you to Michael Christofides, founder of [PgMustard](https://www.pgmustard.com), for reviewing an earlier draft of this post.

Thanks for reading!
