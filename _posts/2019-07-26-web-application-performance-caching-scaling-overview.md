---
layout: post
title: "Web Application Performance, Caching, and Scaling"
tags: [Tips, Programming, Ruby, Rails, Performance, Open Source, Databases]
date: 2019-07-26
comments: true
---

This post describes various strategies to improve performance for web applications. They were written from experience with Ruby on Rails web apps, but are general techniques for other languages and frameworks. This is not a comprehensive list, but an overview of some techniques from my real world experience. Let's dive in!

## Add Missing Indexes
The first improvement to experiment with for slow database queries would be to look for missing database indexes and add them. First, find slow queries and then for Postgres look at the “Indexes” section at the bottom of the table information `\d tablename` for all tables involved in the query.

Get the SQL query text of the query, then use `EXPLAIN (ANALYZE)` (with PostgreSQL) in front of the query text to view the execution plan, and confirm whether the indexes on the tables are being used or not. If working from a list of queries, focus on the slowest executing queries first, and study their execution plans.

In the Rails development environment, [enable slow query logging in PostgreSQL](https://www.heatware.net/databases/how-to-find-log-slow-queries-postgresql/) [^slow]. In the production environment, gather this data from application performance monitoring (APM) tools like [New Relic](https://newrelic.com/) or slow query logs or database telemetry tools. Adding a missing index can be enough of an improvement in the short term and has the benefit of not requiring application code changes.

## Write Better Queries
This Ruby on Rails 365 Guide [^guide] goes into nice detail on query optimization, but I’ll cover a couple of items here. Use Active Record methods like `find_each` when working with large collections to load a batch of results (the default size is 1000 records). Another tactic is to explicitly list model attributes (which map to database fields) when querying, instead of relying on `SELECT *` queries that select all fields. This can improve performance by reducing data access and may better use indexes.

## Use SQL Caching
[SQL Caching](https://guides.rubyonrails.org/caching_with_rails.html#sql-caching) is built-in to Active Record and is often used without the programmer explicitly needing to configure it. SQL Caching stores the result of a database query in memory, then serves the result again from there when the same query is detected. Keep in mind the availability of this memory cache is only for the life of the request.

> Query caches are created at the start of an action and destroyed at the end of that action and thus persist only for the duration of the action. <cite>Rails Guides</cite>

## Use View Layer Caching
While server-rendered HTML is becoming less popular due to the rise of client-side HTML and rendering, for web applications that use Ruby on Rails and generate HTML on the backend, these HTML fragments are cacheable.

In [Caching with Rails: An Overview](https://guides.rubyonrails.org/caching_with_rails.html), this guide demonstrates how to set up HTTP caching and use the options. To store cache data, teams I’ve worked on have used [Memcached](https://memcached.org/) or [Redis](https://redis.io) for this purpose.

One trick to consider is whether your template can live in cache longer by being "de-personalized." Depersonalization of a template involves removing any user-specific or “personal” data, so that it can be reused for all users. This makes it more cacheable.

Another concept is nesting `cache` blocks within other cache blocks. In Ruby on Rails and Active Record, this is usually referred to as [Russian Doll Caching](https://guides.rubyonrails.org/caching_with_rails.html#russian-doll-caching), and is a tactic to study and use.

## Model Layer Caching
Another caching solution that’s different from the view layer, is to cache at the model layer.

A Model Layer Cache could be built manually for a single model. This Sitepoint article[^1] demonstrates reading and writing to a cache layer for article categories, and building it manually. One downside with this type of cache store is that the view code has to access the data differently depending on whether it’s in the cache or not.

## Denormalization of Data
With a SQL database design, individual models and tables are typically designed for *High Cohesion* [^2] and minimize duplication, each storing their data in a separate table, and relying on queries to use JOINs to bring the data together.

For a "blog" or "portfolio" web application, we might expect to see queries for tables like `users`, `posts`, `pages`, `comments`, `tags`, `uploads` and more, even for a single user-facing page or experience.

> If you’re trying to return a long list of objects that are built up from five, ten or even seventeen related tables your response times can be unacceptably slow. <cite>MultiThreaded Stitch Fix Blog</cite>

If adding indexes and other forms of caching are not enough, consider denormalization of the data into a new data structure that’s optimized for reading data, by bundling it all together. This does have a trade-off of requiring more duplication of data.

At LivingSocial, a denormalization solution was built that involved a minimal representation of Active Record objects and their attributes, with fields and values pushed into Redis periodically, then the denormalized structure was read from Redis without any SQL JOIN operations.

The MultiThreaded Stitch Fix describes a similar solution in a post titled [ElasticSearch and Denormalization in Rails](https://multithreaded.stitchfix.com/blog/2015/02/25/elasticsearch-and-denormalization/).

The Stitch Fix post describes a `Denormalizer` object. The Denormalizer works with 2 or more objects that return their queryable fields as a Hash. The Denormalizer is included in model's `#to_hash` instance method, which is expected by `Elasticsearch::Model` (included in the Active Record model) as the data source, and is then converted into JSON to populate Elasticsearch's search index.

Finally, this index is queried from the controller layer using Elasticsearch's `.search` method, and fields are accessed in the view layer (with some help from `method_missing` [^3]). This allows the attribute data to be accessed the same way whether it’s coming from Elasticsearch or Active Record. Slick!

## Use Database Replicas and Sharding
Consider relocating particular tables to a separate writable database to reduce contention and activity on your current primary database. If the maximum number of connections the database can serve reliably are exceeded, then shifting some connections over to a replica for read only queries, or introducing a connection pooler (or better using the Active Record connection pool) could help. Some gems work looking into are [db-charmer](https://github.com/kovyrin/db-charmer) or [ar-octopus](https://github.com/thiagopradi/octopus) for working with multiple databases. (Update: In newer versions of Ruby on Rails, Multiple Databases support is now a native capability)

With replication, all write queries are still performed on the primary database, but read queries can be shifted to one or more secondary follower databases.

## General Performance Tips
* When debugging performance problems locally, I have found that using the [New Relic Ruby Agent](https://github.com/newrelic/rpm) gem in my local development environment to be very useful.
* Bonus Tip: Enable `config.cache_classes` option so that the `show fields` queries are not generated by Active Record after the initial request.
* Look for opportunities to perform "eager loading" and to eliminate "N+1" queries. For Ruby on Rails, we've used the [Bullet gem](https://github.com/flyerhzm/bullet) to help find N+1 queries.
* Look for opportunities to calculate and publish content outside of the user’s request. Some typical candidates are report generation, sending emails or notifications, interacting with third party APIs, or populating caches. We have used [Sidekiq](https://sidekiq.org/) heavily to process millions of jobs offline.

Thanks for reading!

Last updated: Light edits, April 2025

[^1]: [Rails Model Caching with Redis](https://www.sitepoint.com/rails-model-caching-redis/)
[^2]: [Wikipedia: Cohesion (computer science)](https://en.wikipedia.org/wiki/Cohesion_(computer_science))
[^3]: [Ruby `#method_missing` documentation](https://ruby-doc.org/core-2.6.3/BasicObject.html#method-i-method_missing)
[^slow]: Set `log_min_duration_statement` to `100` in the PostgreSQL config file to view queries that take longer than 100ms
[^guide]: [Low hanging fruits for better SQL performance in Rails](http://www.rubyonrails365.com/low-hanging-fruits-for-better-sql-performance-in-rails/)
