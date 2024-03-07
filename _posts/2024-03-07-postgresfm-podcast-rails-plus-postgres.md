---
layout: post
title: "Rails + Postgres | Postgres.FM 086 | podcast"
tags: []
date: 2024-03-07
comments: true
---

Postgres + Rails postgres.fm: Super extended blog post edition!



I was a guest on the most recent episode of postgres.fm, and had a lot of fun! postgres.fm is one of my favorite and most listened-to podcasts, really since it started back in August 2022.

## Why I like the postgres.fm podcast

As a weekly podcast covering PostgreSQL topics, nearing 100 episodes, Michael and Nikolay have covered a lot of topics! All of the episodes have had great content, covering valuable topics at a nice level of depth. Each host brings their background and perspective, and they seem to complement each other.

The launch of the podcast overlapped with the early phase of writing my PostgreSQL book. Each Friday morning when episodes were released in the US, I’d often hop onto my treadmill and listen to them while walking or running. I’d usually have follow-up ideas and things to experiment with after each one.

The weekly release cadence helped me stay motivated while writing, and broadened my perspectives on a variety of topics. I’m really thankful that Michael and Nikolay created the podcast, and have continued to release episodes each week. I know it’s a lot of work, and appreciated having the opportunity to contribute to that.

Now, on with the questions and follow-ups from the episode!
## Is Postgres a popular choice for Rails?

This was difficult to answer with confidence. Subjectively, PostgreSQL feels like the most popular relational database choice for new apps, but I’m in a bubble as I surround myself with PostgreSQL news sources. Michael pointed out how we’re all biased in the episode as we’re all focused on PostgreSQL whether for business or for the book and my jobs, in my case.

To add a little objectivity, we did bring in the Planet Argon survey with results from 2600 respondents from 2022.

The 2022 Ruby on Rails Community Survey from Planet Argon,[1] 2,660 members responded. In the databases section, PostgreSQL flipped with MySQL for the top choice "typically used" from around 2014 onward and continues to be there.

[1] https://rails-hosting.com/2022/#databases

## What about MySQL and others?

As far as other open source relational databases, MySQL or MariaDB are very popular for Ruby on Rails apps today, and also Rails apps that started in the 2000s. Companies like Shopify, GitHub, Airbnb that famously started on Ruby on Rails in the 2000s all generally started with MySQL and continue to use it, per my understanding of publicly shared tech stack info.

There are still benefits for PostgreSQL though. Since the use and ongoing investment into Ruby on Rails has happened at these bigger, public, successful companies, engineers there in some cases are paid to work on Rails, or are able to work on Rails at their jobs, besides all the generosity from open source volunteers, and those investments going into Active Record benefit all the supported relational databases.

From Active Record then, PostgreSQL has gained support in the framework for Multiple Databases, including Sharding support via Horizontal Sharding, Read and Write splitting with automatic routing of reads to a replica, at least with basic implementations available natively without additional dependencies. The benefit of native framework support is that these features are well tested and well documented.

We can draw lines to those companies by digging into the commit history for Ruby on Rails and Active Record for those features like "Horizontal Sharding" [3].

[2] https://github.blog/2021-07-12-adding-support-cross-cluster-associations-rails-7/

[3] https://edgeguides.rubyonrails.org/active_record_multiple_databases.html#horizontal-sharding


Other supported database options are the SQLite relational database for Active Record.

Commercial relational databases like Oracle or SQL Server (MS SQL), or non-relational databases like MongoDB or DynamoDB may work with Active Record, but would require adding more dependencies as they’re not natively supported.

## How do folks typically query Postgres from a Rails app?
Rails developers usually interact with PostgreSQL via the Active Record ORM.

To do that, they place PostgreSQL connection details into the db/config.yml YAML configuration file, then add a Ruby postgres driver like the "pg" gem, which is responsible for establishing connections from the app to PostgreSQL.

Active Record creates an application-level connection pool to lazily open physical database connections to PostgreSQL. These are opened up and left idle when not in use for up to 5 minutes by default.

With that pool of connections available from the application, Active Record Ruby code that developers write will perform reads and writes to PostgreSQL.

