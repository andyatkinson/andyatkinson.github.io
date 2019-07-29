---
layout: post
title: "Web Application Performance, Caching, and Scaling"
tags: [Tips, Programming, Ruby, Rails, Performance, Open Source, Databases]
date: 2019-07-26
comments: true
---

This post describes some strategies to help address performance problems in web applications. They were written with Ruby on Rails in mind, but are general techniques that can be applied to other language and framework environments. This is not a comprehensive list, but an overview of some techniques I have used in my real world experience. Let's dive in!

#### Add Indexes

The first improvement to experiment with for slow database queries, might be to add an index to fields being queried. Find slow queries and then look at the `Indexes` section at the bottom of the table information `\d tablename` and then use `explain analyze` (PostgreSQL) to confirm the index is being used. Start working on the slowest queries first. In development [enable slow query logging in PostgreSQL](https://www.heatware.net/databases/how-to-find-log-slow-queries-postgresql/) [^slow] or in production gather this data from a performance monitoring application like [New Relic](https://newrelic.com/). Adding an index to a search query may be enough of an improvement in the short term.

#### Better Queries

This Ruby on Rails 365 Guide [^guide] goes into nice detail, but to briefly summarize, using methods like `find_each` to load a batch (default size is 1000 records) of records at once and explicitly listing fields being queried instead of `select *` will perform better.

#### SQL Caching

[SQL Caching](https://guides.rubyonrails.org/caching_with_rails.html#sql-caching) is built in to Rails. It caches the result set of each query, so if the same query is made, the result can be pulled from memory instead of being executed again. One thing to keep in mind is the life of the query cache though.

> Query caches are created at the start of an action and destroyed at the end of that action and thus persist only for the duration of the action. <cite>Rails Guides</cite>

#### View Layer Caching

Server-rendered HTML is becoming less popular (with the rise of client-side HTML), however for web applications that generate HTML, why not stick the generated HTML into a cache store? [Caching with Rails: An Overview](https://guides.rubyonrails.org/caching_with_rails.html) demonstrates how to set this up and various options. We have used both [Memcached](https://memcached.org/) and [Redis](https://redis.io) for this purpose.

One trick to consider is whether your template can live in cache longer by being "de-personalized". Depersonalization involves removing any user-specific data from the template, which would then be added back in after page load.

When there are `cache` blocks within blocks, this has been referred to as [Russian Doll Caching](https://guides.rubyonrails.org/caching_with_rails.html#russian-doll-caching).


#### Model Layer Caching

This is a lower level caching solution compared with view layer caching. And of course it also comes with more complexity to administer, and needs to make sense for the business goals for how long stale data can be served acceptably.

A Model Layer Cache could be built manually for a single model. This Sitepoint article [^1] demonstrates reading and writing to a cache layer for article categories, and building it manually. One downside is the view has to access the data differently depending on where it comes from. However, reading the category data from Redis completely eliminates the database query.


#### Denormalization of Data

Individual models and tables are typically designed for *High Cohesion* [^2] which means that features of an application will typically involve many models collaborating together in order to produce a meaningful result.

For example, in a "blog" or "portfolio" application, in order to render all the content for a particular user, it might involve querying tables like `users`, `posts`, `pages`, `comments`, `tags`, `uploads` and more for a single page of content in the app.

> If you’re trying to return a long list of objects that are built up from five, ten or even seventeen related tables your response times can be unacceptably slow. <cite>MultiThreaded Stitch Fix Blog</cite>

If adding indexes and other forms of caching are not enough, an alternative would be to denormalize this data into a new data structure that is optimized for read speed, in other words, requires a single "read" operation to fetch all the user's content at once (or uses a pre-built index). 

At LivingSocial, a solution was built to implement this idea, which involved a minimal representation of Active Record objects and their attributes, with fields and values pushed into Redis periodically.

A design goal of this approach was that the code accessing the fields worked the same whether the object was coming from Active Record or the cache store. Field values were periodically republished via cron, typically after 5 minutes, so stale data may be served for up to 5 minutes.

The MultiThreaded Stitch Fix describes a similar solution in a post titled [ElasticSearch and Denormalization in Rails](https://multithreaded.stitchfix.com/blog/2015/02/25/elasticsearch-and-denormalization/).

The Stitch Fix post describes the concept of a `Denormalizer` object. The Denormalizer collaborates with 2 or more objects that have been configured to return their queryable fields as a Hash. The Denormalizer is used in the model as the implementation for the model's `#to_hash` instance method, which is expected by `Elasticsearch::Model` (included in the Active Record model) as the data source, which is then converted into JSON to populate Elasticsearch's search index. Finally, this index is queried from the controller layer using Elasticsearch's `.search` method, and fields are accessed in the view layer (with some help from `method_missing` [^3]) the same way, whether they're coming from Elasticsearch or Active Record. Slick!

#### Database Replicas and Sharding

Consider relocating particular tables to separate databases to reduce contention. If the maximum number of connections are being exceeded, a replica with its own connection pool could help. Some gems that might help would be [db-charmer](https://github.com/kovyrin/db-charmer) or [ar-octopus](https://github.com/thiagopradi/octopus).

With replication, all write queries could be sent to one database, and read queries from another.

A simple sharding approach might be based on the IDs of the objects. A model could be configured to belong to a particular shard, and queries for that model would execute against the appropriate shard. [db-charmer](https://kovyrin.github.io/db-charmer/) has some nice examples of sharding.

#### General Tips

* When debugging performance problems locally, I have found it useful to run the [New Relic Ruby Agent](https://github.com/newrelic/rpm) in my development environment.

  * Bonus Tip: Enable `config.cache_classes` option so that the `show fields` queries are not generated by Active Record after the initial request. (Or try to run your app in production mode if possible)

* Look for opportunities to perform "eager loading" and to eliminate "n+1" queries. For Ruby on Rails, we've used the [Bullet gem](https://github.com/flyerhzm/bullet) to help find N+1 queries.

* Look for opportunities to calculate and publish content offline. Some typical examples would be sending reports or transactional emails, interacting with 3rd party APIs (ingesting data or external API posts), populating caches and more. We have used [Sidekiq](https://sidekiq.org/) heavily to process millions of jobs offline.


[^1]: [Rails Model Caching with Redis](https://www.sitepoint.com/rails-model-caching-redis/)
[^2]: [Wikipedia: Cohesion (computer science)](https://en.wikipedia.org/wiki/Cohesion_(computer_science))
[^3]: [Ruby `#method_missing` documentation](https://ruby-doc.org/core-2.6.3/BasicObject.html#method-i-method_missing)
[^slow]: Set `log_min_duration_statement` to `100` in the PostgreSQL config file to view queries that take longer than 100ms
[^guide]: [Low hanging fruits for better SQL performance in Rails](http://www.rubyonrails365.com/low-hanging-fruits-for-better-sql-performance-in-rails/)
