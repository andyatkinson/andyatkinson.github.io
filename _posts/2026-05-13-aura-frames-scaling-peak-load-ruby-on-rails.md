---
layout: post
permalink: /how-aura-frames-scales-for-peak-load-ruby-on-rails
title: How Aura Frames Scales For Peak Load with Ruby on Rails (#1 in App Store)
hidden: true
---

<div class="summary-box">
<strong>📌 Overview</strong>
<p>Using Ruby on Rails has helped make it possible to scale out and scale up to meet the demand of millions of customers enjoying their photos on millions of digital frames.</p>
<p>The team added more primary databases to scale write and read operations out. Rails helps this with connection pools for each primary database, while working with the same deployed codebase.</p>
<p>Web servers chosen long ago have been battle tested, including Apache, Phusion Passenger Enterprise Edition, and a custom AMI EC2 instance, part of an Auto Scaling Group (ASG) scaling to thousands of instances at peak for API traffic.</p>
<p>With 8 primary databases in total, each server instance can be vertically scaled up for peak load, and back down later for cost savings.</p>
<p>Primarily moving to Multiple Databases leveraged the <code>disable_joins: true</code> feature of Active Record, simulating joins for tables in separate databases.</p>
<p>This post looks at a variety of additional data layer scaling tactics, some part of Active Record and Ruby on Rails, and some not.</p>
</div>

## Building With Ruby on Rails
The Aura Frames platform has been built with Ruby on Rails since the beginning. Christmas 2025 was one of the busiest days of the year for the company and technical platform, serving a peak of 41 million API requests per second and processing a peak of 11.8 million background jobs per hour.

For an introduction to the Aura Frames company and the products, please check out [Scaling RDS Postgres for Peak Christmas Traffic (#1 in App Store)](https://andyatkinson.com/postgresql-rds-scaling-aws-christmas-day-peak).

Besides Ruby on Rails, Aura Frames uses PostgreSQL and AWS as key technologies.

Historically the database layer, PostgreSQL and Active Record, was the most difficult part to scale. The team relied on vertically scaling the single primary server instance through Christmas of 2024.

The largest machine available for RDS on AWS is currently the 48x family (192 vCPU, 1.5 TB RAM). Even with that jumbo sized instance, the platform had reliability issues at peak load.

To handle greater levels of peak traffic reliably, the team decided to introduce a type of sharding using multiple primary databases. The team weighed several options related to sharding the database work. One goal was to leverage the existing code as much as possible, with minimal changes, and control the sharding distribution from the application level.

Within sharding from the Rails application, another choice was whether to shard at the database table row level, meaning distributing the rows among multiple same-schema copies of the database, or to shard at the “whole table” level.

Fortunately Ruby on Rails was enhanced over more than 15 years of developments to support the needs of mature, scaled-up platforms with billions of rows of data and terabyte sized DBs.

In this post we’ll look at how the team scaled out from a single primary, to 7 primary DBs, as well as a variety of other scaling tactics in use for efficient data access.

Let’s dive into the Rails and Active Record code changes in this post, starting with some technical metrics from Christmas Day 2025.

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

## Getting Started With Multiple Databases
From the earlier post on Postgres changes, you learned that eventually there were 7 total primary databases.

Before any of that was rolled out, we started to make Active Record code changes in the local development environment so that queries accessed only their respective databases. Queries could not span a database boundary, and the tables being moved were no longer in the primary database.

The development environment uses a Docker Postgres instance and to keep things simple locally, all 7 databases were run on the same Docker Postgres instance. This meant the queries still “broke” if they tried to access a table in a different database, for example with SQL Joins that no longer worked. This meant “failing tests,” which were the development fuel to start refactoring. The gist of the changes was pretty straightforward, finding those queries, and changing their connection to make sure they connected to the new database. Their query results were then passed around in Ruby as input to queries in other databases.

With hundreds of failing tests to sift through, the refactoring work became evident and it was a matter of moving through all the test failures one by one. Eventually several weeks later, all tests passed once again. The nice thing about this design is the same reads without SQL Joins could be performed on the existing main DB, meaning the changes were backwards compatible.

Some of the main changes were evaluating all Active Record relationships (`has_many`, `belongs_to`, etc.) and any subquery expressions or other incompatible code, and using `disable_joins: true`, removing subquery expressions and table references.

## From SQL Joins to Multiple SELECTs
The key parts of Ruby on Rails and Active Record that made this possible were Multiple Databases launched in 6.0, then the `disable_joins` feature for `has_many :through` and `belongs_to :through` relationships, to query across databases, [launched in Rails 7.0](https://www.bigbinary.com/blog/rails-7-adds-disable-joins-for-associations) (2021).

Both of these were possible with custom code or third party library code (Ruby gems), but having native support in Rails was a differentiator. Native support meant more real world use, bug fixes, improved documentation, and a longer term commitment to supporting these features.

Having `disable_joins` as a consistent pattern also helped with comprehension by the team. Learn how it works once and then re-use it dozens of times.

The team had some concern about Postgres no longer joining this data. Postgres no longer chose nested loop, merge, or hash joins to join row data.

While it’s true that this approaches doubles the count of SELECT queries, the resulting queries are also simpler, meaning they're easier to parse, plan, and execute by Postgres.

Here's a simple example using `Author` and `Post` models:
- Author (table_name: `authors`)
- Post (table_name: `posts`)
- AuthorPost (table_name: `author_posts`)

Author `has_many :posts, through: :author_posts`.

Change to:
`Author has_many :posts, through: :author_posts, disable_joins: true`

Previously to get an Author’s posts, we’d query the `author_posts` table and join to the posts table on the author’s id.  Instead of that, two queries are now performed. One to the `author_posts` table to get post ids, then a second to the posts table by id.

```sql
select * from author_posts where author_id = '<some id>';
select * from posts where id IN (?);
```

What else?

## New Database Configuration
With Multiple Databases, the first thing we need is a new YML config entry (`config/database.yml`) for the new database. The [Multiple Databases Documentation](https://guides.rubyonrails.org/active_record_multiple_databases.html) uses "animals" and `my_animals_db` as the second primary database, so we'll use that too for examples.

This configuration is where we’ll store the Postgres connection string details and other application config like whether migrations are used, the schema dump path, etc.

Second, Active Record classes that previously inherited (OOP style) from `ApplicationRecord < ActiveRecord::Base` would get a new parent class.

The new parent class would introduce the new DB config for `my_animals_db` and also have the concept of "writing" and "reading" roles, which we can see below.

The new parent class would be `AnimalsRecord` in this case, a child class inheriting from `ApplicationRecord`.

Examples from Rails' Documentation:
```rb
class AnimalsRecord < ApplicationRecord
  self.abstract_class = true

  connects_to database: {
    writing: :animals,
    reading: :animals_replica
  }
end
```

Now, Models/tables we'd move to the new database will inherit from `AnimalsRecord`. For example a `Dog` class:
```rb
class Dog < AnimalsRecord
  # Talks automatically to the animals database.
end
```
This means the `dogs` table (assuming `self.table_name = "dogs"` here) would be a table in the separate Animals database.

This was the gist of the changes needed for Active Record in the Aura Frames codebase. This pattern was repeated 7 times for 7 new DBs.

The nice thing about this was the query changes themselves were backwards compatible, meaning query changes were deployed in advance of the DB split, running on a single primary DB. This as meant to be temporary and while under less load than peak.

Eventually all new infra was set up, and switched over to.

`disable_joins` for `has_many :through` relationships did end up covering a lot of the needed query changes to get tests passing again, as tables were split to multiple DBs.

What else was there?

## Post-split: Subquery Expressions
Multiple tables exist in subquery expressions (aka "subqueries"), and these tables need to be in the same database for the statement to be vald.

When we found those, they needed to be restructured so that the DBs containing the table could be queried.

## Post-split: EXISTS Clauses
Post-split, SQL like below no longer works when these tables aren't in the same DB.
```sql
SELECT users.*
FROM users
WHERE EXISTS (
  SELECT 1 FROM posts WHERE posts.user_id = users.id
)
```

## Post-split: Aggregating And Grouping Multiple Tables
Post-split, the resulting SQL from this Active Record no longer works when these tables aren't in the same DB.
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

## Handling has_and_belongs_to_many
We did have a handful of `has_and_belongs_to_many` (HABTM) relationships ([API Documentation](https://guides.rubyonrails.org/association_basics.html#has-and-belongs-to-many)). With these there is still a join table, but there is no Active Record model for it. The tables are also slim, no primary key or timestamp columns.

For HABTM relationships that would span a DB boundary, we decided to keep the table definitions as is, but introduce a model class and convert the code-level relationship from HABTM to `has_many :through` (HMT) so that we could use the `disable_joins: true` option.

HABTM relationships that existed in the same DB were left alone.

## Scaling Inserts and Updates
Rails supports bulk inserts and *upserts* (either an insert or an update), however the helper methods are limited. One limitation is that the ON CONFLICT clause can’t be customized. For example attempting an INSERT and specifying the DO NOTHING option when unique constraint violations occur.

For `insert_all()` ([API Documentation](https://apidock.com/rails/v6.0.0/ActiveRecord/Persistence/ClassMethods/insert_all)) the ON CONFLICT clause can’t be controlled.

Aura has custom code for mass insert with drect control over the ON CONFLICT clause. Being able to batch inserts and updates like this is a critical part of scalability, consolidating the overhead of a single transactional commit from many rows, possibly 1000, into a single commit.

Note that from Postgres 15 onward there is also support for the SQL MERGE keyword, but neither Active Record nor the custom code is using MERGE as of now.

## Scaling reads with batching
Rails supports batched read queries with a few Active Record methods: `find_each()`, `in_batches()`, and `find_in_batches()`.

Aura has custom code for batched finding specifying an arbitrary column on the table and a sorting direction. 

Rails 6.1 did add support for `find_in_batches()` ([API Documentation](https://apidock.com/rails/ActiveRecord/Batches/find_in_batches)) to control ordering, but unfortunately the only column to order on is the primary key column.

Still, reading a batch worth of rows at a time is a critical scalability tactic to make sure that that the query runs fast and the query result size is not overwhelming.

## Scaling Reads with Paginated Queries
Aura has custom code to perform keyset pagination, and generally does not use LIMIT and OFFSET style pagination that’s built in to Active Record. While LIMIT and OFFSET style pagination may work for smaller amounts of data, it doesn’t scale well for deep pagination levels or working with billions of rows.

Instead, keyset pagination scales well for any amount of row data. The trick is to index a high cardinality column like a timestamp column, then query using that column in the WHERE clause and fetch a batch of rows. For example fetching rows from a position with a >= or < operator and a LIMIT of 1000. The last accessed value then becomes the cursor position to start from. 

This is an incredibly useful pattern and common used in the codebase for paginating API requests and other spots, but to my knowledge Active Record does not have a generic pagination helper built in like this.  

## Counter Cache Maintenance for Frequently Updated Counters
Rails supports counter_cache columns, but these are columns that are updated on a table. Updating them means row row churn in Postgres, as updates even for a single column create a new immutable row version behind the scenes, leaving behind a former row version.

The updates could also cause contention for that row being updated by another process.

Aura Frames does something similar but keeps counter cache columns in a separate but related table. This avoids contention and row churn on the target table.

That said, keeping a running count to avoid slow filtered COUNT queries is a critical part of high scale.

## Random values and Sampling
Ordering by `RANDOM()` is slow (`ORDER BY RAND()`). Aura makes use of TABLESAMPLE in Postgres, specified with a FROM clause for a table ([Postgres Documentation](https://www.postgresql.org/docs/current/sql-select.html)).

A couple of options are supported like `sampling_method` with built-in options of `system` and `bernoulli`, or they can be expanded further by enabling the `tsm_system_rows module` ([Postgres Documentation](https://www.postgresql.org/docs/current/tsm-system-rows.html)).

## Using Memory Key Value Cache Stores
Aura Frames makes use of the [Active Support Cache Store](https://api.rubyonrails.org/classes/ActiveSupport/Cache/Store.html), Memcached with HAProxy performing connection management.

Keeping certain values in Memcached is a key part of the scaling strategy. Things like per-user counters, per-feature rate limiting, or cached values with TTLs of certain environment variables are key pieces of data stored in Memcached.

## Managing Schema Changes with Multiple Databases
Given each of the 6 new primary databases had their own config in `config/database.yml`, we could also manage DDL changes to these tables in the regular Rails way.  Each had their own `schema.rb`, a Ruby representation of the schema definition.

Each DB had its own directory for migration files and a respective `schema.rb` equivalent generated from migrations.

Since each "new" database was not actually new, but based on an existing table, we started a new "first" migration for it using the existing using `pg_dump`.

This migration version would be added *idempotently* meaning the table was added when it didn’t exist. Initially the table would not exist in dev, test, and staging, but based on how we planned to migrate the tables in production, the table would exist there.

The plan was to use physical replication from the original primary instance to create a read only replica, then promote it to become a writer database at switchover time. The replication was used as the means of moving all of the row data. This approach proved very reliable, but it did mean we had the former table copy on the original DB to clean up later. 

Imagine that new migration version was `1234567890`. Once switch over, we manually inserted that version into `schema_migrations`. This was manual but it could be approved via PR in advance and ultimately was only 6 insert statements. Prior to the insert we `TRUNCATE`'d the new DB’s `schema_migrations` table meaning it started empty.
```sql
insert into schema_migrations (version) values ('1234567890');
```


Once all of that was done, schema management via migrations worked like normal from that point forward. Migrations can be generated, their files are in their own directory, and when applied with `rails db:migrate` all the respective `schema.rb` files are updated. Nifty!

```sh
rails g migration --database new_db

rails db:migrate --database my_animals_db
# or rails db:migrate for all databases

rails db:schema:cache:dump
```

## What’s missing in Rails?
While Ruby on Rails has been expanded to help the needs of large scale apps, and intends to be a somewhat generic framework used for a variety of specific purposes, we did look at some ways that current features came up a bit short. This section will recap those with the idea that these may be possible future enhancement areas for Rails and Active Record.

- Limitations of `disable_joins: true`, not all association types are supported
- Batched finders like `find_in_batches()` don’t support filtering (`WHERE` clause) on non primary key columns. We want to specify a non-PK column, set the direction ascending or descending, and set a limit.
- Methods `insert_all()` and `upsert_all()` don’t support a customizable `ON CONFLICT` clause.
- No built-in method for keyset pagination style pagination.

## Wrap Up
Ruby on Rails has been a critical technology for Aura Frames to build with for more than a decade. Enhancements in the last handful of versions have been put to use by the platform, helping it reach greater levels of scale, and helping deliver a faster and more reliable experience to customers.

If these types of posts are interesting to you, please consider subscribing to my blog or buying my book. If you're an engineer interested in working on these types of challenges, please get in touch.

Thanks for reading!

<div style="
  max-width: 420px;
  margin: 2rem auto;
  padding: 1.25rem 1.5rem;
  background: #fff8b3;
  color: #333;
  border-left: 6px solid #f4d03f;
  border-radius: 3px;
  box-shadow: 3px 4px 10px rgba(0,0,0,0.15);
  font-family: sans-serif;
  transform: rotate(-1deg);
  position: relative;
">

  <div style="
    position: absolute;
    top: -10px;
    right: 20px;
    width: 70px;
    height: 22px;
    background: rgba(255,255,255,0.5);
    transform: rotate(4deg);
    border: 1px solid rgba(0,0,0,0.05);
  "></div>

  <strong style="display:block; margin-bottom:0.5rem;">
    Related Reading
  </strong>

  <p style="margin:0; line-height:1.5;">
    If you're interested in the PostgreSQL details for peak traffic on Christmas Day 2025,
    you may also enjoy
    <a href="https://andyatkinson.com/postgresql-rds-scaling-aws-christmas-day-peak"
       style="color:#005bbb; font-weight:600; text-decoration:none;">
      Scaling RDS Postgres for Peak Christmas Traffic (#1 in App Store)
    </a>.
  </p>
</div>

