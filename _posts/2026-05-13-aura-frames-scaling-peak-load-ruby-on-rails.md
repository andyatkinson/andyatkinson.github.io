---
layout: post
permalink: /how-aura-frames-scales-for-peak-load-ruby-on-rails
title: "Scaling Rails at Aura Frames: Lessons from Splitting to 8 Primaries and reaching #1 in the App Store"
hidden: true
---

<div class="summary-box">
<strong>📌 Overview</strong>
<p>Ruby on Rails has helped make it possible to scale out the database layer, meeting the demands of millions of customers setting up millions of digital frames.</p>
<p>In 2025, the Aura Frames team added primary databases to expand capacity for peak write and read load ahead of Christmas Day, the busiest day of the year for the company. Rails helps manage pools of connections for each primary database, within the same codebase.</p>
<p>With 8 primary databases in total, each server instance can be vertically scaled ahead of peak load, and back down for cost savings.</p>
<p>To make this possible within a single Ruby on Rails codebase, the team leveraged native support for Multiple Databases and the <code>disable_joins: true</code> feature in Active Record, which replaces SQL joins but still combines data from tables in different databases.</p>
<p>This post looks back at the technical details of that plan, as well as a variety of additional data layer scaling tactics, that culminated in a successful Christmas 2025 season, and a peak App Store ranking of #1 in the US and Canada.</p>
</div>

## Building With Ruby on Rails
The Aura Frames platform has been built with Ruby on Rails since the beginning. Christmas 2025 was the busiest day of the year for the company and technical platform, serving a peak of 41 million API requests per hour (~11.4K requests per second), and processing a peak of 11.8 million background jobs per hour.

For an introduction to the Aura Frames company and products, please check out Part 1 of this series.

**Brief Recap from Part 1**: Besides Ruby on Rails, Aura Frames uses PostgreSQL and AWS as key technologies.

Due to not being easily scalable horizontally for write operations, the database layer of PostgreSQL and Active Record often became a bottleneck. The team relied on vertically scaling the single primary server instance through Christmas of 2024.

The largest instance available for RDS at the time was the 48x family (192 vCPU, 1.5 TB RAM). Even with that jumbo-sized instance, the platform had reliability issues at peak load on Christmas 2024, driving a need to re-design for reliability improvements before Christmas 2025.

To handle greater levels of peak traffic reliably, the team decided to introduce application-level sharding using multiple primary databases. Several alternative approaches were considered. One goal was to leverage the existing code as much as possible, with minimal changes, and control the sharding distribution from the application level.

Another choice was whether to do traditional sharding at the row level, which distributes rows across multiple instances with databases having the same schema.

Fortunately Ruby on Rails was enhanced over more than 15 years of development to support the needs of mature, scaled-up platforms with billions of rows and terabytes of data, with patterns but also flexibility. A couple of key capabilities could be used to accommodate either strategy.

Before getting into the solution details, let's look at some technical metrics from Christmas Day 2025 to help set context.

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
      <td>41 million requests/hour</td>
    </tr>
    <tr>
      <td>Average Response Time (10am to 9pm CT)</td>
      <td>650 milliseconds</td>
    </tr>
    <tr>
      <td>Cloudfront Global Requests</td>
      <td>33,675,000 requests/hour</td>
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

An exciting development for the team was seeing the free iOS and Android Aura Frames app rise in ranking throughout the day.

Late on Christmas Day, the app reached a peak rank of #1 among all free apps in the U.S. and Canadian App Stores, beating apps from big companies like OpenAI (ChatGPT) and Meta (Meta AI)!

