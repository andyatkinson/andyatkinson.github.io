---
layout: post
title: "#PGSQLPhriday 008 - pg_stat_statements and PgHero"
tags: [PostgreSQL, Rails, Open Source]
date: 2023-05-17
comments: true
---

I’m late to the party, but I wanted to sneak in a `pg_stat_statements` #PGSQLPhriday entry into this community blog post series.

In this post I’ll explain why I like `pg_stat_statements` and PgHero, and hope to convince you to try them!


## Outline

- Intro
- Setup and Restart
- Parameters
- PgHero
- Computing a Query ID
- Query ID and 14
- Wrap Up

## Intro

`pg_stat_statements` is a PostgreSQL extension that captures query statistics. Instead of specific queries with parameters they are normalized, which means parameters are removed.

Each normalized query gets a Query ID. Queries that have the same structure, but with different parameters get the same Query ID.

This means you can move your analysis to the query ID (aka "query group" or "normalized query") level, increasing the impact of query optimization efforts that target that group of queries.

With statistics like total calls and the average duration, the queries that are larger contributors to poor performance will stand out.

Check out this [Postgres.fm episode on `pg_stat_statements`](https://postgres.fm/episodes/pg_stat_statements) for more background and context.

Now that you know a little about the extension, how do you install it and configure it?

## Setup and Restart

The post won’t go into the full details. Check out the official docs[^1] if you're self-hosting PostgreSQL or check out docs from your cloud provider.

AWS has a nice video called [How do I implement Postgres extensions in Amazon Relational Database Service for PostgreSQL?](https://www.youtube.com/watch?v=INx8VGGfGGU) that shows how to set up `pg_stat_statements` on AWS RDS.

You’ll add the extension to `shared_preload_libraries`, confirm it's enabled with the `\dx` meta command. Enable it for each database where you want it to collect statistics. To do that, run `create extension pg_stat_statements;` in each database.

Query the captured query stats using a client like `psql`. Take a look at the [Top 10 Worst Queries](https://github.com/andyatkinson/pg_scripts/blob/master/list_10_worst_queries.sql).

While that works well individually, on a team I recommend setting up tooling so the whole team can access this info more easily.

For that I recommend [PgHero](/blog/2022/10/04/pghero-3). PgHero has a nice presentation of Query Stats that will help your team have a shared view of slow queries. This shared perspective can help make collaboration faster and easier.

`pg_stat_statements` (or PGSS) can be tuned a bit as well. What are the tuning parameters?


## Parameters

PGSS lets you configure how many statements you’ll be capturing. You can dial it up or dial it back depending on your needs.

Check out a param like [`pg_stat_statements.track`](https://www.postgresql.org/docs/current/pgstatstatements.html) which has a default value of `top` for example.

```
pg_stat_statements.track (enum)
```

Now you know PgHero can display PGSS stats. What's that look like?

## PgHero

With PGSS enabled and PgHero connected to your database, you’ll now get Query Statistics visible in the Queries tab.

PostgreSQL makes a view called `pg_stat_statements` available and PgHero queries it and copies stats into tables it controls.

PgHero presents this data using a web application UI.

PgHero is a Rails Engine and is available as a Ruby gem. And if you don’t have a Rails app to run it with as a gem, you can run it as a Docker container in your container based deployment.

For Rails developers, as a Rails Engine it means PgHero is structured in a familiar way to the Rails app you’re already running, making it easier to modify the code.

The creator Andrew Kane is a great creator and maintainer of the project. Open an Issue or PR to discuss your proposed changes to PgHero, or run your changes on a forked version at your company.

Where I work, we’re running a fork with a couple of small changes that I felt were useful but didn’t make it back to the main project.

Next, let’s dive in to the Query ID attribute.

## Computing a Query ID

Since PostgreSQL 14, a new option `compute_query_id` can be enabled in your config file.

[`compute_query_id`](https://postgresqlco.nf/doc/en/param/compute_query_id/) needs to be set to `auto` or `on`.

While the Query ID has been available in PGSS since earlier versions, it's now available in `pg_stat_activity` and the PostgreSQL log file as well.

Configure these tools to correlate a PGSS Query ID and a Query ID to the activity view or a specific query sample from your logs.

Now that you know a little about the Query ID and PGSS, and that it’s useful elsewhere like in logs, how would you set that up?

## Query ID and 14

In the post [Using Query ID in Postgres 14](https://blog.rustprooflabs.com/2021/10/postgres-14-query-id), the author shows how you can connect the Query ID from PGSS to a production query from the `postgresql.log` .

The query text is the full text of the query including the specific parameters. Any variations of the query that are the same structure but with different parameters, will also have the same Query ID. Searching the log then for the Query ID, you’re able to collect real samples with parameters.

This requires PostgreSQL 14 and the `compute_query_id` parameter set to `on`.

Once that’s `on`, the author shows how to use `log_line_prefix` to print the query ID.

Use the fragment `query_id=%Q` where `%Q` is the Query ID.

You probably need to enable `log_duration` as well. I wasn’t able to figure out how to log the Query ID without the `log_duration` enabled.

With that in place, you can now follow this workflow.

- Get the Query ID from PGSS for a slow query group you wish to optimize
- Log the `query_id` in the postgres.log using `log_line_prefix`, `%Q`
- Grep or search the log file to find matching log file entries for the Query ID. The query text will probably be on the next line and not on the same line unfortunately.
- Once you've collected a sample with parameters, get the execution plan with `EXPLAIN (ANALYZE, VERBOSE)`

Confirm the same Query ID is printed in the execution plan. Note that the `VERBOSE` argument *is required*.

Michael from Postgres.fm and pgMustard pointed out improvements coming in PostgreSQL 16 with `auto_explain` and Query ID in the following post. [PostgreSQL: Record queryid when auto_explain.log_verbose is on](https://www.postgresql.org/message-id/flat/1ea21936981f161bccfce05765c03bee@oss.nttdata.com).

With `auto_explain` and the `log_verbose` option, logged query execution plans will also include the Query ID.

This will make it even easier to connect the Query ID from PGSS to execution plans generated from full query text samples with parameters.

## Wrap Up

There you have it. Let’s recap briefly.

- `pg_stat_statements` is a useful extension and I recommend enabling it for every production database you work with
- You can query the normalized queries it captures (or "query groups" as Nikolay says in the [`pg_stat_statements` Postgres.fm episode](https://postgres.fm/episodes/pg_stat_statements)) using SQL, or you can use PgHero to present the Query Stats. PgHero can make this data easier to share on teams.
- PgHero is a Rails Engine. It’s open source, and organized like your Rails app, Consider running it and making modifications to it based on the needs at your company. The needs you have may be useful enough that the main project accepts a PR with your changes.
- From a Query ID in PGSS, you can find samples in production logs from version 14. You’ll need to configure `compute_query_id`, `log_duration`, and `log_line_prefix` and it’s a little bit of work and still kind of choppy, but you’ll get good query performance visibility once it's all configured.

Thanks for reading!

[^1]: `pg_stat_statements` <https://www.postgresql.org/docs/current/pgstatstatements.html>
