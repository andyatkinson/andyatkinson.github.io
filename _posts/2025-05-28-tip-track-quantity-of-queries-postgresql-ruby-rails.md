---
layout: post
permalink: /tip-track-sql-queries-quantity-ruby-rails-postgresql
title: 'Tip: Put your Rails app on a SQL Query diet'
featured_image: /assets/images/image-diet.jpg
featured_image_caption: "Vegetables and measuring tape symbolizing healthy eating and dieting, cutting calories or cutting SQL queries!"
tags: [Ruby on Rails, PostgreSQL]
date: 2025-05-29 17:30:00
---

## Introduction
Much of the time taken processing HTTP requests in web apps is processing SQL queries. To minimize that, we want to avoid unnecessary or duplicate queries, and generally perform as few queries as possible.

Think of the work that needs to happen for *every* query. The database engine parses it, creates a query execution plan, executes it, and then sends the response to the client.

When the response reaches the client, there’s even more work to do. The response is transformed into application objects in memory.

How do we see how many queries are being created for our app actions?

## Count the queries
When doing backend work in a web app like Rails, monitor the number of queries being created directly, by the ORM, or by libraries. ORMs like Active Record can generate more than one query from a given line of code. Libraries can generate queries that are problematic and may be unnecessary.

Over time, developers may duplicate queries unknowingly. These are all real causes of unnecessary queries from my work experience.

Why are excessive queries a problem?

## Why reduce the number of queries?
Besides parsing, planning, executing, and serializing the response, the client is subject to a hard upper limit on the number of TCP connections it can send to the database server.

In Postgres that's configured as `max_connections`. The application will have a variable number of open connections based on use, and its configuration of processes, threads and its connection pool. Keeping the query count low helps avoid exceeding the upper limit.

What about memory use?

## What about app server memory?
With Ruby on Rails, the cost of repeated queries is shifted because the [SQL Cache](https://guides.rubyonrails.org/caching_with_rails.html#sql-caching) is enabled by default, which stores and serves results for matching repeated queries, at the cost of some memory use.

As an side, from [Rails 7.1 the SQL Cache uses a least recently used (LRU) algorithm](https://www.shakacode.com/blog/rails-make-active-records-query-cache-an-lru). We can also configure the max number of queries to cache, 100 by default, to control how much memory is used.

## Counting queries prior to Rails 7.2
Prior to Rails 7.2, I recommend adding the [**query_count**](https://github.com/rubysamurai/query_count) gem which does a simple thing, it shows the count of SQL queries processed for an action.

The count is in the Rails log file like this: `SQL Queries: 100 (50 cached)`. In this case, 100 queries were performed and 50 used the SQL Cache.

## Built-in from Rails 7.2 onward
From Rails 7.2 onward, the count of queries is now built in, so [query_count is no longer needed](https://github.com/rubysamurai/query_count/issues/2).

Rails 7.2 onward looks like this: `ActiveRecord: 105.5ms (10 queries, 1 cached)`. Here 10 queries ran, and 1 used the SQL Cache.

## Repeated queries
While the SQL Cache saves the roundtrip for a repeated query, ideally we want to eliminate the repeated query. It’s worth hunting for it and considering refactoring or restructuring data access.

Another tactic is using memoization to store results for the duration of processing one controller action. Read more about that: [Speeding up Rails with Memoization](https://www.honeybadger.io/blog/ruby-rails-memoization/).

How do I get started?

## Finding the source code location of the queries
To get started, identify some slow API endpoints in production, run them locally in development, and begin monitoring their quantity of SQL queries. Find the [Source code locations for database queries in Rails with Marginalia and Query Logs](https://andyatkinson.com/source-code-line-numbers-ruby-on-rails-marginalia-query-logs).

Determine how to factor out data access that can be shared.

## How many queries are "a lot?"
It’s hard to give a generic number. However, duplicate queries are a category to remove.

Let’s say you’ve got a Book model for your bookstore app. Scan your Rails log file for a pattern like this:
```sql
Book Load (4.3ms) …
Book Load (5.0ms) …
Book Load (0.5ms) …
Book Load (2.3ms) …
```

If you see that sort of pattern, track down the source locations, and eliminate any repeated loads. Let's assume this is not a [N + 1 queries problem](https://guides.rubyonrails.org/active_record_querying.html#n-1-queries-problem), but repeated access to the same data from different source code locations.

You may be able to factor out and consolidate a data load. You may be able to use an existing loaded collection for an existence check, or use memoization to use previously calculated results.

Using these tactics, I’ve reduced controller actions with 250+ SQL queries (a ton!) to 50 or fewer (still a lot), by going through these steps. Monitor the log, find source locations for first party code, ORM generated queries, query code from libraries (gems), Rails controller action "before filters," and other sources, then eliminate and consolidate.

When faced with a lot of queries, I find it helpful to study the bare minimum of what's needed by the client, working outside in, then look to see if it's possible to reduce the tables, rows, and columns to only what's needed.

## Wrap Up
- Track the count of SQL queries performed in different versions of Rails
- Remove unnecessary queries so they don't use limited system resources
- Eliminate repeated queries to keep the count as low as possible
- Only access data that's needed for client application use cases
