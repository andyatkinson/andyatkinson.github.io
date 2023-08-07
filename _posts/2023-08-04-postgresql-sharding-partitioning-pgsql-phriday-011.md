---
layout: post
title: "PGSQL Phriday #011 &mdash; Sharding and Partitioning"
tags: [PostgreSQL, Rails, Open Source]
date: 2023-07-31
comments: true
---

This month's [PGSQL Phriday #011](https://engineering.adjust.com/post/pgsql_phriday_011_-_partitioning_vs_sharding_in_postgresql/) prompts bloggers to write about Sharding and Partitioning in PostgreSQL.

Posts should help clarify what these terms mean, why these capabilities are useful, and how to use them.

Let's dive in! 🤿

## Outline

- Native Sharding
- Vertical Sharding
- PostgreSQL Replication and Instances
- PostgreSQL Table Partitioning
- Active Record Horizontal Sharding
- High Performance PostgreSQL for Rails Book
- Sharding and Partitioning Blog Posts and Podcasts


## Is Sharding Offered Natively?

PostgreSQL does not offer a native Sharding solution or "Sharded writes." Sharding is a generic term so this post uses a definition borrowed from ["What is database sharding?"](https://aws.amazon.com/what-is/database-sharding/) which is "a single database split over multiple server instances."

PostgreSQL does not offer this distributed architecture but on the other hand, has a conceptually less complex design. By default a single primary instance receives all writes and reads.

The main concern with a single primary database architecture is that vertically scaling the instance will reach a hardware ceiling and the server won't be able to meet the demands of the workload.

On modern instances from cloud providers, with huge amounts of memory and fast disks, many organizations will never run into this issue. In fact often our instances where I work now are over provisioned for the workload. This is often though because the company has anticipated the single instance limitations and invested in creating isolated deployments to separate the workloads. For context, the largest database we operate is in the low single terabytes and our workload is fairly predictable being a B2B SaaS.

When there is a need to scale beyond an instance, how can that be handled?

## Application Level Sharding

One of the main design techniques used to split up a database workload is "application level sharding." With application level sharding, a subset of database tables are split to their own database on a separate instance that can be scaled independently.

The instance can be connected to the same application codebase, or the entire codebase can be deployed in an isolated deployment with duplicated runtime dependencies for full isolation. The latter configuration is much more costly but does not require application code changes.

See the post ["Herding elephants: Lessons learned from sharding Postgres at Notion"](https://www.notion.so/blog/sharding-postgres-at-notion) which explores application level sharding at Notion. GitHub wrote about "Partitioning" (confusing terminology based on definitions in this post) in [Partitioning GitHub’s relational databases to handle scale](https://github.blog/2021-09-27-partitioning-githubs-relational-databases-scale/) which describes their process of what this post calls "application level sharding."

Although GitHub operates MySQL and not PostgreSQL, there are loads of insights in the post. The post also demonstrates how the terms Sharding and Partitioning can have conflicting and overlapping usages.

## What is Vertical Sharding?

Sharding can be categorized into Vertical Sharding and Horizontal Sharding. What is "Vertical Sharding" and how is it different from "Horizontal Sharding"?

By mapping the columns of a table to the term "vertical" and the rows to "horizontal", we can begin to guess at how vertical and horizontal sharding might be different. Vertical sharding separates columns from a table into a new table. The new table can run on a separate instance and scale independently. This is similar to application level sharding in that the client application is responsible for routing to multiple databases and the logic lives in the application.

## Replication and Instances

While PostgreSQL has a single primary instance design, commonly many instances are used in collaboration with each other.

Physical or Logical replication is used to connect a Primary instance with one or more secondary Instances. The secondary instances run in a read only mode. This unlocks a very common scaling technique for web applications "Read and Write splitting" where reads can now be performed on the replica instances. This separates the write and read workloads and again helps their individual instance scalability.

Can writes be distributed in PostgreSQL? Writes cannot be distributed at the database instance level. However, writes can be distributed at the table level.
Read on to learn more.

## Table Partitioning

PostgreSQL added a native table partitioning mechanism in version 10 called [Declarative Partitioning](https://www.postgresql.org/docs/current/ddl-partitioning.html). With declarative partitioning writes can be distributed to multiple child partitions of a table.

Since these tables are all running on the same instance, the writes will all consume resources on the same instance. Thus, table partitioning doesn't help with instance scalability in the same way. However, partitioned tables can lessen the resource consumption on an instance, and indirectly help with how scalable it is One way is that partitioned tables can be have Vacuum operations running in parallel. With more frequent and efficient maintenance, excessive resource consumption from maintenance and queries on what would otherwise be bloated tables and indexes, is avoided.

For a more general introduction to table partitioning, check out the links at the bottom of this post.

In a sense, table partitioning offers "table level sharded writes".

The next section shifts away from PostgreSQL and into Ruby on Rails and Active Record. Active Record added support for working with Multiple Databases as part of the framework, because of how important this architectural pattern is for scaling out.

One of use cases for Active Record Multiple Databases is called Horizontal Sharding. What's that all about?

## Active Record Horizontal Sharding

In version 6.1 Active Record added [Horizontal Sharding](https://edgeguides.rubyonrails.org/active_record_multiple_databases.html#horizontal-sharding). This capability was added to the core framework expanding on the Multiple Databases support added in 6.0.

Horizontal Sharding means a second database can be added to work with the same application, as long as it has the same schema. The separated set of rows and tables is called a "shard" in a general sense. The Rails application has an identifier to the shard and can even independently work with writer and reader roles for a shard. See the [Multiple Databases with Active Record Rails Guide](https://guides.rubyonrails.org/active_record_multiple_databases.html) for more information.

A use case for Horizontal Sharding is a customer-specific database as a "shard". Customer database level tenancy is a common need for SaaS platforms that are scaling  up and want to offer data isolation or instance level compute isolation to a customer.

As you saw earlier, the "Horizontal" refers to the rows in a table. Rows that would have otherwise been in the original application database, are instead part of a "shard" that represents the customer database.

By using Application Level Sharding (Vertical Sharding), Horizontal Sharding with Active Record, and PostgreSQL table partitioning, developers are able to create a powerful combination of technologies and databases to scale up to meet very demanding workloads.

I happen to be passionate about advocating for this combination of technologies, and I've even written a book on the topic!

## High Performance PostgreSQL for Rails

The powerful combination of technologies introduced in this post are covered in much greater depth in "High Performance PostgreSQL for Rails," a new book arriving in 2023 published by [Pragmatic Programmers](https://pragprog.com).

Subscribe for updates and exclusive content at <https://pgrailsbook.com>.


## Table Partitioning Presentation

Earlier this year I presented at PGDay Chicago on Table Partitioning. Read more at [PGDay Chicago 2023 Conference](/blog/2023/05/24/pgday-chicago). Join the SF Bay Area PostgreSQL User Group next week virtually to see a live version. Visit ["Partitioned Table Conversion: Concept to Reality" with Andrew Atkinson](https://www.meetup.com/postgresql-1/events/295042365/) to RSVP.


## Table Partitioning Posts

I recently wrote a two part blog post series related to partitioning.

In [PostgreSQL Table Partitioning — Growing the Practice — Part 1 of 2](/blog/2023/07/27/partitioning-growing-practice) there is a general introduction to partitioning.

The second post [PostgreSQL Table Partitioning Primary Keys — The Reckoning — Part 2 of 2](/blog/2023/07/28/partitioning-primary-keys-reckoning) describes a challenging online migration we performed to modify the partitioned table primary key definition and avoid a disruptive table lock.

## Podcast

In July of 2023 I joined Jason Swett on the Code With Jason podcast. We discussed PostgreSQL table partitioning among other topics. Check out the episode at [Code With Jason 190 — PostgreSQL and Sin City Ruby 🎙️](/blog/2023/07/28/code-with-jason-postgresql-sin-city-ruby).

Thanks for taking a look. I'd love to hear any feedback you have and what you're building with PostgreSQL and Ruby on Rails! 👋
