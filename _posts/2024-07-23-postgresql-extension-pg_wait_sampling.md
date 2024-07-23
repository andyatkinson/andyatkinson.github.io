---
layout: post
title: "Wait a minute! — PostgreSQL extension pg_wait_sampling"
tags: [PostgreSQL]
date: 2024-07-23
comments: true
---

PostgreSQL uses a complex system of locks to balance concurrent read and write operations, with consistent views of data across transactions.

Trade-offs in balancing concurrency with consistency is an inherent part of the MVCC design that PostgreSQL uses. One of the operational problems that can occur as a result, is that queries can block other queries, or queries can get stuck waiting.

In order to understand this in more detail, when queries get stuck waiting, or take a really long time to finish when they’d normally be quick, it’s critical to understand how locks work, and gain visibility into which locks are open, why, and for what purpose.

Fortunately, in PostgreSQL we can access the `pg_waits` and `pg_stat_activity` system catalogs to get that data. Is that enough? What are the shortcomings?

## Knowledge and Observability
When a query is blocked, it’s usually waiting to acquire a lock. What is the query holding the lock? That’s the “blocking” query. Things aren’t that straightforward though. A waiting query and blocking query don’t always form a one to one relationship, but may be part of a complex tree relationship of query data, with multiple levels of blocking and waiting queries.

## Real-time observability
In Postgres, we have “real-time” visibility using `pg_stat_activity`, and `pg_locks`. We can also discover trees of information using these catalogs and well-crafted SQL queries.

We can find queries in a “waiting” state:

```sql
SELECT
    pid,
    wait_event_type,
    wait_event,
    LEFT (query,
        60) AS query,
    backend_start,
    query_start,
    (CURRENT_TIMESTAMP - query_start) AS ago
FROM
    pg_stat_activity
WHERE
    datname = 'rideshare_development';
```

We can look at locks being held via the `pg_locks` system catalog.

Blocking queries SQL:
<https://github.com/andyatkinson/pg_scripts/blob/main/lock_blocking_waiting_pg_locks.sql>

We can combine waiting queries from `pg_waits`, lock acquiring queries via `pg_locks`, with active query information from `pg_stat_activity`. This query joins these three tables together to produce useful results like this.

- `blocked_pid`
- `blocked_user`
- `blocking_pid`
- `blocking_user`
- `blocked_query`
- `blocking_query`
- `blocked_query_start`
- `blocking_query_start`

That's all great information, however there can still be a problem.

When there’s an incident and it’s been resolved, queries are cleared out, we no longer have live activity in `pg_stat_activity`, or live locks to view in `pg_locks`, or waiting queries in `pg_waits`.

How can we discover what happened historically? Another scenario is that in the above examples, we’re looking at a single snapshot of results.

How can we take a broader perspective and look at data across many samples, so that we focus on the most problematic areas?

## Introducing pg_wait_sampling
To solve the need for historical analysis, and for the collection of many samples that we can base an analysis on, the extension `pg_wait_sampling` was created by Alexander Korotkov. This extension can be compiled locally and used, and fortunately has gained wide support from cloud providers.



## Configuring pg_wait_sampling on macOS
1. Compile extension
1. Edit `postgresql.conf` to add the extension to `shared_preload_libraries`
1. Restart Postgres (due to shared preload libraries)
1. Enable extension (via `CREATE EXTENSION` command) from psql, as a superuser (`postgres`)
1. After connecting via psql, change `search_path` to the schema for the extension (`rideshare`)


## Basic Usage of pg_wait_sampling
With the extension enabled, we get access to two views:

- `pg_wait_sampling_profile`
From this view, we get the following fields. The `queryid` field is the same queryid that’s a unique identifier per instance in Postgres that we have available from `pg_stat_statements`.

- `pid`
- `event_type`
- `event`
- `queryid`
- `count`


`pg_wait_sampling_history`

From the sample history, we get these fields:
- `pid`
- `ts` (timestamp)
- `event_type`
- `event`
- `queryid`


## Customization
- `pg_wait_sampling.sample_interval = '10ms'`
- `pg_wait_sampling.history_size = 1000`


## Cloud Support
- AWS RDS [does not list pg_wait_sampling in supported extensions](https://docs.aws.amazon.com/AmazonRDS/latest/PostgreSQLReleaseNotes/postgresql-extensions.html#postgresql-extensions-15x)
- [GCP Cloud SQL](https://cloud.google.com/sql/docs/postgres/extensions) supports it, and without a server restart
- Microsoft Azure Database for PostgreSQL - Flexible Server, [does not list pg_wait_sampling in extensions](https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/concepts-extensions)
- Tembo [supports pg_wait_sampling via trunk](https://pgt.dev/extensions/pg_wait_sampling)

AWS seems to have its own wait event analysis.

## Resources
- Learn more about Alexander on Hacking Postgres: <https://www.youtube.com/watch?v=FrOvwkmAPvg>
- Extension: <https://github.com/postgrespro/pg_wait_sampling>
- Announcement blog post: <https://akorotkov.github.io/blog/2016/03/25/wait_monitoring_9_6/>
