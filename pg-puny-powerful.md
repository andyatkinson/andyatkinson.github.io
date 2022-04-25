---
layout: page
permalink: /pg-puny-powerful
title: PostgreSQL Puny to Powerful
---

## Migrations On Busy Databases

### Locking, Blocking, Queueing

* [Lock Queue](https://joinhandshake.com/blog/our-team/postgresql-and-lock-queue/)


## Exhausting Connections

* How many have been idle for a long time?
* Assessing connection usage for application servers and background processes
* High Connections in PgHero. `show max_connections;`


## High Performance SQL


### PgHero


* High impact queries via statistics with `pg_stat_statements`
* Foreign key constraints that are not `VALID`
* High connections


### PgHero Customizations

* Index Bloat Estimated Percentage
* Scheduled Jobs via `pg_cron`

## High Impact Maintenance

* [Routing Reindexing](https://www.postgresql.org/docs/current/routine-reindex.html)
* <https://www.postgresql.org/docs/current/sql-reindex.html>

> It might be worthwhile to reindex periodically just to improve access speed.

* REINDEX requires ACCESS EXCLUSIVE
* Use with CONCURRENTLY option, which requires only a SHARE UPDATE EXCLUSIVE

```
andy@[local]:5432 rideshare_development# reindex index trips_intermediate_rating_idx;
REINDEX
Time: 13.556 ms
andy@[local]:5432 rideshare_development# reindex index concurrently trips_intermediate_rating_idx;
REINDEX
Time: 50.108 ms
```

## Replication and Partitioning


### Multiple Databases Replication Example

* Concrete example with rideshare


### Partitioning Example With List Partitioning

* Concrete example with pgslice
* Record a example video with trips in rideshare