Besides applications as the "clients," teams might use CLI clients like psql or graphical clients like TablePlus or DBeaver to connect to PostgreSQL for introspection, administration, or other tasks.

Rails applications ship with a "Rails Console," which is an enhanced version of the interactive Ruby interpreter REPL that’s included with Ruby.

We can use the Rails Console to run snippets of Active Record code, and inspect the generated SQL.

For example we might run "User.find(1)" in the Rails Console, which would execute a query like `["SELECT * FROM users WHERE id = ?", 1]`. Active Record can do a lot of things before sending the query, such as annotating queries with comments describing which code generated the query.

## What’s the ORM like? Any tips around setup?
Active Record is used in two major ways.

Most people would first think of using the ORM to write application code that produces SQL queries. The SQL queries persist or retrieve data that’s associated with in-memory Active Record object instances.

How does that work? Mainly, we create Ruby classes as "models" that map up PostgreSQL table names, and "associations" to link up associated models with each other.

Active Record is pleasant to use as a Ruby programmer, just as the Ruby programming language is pleasant to use. Ruby and Active Record can be more compact compared with SQL or more verbose languages like Java, and can have less "obscure" incantations or boilerplate to get things done.

Active Record could be one of the main reasons Rails developers like Rails. While Active Record helpers are designed to allow developers to not need to write SQL, Active Record also allows developers to write SQL within strings, use bind parameters, and map responses to primitive types or to Active Record instances. This can be quite handy to co-mingle SQL and Active Record code.

## Active Record for schema evolution management

Besides generating SQL queries, Active Record is also used to modify the "schema" or structure of the database. This is when we’re adding database objects like tables, indexes, etc.

Outside of Ruby on Rails, other popular technologies for this are Flyway or Liquibase, of a built-in mechanism the web framework provides.

Active Record has a lot of nice helpers to perform these kinds of DDL changes, and beyond that, there are lots of additional open source libraries that enhance Active Record further.

There is no concept of safety though, which refers to operations that take long locks and can block other concurrent operations. Fortunately there are open source libraries to add to Ruby on Rails that help avoid unsafe DDL operations. 


## What’s the schema.rb vs structure.sql beef about?
This is not a "real" beef (hehe), but is a sort of a decision point Rails programmers make, or re-make over time.

In Active Record, the schema is represented as a text file that’s checked into source code control within the repository. This file represents the entire state of the database, and is a secondary file that’s derived from other smaller files that each represent an incremental change. These incremental change files are called "Migrations."

The text file may be a Ruby file or a SQL file. When PostgreSQL is used, the SQL file that’s generated is almost exclusively the output from running "pg_dump" against the application database, with a bit more content added to the end.

The Ruby version is schema.rb, and is 100% Ruby code, and has maybe 90% of the information that the SQL version has. For example some database objects are not captured at all in the Ruby version of the file. This is a big problem if you want the highest fidelity information about your database schema design saved into this file.

In those cases, developers need to either extend the Ruby version of the file, or switch to adopting the SQL version. For teams that aren’t used to working with pg_dump output, and mostly work exclusively with Ruby or serialization formats like YAML, adopting the SQL version of the file can represent a significant change that they might push off or avoid. 


## Any issues a DBA is more likely to see in a Postgres instance serving Rails-like applications?

The N+1 pattern can show up commonly from Active Record, which is an inefficient query pattern where repeated queries inside a loop can be rewritten to be a single query for multiple values.

This can result from not thinking about joins in the relational DB possibly, since developers are working in the object-oriented code paradigm, and not as much thinking about the queries being generated.

To generalize this a bit further, a DBA could see inefficient query plans being generated, which could come from inefficient schema design, misuse of features, or under-use of indexes. Another form of inefficient queries could be "SELECT *" when fewer columns would be adequate, not adding all the possible query restrictions to the WHERE clauses, or not adding a LIMIT and returning more rows than necessary. These aren’t limited to Ruby on Rails, but perhaps all ORM users can fall into these kinds of traps but not closely thinking about the SQL and without storing and accessing as little data as possible in each operation. 

