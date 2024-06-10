---
layout: post
title: "Rails + Postgres Postgres.FM 086 — Extended blog post edition! 🎙️"
tags: [Ruby on Rails, PostgreSQL, Podcasts]
date: 2024-03-07
comments: true
---

I recently joined Michael and Nikolay as a guest on a favorite podcast of mine, [postgres.fm](https://postgres.fm), which has been a favorite going back to when it started in August 2022. Why's that?

![Andrew, Nikolay, and Michael on Rails + Postgres postgres.fm podcast](/assets/images/posts/2024/postgresfm.jpg)
<small>Andrew, Nikolay, and Michael on Rails + Postgres postgres.fm podcast. Image credit: <a href="https://postgres.fm/">postgres.fm</a>.</small>

## Why I like the postgres.fm podcast

As a weekly-release podcast covering PostgreSQL for nearly 100 episodes, Michael and Nikolay have covered a lot of ground! All of the episodes have great content, covering a nice level of depth, in a short amount of time. Each host brings their unique perspective.

The launch of the podcast overlapped with writing my PostgreSQL book. Most Friday mornings of episode releases, I’d hop onto my treadmill and listen. I’d usually have follow-up ideas and notes from each episode.

The weekly release cadence helped me stay motivated while writing, and the coverage helped broaden my perspectives.

I’m really thankful to Michael and Nikolay for creating the podcast, and releasing episodes each week. I know it’s been a lot of work for them, and it's been quite generous of them to share their knowledge with the community.

Now, on with the Rails + Postgres episode!

## Is Postgres a popular choice for Rails?

This was the first question from Michael. It's difficult to answer with confidence, especially since I'm in sort of a bubble of PostgreSQL fans.

Subjectively, PostgreSQL feels like the most popular relational database choice for new Rails apps.

To add a little objectivity, we did bring in the Planet Argon survey with results from more than 2600 respondents from 2022.

The 2022 Ruby on Rails Community Survey from Planet Argon[^1] responses show that PostgreSQL took over in 2014 from MySQL, as the top choice of being "typically used" as the relational database, and has continued to stay there.

[^1]: <https://rails-hosting.com/2022/#databases>

## What about MySQL and others?

As far as other open source relational databases, MySQL or MariaDB are popular for Ruby on Rails apps today, and have been since Rails started in the 2000s. Companies like Shopify, GitHub, Airbnb that famously adopted Ruby on Rails in the 2000s and continue to use it, all generally started with MySQL and continue to use it. For those companies that have invested heavily in performance, sharding,[^2] and other operations, it makes a lot of sense to stick with their relational database.

The investments these companies have made into Ruby on Rails though still provides benefits to PostgreSQL.

From investments into Active Record engineers at those companies have made into open source, PostgreSQL has gained framework support for Multiple Databases, including support for sharding as "Horizontal Sharding," read and write splitting with automatic routing of reads to a replica ("Automatic Role Switching"), and more.

We can see this investment by digging into the commit history for Ruby on Rails and Active Record from engineers at those companies, and for features like Horizontal Sharding. [^3]

[^2]: <https://github.blog/2021-07-12-adding-support-cross-cluster-associations-rails-7>

[^3]: <https://edgeguides.rubyonrails.org/active_record_multiple_databases.html#horizontal-sharding>

Other supported relational database options include SQLite.

Commercial relational databases like Oracle or SQL Server (MS SQL), or non-relational databases like MongoDB or DynamoDB may work with Active Record, but require additional library code.

## How do folks typically query Postgres from a Rails app?

Rails developers usually interact with PostgreSQL via the Active Record ORM.

To do that, they place PostgreSQL connection details into the db/config.yml YAML configuration file, then add a Ruby postgres driver like the "pg" gem, which is responsible for establishing connections from the app to PostgreSQL.

Active Record creates an application-level connection pool to lazily open physical database connections to PostgreSQL. These are opened up and left idle when not in use for up to 5 minutes by default.

With that pool of connections available, Active Record Ruby writes and reads data to PostgreSQL.

Besides applications as "clients," teams might use CLI clients like psql or graphical clients like TablePlus or DBeaver.

Rails applications ship with a "[Rails Console](https://guides.rubyonrails.org/command_line.html)" which is an enhanced version of the interactive Ruby interpreter REPL included with Ruby.

We can use the Rails Console to run snippets of Active Record code, and inspect the generated SQL.

For example we might run `User.find(1)` which would generate and execute a SQL query like `["SELECT * FROM users WHERE id = ?", 1]`.

Active Record can do a lot of things before sending the query, such as annotating queries as [Query Logs](https://api.rubyonrails.org/v7.0.4/classes/ActiveRecord/QueryLogs.html) which are comments that describe where the query was generated.

## What’s the ORM like? Any tips around setup?

Active Record is used in two major ways.

Most people think of the ORM usage that writes SQL queries from programming language code (Active Record in Ruby). The SQL queries either persist or retrieve data that populates in-memory Active Record object instances.

The ORM use is primarily Ruby classes as "models" in our application code, which could be business logic, that are then mapped to PostgreSQL table names. "Associations" in Active Record are used to link models together.

Active Record is pleasant to use as a Ruby programmer, just as the Ruby programming language is pleasant to use. They complement each other. Ruby and Active Record are more compact compared with SQL or more verbose programming languages like Java in my experience.

Active Record is one of the main reasons Rails developers like Rails.

While Active Record helpers are designed to allow developers to not write SQL, for developers that *do* wish to write SQL, that's also possible using Active Record. This can be quite handy to co-mingle SQL and Active Record code.

## Active Record for schema evolution management

Besides acting as an ORM, there's another primary use of Active Record, and that's as the schema management and evolution tool. This means we're writing Active Record to modify database objects, creating things like tables, indexes, or views.

Outside of Ruby on Rails, other communities might use tools like Flyway or Liquibase, or a tool that's built in to the web framework.

Active Record has a lot of nice helpers to perform DDL changes, and beyond that, there are lots of open source libraries that enhance Active Record further for "Migrations."

There's no concept of safe migrations though, which are migrations that take long locks and can block concurrent operations. Fortunately, open source libraries exist that can be easily added to achieve this.


## What’s the schema.rb vs structure.sql beef about?

In Active Record, the schema is represented as a text file that’s checked into source code control within the repository. This file represents the entire state of the database, and is a secondary file that’s derived from other smaller files that each represent an incremental change. These incremental change files are called "Migrations."

The text file may be a Ruby file or a SQL file. When PostgreSQL is used and the SQL format is chosen, the output file is generated from running `pg_dump` against the local application database.

The Ruby version is the default though, and is called `schema.rb`, and is 100% Ruby code. This file has maybe 90% of the information that the SQL version would have, so often in the course of an application, teams might *switch* to the SQL version to gain greater fidelity in how the database state is represented in file form.

For example, some database objects are not captured at all in the Ruby version of the file, such as database triggers. This can be a big problem when you're using those features, as newer instances of the application would have inconsistent database objects.

In those cases, developers need to extend the Ruby version capabilities, or switch to the SQL version.

For teams that aren’t used to working with `pg_dump` output, and mostly work exclusively with Ruby or serialization formats like YAML, adopting the SQL version might be a significant change for them, and they may push it off or avoid it.


## Any issues a DBA is more likely to see in a Postgres instance serving Rails-like applications?

The N+1 pattern can show up commonly from Active Record, which is an inefficient query pattern where repeated queries inside a loop can be rewritten to be a single query for multiple values.

This can result from not thinking about `JOIN` operations possibly, since developers are usually working in the object-oriented code paradigm, and thinking as much about the relational data model, and database operations.

To generalize this further, a DBA could see inefficient queries due to inefficient schema design, missing indexes, the existences of unused indexes, missed opportunities for HOT updates, poorly tuned databases, or many more common operational issues.

Another form of inefficient queries could be `SELECT *` when fewer columns are sufficient, or not adding query restrictions to `WHERE` clauses or `JOIN` conditions, or not adding a `LIMIT` and returning more rows than necessary.

Some of these query inefficiencies aren’t limited to Ruby on Rails, and might be common whenever an ORM is used, as developers can fall into these kinds of traps by not closely considering their SQL queries.

Another common poor-performer especially on versions earlier than Postgres 14 is the pattern of a "giant list of values for an `IN` clause," or limited use of `IN` vs. `ANY()`.

- <https://pganalyze.com/blog/5mins-postgres-performance-in-lists-vs-any-operator-bind-parameters>
- <https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=50e17ad28>

For `SELECT *` or when no `SELECT()` statement is provided, we can use an option in Active Record that enumerates all fields. This could help developers find this during development, and determine whether a narrower list of columns would suffice.

- `config.active_record.enumerate_columns_in_select_statements` <https://www.bigbinary.com/blog/rails-7-adds-setting-for-enumerating-columns-in-select-statements>

Another recent improvement to highlight in Active Record adds to the Active Record instrumentation, warning about very large result sets.

- <https://github.com/rails/rails/pull/50887>

Nikolay pointed out that `pg_stat_statements` also includes the rows returned as one of the statistics, which again is an opportunity for a developer or DBA to look at their query workload and add more query restrictions.


## Structural changes on live databases

Another possible surprise for DBAs new to Rails, is that Rails developers typically "own" the schema design for the applications, which can mean they might make unsafe DDL changes not knowing the impact.

For example, adding an index to a table without using the `CONCURRENTLY` keyword, then causing errors due to blocked writes.

While Active Record doesn't detect this, fortunately open source tools can, and are often added to Rails applications to add safety.


## What’s the Rails + Postgres tooling ecosystem like? What are gems?

The Ruby open source shared library code ecosystem is very rich. In the book we cover more than 40 open source software items, with around 20 of those being Ruby gems (the other 20 are PostgreSQL extensions) that are added to the Rideshare application, used for examples and exercises in the book.

RubyGems are the mechanism in the Ruby language to package up and distribute shared library code. They are built and hosted usually on <rubygems.org>. They are roughly equivalent to PostgreSQL extensions, in that they leverage extension points, and add functionality to the core.

The book covers these gems or you can explore the Ruby Toolbox which has gems grouped into categories. <https://www.ruby-toolbox.com/>

## Any tips, or myths, around scaling?

I have some generic tips for creating high performance PostgreSQL queries.

First, learn how to understand the "costs" for components of a query, by regularly inspecting query plans using the `EXPLAIN` keyword and query planner.

The planner provides cost information, and the job of developers writing queries is to lower the cost of them, mostly by adding well-placed indexes.

For myths, I think developers think that `JOIN` operations are so costly as to be avoided, which means that they may skip out on good data normalization practices.

Brian Davis has a great post with benchmarks showing the cost of a join.[^5] The takeaway for me from that post was that the cost of a join is nominal and should not limit the use of good data normalization practices, even when tables grow to millions of rows, and many `JOIN`s are being performed at once.

[^5]: <https://www.brianlikespostgres.com/cost-of-a-join.html>

There's a cost though of course. This means the developer needs to use efficient schema design choices and create well-placed indexes that support the queries and join operations.

For example, tactics like indexing foreign keys, using Multicolumn and Covering indexes, and using indexes to support `ORDER BY` operations.

Another myth is that PostgreSQL isn’t capable of certain kinds of work like Full Text Search, caching, analytics, sharding, or background jobs. Instead, teams might add additional non-relational databases, and a complicated data synchronization process.

While this was more true 10 years ago with slower and smaller and more expensive disks, with SSD drives and the performance improvements to PostgreSQL over the last decade, this is not true today.

PostgreSQL is often heavily *under-utilized* in the overall workloads for business applications. Instead of using PostgreSQL, teams might be using a hodgepodge mix of database systems, taking on a lot more complexity, maintenance, and cost.

## Is there anything you’d like to see from the Postgres community that would make things easier/better for Rails users?

I think web application developers really want to know which queries to optimize, and for that optimization process to be succinct and repeatable. PGSS (`pg_stat_statements`) is a great visibility tool but still lacks things like "samples". In PostgreSQL 16 we gained "generic plans" but samples with full query text would help.

I gave a 5 minute lightning talk on some visibility tools at PGConf NYC to help raise awareness of what we've got now in PostgreSQL 16. Michael and I collaborated on how to use the queryid "fingerprint" information that PostgreSQL gained in 14 with `auto_explain`, but that's limited to configuring your system to only log queries that are quite lengthy, when we might want samples from "fast" queries too.

- <https://speakerdeck.com/andyatkinson/pgconf-nyc-2023-lightning-talk>

Since PostgreSQL adds and enhances system catalogs, maybe a catalog could contain query text samples for certain queries by their `queryid` identifier, or even collect samples based on different thresholds like excessive buffers or excessive row counts, that we could then use as information to perform query optimizations.

## Post-show ideas/reflections/thoughts

For anyone interested in exploring a bit with Rails and PostgreSQL, the book uses a Rails application on GitHub called "Rideshare", throughout the book for examples and exercises. We didn’t mention this in the episode, but I wanted to mention it here. The application is public and available here: <https://github.com/andyatkinson/rideshare>

Within the source code directory, there’s a "postgresql" directory that has some goodies <https://github.com/andyatkinson/rideshare/tree/main/postgresql> like a `.pgpass` file to store credentials, a config file for pgbouncer, and a postgresql sample config file with some changes made in book exercises.

We didn’t cover this, but the book also uses the PostgreSQL client "psql" exclusively. Since Rails developers are used to working with the Rails Console, I hoped some readers might pick up psql as their go-to client.

There's a lot of content in the book that’s not related to Ruby on Rails at all. For example, SQL language functions, PL/pgSQL functions, shell scripts, table partitioning, full text search (with `tsvector` and `tsquery`) are covered. We also show how to use PostgreSQL as a message queue or for background jobs with `LISTEN` and `NOTIFY`, and some brief coverage of the `pgvector` extension and vector similarity search.

##  More coverage of Active Record and PostgreSQL

We didn’t cover some of the breadth of support for PostgreSQL features in Active Record, so I wanted to add some of that in here in this section. These topics are all covered in the book.

Consider exploring the PostgreSQL page within the Active Record documentation: <https://guides.rubyonrails.org/v7.1/active_record_postgresql.html>

- PostgreSQL Generated columns (Active Record virtual stored columns)
- Deferrable foreign keys support
- Check constraints
- Setting a Transaction isolation mode in Active Record
- Exclusion constraints
- Full text search using tsvector
- Database views
- Advanced Data types like Arrays and Ranges
- Query hint planning from Active Record, using `pg_hint_plan`. The book has an example of how to use this. 
- `RETURNING` clause for `INSERT` (and possible other DML ops in the future: <https://github.com/rails/rails/pull/47161>)


## Additional Links

- GitLab Migration Style Guide (mentioned by Nikolay) <https://docs.gitlab.com/ee/development/migration_style_guide.html>
- Lukas Fittl’s gem mentioned in the show, that helps keep the SQL structure dump consistently formatted <https://github.com/lfittl/activerecord-clean-db-structure>


## Errors

I mentioned Rails was used at DoorDash, but I don’t know if that's true.

I knew DoorDash used PostgreSQL in the past, but I could only find public writing about having used the Python Django framework.

The DoorDash engineering blog has some nice posts on production migration operations with PostgreSQL.

- <https://doordash.engineering/2022/01/19/making-applications-compatible-with-postgres-tables-bigint-update/>


<!-- Callout box -->
<section>
<div style="border-radius:0.8em;background-color:#eee;padding:1em;margin:1em;color:#000;">
<h2>Podcast</h2>
<p>👉 <a href="https://postgres.fm/episodes/rails-postgres">Listen to the episode</a></p>
</div>
</section>

## Wrapping Up

Thank you Michael and Nikolay!
