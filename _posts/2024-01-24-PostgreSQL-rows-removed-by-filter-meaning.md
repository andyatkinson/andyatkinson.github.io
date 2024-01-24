---
layout: post
title: "What's the meaning of 'Rows Removed By Filter' in PostgreSQL Query Plans?"
tags: []
date: 2024-01-24
comments: true
---

Recently I was discussing "Rows Removed by Filter" with a team during a training session, and realized I didn’t fully understand it.

Sometimes the values were very sensible, and other times they weren't.

For example, when selecting one row based on a unique column value, the "Rows Removed" figure was "one less" than the total row count. Very sensible. None of the other rows matched the filter condition.

However, for *different* unique values, "Rows Removed" might be "slightly" less, nearly none at all, or something in between.

In the example below, from 20210 total rows, matching one row, we see 20187 were evaluted and discarded. Where does 20187 come from?

![Analyzing Rows Removed by Filter in psql](/assets/images/posts/query-code.jpg)
<small>Analyzing "Rows Removed By Filter" in psql</small>

## Digging Into "Rows Removed"
Here are the details:

- We’re working on a table with 20210 rows
- We queried for a single row, based on a unique column value.
- For all queries, a Sequential Scan was used for filtering. While an index would be useful, we were intentionally not using one here.
- All data was accessed from shared buffers, confirmed by prepending `EXPLAIN (ANALYZE, BUFFERS)` to queries.
- All queries specified a `LIMIT 1`. We weren't treating the data like it was unique, so we added this limit because we needed just one match.

The difference was that for some column values, nearly *all* rows were processed and discarded, while for other values *hardly any* needed to be processed before a match was found.

This was an "early match", and seems to be correlated with insertion order for the records.

By prepending `EXPLAIN (ANALYZE, BUFFERS)` onto the query, when early matches happened, we also saw fewer buffers were accessed. By accessing less data, there was less latency and better lower execution time.

See: [EXPLAIN (ANALYZE) needs BUFFERS to improve the Postgres query optimization process](https://postgres.ai/blog/20220106-explain-analyze-needs-buffers-to-improve-the-postgres-query-optimization-process)

## Additional information about "Rows removed by filter"
Is this figure an exact value? Well, it could be.

PgMustard describes it thusly: <https://www.pgmustard.com/docs/explain/rows-removed-by-filter>

> This is a per-loop average.

What does this mean? If more than one loop was used for the plan node (`loops=2` or more), our plan node was a Seq Scan, then the "Rows Removed" is an average among the loops.

For example in one loop if 10 rows were removed, then 30 in a second, we'd expect to see 20 as an average of the two loops.

However, when there’s one loop (`loops=1`), then the figure is an average of one loop, or in other words should be the exact number of rows that were processed and discarded.

## Other Tidbits
- The PostgreSQL documentation explains that "rows removed by filter" appears only when `ANALYZE` is added to `EXPLAIN`. When `EXPLAIN` is used on it’s own, we see a plan estimate and no "Rows Removed" information.
- Rows Removed Applies for filter conditions like a `WHERE` clause, but can also be added for conditions on a `JOIN` node
- Rows Removed information appears when *at least one row is scanned for evaluation*, or a "potential join pair" (for join nodes) when rows were discarded by the filter condition

## Takeaways
- For Sequential Scans when a `LIMIT 1` is used, Rows Removed *may* equal "one less" than the total row count, or it may not. You'll need to look at the access method, whether the query has a limit, and there may be an "early" match resulting in less "Rows Removed" than expected.
- When viewing "Rows Removed," check whether the plan node had more than one loop. When there’s more than one loop, the number that’s returned is an average among all the loops.
- When working on performance optimization, a high amount of rows removed indicates an optimization opportunity. There's likely a helpful index, or an index could be made more selective using an expression. Generally the goal is to access fewer pages/buffers, resulting in less latency, achieving a faster execution time.

Thanks for reading!
