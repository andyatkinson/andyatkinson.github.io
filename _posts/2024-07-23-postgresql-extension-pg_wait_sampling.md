---
layout: post
title: "Wait a minute! — PostgreSQL extension pg_wait_sampling"
tags: [PostgreSQL]
date: 2024-07-23
comments: true
---

PostgreSQL uses a complex system of locks to balance concurrent operations and data consistency, across many transactions. Those intricacies are beyond the scope of this post. Here we want to specifically look at queries that are waiting, whether on locks or for other resources, and learn how to get more insights about why.

Balancing concurrency with consistency is an inherent part of the [MVCC](https://www.postgresql.org/docs/current/mvcc.html) system that PostgreSQL uses. One of the operational problems that can occur with this system, is that queries get blocked waiting to acquire a lock, and that wait time can be excessive, causing errors.

In order to understand what's happening with near real-time visibility, PostgreSQL provides system views like `pg_locks` and `pg_stat_activity` that can be queried to see what is currently executing. Is that level of visibility enough? If not, what other opportunities are there?

## Knowledge and Observability
When a query is blocked and waiting to acquire a lock, we usually want to get more information when debugging.

The query holding the lock is the "blocking" query. A waiting query and a blocking query don’t always form a one-to-one relationship though. There may be multiple levels of blocking and waiting.

## Real-time observability
In Postgres, we have "real-time" visibility using `pg_stat_activity`.

We can find queries in a "waiting" state:

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

We can combine that information with lock information from the `pg_locks` catalog.

Combining lock information from `pg_locks` and active query information from `pg_stat_activity` becomes powerful. The query below joins these sources together.

<https://github.com/andyatkinson/pg_scripts/blob/main/lock_blocking_waiting_pg_locks.sql>

The result row fields include:
- `blocked_pid`
- `blocked_user`
- `blocking_pid`
- `blocking_user`
- `blocked_query`
- `blocking_query`
- `blocked_query_start`
- `blocking_query_start`

That's great information, however there can still be a problem.

When there’s an incident and after it’s resolved, queries get cleared out and we no longer have historical information, since what we looked at in `pg_stat_activity` and `pg_locks` was live information.

How can we explore historical context? Or, how can we broaden our searches to include many samples and not just a single sample?

## Introducing pg_wait_sampling
To solve the need for historical analysis, and for the collection of many samples, the extension `pg_wait_sampling` was created by Alexander Korotkov to solve these problems.


## Configuring pg_wait_sampling on macOS
1. Compile extension following instructions on [GitHub postgrespro/pg_wait_sampling](https://github.com/postgrespro/pg_wait_sampling)
1. Edit `postgresql.conf` to add the extension to `shared_preload_libraries`
1. Restart Postgres (due to shared preload libraries)
1. Enable extension (via `CREATE EXTENSION` command) from psql, as a superuser (`postgres`)
1. After connecting via psql, change `search_path` to the schema for the extension (`rideshare`)


## Basic Usage of pg_wait_sampling
With the extension enabled, we get access to two views:

From the view `pg_wait_sampling_profile` we get the following fields. The `queryid` field is the same queryid that’s a unique identifier per instance in Postgres that we have available from `pg_stat_statements`.

- `pid`
- `event_type`
- `event`
- `queryid`
- `count`

Here are fields we get in the `pg_wait_sampling_history`:
- `pid`
- `ts` (timestamp)
- `event_type`
- `event`
- `queryid`


## Customization
<https://postgrespro.com/docs/enterprise/9.6/pg-wait-sampling>
- `pg_wait_sampling.profile_period= '10ms'`
- `pg_wait_sampling.history_size = 1000`


## Cloud Support
- [GCP Cloud SQL](https://cloud.google.com/sql/docs/postgres/extensions) supports it, and without a server restart
- Tembo [supports pg_wait_sampling via trunk](https://pgt.dev/extensions/pg_wait_sampling)
- AWS RDS [does not list pg_wait_sampling in supported extensions](https://docs.aws.amazon.com/AmazonRDS/latest/PostgreSQLReleaseNotes/postgresql-extensions.html#postgresql-extensions-15x)
- Microsoft Azure Database for PostgreSQL - Flexible Server, [does not list pg_wait_sampling in extensions](https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/concepts-extensions)

AWS seems to have its own wait event analysis.

## Resources
- Learn more about Alexander on Hacking Postgres: <https://www.youtube.com/watch?v=FrOvwkmAPvg>
- Extension: <https://github.com/postgrespro/pg_wait_sampling>
- Announcement blog post: <https://akorotkov.github.io/blog/2016/03/25/wait_monitoring_9_6/>
- [Exploring Query Locks in Postgres](https://big-elephants.com/2013-09/exploring-query-locks-in-postgres/)
- `pg_blocking_pids()` <https://pgpedia.info/p/pg_blocking_pids.html>
- [Postgres.fm Wait events episode](https://postgres.fm/episodes/wait-events)

## Wrap Up
This post was meant to describe the problem pg_wait_sampling solves, how to install it for macOS and begin exploring the information. In a future post, we may use pg_wait_sampling as part of a concurrency/blocking query analysis and investigation. Stay tuned.

Thanks for reading!