Another common poor-performer at least < Postgres 14 is the "giant list of values in an IN clause." Performance for large amounts of values like 1000 or more was improved in PostgreSQL 14. 
(Andy add links)
https://pganalyze.com/blog/5mins-postgres-performance-in-lists-vs-any-operator-bind-parameters
James Coleman patch (copied from the 5min of Postgres links): https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=50e17ad28

Benoit is also working with PostgreSQL contributor Peter G. on a certain type of query pattern with multiple WHERE clause conditions that causes an additional filtering step within an index scan, leading to poorly performing plans. This could happen in Active Record when chaining together multiple "where()" clause conditions.

Per Benoit, Peter says the fix going into PostgreSQL should ship in version 17, that can identify this scenario, and optimize the query plan to avoid the additional filtering step.

For "SELECT *" we can use an option in Active Record to enumerate all fields. This might make it more obvious for developers during development, that all fields are being fetched.

Config.active_record.enumerate_columns_in_select_statements
https://www.bigbinary.com/blog/rails-7-adds-setting-for-enumerating-columns-in-select-statements

This change in Active Record adds to the Active Record instrumentation events and warns about very large result sets being returned.
https://github.com/rails/rails/pull/50887

Nikolay pointed out that pg_stat_statements shows the rows returned as a stats column, which can also be used to identify opportunities to add more query restrictions or a LIMIT clause.

## Structural changes on live databases

Another big category DBAs might be surprised about is that Rails developers are "owning" the schema evolution, including making possible unsafe DDL changes.

For example, an index being added to a table that’s actively receiving writes, without adding hte index using the CONCURRENTLY option, and causing errors due to blocked writes. This can be detected by tools that force the use of CONCURRENTLY, and are added into the Migrations process for developers, but this doesn’t happen automatically with Ruby on Rails. As mentioned before, there’s no built-in concept of "safety."


## What’s the Rails + Postgres tooling ecosystem like? What are gems? 
The Ruby open source shared library code ecosystem is very rich. In the book we cover more than 40 open source software items, with around 20 of those being Ruby gems that are added to the Rideshare application for examples and exercises throughout the book. These are Ruby gems that for the most part, I’ve used in production apps at companies with significant scale, and they’ve proven the test of time.

RubyGems are the mechanism in the Ruby language to package up and distribute code. They are built and hosted usually on rubygems.org. They are roughly equivalent to PostgreSQL extensions, in that they leverage extension points, and add functionality to the core.

Ruby gems that are helpful for running PostgreSQL apps range from "helpers" that developers can run to compare their application code and PostgreSQL database, for example rails-pg-extras, database_consistency, or others are mentioned in the book.
Another category would be gems that help avoid unsafe DDL changes, by adding a safety concept to migrations. These gems identify blocking operations in PostgreSQL and suggest non-blocking alternatives, such as creating indexes concurrently.

The book covers these gems or you can explore the Ruby Toolbox which has gems grouped into categories. https://www.ruby-toolbox.com/

## Any tips, or myths, around scaling?

I have some generic tips for creating high performance PostgreSQL queries.

Learn how to understand the costs of the components for a query, by regularly using the query planner. The planner provides this cost information, and your job as a developer is to lower the cost, mostly by adding well-placed indexes.

Once you can identify the costly parts, you can develop your bag of tricks for how to optimize parts which includes indexes and other tactics.

For myths, I think developers think that JOIN operations are very costly and should be avoided, which means that normalizing data may be avoided.

Brian Davis has a great post with benchmarks showing the cost of a join. The takeaway for me from that post was that the cost of a join is nominal and should not limit the use of good data normalization practices, even when tables grow to millions of rows and rows are being joined together from many tables at once.

https://www.brianlikespostgres.com/cost-of-a-join.html

Nothing’s free though, and this does mean that a developer needs to create an efficient schema design with appropriate use of types, and create well-placed indexes that support the queries and join operations. For example, making sure that foreign keys are indexed, likely making good use of Multicolumn and Covering indexes, and using indexes to support ordering operations among other tactics.


Another myth is that PostgreSQL isn’t capable of certain kinds of work like full text search, caching, analytics, sharding, or background jobs, and adding in other non-relational companion databases is needed.

