---
layout: post
permalink: /tip-track-sql-queries-quantity-ruby-rails-postgresql
title: 'Tip: Track Quantity of SQL Queries with Ruby on Rails'
---

## Introduction
A big proportion of the time taken processing an HTTP request by a web app is time spent processing SQL queries. We don’t want unnecessary or duplicate queries, which slow things down unnecessarily. Think of the work that needs to happen for any query. The database engine needs to parse the incoming client query, create a query execution plan from that, execute it, and finally send the response to the client.

When the database response reaches the client application, there’s even more work to do. The application transforms the response into application objects as instances in memory.

Related to the quantity of queries, besides the queries themselves being efficient, we want as few of the queries as possible. How do we see how many we have? 

## Count the queries
When doing backend work in a web app like Rails, monitor the number of queries being created directly, by the ORM, or by libraries. ORMs like Active Record can generate more than one query from a given line of code. Libraries can generate queries that are unexpected and problematic, like count queries for pagination. Over time, developers may end up duplicating queries unknowingly. These are all possible causes of duplicate or unnecessary queries.

Why are excessive queries a problem?

## Why reduce the number of queries?
Besides parsing, planning, executing, and serializing the response, the application has a hard limit on the number of concurrent TCP connections between the Rails app and database server that can be used at the same time.

In Postgres that's configured on the DB side as `max_connections`. The application will have a variable number of connections open concurrently based on load, and how the processes and threads and connection pool is configured. However, it's a limited upper cap, so keeping query count low helps avoid exceeding the cap.

What about memory use?

## What about app server memory?
With Ruby on Rails, repeated queries can use the [SQL Cache](https://guides.rubyonrails.org/caching_with_rails.html#sql-caching), enabled by default, to use an existing calculated response instead of sending the query. From [Rails 7.1 the SQL Cache uses a least recently used (LRU) algorithm](https://www.shakacode.com/blog/rails-make-active-records-query-cache-an-lru). We can also configure the max number of queries to cache, 100 by default, to control how much memory is used.

## Counting queries prior to Rails 7.2
Prior to Rails 7.2, I recommend adding the [*query_count*](https://github.com/rubysamurai/query_count) gem which does a simple thing, it shows the quantity of SQL queries processed for an action.

The quantity is reported like this: `SQL Queries: 100 (50 cached)`. In this case 100 queries were performed and 50 used the SQL Cache.

## Built-in from Rails 7.2 onward
From Rails 7.2 onward, the count of queries is now built in, so [query_count is no longer needed](https://github.com/rubysamurai/query_count/issues/2).

The quantity of queries for an action is reported like this from Rails 7.2 onward: `ActiveRecord: 105.5ms (10 queries, 1 cached)`.

## Repeated queries
While the SQL Cache means the cycle time of a repeated query was avoided, this also means there’s a repeated query that could be removed. It’s worth hunting for the repeated query and trying to eliminate it. This could involve restructuring the code to factor out common data access.

Another tactic is using memoization to store results that are reused, for the duration of processing one controller action. <https://www.honeybadger.io/blog/ruby-rails-memoization/>

How do I get started?

## Finding the source code location of the queries
To get started, identify some slow API endpoints in production, run them locally in development, and begin monitoring their quantity of SQL queries. Track down the source code location where the queries originate:
<https://andyatkinson.com/source-code-line-numbers-ruby-on-rails-marginalia-query-logs>

## How many are a lot?
It’s hard to give a generic number. However, duplicate queries are a category to remove. Let’s say you’ve got a Book model for your bookstore app. Scan your Rails log file for a pattern like this:
```sql
Book Load (4.3ms) …
Book Load (5.0ms) …
Book Load (0.5ms) …
Book Load (2.3ms) …
```

If you see that sort of pattern, track down the source locations, and eliminate any repeated loads. You may be able to factor out and consolidate a data load. You may be able to use an existing loaded collection for an existence check, or use memoization to use previously calculated results.

Using these tactics, I’ve worked on controller actions that started with 250+ SQL queries (a ton!) and finished with 50 or fewer queries (still a lot), by monitoring the log, finding source locations for direct code, ORM generated queries, query code from libraries (gems), Rails controller action "before filters," and other sources, then looking to eliminate and consolidate.

When faced with a lot of queries, I find it helpful to study the bare minimum of what's needed by the client, then look to see if the queries can be cut down to load only the rows and columns needed, as they may often be scanning or accessing tables, rows, and columns beyond what's needed.

## Wrap Up
- Track the quantity of SQL queries performed
- Remove or consolidate unnecessary queries so they don't waste limited resources like connections or system memory
- Eliminate repeated queries to keep the count as low as possible
- Only access data needed by the client application use cases