![Aura Frames #1 App U.S. App Store Christmas Day](/assets/images/aura-christmas-2025.jpg)
<br/>
<small>Screenshot showing the Aura Frames app at the #1 rank in the U.S. Apple App Store</small>

Although there is a lot of interesting history from how the Aura Rails codebase evolved over a decade, let's look at the changes made from mid-2025 before Christmas Day 2025 to Active Record to make the numbers above possible.

## Getting Started With Multiple Databases
From earlier, you learned that the Aura Frames platform was expanded from a single primary application DB to a total of 8.

To do that, heavy refactoring was performed to Active Record query layer code for tables being moved.

Queries for tables must not span a database boundary, and given some of the big tables were being moved to a new database, queries would break.

The development environment uses a Docker Postgres instance and to keep things simple locally, all 8 databases were run there. This meant the queries still "broke" (helpfully) when they spanned a database boundary, but we didn't need to run 8 different instances locally.

These breakages showed up as “failing tests” in the extensive test suite, which was supremely useful to help know what needed to change.

The gist of the changes was pretty straightforward, find the breaking queries, unravel joins or other incompatible SQL, and change connections to the correct database. Their query results were then passed around in Ruby as input to queries in other databases.

With hundreds of failing tests to sift through, the refactoring work took a long time as test failures were addressed one by one, but progress was easy to measure.

Eventually, weeks later, all tests were passing! The nice property about this design was the same query changes without SQL joins could be performed on the existing main DB, meaning the changes were backwards compatible and could be rolled out in place initially before the new DBs were in place.

Some of the main changes were evaluating all Active Record relationships (`has_many`, `belongs_to`, etc.) and any subquery expressions or other incompatible code, and using `disable_joins: true`, removing subquery expressions and table references.

## From SQL Joins to Multiple SELECTs
The key parts of Ruby on Rails and Active Record that made this possible were Multiple Databases launched in 6.0, then the `disable_joins` feature for `has_many :through` and `has_one :through` relationships, to query across databases, [launched in Rails 7.0](https://www.bigbinary.com/blog/rails-7-adds-disable-joins-for-associations) (2021).

Both of these were possible with custom code or third party library code (Ruby gems) before, but having native support in Rails was a differentiator. Native support meant more real world use, bug fixes, improved documentation, and a longer term commitment to supporting these features.

Having `disable_joins` as a consistent pattern also helped with comprehension by the team, enabling "learn how it works once, then re-use it all over the codebase."

Due to the increase in SELECT queries (and loss of join efficiency), the team had concerns about additional read query volume. Fortunately the team had a load testing tool in place and was able to verify through load testing that the additional read queries performed would not be a problem.

Here's a simple example using `Author` and `Post` models illustrating how `disable_joins: true` works:
- Author (table_name: `authors`)
- Post (table_name: `posts`)
- AuthorPost (table_name: `author_posts`)

Author model has an existing association defined as: `has_many :posts, through: :author_posts`.

To change this association, the `disable_joins: true` option is added like this:
```rb
class Author < ApplicationRecord
  has_many :posts, through: :author_posts, disable_joins: true
end
```

What's happening in SQL? Previously to get an Author’s posts, we’d query the `author_posts` table and join to the posts table on the author’s id.

Instead of that, there will now be two queries performed like below. One queries `author_posts` by `author_id` (an important foreign key column to index) to get post `id` values. Then a second query to the `posts` table by `id` (uses primary key index) gets the rows from the second table.
```sql
select * from author_posts where author_id = '<some id>';
select * from posts where id IN (?);
```

What else needed to change?

## New Database Configuration
Although we could roll this out on the same single DB, that was planned only temporarily to validate queries without the new DBs in place.

The main plan was to use Multiple Databases, relocate some of the largest, busiest tables to their own instances, all accessed from the single Rails codebase.

For that we'd need to provision all the new DBs and connect to them from Rails. The first thing we needed was new YML config entries (`config/database.yml`) for each of them. The [Multiple Databases Documentation](https://guides.rubyonrails.org/active_record_multiple_databases.html) uses "animals" and `my_animals_db` as the second primary database, so we'll use that too for examples here.

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

Eventually all new DBs and infra (PgBouncer, config vars) were set up, and could be switched over to. In the Rails app, the new DBs were named generically as they didn't really correspond to a particular grouping of activity like a service, we just wanted a bunch of DBs with unique names.

The names of the DBs were part of the parent model, now the parent of the original model. Since the original model doesn't change with this, the new DB details are nicely "hidden" (encapsulated) in the parent model.

`disable_joins` for `has_many :through` relationships ended up covering a lot of the needed query changes to get tests passing again, however there were other issues encountered on the way.

What were they?

## Post-split: Subquery Expressions
Multiple tables exist in subquery expressions (aka "subqueries"), and these tables need to be in the same database for the statement to be valid.

When we found those, they needed to be restructured so that the DBs containing the table could be queried.

## Post-split: EXISTS Clauses
Post-split, the SQL below doesn't work when `users` and `posts` (example models) aren't in the same DB.
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

Not all HABTM relationships were changed. When the HABTM involved tables in the same DB, those didn't need to change and were left unmodified.

## Scaling Inserts and Updates
With Multiple Databases and `disable_joins: true` covered, what other database scalability tactics are used?

Rails supports bulk inserts and *upserts* (either an insert or an update), however the helper method for mass-inserting data didn't support what we needed. A limitation was that the ON CONFLICT clause couldn't be customized for `insert_all()` ([API Documentation](https://api.rubyonrails.org/v7.0/classes/ActiveRecord/Persistence/ClassMethods.html#method-i-insert_all)). For example attempting an INSERT and specifying the DO NOTHING option when unique constraint violations occur.

Note that `upsert_all()` does support a `:on_duplicate` option.

Aura Frames has custom code for mass insert with direct control over the ON CONFLICT clause. Being able to batch inserts like this is a critical part of write scalability, consolidating the overhead of a batch of row insertions (e.g. 1000) into a single commit.

## Scaling reads with batching
Rails supports batched read queries with a few Active Record methods: `find_each()`, `in_batches()`, and `find_in_batches()`.

Aura Frames has custom code for batched finding, specifying an arbitrary column on the table and a sorting direction. 

Rails 6.1 did add support for `find_in_batches()` ([API Documentation](https://apidock.com/rails/ActiveRecord/Batches/find_in_batches)) to control ordering, but only the primary key column may be ordered on in ascending or descending order. We needed to order on arbitrary columns.

Still, reading a batch of rows is a critical tactic to make sure that query execution times are stable when querying data with varying amounts of results.

## Scaling Reads with Paginated Queries
Aura Frames has custom code to perform keyset pagination, and generally does not use LIMIT and OFFSET style pagination built-in to Active Record. LIMIT and OFFSET pagination works for smaller amounts of data, but doesn’t scale well for deep pagination levels or when working with tables with billions of rows.

Keyset pagination with a high cardinality indexed column works well for fetching batches even for multi-billion row tables. The trick is to index a high cardinality column like a timestamp column, then filter on that with a WHERE clause and use LIMIT for a batch of rows. Note that timestamps can be duplicated, so you may need an additional column in that case.

An example fetch might be from a value with a `>=` or `<` operator and a LIMIT of 1000 as a batch size. The last accessed value then becomes the cursor position to start from.

This is an incredibly useful pattern and commonly used for API requests and other spots. To my knowledge Active Record doesn't have a generic keyset style pagination helper.

## Counter Cache Maintenance for Frequently Updated Counters
Rails supports counter_cache columns ([Blog post](https://blog.appsignal.com/2018/06/19/activerecords-counter-cache.html)) as a running counter, kept updated at write time.

Updating their values means row churn in Postgres, as updates even for a single column create a new immutable row version behind the scenes, leaving behind a former row version, so it's smart to think about which tables will get churned this way and the follow-on impact (the need for Vacuum).

The updates could also cause contention for that row being updated by another process.

Aura Frames does something similar but keeps counter cache columns in a separate but related table. This reduces contention and places the churn more on a separate utility table.

## Random values and Sampling
Ordering by `RANDOM()` is slow. To avoid that, the Aura codebase uses TABLESAMPLE in Postgres, which is specified with a FROM clause for a table ([Postgres Documentation](https://www.postgresql.org/docs/current/sql-select.html)).

A couple of options are supported like `sampling_method` with built-in options of `system` and `bernoulli`, or they can be expanded further by enabling the `tsm_system_rows module` ([Postgres Documentation](https://www.postgresql.org/docs/current/tsm-system-rows.html)).

## Using Memory Key Value Cache Stores
Aura Frames makes use of the [Active Support Cache Store](https://api.rubyonrails.org/classes/ActiveSupport/Cache/Store.html) via Memcached with HAProxy performing connection management.

Keeping certain values in Memcached is a key part of the scaling strategy, values like per-user counters, per-feature rate limiting, or cached environment variable values with TTLs.

## Managing Schema Changes with Multiple Databases
With the 7 new DBs and configs in `config/database.yml`, we wanted to continue managing DDL changes via Rails Migrations like normal.

Fortunately this is supported. Each DB has its own `schema.rb`, a Ruby representation of the schema definition, a directory for migration files, and a place for config options.

Since each "new" database was not actually new, but based on an existing table definition, we started a new "first" migration for it using the existing table definition dumped via `pg_dump`.

This migration version was written to be *idempotent* meaning the table was added only when it didn’t exist. Initially the table would *not exist* in dev, test, and staging, but based on how we planned to migrate the tables in production, the table would exist there.

**Brief recap from Part 1**: The plan was to use physical replication from the original primary instance to create a read only replica, then promote it to become a writer database. The replication was used as the means of moving all of the row data. This approach proved very reliable, but it did mean we had the former table copy on the original DB to clean up later. 

Imagine the new migration version was `1234567890`. Once switched over, we manually inserted the version into `schema_migrations` to keep the state consistent with the migration file.

We'd `TRUNCATE` the new DB's `schema_migrations` table and then insert the "new" migration version above as follows:
```sql
insert into schema_migrations (version) values ('1234567890');
```

Once that was done, schema management via migrations worked like normal. Migrations could be generated with their own directory for files, applied with `rails db:migrate` and `schema.rb` kept updated.

Some example commands:
```sh
rails g migration --database new_db

rails db:migrate --database my_animals_db
# or rails db:migrate for all databases

rails db:schema:cache:dump
```

## What’s missing in Rails?
While Ruby on Rails has expanded to help the needs of large scale apps, we did find that some of the features didn't yet support our specific needs. This is a short recap of those (from above) with the idea it may be useful information for future enhancements to Active Record.

- Limitations of `disable_joins: true`, not all association types are supported
- Batched finders like `find_in_batches()` work with primary key columns, but we wanted to use cursor or keyset style pagination from arbitrary columns on the table. We also need to set the direction and the batch size.
- Method `insert_all()` didn't support customization of the `ON CONFLICT` clause.
- No built-in method for keyset style pagination.

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

