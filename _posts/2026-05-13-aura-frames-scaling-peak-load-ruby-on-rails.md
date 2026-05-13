---
layout: post
permalink: /how-aura-frames-scales-for-peak-load-ruby-on-rails
title: How Aura Frames Scales For Peak Load with Ruby on Rails (#1 in App Store)
hidden: true
---

<div class="summary-box">
<strong>📌 Overview</strong>
<p>Rails made it possible to scale out and scale up to meet the demand of millions of customers enjoying their photos across millions of frames.</p>
<p>Scale out with databases: Adding more primary databases to distribute the writes and reads. Rails orchestrates this with connection pools managing connections for each primary database, mixing and matching data in the single shared codebase.</p>
<p>Scale out with application servers: Apache, Phusion Passenger Enterprise Edition, custom AMI EC2 instance, Auto Scaling Group (ASG) scaling from hundreds to thousands of instances behind an application load balancer (ALB), to meet the needs of serving traffic.</p>
<p>Scale Up: After scaling out from 1 to 7 primary databases, each database server instance can be vertically scaled up and down as needed to meet peak load. Aura scaled up to very large 48x instances as needed, and back down.</p>
<p>High Performance: With sub-1ms query execution the “norm” and 25 microseconds average query execution times through 4-5x normal load, under peak load, the platform is able to achieve very high throughput.</p>
<p>Moving beyond a single primary DB ahead of Christmas Day 2025, leveraging Multiple Databases, and disable_joins: true features of Active Record.</p>
<p>A variety of scaling tactics, some from Active Record and Ruby on Rails, and some from custom code built over years at Aura Frames.</p>
</div>

## Building With Ruby on Rails
The Aura Frames platform has been built with Ruby on Rails since the beginning. Christmas 2025 was one of the busiest days of the year for the company and technical platform, serving a peak of 41 million API requests per second and processing a peak of 11.8 million background jobs per hour.

For an introduction to the Aura Frames company and the products, please check out Part 1 - [Scaling RDS Postgres for Peak Christmas Traffic (#1 in U.S. App Store)](https://andyatkinson.com/postgresql-rds-scaling-aws-christmas-day-peak).

Besides Ruby on Rails, Aura Frames uses PostgreSQL and AWS as key technologies.

The Rails stack is a custom Amazon Machine Image (AMI) deployed on EC2 instances that are part of an Auto Scaling Group (ASG). The ASG auto scales the number of instances up and down based on CPU load. For peak traffic on Christmas Day 2025 nearly 2000 instances were in use serving API traffic.

Historically the database layer, PostgreSQL and Active Record, was the most difficult part to scale. The team relied on vertically scaling the single primary server instance through Christmas of 2024.

The largest machine available for RDS on AWS is currently the 48x family (192 vCPU, 1.5 TB RAM). Even with that jumbo sized instance, the platform had reliability issues at peak load.

To handle greater levels of peak traffic reliably, the team decided to introduce a type of sharding using multiple primary databases. The team weighed several options related to sharding the database work. One goal was to leverage the existing code as much as possible, with minimal changes, and control the sharding distribution from the application level for a high degree of operator control. Within sharding from the Rails application, another choice was whether to shard at the database table row level, meaning distributing the rows among multiple same-schema copies of the database, or to shard at the “whole table” level.

Fortunately Ruby on Rails was enhanced over more than 15 years of developments to support the needs of mature, scaled-up platforms. These platforms have billions of rows of data in databases in the terabytes of size. Rails added key capabilities natively that would help achieve the goals above, both managing distributed queries and the schema definitions across multiple primary databases.

In this post we’ll look at how the team expanded to a total of 7 primary DBs, each on their own server instances. This increased production DB server resources by 4-5x, greatly improving the ability to handle peak load with very high reliability. This post will focus on the Active Record changes needed to make that possible.

For a deeper look at the Postgres side of things, check out Part 1 - [Scaling RDS Postgres for Peak Christmas Traffic (#1 in U.S. App Store)](https://andyatkinson.com/postgresql-rds-scaling-aws-christmas-day-peak).

Let’s dive into some technical metrics for HTTP requests and Background Jobs processed on Christmas Day 2025.

## Technical Metrics
Metrics and measurements from Christmas Day 2025.
<table class="styled-table">
  <thead>
    <tr>
      <th>Metric</th>
      <th>Value</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>Peak requests (1pm CT) at load balancer</td>
      <td>41 million requests/second</td>
    </tr>
    <tr>
      <td>Average response time (10am to 9pm CT)</td>
      <td>650 milliseconds</td>
    </tr>
    <tr>
      <td>Cloudfront global requests</td>
      <td>33,675,000/hour (561K requests/second)</td>
    </tr>
    <tr>
      <td>Image Processing EC2 Instances Count Peak</td>
      <td>2990</td>
    </tr>
    <tr>
      <td>API EC2 Instances Count Peak</td>
      <td>1849</td>
    </tr>
    <tr>
      <td>Background Job Processing Peak</td>
      <td>11.8 million jobs/hour (197K jobs/second)</td>
    </tr>
  </tbody>
</table>

An exciting development for the team was seeing the Aura Frames app rise in the rank position throughout the day. Later in the day on Christmas, the app reached the #1 rank for free apps in the U.S. and Canadian App Stores on December 25, 2025, beating out ChatGPT and Meta AI.

![Aura Frames #1 App U.S. App Store Christmas Day](/assets/images/aura-christmas-2025.jpg)
<br/>
<small>Screenshot showing the Aura Frames app at the #1 rank in the U.S. Apple App Store</small>

Although there is a lot of interesting history from how the Aura Frames Rails codebase evolved over a decade, this post will focus on the slice of time from mid-2025 through Christmas 2025, preparing for a large scale Active Record query layer refactoring to distribute the work to multiple primary DBs.

Before getting access to these useful features in Rails, the platform would need to be upgraded.

## Upgrading Ruby, Ruby on Rails, and Postgres
In order to get some key features in newer versions of Rails, the first challenge was that the Aura Frames codebase was on a quite old version of Rails in early 2025. Over the years, language and framework versions were deferred due to being a small team and having limited resources. To catch things up, in 2025 a number of upgrades were performed back to back.

In a single year the 12 year old Rails codebase was upgraded first from Rails 4 to 5, then 5 to 6, and finally 6 to 7. Ruby was upgraded from 2.x to  3.x. I was pretty impressed with how quickly these were all performed and rolled out.

Compared with Ruby and Ruby on Rails versions, Postgres received upgrades more frequently. In 2025 Postgres was upgraded from 16 to 17.

With some of the latest database focused features available now in Rails, one of the prerequisites was completed and the team could dive into the specific query changes needed.

The goal was to distribute the database work to multiple primary instances. To do that, a handful of the largest and busiest tables were identified to be relocated to their own databases on their own server instances, or be part of a small group. One of the tricky parts is these tables had billions of rows of data and could be terabytes in size.

The goal was to move and not lose any writes, and minimize user-facing downtime.

The high level plan was to make the code changes, get all unit tests passing, and complete production-like synthetic load testing to verify that the changes didn’t introduce new scalability problems. There was also a fairly tight timeline of a few months to get that done and rolled out ahead of Christmas Day. How did it work out?

## Getting Started With Multiple Databases
From the Part 1 post on Postgres changes, you learned that eventually there were 7 total primary databases.

Before any of that was rolled out, we started to make Active Record code changes in the local development environment so that queries accessed only their respective databases. Queries could not span a database boundary, and the tables being moved were no longer in the primary database.

The development environment uses a Docker Postgres instance and to keep things simple locally, all 7 databases were run on the same Docker Postgres instance. This meant the queries still “broke” if they tried to access a table in a different database, for example with SQL Joins that no longer worked. This meant “failing tests,” which were the development fuel to start refactoring. The gist of the changes was pretty straightforward, finding those queries, and changing their connection to make sure they connected to the new database. Their query results were then passed around in Ruby as input to queries in other databases.

With hundreds of failing tests to sift through, the refactoring work became evident and it was a matter of moving through all the test failures one by one. Eventually several weeks later, all tests passed once again. The nice thing about this design is the same reads without SQL Joins could be performed on the existing main DB, meaning the changes were backwards compatible.

Some of the main changes were evaluating all Active Record relationships (`has_many`, `belongs_to`, etc.) and any subquery expressions or other incompatible code, and using `disable_joins: true`, removing subquery expressions and table references.

## From SQL Joins to Multiple SELECTs
The key parts of Ruby on Rails and Active Record that made this possible were two features from Rails. Starting with support for Multiple Databases launched in 6.0, then second the feature of the `disable_joins` option for `has_many :through` and `belongs_to :through` relationships.

Both of these were possible with custom code or with third party library code (gems), but having native support in Rails was a differentiator. Native support meant more real world use, a lot of bugs were fixed (maturity of code), documentation was good, and there would be a commitment to supporting these features for a long time. 

Having `disable_joins` as a consistent pattern also helped with comprehension by the team. Learn the behavior once and then re-use it dozens of times in the codebase.

The team had some concern about Postgres no longer joining this data, not more nested loop, merge, or hash joins. While it’s true that it increased the quantity of SELECT queries (2x), the resulting SELECT queries are very simple, meaning they are simple to parse, plan, and execute by Postgres.

Here's a simple example using `Author` and `Post` models:
- Author (table_name: `authors`)
- Post (table_name: `posts`)
- AuthorPost (table_name: `author_posts`)

Author `has_many :posts, through: :author_posts`.

Change to:
`Author has_many :posts, through: :author_posts, disable_joins: true`

This means that to previously to get an Author’s posts, we’d query the `author_posts` table and join to the posts table on the author’s id.  Instead of that, two queries are now performed. One to the `author_posts` table to get post ids, then a second to the posts table by id.

```sql
select * from author_posts where author_id = '<some id>';
select * from posts where id IN (?);
```

What else?

## Rails side - New config and new parent classes
With Multiple Databases, the first thing we need is a new YML config entry (`config/database.yml`) for the new database. The [Multiple Databases Documentation](https://guides.rubyonrails.org/active_record_multiple_databases.html) uses "animals" and `my_animals_db` as the second primary database, so we'll use that too.

This configuration is where we’ll store the Postgres connection string details and other application config like whether migrations are used, the schema dump path, schema cache path etc.

Second, Active Record classes that previously inherited (OOP style) from `ApplicationRecord < ActiveRecord::Base` would get a new parent class.

The new parent class would introduce the new DB config for `my_animals_db` and also have the concept of “writer” and “reader.” We could call this class `AnimalsRecord`, and it will now inherit from `ApplicationRecord`.

Examples from Rails' Documentation:
```rb
class AnimalsRecord < ApplicationRecord
  self.abstract_class = true

  connects_to database: {
    writing: :animals,
    reading: :animals_replica
  }
end

class Dog < AnimalsRecord
  # Talks automatically to the animals database.
end
```

In our case if we had a single table in the new database, the Active Record model code for that table would now inherit from `AnimalsRecord`. This was the gist of the changes needed for Active Record, repeated 6 times for 6 new DBs.

The nice thing about this was the query changes themselves were backwards compatible, meaning we could deploy all of the changes into production without using the new classes, new config, etc. The query changes replaced SQL Joins with separate SELECT queries.

## Post-split: Subquery Expressions
Another limitation was subquery expressions where a table is referenced that’s no longer in the database. These could be trickier to find, we relied on unit tests and some manual testing. 

There we needed to separate those into individual statements so the correct parent model based connection could be used, to access the table in its respective database.

`disable_joins` for `has_many :through` relationships did end up covering a lot of the needed query changes to get tests passing again, as tables were split to multiple DBs.

Another common pattern was needing a lookup map, mapping primary key ids to objects. Some Ruby Enumerable methods help facilitate that too like `index_by()` [API Documentation](https://apidock.com/rails/Enumerable/index_by).

Besides `select()` and `map()` of fields, `pluck()` was also used heavily to access limited columns but instantiate primitive objects instead of full Active Record objects.

## Post-split: EXISTS Clauses
Post split, this statement no longer works when these tables aren't in the same DB.
```sql
SELECT users.*
FROM users
WHERE EXISTS (
  SELECT 1 FROM posts WHERE posts.user_id = users.id
)
```

## Post-split: Aggregating And Grouping Multiple Tables
Post split, this statement no longer works when these tables aren't in the same DB.
```sql
Users.select("users.*, COUNT(posts.id) AS posts_count")
```

## Post-split: Merging Scopes
If `User` and `Post` are not in the same database, we can't merge a scope like this:
```sql
User.merge(Post.recent)
```

## Post-split: References Method
`references` [API Documentation](https://apidock.com/rails/v7.1.3.2/ActiveRecord/QueryMethods/references) (adds a SQL Join)
Used in conjunction with `includes()` when it’s not clear what table is being referenced. Can’t reference a table that’s not in the same database. 

Let’s get into the details.


## Handling has_and_belongs_to_many
We did have a handful of `has_and_belongs_to_many` (HABTM) relationships ([API Documentation](https://guides.rubyonrails.org/association_basics.html#has-and-belongs-to-many)). With these there is still a join table, but there is no Active Record model for it. These are also slim table definitions with no primary key or timestamp columns.

For the HABTM that would span a DB boundary, we decided to keep the table definitions as is, but introduce a model class and convert the relationships to HMT so we could use `disable_joins`.

The HABTM relationships that still existed in the same DB were left alone.


## Scaling at the operation level, inserts and updates
Rails supports bulk insert and upsert (insert or update), however they’re limited. One limitation is that the ON CONFLICT clause can’t be customized, for example an attempted insert where a duplicate happens and skipping that by doing nothing.

For `insert_all()` ([API Documentation](https://apidock.com/rails/v6.0.0/ActiveRecord/Persistence/ClassMethods/insert_all)) the on conflict clause can’t be controlled.

Aura has custom code for mass insert with control over the on conflict clause, for this reason. Sometimes we want to bulk insert and skip duplicates. Being able to batch inserts and updates like this is a critical part of scalability, consolidating the overhead of a single transactional commit from many rows, possibly 1000, into a single commit.

Note that from Postgres 15 onward there is also support for the SQL MERGE keyword, but neither Active Record nor the custom code is using MERGE as of now.


## Scaling reads with batching
Rails supports batched read queries with a few Active Record methods: find_each, in_batches, and find_in_batches.

Aura has custom code for batched finding specifying an arbitrary column on the table and a sorting direction. 

Rails 6.1 did add support for `find_in_batches()` ([API Documentation](https://apidock.com/rails/ActiveRecord/Batches/find_in_batches)) to control ordering, but unfortunately the only column to order on is the primary key column.

Still, reading a batch worth of rows at a time is a critical scalability tactic to make sure that that the query runs fast and the query result size is not overwhelming.

## Scaling paginated queries with cursor positions
Aura has custom code to perform keyset pagination, and generally does not use LIMIT and OFFSET style pagination that’s built in to Active Record. While LIMIT and OFFSET style pagination may work for smaller amounts of data, it doesn’t scale well for deep pagination levels or working with billions of rows.

Instead, keyset pagination scales well for any amount of row data. The trick is to index a high cardinality column like a timestamp column, then query using that column in the WHERE clause and fetch a batch of rows. For example fetching rows from a position with a >= or < operator and a LIMIT of 1000. The last accessed value then becomes the cursor position to start from. 

This is an incredibly useful pattern and common used in the codebase for paginating API requests and other spots, but to my knowledge Active Record does not have a generic pagination helper built in like this.  


## Caching data type lookups: Schema cache querying
The schema inspection queries for data types and other things, `pg_attribute`, while small individually, end up accounting for a significant amount of query volume at high scale. These queries are made against the primary instance using some resources that would better be made available for application queries.

To fix that we use the schema cache feature in Active Record. Instead of querying Postgres for data types info, the `scheme_cache.yml` holds a serialized dump of this info in a file that can be read by Rails. Unfortunately in the initial expansion to supporting Multiple Databases, the schema cache was only available for the main primary DB.

Later on an option was added to lazily load the schema cache, and this supports multiple primary DBs.

`config.active_record.lazily_load_schema_cache = true` ([Blog post](https://blog.saeloun.com/2022/04/20/rails-7-lazy-loads-schema-cache/))

`db/schema_cache.yml # default spot`

## Counter cache style maintenance of frequently updated counters
Rails supports counter_cache columns, but these are columns that are updated on a table. Updating them means row row churn in Postgres, as updates even for a single column create a new immutable row version behind the scenes, leaving behind a former row version.

The updates could also cause contention for that row being updated by another process.

Aura Frames does something similar but keeps counter cache columns in a separate but related table. This avoids contention and row churn on the target table.

That said, keeping a running count to avoid slow filtered COUNT queries is a critical part of high scale.

## Getting random values for sampling
Ordering by `RANDOM()` is slow (order by rand). Aura makes use of TABLESAMPLE in Postgres, specified with a “from” clause for a table. A couple of options are supported like “sampling_method” with built-in options of system and bernoulli, or they can be expanded further by enabling the `tsm_system_rows module`. Check the documentation.

<https://www.postgresql.org/docs/current/sql-select.html>
<https://www.postgresql.org/docs/current/tsm-system-rows.html>

## Scaling With Rails Caching
Aura Frames makes use of the ActiveRecord Cache Store, Memcached with HAProxy performing connection management.

Keeping certain values in Memcached is a key part of the scaling strategy. Things like per-user counters, per-feature rate limiting, or cached values with TTLs of certain environment variables are key pieces of data stored in Memcached.

## Managing Schema Changes with Multiple Databases
Given each of the 6 new primary databases had their own config in config/database.yml, we could also manage DDL changes to these tables in the regular Rails way.  Each had their own db/schema.rb, a Ruby representation of the schema definition. There is also schema data type caching via `db/schema_cache.yml` but we will cover that later. 

Each DB had its own directory for migration files, a respective schema.rb equivalent that was generated from the migrations, and a schema cache (schema_cache.yml) file.

Since each “new” database was actually based on an existing table, we started the “first” migration for the new database from the existing table definition. We used pg_dump to dump the current table definition from production.

This migration version would be added “idempotently” meaning the table was added when it didn’t exist. Initially the table would not exist in dev, test, and staging, but based on how we planned to migrate the tables in production, the table would exist there. The plan was to use physical replication from the original primary instance to create a read only replica, then promote it to become a writer database at “switch over” time. The replication was used as the means of moving all of the row data. This approach proved very reliable, but it did mean we had the former table copy on the original DB to clean up later. 

Imagine that new migration version was “1234567890.” Once switch over, we manually inserted that version into `schema_migrations`. This was manual but it could be approved via PR in advance and ultimately was only 6 insert statements. Prior to the insert we TRUNCATED the new DB’s `schema_migrations` table meaning it started as empty. 

Once all of that was done, schema management via migrations worked like normal from that point forward. Migrations can be generated, their files are in their own directory, and when applied with “rails db:migrate” schema.rb and schema_cache.yml generated files are produced for each. Nifty!

```sh
rails g migration --database new_db
rails db:migrate --database my_animals_db
rails db:schema:cache:dump
```


## What’s missing in Rails?
While Ruby on Rails has been expanded to help the needs of large scale apps, and intends to be a somewhat generic framework used for a variety of specific purposes, we did look at some ways that current features came up a bit short. This section will recap those with the idea that these may be possible future enhancement areas for Rails and Active Record.

Limitations of `disable_joins: true` - not all association types are supported

Limitation of schema cache dumping, can’t eagerly load schema cache for all primary DBs, but does seem supported when schema cache is lazily loaded for multiple DBs.

Batched finders like `find_in_batches()` don’t support filtering (`WHERE` clause) on non primary key columns. We want to specify a non-PK column, set the direction ascending or descending, and set a limit.

Methods `insert_all()` and `upsert_all()` don’t support a customizable `ON CONFLICT` clause.

No built-in method for keyset pagination style pagination.

## Wrap Up
If these types of posts are interesting to you, please consider subscribing to my blog or buying my book. If you're an engineer interested in working on these types of challenges, please get in touch.

Thanks for reading!
