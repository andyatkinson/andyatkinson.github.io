---
layout: post
title: "#PGSQLPhriday 008 - pg_stat_statements, PgHero, Query ID"
tags: [PostgreSQL, Rails, Open Source]
date: 2023-05-17
comments: true
---

I’m late to the party, but I wanted to sneak in a #PGSQLPhriday entry for this community blog post series because I'm a fan of this topic.

In this post I’ll share my experience and recommendations for `pg_stat_statements`, PgHero, and the Query ID.

## Outline

- Intro
- Setup and Restart
- Parameters
- PgHero
- Computing a Query ID
- Query ID and 14
- Wrap Up

## Intro

`pg_stat_statements` is a PostgreSQL extension that provides query statistics. You can use these statistics to better understand your query workload, including identifying slow queries.

Statistics are collected for normalized forms of queries within a group. With specific query parameters removed, a normalized form with a unique Query ID is stored, and statistics for queries that fall into this group include the total number of calls, the duration, and more.

What does this mean for query performance analysis?

This means your analysis can move to the Query ID or normalized query level, instead of at the level of specific instances of a query within that group.

Improving the performance of an entire "group" of queries increases the impact of your optimization efforts!

Some of the statistics collected are total calls and average duration. Queries that are larger contributors to poor performance will stand out.

Check out this [Postgres.fm episode on `pg_stat_statements`](https://postgres.fm/episodes/pg_stat_statements) for more information.

Now that you know a little about the PGSS extension, and the Query ID, how can you install and configure this extension to get started?

## Setup and Restart

You'll want to check out the official docs[^1] if you're self-hosting PostgreSQL or check out docs from your cloud provider.

AWS has a nice video called [How do I implement Postgres extensions in Amazon Relational Database Service for PostgreSQL?](https://www.youtube.com/watch?v=INx8VGGfGGU) that shows how to set up `pg_stat_statements` on AWS RDS.

You’ll add the extension to `shared_preload_libraries`, confirm it's enabled with the `\dx` meta command, and enable it for each database where you want to collect statistics.

To enable it, run `create extension pg_stat_statements;`.

Query the captured stats using a client like `psql`. Take a look at your [Top 10 Worst Queries](https://github.com/andyatkinson/pg_scripts/blob/master/list_10_worst_queries.sql).

While that process works well for individuals that know where to look, and how to query the information, on a team I recommend adding a tool that makes this process easier.

For that tooling I recommend [PgHero](/blog/2022/10/04/pghero-3). PgHero has a nice presentation of Query Stats that can help your team have a shared view of all queries, including slow queries. This can make collaboration faster and easier.

## PgHero

With PGSS enabled and PgHero connected to your database, Query Statistics are now visible in the Queries tab.

PgHero is a Rails Engine and is available as a Ruby gem or in a Docker container.

For Rails developers, the code structure of PgHero is familiar since it's a Rails Engine.

Creator [Andrew Kane](https://github.com/ankane) is a great maintainer of the project. Open an Issue or PR to discuss your proposed changes to PgHero, or run your changes on a fork.

Where I work, we’re running a fork with a couple of small changes that I felt were useful but didn’t make it back to the main project.

Next, let’s dive in to the Query ID attribute.

## Computing a Query ID

Since PostgreSQL 14, enable `compute_query_id` to compute a Query ID.

Set [`compute_query_id`](https://postgresqlco.nf/doc/en/param/compute_query_id/) to `auto` or `on`.

While a Query ID was available in earlier versions with PGSS, it's now available in more places like `pg_stat_activity` and the PostgreSQL log.

Configure these tools so that you can connect a PGSS Query ID with a sample from your log file or in your activity view.

How would you set that up?

## Query ID and 14

In the post [Using Query ID in Postgres 14](https://blog.rustprooflabs.com/2021/10/postgres-14-query-id), the author shows how to connect the Query ID from PGSS to query text logged in the `postgresql.log` .

The query text is the full text of the query including the specific parameters. Any variations of the query with the same structure but different parameters will have the same Query ID.

With `compute_query_id` set to `on`, the author shows how to use `log_line_prefix` to print the query ID.

Use the fragment `query_id=%Q` where `%Q` is the Query ID.

You probably need to enable `log_duration` as well. I wasn’t able to log the Query ID without `log_duration` enabled.

With that in place, you can now follow this workflow.

- Get the Query ID from PGSS for a slow query group you wish to optimize
- Log the `query_id` using `log_line_prefix`, `%Q`
- Search the log file to find matches by Query ID. The query text will probably be on the next line and not on the same line.
- Once you've collected a query text sample with parameters, get the execution plan manually with `EXPLAIN (ANALYZE, VERBOSE)`

Michael from pgMustard pointed out improvements coming to PostgreSQL 16, where `auto_explain.log_verbose` will include the Query ID. See: [PostgreSQL: Record queryid when auto_explain.log_verbose is on](https://www.postgresql.org/message-id/flat/1ea21936981f161bccfce05765c03bee@oss.nttdata.com).

This will make it even easier to connect the Query ID from PGSS to samples from the log, and even their execution plans logged automatically with `auto_explain`.

## Wrap Up

There you have it. Let’s recap.

- `pg_stat_statements` is a useful extension. I recommend enabling it for every database you work with.
- Query the normalized queries and statistics captured using a client, or consider using PgHero to present this data to a team.
- Configure `compute_query_id`, `log_duration`, and `log_line_prefix`.
- From a Query ID in PGSS, find matching Query ID values for samples of queries with text and parameters from logs starting in Version 14.

Thanks for reading!

[^1]: `pg_stat_statements` <https://www.postgresql.org/docs/current/pgstatstatements.html>