While this was more true 10 years ago with slower and smaller and more expensive disks, with SSDs and all the performance improvements to PostgreSQL over the last decade, this is not true today. In fact, often PostgreSQL is going heavily under-utilized in the overall workloads at businesses. This means they’re using a hodgepodge of database systems when PostgreSQL could handle all the needs.

Part of this is credited to how extensible PostgreSQL is, supporting many more data types and indexes and other capabilities beyond the core offering. If the core PostgreSQL isn’t sufficient for analytics or full text search, there are a variety of extensions that can be added to help serve these use cases, without needing to synchronize and operate additional databases.

## Is there anything you’d like to see from the Postgres community that would make things easier/better for Rails users?

I think web application developers really want to know which queries to optimize, and for that optimization process to be succinct and repeatable. PGSS (pg_stat_statements) is a great visibility tool but still lacks things like "samples". In PostgreSQL 16 we gained "generic plans" but samples with full query text would help.

I also gave a 5 minute lightning talk on some visibility tools at PGConf NYC. Michael and I collaborated on how to use the queryid "fingerprint" information that PostgreSQL gained in 14, to combine that with auto_explain information in 16 to get samples from the postgresql.log file, at least when the timing of a query exceeds a minimum.
https://speakerdeck.com/andyatkinson/pgconf-nyc-2023-lightning-talk

Since PostgreSQL adds catalog views over time, maybe a new catalog view or an expanded existing catalog could contain query text samples for certain queries by their queryid identifier, or even collect samples based on different thresholds like "excessive buffers", excessive row counts, that we could then use to add those optimizations. A "max_samples" could be set so that old samples are removed.

## Post-show ideas/reflections/thoughts

For anyone interested in exploring a bit with Rails and PostgreSQL, the book uses a Rails application on GitHub called "Rideshare", throughout the book for examples and exercises. We didn’t mention this in the episode, but I wanted to mention it here. The application is public and available here: https://github.com/andyatkinson/rideshare

Within the source code directory, there’s a "postgresql" that has some goodies https://github.com/andyatkinson/rideshare/tree/main/postgresql like a .pgpass file to store the credentials, a config file for pgbouncer, and a postgresql sample config file with some of the changes made during exercises in the book.

We didn’t cover this, but the book examples all use the built-in command line PostgreSQL client "psql" exclusively. Since Rails developers are used to working with the Rails Console, I wanted to advocate for using the built-in CLI client psql.

There is a lot of content in the book that’s not related to Ruby on Rails at all. For example, SQL language functions, PL/pgSQL functions, shell scripts, table partitioning, full text search (with tsvector and tsquery), using Postgres as a message queue or for background jobs with LISTEN and NOTIFY, and some brief coverage of pgvector, and vector similarity searching.

##  More coverage of Active Record and PostgreSQL

We didn’t cover some of the breadth of support for PostgreSQL features in Active Record, so I wanted to add some of that in here in this section. These topics are all covered in the book.

Consider exploring the PostgreSQL page within the Active Record documentation for the current released major version - 7.1: https://guides.rubyonrails.org/v7.1/active_record_postgresql.html

- PostgreSQL Generated columns (Active Record virtual stored columns)
- Deferrable foreign keys support
- Check constraints
- Setting a Transaction isolation mode in Active Record
- Exclusion constraints
- Full text search using tsvector
- Database views
- Advanced Data types like Arrays and Ranges
- Query hint planning from Active Record, using pg_hint_plan. The book has an example of how to use this. 
- RETURNING clause, with INSERT (and possible other DML ops in the future)


## Additional Links

- GitLab Migration Style Guide (mentioned by Nikolay) https://docs.gitlab.com/ee/development/migration_style_guide.html
- Lukas Fittl’s gem mentioned in the show, that helps keep the SQL structure dump consistently formatted https://github.com/lfittl/activerecord-clean-db-structure




## Errors in what I said

I mentioned Rails was used at DoorDash, but I don’t actually know if that was ever the case. I may have been confused.

I found that DoorDash used PostgreSQL in the past, and also used the Python Django framework. The DoorDash engineering blog has some nice posts on production migration operations with PostgreSQL. https://doordash.engineering/2022/01/19/making-applications-compatible-with-postgres-tables-bigint-update/



## Wrapping Up

Thank you Michael and Nikolay!
