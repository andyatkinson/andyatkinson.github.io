---
layout: post
permalink: /how-aura-frames-scales-for-peak-load-ruby-on-rails
title: How Aura Frames Scales For Peak Load with Ruby on Rails (#1 in App Store)
hidden: true
---

<div class="summary-box">
<strong>📌 Overview</strong>
<p>Using Ruby on Rails has helped make it possible to scale out and scale up, meeting the demands of millions of customers adding and viewing photos on millions of digital frames.</p>
<p>In 2025, the team added more primary databases to scale peak write and read load ahead of Christmas Day. Rails helps manage pools of connections for each primary database, within the same codebase.</p>
<p>The Ruby web stack was chosen long ago and has been battle tested, including Apache and Phusion Passenger Enterprise Edition, built on a custom AMI EC2 instance, part of an Auto Scaling Group (ASG) that auto-scales to thousands of instances for peak API traffic.</p>
<p>With 8 primary databases in total, each server instance can be vertically scaled up for peak load, and back down later for cost savings.</p>
<p>To make this possible within Ruby on Rails, the team leveraged native support for Multiple Databases and the <code>disable_joins: true</code> Active Record feature which simulates joins between tables in different databases.</p>
<p>This post looks at how that plan was developed and rolled out, as well as a variety of additional data layer scaling tactics.</p>
</div>

## Building With Ruby on Rails
The Aura Frames platform has been built with Ruby on Rails since the beginning. Christmas 2025 was one of the busiest days of the year for the company and technical platform, serving a peak of 41 million API requests per second and processing a peak of 11.8 million background jobs per hour.

For an introduction to the Aura Frames company and the products, please check out [Scaling RDS Postgres for Peak Christmas Traffic (#1 in App Store)](https://andyatkinson.com/postgresql-rds-scaling-aws-christmas-day-peak).

Besides Ruby on Rails, Aura Frames uses PostgreSQL and AWS as key technologies.

Due to not being easily scalable horizontally for write operations, the database layer of PostgreSQL and Active Record often became a bottleneck. The team relied on vertically scaling the single primary server instance through Christmas of 2024.

The largest machine available for RDS on AWS is currently the 48x family (192 vCPU, 1.5 TB RAM). Even with that jumbo sized instance, the platform had reliability issues at peak load on Christmas 2024, driving a need to re-design for reliability improvements before Christmas 2025.

To handle greater levels of peak traffic reliably, the team decided to introduce a type of sharding using multiple primary databases. Several sharding approaches were considered. One goal was to leverage the existing code as much as possible, with minimal changes, and control the sharding distribution from the application level.

Within sharding from the Rails application, another choice was whether to shard at the database table row level, meaning distributing the rows among multiple same-schema copies of the database, or to shard at the “whole table” level.

Fortunately Ruby on Rails was enhanced over more than 15 years of developments to support the needs of mature, scaled-up platforms with billions of rows of data and terabyte sized DBs, and had a few capabilities that could accommodate either strategy.

Let’s dive into some technical metrics from Christmas Day 2025 to help set the context.

## Technical Metrics
On Christmas Day, the Aura Frames platform sees a 4-5x increase in load. Below are some HTTP and background jobs oriented metrics that Rails developers might find interesting.
<table class="styled-table">
  <thead>
    <tr>
      <th>Metric</th>
      <th>Peak Value</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>HTTP Requests (1pm CT) at Load Balancer</td>
      <td>41 million requests/second</td>
    </tr>
    <tr>
      <td>Average Response Time (10am to 9pm CT)</td>
      <td>650 milliseconds</td>
    </tr>
    <tr>
      <td>Cloudfront Global Requests</td>
      <td>33,675,000/hour (561K requests/second)</td>
    </tr>
    <tr>
      <td>Image Processing EC2 Instances Count</td>
      <td>2990</td>
    </tr>
    <tr>
      <td>API EC2 Instances Count</td>
      <td>1849</td>
    </tr>
    <tr>
      <td>Background Job Processing Rate</td>
      <td>11.8 million jobs/hour (197K jobs/second)</td>
    </tr>
  </tbody>
</table>

An exciting development for the team was seeing the free iOS Aura Frames app rise in App Store rank throughout the day.

Later on Christmas Day, the app reached a peak rank of #1 among all free apps in the U.S. and Canadian App Stores, even beating out apps from big companies like ChatGPT and Meta AI.

![Aura Frames #1 App U.S. App Store Christmas Day](/assets/images/aura-christmas-2025.jpg)
<br/>
<small>Screenshot showing the Aura Frames app at the #1 rank in the U.S. Apple App Store</small>

Although there is a lot of interesting history from how the Aura Frames Rails codebase evolved over a decade, to handle the peak load for this post will look at changes made from mid-2025 through Christmas 2025 to the Active Record query layer, through refactoring and gradual rollouts.

## Getting Started With Multiple Databases
From earlier, you learned that the Aura Frames platform was expanded from a single primary application DB to a total of 8.

To make that possible, heavy refactoring was performed to the Active Record that worked with the tables that were ultimately moved.

Queries for tables must not span a database boundary, and given some of the big tables being moved to new databases, they'd no longer be in the primary database.

The development environment uses a Docker Postgres instance and to keep things simple locally, all 8 databases were run on the same Docker Postgres instance. This meant the queries still "broke" (helpfully) when they spanned a database boundary, but we didn't need to run 8 different instances locally.

These breakages showed up as “failing tests” in the extensive test suite, which was supremely useful to help know what needed to change.

The gist of the changes was pretty straightforward, finding those breaking queries, then unraveling joins and changing connections for tables to be routed to the correct database. Their query results were then passed around in Ruby as input to queries in other databases.

With hundreds of failing tests to sift through, the refactoring work took a long time as test failures were addressed one by one, but progress was easy to measure.

Eventually, weeks later, all tests were passing! The nice property about this design was the same query changes without SQL joins could be performed on the existing main DB, meaning the changes were backwards compatible and could be rolled out in place initially, before the new DBs were in place.

Some of the main changes were evaluating all Active Record relationships (`has_many`, `belongs_to`, etc.) and any subquery expressions or other incompatible code, and using `disable_joins: true`, removing subquery expressions and table references.

## From SQL Joins to Multiple SELECTs
The key parts of Ruby on Rails and Active Record that made this possible were Multiple Databases launched in 6.0, then the `disable_joins` feature for `has_many :through` and `belongs_to :through` relationships, to query across databases, [launched in Rails 7.0](https://www.bigbinary.com/blog/rails-7-adds-disable-joins-for-associations) (2021).

Both of these were possible with custom code or third party library code (Ruby gems) before, but having native support in Rails was a differentiator. Native support meant more real world use, bug fixes, improved documentation, and a longer term commitment to supporting these features.

Having `disable_joins` as a consistent pattern also helped with comprehension by the team. Enabling "learn how it works once, then re-use it all over the codebase."

Due to the increase in SELECT queries (and loss of join efficiency), the team had concerns about additional read query volume. Fortunately the team had a load testing tool in place and was able to verify through load testing that the additional read queries performed would not be a problem.

Here's a simple example using `Author` and `Post` models illustrating how `disable_joins: true` works:
- Author (table_name: `authors`)
- Post (table_name: `posts`)
- AuthorPost (table_name: `author_posts`)

Author model has an existing association defined as: `has_many :posts, through: :author_posts`.

To change this association, the `disable_joins: true` option is added like this:
`Author has_many :posts, through: :author_posts, disable_joins: true`

What's happening in SQL? Previously to get an Author’s posts, we’d query the `author_posts` table and join to the posts table on the author’s id.

Instead of that, there will now be two queries performed like below. One queries `author_posts` by `author_id` (an important foreign key column to index) table to get post `id` values. Then a second query to the `posts` table by `id` (uses primary key index).

```sql
select * from author_posts where author_id = '<some id>';
select * from posts where id IN (?);
```

What else needed to change to make this possible?

## New Database Configuration
Although we could roll this out on the same single DB, that was a temporary plan. The main plan was to use Multiple Databases and effectively relocate some of the largest, busiest tables to their own instances.

For that we'd need to identify all the new DBs. The first thing we needed was new YML config entries (`config/database.yml`) for each of them. The [Multiple Databases Documentation](https://guides.rubyonrails.org/active_record_multiple_databases.html) uses "animals" and `my_animals_db` as the second primary database, so we'll use that too for examples here.

This configuration is where we’ll store the Postgres connection string details and other application config like whether migrations are used, the schema dump path, etc.

Second, Active Record classes that previously inherited (OOP style) from `ApplicationRecord < ActiveRecord::Base` would get a new parent class.

The new parent class would introduce the new DB config for `my_animals_db` and have the concept of "writing" and "reading" roles, shown below.

The new parent class from the example then is `AnimalsRecord`, which is a child class that inherits from `ApplicationRecord`, and effectively becomes the "interface" for any Active Record classes that wish to read/write to this new DB.

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
This means the `dogs` table (assuming `self.table_name = "dogs"` here) would be a table in the separate Animals database (`my_animals_db`).

Eventually all new DBs and infra (PgBouncer, config vars) were set up, and could be switched over to.

`disable_joins` for `has_many :through` relationships ended up covering a lot of the needed query changes to get tests passing again, however there were other issues encountered on the way.

What were they?

## Post-split: Subquery Expressions
Multiple tables exist in subquery expressions (aka "subqueries"), and these tables need to be in the same database for the statement to be valid.

When we found those, they needed to be restructured so that the DBs containing the table could be queried.

## Post-split: EXISTS Clauses
Post-split, the SQL below doesn't work when `users` and `posts` aren't in the same DB.
```sql
SELECT users.*
FROM users
WHERE EXISTS (
  SELECT 1 FROM posts WHERE posts.user_id = users.id
)
```

## Post-split: Aggregating And Grouping Multiple Tables
Post-split, there can be SQL fragments like this lurking, and this code needs to be changed.
```sql
Users.select("users.*, COUNT(posts.id) AS posts_count")
```

## Post-split: Merging Scopes
If the tables for `User` and `Post` aren't in the same database, we can't merge a scope like this:
```sql
User.merge(Post.recent)
```

## Post-split: References Method
`references` [API Documentation](https://apidock.com/rails/v7.1.3.2/ActiveRecord/QueryMethods/references) which adds a SQL join, is used in conjunction with `includes()` to specify a table. However, this won't work if the table is no longer in the same database.

## Other Associations: has_and_belongs_to_many
We did have a handful of `has_and_belongs_to_many` (HABTM) relationships ([API Documentation](https://guides.rubyonrails.org/association_basics.html#has-and-belongs-to-many)). With these there is still a join table, but there is no Active Record model for it. The tables are also slim, no primary key or timestamp columns.

For HABTM relationships that would span a DB boundary, we decided to keep the table definitions as is, but introduce a model class and convert the code-level relationship from HABTM to `has_many :through` (HMT) so that we could use `disable_joins: true`.

HABTM relationships in the same DB were left alone.

## Scaling Inserts and Updates
With Multiple Databases and `disable_joins: true` covered, what other database scalability tactics are used?

Rails supports bulk inserts and *upserts* (either an insert or an update), however the helper method for mass-inserting data didn't support what we needed. A limitation was that the ON CONFLICT clause couldn't be customized for `insert_all()` ([API Documentation](https://api.rubyonrails.org/v7.0/classes/ActiveRecord/Persistence/ClassMethods.html#method-i-insert_all)). For example attempting an INSERT and specifying the DO NOTHING option when unique constraint violations occur.

Note that `upsert_all()` does support a `:on_duplicate` option.

Aura Frames has custom code for mass insert with direct control over the ON CONFLICT clause. Being able to batch inserts like this is a critical part of write scalability, consolidating the overhead of a batch of row insertions (e.g. 1000) into a single commit.

## Scaling reads with batching
Rails supports batched read queries with a few Active Record methods: `find_each()`, `in_batches()`, and `find_in_batches()`.

Aura Frames has custom code for batched finding specifying an arbitrary column on the table and a sorting direction. 

Rails 6.1 did add support for `find_in_batches()` ([API Documentation](https://apidock.com/rails/ActiveRecord/Batches/find_in_batches)) to control ordering, but unfortunately the only column to order on is the primary key column.

Still, reading a batch worth of rows at a time is a critical scalability tactic to make sure that the query runs fast and the result size is not overwhelming.

## Scaling Reads with Paginated Queries
Aura Frames has custom code to perform keyset pagination, and generally does not use LIMIT and OFFSET style pagination built-in to Active Record. LIMIT and OFFSET pagination works for smaller amounts of data, but doesn’t scale well for deep pagination levels or when working with tables with billions of rows.

Keyset pagination with a high cardinality indexed column works well for fetching batches even for multi-billion row tables. The trick is to index a high cardinality column like a timestamp column, then filter on that with a WHERE clause and a LIMIT sized batch of rows. For example fetching rows from a position with a >= or < operator and a LIMIT of 1000. The last accessed value then becomes the cursor position to start from. 

This is an incredibly useful pattern and commonly used for API requests and other spots. To my knowledge Active Record doesn't have a generic keyset style pagination helper.

## Counter Cache Maintenance for Frequently Updated Counters
Rails supports counter_cache columns ([Blog post](https://blog.appsignal.com/2018/06/19/activerecords-counter-cache.html)) as a running counter, kept updated at write time.

Updating their values means row row churn in Postgres, as updates even for a single column create a new immutable row version behind the scenes, leaving behind a former row version, so it's smart to think about which tables will get churned this way and the follow-on impact (the need for Vacuum).

The updates could also cause contention for that row being updated by another process.

Aura Frames does something similar but keeps counter cache columns in a separate but related table. This reduces contention and places the churn more on a separate utility table.

## Random values and Sampling
Ordering by `RANDOM()` is slow (`ORDER BY RAND()`). Aura Frames uses TABLESAMPLE in Postgres, specified with a FROM clause for a table ([Postgres Documentation](https://www.postgresql.org/docs/current/sql-select.html)).

A couple of options are supported like `sampling_method` with built-in options of `system` and `bernoulli`, or they can be expanded further by enabling the `tsm_system_rows module` ([Postgres Documentation](https://www.postgresql.org/docs/current/tsm-system-rows.html)).

## Using Memory Key Value Cache Stores
Aura Frames makes use of the [Active Support Cache Store](https://api.rubyonrails.org/classes/ActiveSupport/Cache/Store.html) via Memcached with HAProxy performing connection management.

Keeping certain values in Memcached is a key part of the scaling strategy, values like per-user counters, per-feature rate limiting, or cached environment variable values with TTLs.

## Managing Schema Changes with Multiple Databases
With 7 new primary databases and new configs in `config/database.yml`, we wanted to continue managing DDL changes via Rails Migrations like normal.

Fortunately this is supported. Each DB has its own `schema.rb`, a Ruby representation of the schema definition, and a directory for migration files.

Since each "new" database was not actually new, but based on an existing table, we started a new "first" migration for it using the existing table definition dumped via `pg_dump`.

This migration version would be added *idempotently* meaning the table was added when it didn’t exist. Initially the table would *not exist* in dev, test, and staging, but based on how we planned to migrate the tables in production, the table would exist there.

The plan was to use physical replication from the original primary instance to create a read only replica, then promote it to become a writer database at switchover time. The replication was used as the means of moving all of the row data. This approach proved very reliable, but it did mean we had the former table copy on the original DB to clean up later. 

Imagine the new migration version was `1234567890`. Once switched over, we manually inserted the version into `schema_migrations` to keep the state consistent with the migration file.

Before inserting the version, we'd `TRUNCATE` the new DB's `schema_migrations` table.
```sql
insert into schema_migrations (version) values ('1234567890');
```

Once that was done, schema management via migrations worked like normal. Migrations can be generated, their files are in their own directory, applied with `rails db:migrate` and `schema.rb` is kept updated. Nifty!
```sh
rails g migration --database new_db

rails db:migrate --database my_animals_db
# or rails db:migrate for all databases

rails db:schema:cache:dump
```

## What’s missing in Rails?
While Ruby on Rails has been expanded to help the needs of large scale apps, and intends to be a somewhat generic framework used for a variety of specific purposes, we did find that some of the features didn't support what we needed. This is a short recap with the idea it may be useful information for future enhancements to Active Record.

- Limitations of `disable_joins: true`, not all association types supported
- Batched finders like `find_in_batches()` don’t support filtering (`WHERE` clause) on non-primary key columns. We want to specify a non-PK column, set the direction ascending or descending, and set a limit.
- Method `insert_all()` didn't support customization of the `ON CONFLICT` clause.
- No built-in method for keyset pagination style pagination.

## Wrap Up
Ruby on Rails has been a critical technology for Aura Frames to build with for more than a decade, enabling a small team to continually ship improvements to customers within the same codebase.

Enhancements in the last handful of versions have been put to use, helping the platform reach greater levels of scale, delivering faster and more reliable experiences to customers.

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

