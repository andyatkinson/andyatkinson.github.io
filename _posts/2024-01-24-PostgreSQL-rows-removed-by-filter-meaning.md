---
layout: post
title: "What's the meaning of 'Rows Removed By Filter' in PostgreSQL Query Plans?"
tags: []
date: 2024-01-24
comments: true
---

I was recently conducting a training session on the query planner, and discussing the "Rows Removed by Filter" results from the plan.

As we changed the query parameters, I realized I didn’t fully understand the value being reported for “Rows Removed by Filter”. I wanted to dig into that more so that I had a stronger understanding of that information.

Let’s dive into the specifics.

## Digging Into "Rows Removed by Filter"

- We queried a table with 20210 total rows
- We used the same `WHERE` clause, changing only the value for the `name_code` column, which holds a unique code for each row.
- When looking at the query execution plans, they always used a Sequential Scan to retrieve the data, as there was no index for this column. An index for `name_code` would make sense to add normally, but in this case we wanted to understand the behavior without it.
- All data was accessed from shared buffers, confirmed by adding `BUFFERS` to `EXPLAIN (ANALYZE)` in front of the query, and seeing [`Buffers: shared hit` in the execution plan](https://www.pgmustard.com/docs/explain/buffers-shared-hit).
- Queries always had a `LIMIT 1` which was possibly redundant, as each code occurred only once in this table. Note that no unique constraint was present.

![Analyzing Rows Removed by Filter in psql](/assets/images/posts/query-code.jpg)
<small>Analyzing "Rows Removed By Filter" in psql</small>

## Expectation versus reality

What I expected to see in "Rows Removed by Filter" was a value that was one less than the total number of rows in the table. For some `name_code` values, that did happen. When that happened, the number made sense to me, thinking through how none of the other rows matched the filter condition, so they’d all be loaded and then filtered out.

However, for other `name_code` values, the "Rows Removed by Filter" value was less than what I expected to see, sometimes even very few rows, such as 1% or less of the total number of rows in the table. I didn’t really understand why there was this kind of variation.

So what was happening here?

## What was happening?

For `name_code` values that produced an execution plan with low values for “Rows Removed by Filter”, what was happening was an "early match" from the pages/buffers being accessed, based on there being a `LIMIT` in the query, essentially “short circuiting” further evaluation. With that in mind, it made sense. PostgreSQL found a single match that was requested, so why bother loading additional pages?

Great. But why was there the variability?

The table uses an auto-incrementing integer sequence for the “id” primary key column. By looking at table rows and flipping `ORDER BY id` around between `ASC` and `DESC`, we could supply `name_code` values that were correlated with earlier or later `id` values.

What we observed is a correlation with the insertion order of the rows. When supplying `name_code` values from earlier id values, fewer pages/buffers are accessed. For `name_code` values very “late” in the sequence, many more pages/buffers are accessed.

## Performance impact

By prepending `EXPLAIN (ANALYZE, BUFFERS)` onto the query, when early matches happened, we saw fewer buffers accessed. Since less buffers were accessed, there was less latency, which resulted in lower execution times.

See: [EXPLAIN (ANALYZE) needs BUFFERS to improve the Postgres query optimization process](https://postgres.ai/blog/20220106-explain-analyze-needs-buffers-to-improve-the-postgres-query-optimization-process)

## Additional information about "Rows removed by filter"
One question I had was whether “Rows Removed by Filter” was an actual figure or an estimated figure.

The [PgMustard Glossary](https://www.pgmustard.com/docs/explain/rows-removed-by-filter) explains it as:

> This is a per-loop average, rounded to the nearest integer.

What does this mean? When more than one loop is used for the plan node (e.g. `loops=2` or greater), then "Rows Removed by Filter" is an average value of the “Rows Removed by Filter” per-loop.

For example, if one loop removed 10 rows, and another removed 30 rows, we'd expect to see a value of 20 as the average of the two.

When there’s one loop (`loops=1`), the figure is the actual number of rows processed and removed.

## Other Tidbits
- The [PostgreSQL EXPLAIN documentation](https://www.postgresql.org/docs/current/using-explain.html) describes how "rows removed by filter" appears only when `ANALYZE` is added to `EXPLAIN`.
- "Rows Removed by Filter" Applies for filter conditions like a `WHERE` clause, but can also be added for conditions on a `JOIN` node
- "Rows Removed by Filter" information appears when *at least one row is scanned for evaluation*, or a "potential join pair" (for join nodes) when rows were discarded by the filter condition
- Michael C.[^michael] notes that using `ORDER BY`, commonly used with `LIMIT`, can produce more predictable planning results. See this thread for more: <https://twitter.com/Xof/status/1413542818673577987>

## Takeaways
- When `LIMIT 1` is used, and no ordering is specified, when finding a single row, "Rows Removed by Filter" *could be* one less than the total row count, or fewer rows when it exits early. It depends on which page the row data is stored in. PostgreSQL tries to access as few pages/buffers as possible.
- When viewing "Rows Removed by Filter" in general, check whether the plan node has more than one loop. When there’s more than one loop, the number that’s returned is an average of all loops.
- When working on performance optimization, a high *proportion* of rows that are removed by a filter means there’s an optimization opportunity there. There's likely a helpful index that's missing for the column in the query condition. For the best performance, the query should access as few pages/buffers as possible, which reduces latency, and achieves a faster execution time.

[^michael]: A special thank you to Michael Christofides, founder of [PgMustard](https://www.pgmustard.com), for reviewing earlier drafts of this post.

Thanks for reading!

