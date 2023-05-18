---
layout: post
title: "Ruby For All Podcast: My Guest Experience 🎙️"
tags: [PostgreSQL, Rails, Podcast]
date: 2023-01-19
comments: true
---

I joined [Julie](https://www.rubyforall.com/people/julie-j) and [Andrew](https://www.rubyforall.com/people/andrew-mason) as a guest on the Ruby For All Podcast!💎

I answered some questions and shared my enthusiasm for PostgreSQL and Ruby on Rails. We discussed PostgreSQL, PostgreSQL vs. MySQL, transactions, locking, PgBouncer, and data modeling.

Check out the episode here:👉[The Database Wizard with Andrew Atkinson](https://www.rubyforall.com/episodes/the-database-wizard-with-andrew-atkinson) January 19, 2023 · 28:38

Prior to the episode, Julie sent questions that we used to kick off discussions. I prepared answers in advance, and in this post I'll expand on what was discussed in the episode with those answers.

Let's get into it!

## Is MySQL faster than PostgreSQL? 🐘

Short answer: I don't really know. I'd tell someone "they’re roughly the same." Performance probably isn't the main reason to choose one over the other.

To understand performance, benchmark testing is needed comparing identical workloads running on identical servers. An equivalent set of `INSERT`, `UPDATE`, and `DELETE` statements (`DML`) could be grouped up, and sent to the database.

For PostgreSQL, [pgbench](https://www.postgresql.org/docs/current/pgbench.html) is included and can be used to measure *Transactions Per Second* (`TPS`) that the server is capable of. It’s probably too difficult to isolate interesting differences though. It's also "synthetic" or artificial and isn't representing the real web application workload.

Application layer HTTP benchmarking is probably more useful.

Besides performance, there are other criteria to consider when evaluating databases.

- Licensing and permissiveness ([MariaDB](https://mariadb.org) was forked from MySQL after it was acquired by Sun/Oracle, and has a more permissive license), availability from Cloud providers ([AWS RDS](https://aws.amazon.com/rds/), CrunchyData [Crunchy Bridge](https://www.crunchydata.com/products/crunchy-bridge), or even self-hosted PostgreSQL)
- Features and support. The database should offer compelling features for Reliability and Scalability, including Replication, Partitioning, and more.
- Cost Efficiency. Read/Write splitting is a common technique to scale reads. Cost efficiency could be compared for read workloads with replicas.

For cloud databases, hourly pricing is available and MySQL and PostgreSQL can be compared that way. This is still a lot of work!

And what about staffing for your team?

- Popularity in the market

From [DB Engines 2022](https://db-engines.com/en/): In 2022, PostgreSQL was the #3 overall most popular database, ahead of MySQL, and first in the `OLTP` category (#1 and #2 are `OLAP` databases). PostgreSQL has been #1 in recent years. 

Investing your time learning PostgreSQL or MySQL well is a good career move, they’re both popular, and skills with it are in demand!

You'll also need to Upgrade and Maintain your database.

From [Choosing a database Twitter thread](https://twitter.com/DBPadawan/status/1609799158331998210), don't forget about Upgrades and Maintenance.

Cloud hosted databases are making this easier, but in PostgreSQL, major version upgrades can be a challenge. When it comes to near zero downtime upgrades, MySQL may have an advantage. Although this is possible with PostgreSQL.


## Why choose PostgreSQL over MySQL?

Short answer: Besides Performance, consider Reliability, Scalability, Consistency, Availability on Cloud providers, and Maturity. Consider the broader Ecosystem including the Community resources (Docs, Forums, Email lists, Conferences, Meetups, Books, Videos, and Podcasts).

I learned a lot from working with it where it served 100s of thousands of requests/minute, and experienced some of the challenges from higher scale operations.

The experience there formed the basis of [How We Made PostgreSQL Fitter, Happier, More Productive](https://speakerdeck.com/andyatkinson/how-we-made-postgresql-fitter-happier-more-productive). A single writer PostgreSQL and a single read replica are very capable, given enough memory, CPUs, and fast disks.

## PostgreSQL Exclusive Features

This list is from [SQL For Devs](https://sqlfordevs.com) written by [Tobias Petry](https://twitter.com/tobias_petry), a great site! Below, I selected the features listed that are available only in PostgreSQL.

- `DISTINCT ON` keyword
- `RETURNING` keyword
- Partial indexes (indexes with a condition, See: [Rails: Postgres Partial Indexing](https://www.johnnunemaker.com/rails-postgres-partial-indexing/))
- `EXCLUSION` Constraint with a GiST index type
- Fast wildcard searches, aka `LIKE` and `ILIKE`, GIN index, `gin_trgm_ops` operator class
- `FETCH FIRST ... WITH TIES`

PostgreSQL has a broad feature set, and is often underutilized at companies. Specialized databases are run for workloads that PostgreSQL could handle. Some people even advocate to choose [PostgreSQL For Everything](https://www.amazingcto.com/postgres-for-everything)!

These types of use cases like Full Text Search (`FTS`) that PostgreSQL is capable of, still have complex concepts and domains. Although that complexity is inherent to the full text search domain. The complexity from operating several databases (arguably "unnecessary complexity") is avoided.

Some additional PostgreSQL capabilities are below.

- Full Text Search (`FTS`) support, may not need Elasticsearch or OpenSearch ([Supabase: Postgres Full Text Search vs the rest](https://supabase.com/blog/postgres-full-text-search-vs-the-rest))
- `LISTEN` / `NOTIFY` pub/sub implementation which is similar to `ActiveSupport::Notifications API`
- [JSONB](https://www.postgresql.org/docs/current/datatype-json.html) support, indexing into JSON data, convert SQL to JSON for APIs, may not need MongoDB
- Geospatial queries ([PostGIS](https://postgis.net))
- Queues/background processing. May not need Redis and Sidekiq. Check out [good_job](https://github.com/bensheldon/good_job)
- May not need Kafka. Check out PostgreSQL Logical Replication, Logical Decoding, and JSON decoded output for `CDC` (change data capture). [Change data capture in Postgres: How to use logical decoding and wal2json](https://techcommunity.microsoft.com/t5/azure-database-for-postgresql/change-data-capture-in-postgres-how-to-use-logical-decoding-and/ba-p/1396421)
- Wild stuff: [PostgREST](https://postgrest.org/en/stable/) (Haskell, also rewritten in Go), REST API with no back-end needed!


## Should I be using `JOIN`s vs. an Array column with values?

> Either one works. They have different trade-offs.

PostgreSQL supports nesting values in an array column, and unnesting them if needed. Nesting is a form of *denormalization*.

In general, my recommendation is to prefer normalized structures and denormalize later if there is a clear advantage. With normalized data structures, referential integrity is enforced in the database using constraints and values in columns will be consistent by using types.

Besides the needs of the application, consider additional needs as consumers of the data. This could be ETL/ELT clients that are part of your company data pipeline, copying data into a data warehouse.

The more structured and constrained the data is in the primary database, the more consistent the data will be including for the application and for other clients.

Generally storage optimizations might seem clever but aren't as helpful to readers and maintainers as conventional approaches.

To take this a step further, [PostgreSQL Enumerated Types](https://www.postgresql.org/docs/current/datatype-enum.html) can be used to put possible values into the database as data. You may have less bugs with a column that has a narrow set of fixed values.

With Active Record, since this is now a database object, database enums are dumped to `db/structure.sql` on every schema change.


## Example From the Show On Modeling a "Friendship" Relationship

Julie used an example of storing "friends" and a "friendship" between two friends, either as an Array of id values in a column, or as a join table. Trade-offs were discussed.

Normalization is similar to `DRY` (Don't repeat yourself) in a sense, which is a philosophy of Ruby and Rails. Normalization attempts to eliminate duplication in how data is stored.

Andrew M. added a point about how with a dedicated table-backed model, to think about how that might be extended over time. In Rails, a table-backed Friendship Active Record model might have two foreign key columns, each linked to the primary key of a friend.

If the friendship was stored as integers in an Array column, because it's a column as opposed to a table it couldn't be extended with new attributes. Over time a friendship might want to add attributes, like tracking how the friendship was first created.


## Locking

Rails supports Optimistic locking using a database Advisory Lock.

Pessimistic locking is also supported. In PostgreSQL, Active Record uses the Row Locking mechanism `FOR UPDATE`. See: [ActiveRecord::Locking::Pessimistic](https://api.rubyonrails.org/classes/ActiveRecord/Locking/Pessimistic.html). `NOWAIT` or `SKIP LOCKED` [PostgreSQL Docs](https://www.postgresql.org/docs/current/sql-select.html) can be used to report an error when a lock cannot be obtained or skip rows that are locked.

Locking capabilities provided by Ruby on Rails, and database locks, are another interesting topic that we just scratched the surface of.


## Wrap Up

I enjoyed chatting with Julie and Andrew about PostgreSQL and Ruby on Rails.

Julie and Andrew are doing a great job with Ruby for All, and I think it's a great podcast for the Ruby programming community.

I'd love to hear your feedback. Was there something that wasn't covered you'd like to learn about?

Thanks! 👋
