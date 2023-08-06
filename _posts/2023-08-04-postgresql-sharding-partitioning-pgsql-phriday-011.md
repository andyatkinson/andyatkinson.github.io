---
layout: post
title: "PGSQL Phriday #009 &mdash; Sharding and Partitioning"
tags: [PostgreSQL, Rails, Open Source]
date: 2023-07-31
comments: true
---

This month's [PGSQL Phriday topic](https://engineering.adjust.com/post/pgsql_phriday_011_-_partitioning_vs_sharding_in_postgresql/) prompts bloggers to write about Sharding and Partitioning. Posts should help clarify what these terms mean, and how these capabilities can be put to use.

Let's dive in! 🤿

## Is Sharding Offered Natively?

PostgreSQL does not offer a native Sharding solution or "Sharded writes." Since Sharding is a generic term, the definition used in this post is borrowed from ["What is database sharding?"](https://aws.amazon.com/what-is/database-sharding/). In that definition of sharded databases, a single database is split over multiple server instances. The instances could be called "nodes". These instances handle both reads and writes.

Distributed databases offer a horizontally scalable architecture where nodes are added to scale out, or removed to scale in.

These architectures carry more complexity internally in how they keep data consistent among nodes. PostgreSQL does not offer this distributed architecture but on the other hand, has a conceptually less complex design. By default a single primary instance receives all writes and reads.

The main concern with a single primary database architecture is that it won't be able to be scaled vertically to meet the demands of the workload. A ceiling may be reached where all available hardware resources are provisioned but they're not enough.

On modern instance sizes from large cloud providers, with huge amounts of memory relative to the size of databases, and very fast disks, the possibility of not being able to scale vertically continues to get less likely. Modern instances offer more than 1TB of RAM and for medium sized organizations with databases even sized into the low terabytes, these instances are more than capable of meeting demand.

Besides the capabilities of instances, there are other ways to work around this limitation. This is where database reliability engineering comes in!

One of the main workarounds is to split up the database using a technique called "application level sharding." With application level sharding, a subset of database tables are split to their own database running on a separate instance.

The new database instance can be scaled independently. This solution can involve significant code changes, and is more demanding of database skills within the application development team. Having a high degree of test suite coverage where the database changes can be made and tested in the application, and having modern processes like continuous deployment will help teams successfully execute this kind of split.

See the post ["Herding elephants: Lessons learned from sharding Postgres at Notion"](https://www.notion.so/blog/sharding-postgres-at-notion) which explores application level sharding at Notion. GitHub wrote about "Partitioning" (confusing terminology based on definitions in this post) in [Partitioning GitHub’s relational databases to handle scale](https://github.blog/2021-09-27-partitioning-githubs-relational-databases-scale/) which describes their process of what this post calls "application level sharding."

Although GitHub operates MySQL, there are loads of insights in this post showing how they achieved their results. This post also demonstrates how the terms Sharding and Partitioning can have conflicting and overlapping definitions.

## What is Vertical Sharding?

This section will briefly cover "Vertical Sharding" to differentiate it from "Horizontal Sharding" covered later. What is Vertical Sharding?

Thinking of columns as "vertical" and rows as "horizontal" in a database table, vertical sharding can be thought of as separating some of the columns from a table into a new table, again locating it in a separate database and instance. The end result ends up being the same as application level sharding, where the client application is configured to work with multiple databases and the routing logic lives in the application.

## Replication and Instances

While PostgreSQL has a single primary instance design, commonly many instances are used and work together to meet the workload demand.

Physical or Logical replication is used to connect a Primary instance with one or more secondary Instances. The secondary instances run in a read only mode. This unlocks a very common scaling technique for web applications which is called Read and Write splitting, where reads can now be sent to the read only replica instances.

Since replica instances can be added and removed, they provide horizontal scalability for read queries, when read queries can be distributed to a larger pool of replicas if needed.

Since Web applications tend to have many more reads compared with write operations, web application engineers are often focused on scaling out read queries on replicas. This means the primary instance takes on a role that is more "writes" focused.

Can writes be distributed in PostgreSQL? Writes cannot be distributed at the database instance level. However, writes can be distributed at the table level.
Read on to learn more about that.

## Table Partitioning

PostgreSQL added a native table partitioning mechanism in version 10 called [Declarative Partitioning](https://www.postgresql.org/docs/current/ddl-partitioning.html). With declarative partitioning, writes can be distributed to multiple partitions that are connected to a partitioned table.

Since these tables are all running on the same instance, the writes will all consume resources on the same instance. However with a partitioned table it's possible to parallelize writes, reads, and background maintenance operations.

Why might you do this? In PostgreSQL breaking up a large table into a set of smaller tables makes them easier to work with. Partitioned tables can be faster to add Indexes and constraints to and perform maintenance on. Maintenance operations can be parallelized. Queries can be faster when partition information is added to them.

In a sense, table partitioning offers "table level sharded writes".

## Active Record Horizontal Sharding

If you're not familiar with it, Active Record is the ORM for Ruby on Rails. In version 6.1 a feature called [Horizontal Sharding](https://edgeguides.rubyonrails.org/active_record_multiple_databases.html#horizontal-sharding) was added to the existing native support in the framework for working with Multiple Databases.

Horizontal Sharding meant that a second database could be added to the application with the same schema. The Rails application had an identifier for it to route writes and reads to it.

Horizontal Sharding opened up the possibility of working with multiple databases to solve a few use cases.

A use case for Horizontal Sharding is "customer database level tenancy." A SaaS platform may offer customers an isolated database that contains an exact copy of the schema, but contains only rows that were created and modified for that customer.

Besides data isolation, this also helps with scalability because it means that particularly heavy traffic on one side or the other does not affect it's "neighbor". Either the main application database instance or the customer database instance can be scaled vertically, independently from the other.

The "Horizontal" part of Horizontal Sharding refers to rows. Rows that would have otherwise been in the original application database are instead part of a "shard" that represents the customer database.

Since "shards" are used generically the concept can be used differently and refer to any particular range of rows. The end goal is still to move the shard onto a separate instance where it can be scaled independently.

Combining Application Level Sharding and Horizontal Sharding with Active Record, with PostgreSQL table partitioning, creates a very scalable combination of technologies.

This combination of technologies helps developers build powerful applications.

I happen to be passionate about advocating for this combination of technologies, and have even written a book about it! Read on to learn more.

## High Performance PostgreSQL for Rails

The powerful combination of technologies covered in this post, are covered in much greater depth in the book "High Performance PostgreSQL for Rails," being published this month by [Pragmatic Programmers](https://pragprog.com).

Please subscribe at <https://pgrailsbook.com> for updates about the book and exclusive content.


## Table Partitioning Presentation

Earlier this year I presented at PGDay Chicago on Table Partitioning. Read more at [PGDay Chicago 2023 Conference](/blog/2023/05/24/pgday-chicago). Join the SF Bay Area PostgreSQL User Group next week virtually to see a live version. Visit ["Partitioned Table Conversion: Concept to Reality" with Andrew Atkinson](https://www.meetup.com/postgresql-1/events/295042365/) to RSVP.


## Table Partitioning Posts

I recently wrote a two part blog post series related to partitioning.

In [PostgreSQL Table Partitioning — Growing the Practice — Part 1 of 2](/blog/2023/07/27/partitioning-growing-practice) there is a general introduction to partitioning.

The second post [PostgreSQL Table Partitioning Primary Keys — The Reckoning — Part 2 of 2](/blog/2023/07/28/partitioning-primary-keys-reckoning) describes a challenging online migration we performed to modify the partitioned table primary key definition and avoid a disruptive table lock.

## Podcast

In July of 2023 I joined Jason Swett on the Code With Jason podcast. We discussed PostgreSQL table partitioning among other topics. Check out the episode at [Code With Jason 190 — PostgreSQL and Sin City Ruby 🎙️](/blog/2023/07/28/code-with-jason-postgresql-sin-city-ruby).

Thanks for taking a look. I'd love to hear any feedback you have and what you're building with PostgreSQL and Ruby on Rails! 👋