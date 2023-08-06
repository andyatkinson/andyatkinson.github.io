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

The main concern with a single primary database architecture is that it won't be able to be scaled vertically to meet the demands of the workload. A ceiling may be reached where all available hardware resources are purchased, or the max resources for a budget are purchased, but it's not enough to handle the workload demand.

On modern instance sizes from large cloud providers, with huge amounts of memory relative to the size of databases, and very fast disks, the possibility of not being able to scale vertically continues to get less likely. Modern instances offer more than 1TB of Ram and for medium sized organizations with databases in the hundreds of gigabytes or lower terabytes, these instances are very capable.

Besides the capabilities of instances, there are other ways to work around this limitatino.

One of the main workarounds is simplity to split up the database using a technique called "application level sharding," where a second (or more) subset of the database becomes a new database, running on a separate instance.

The separate instance can be scaled independently. This solution can involve significant code changes, and demands great database skills within the application development team. Team capabilities like a high degree of test suite coverage and continuous deployment will help this split operation go more smoothly.

See the post ["Herding elephants: Lessons learned from sharding Postgres at Notion"](https://www.notion.so/blog/sharding-postgres-at-notion) which explores application level sharding at Notion. GitHub wrote about "Partitioning" (confusing terminology based on definitions in this post) in [Partitioning GitHub’s relational databases to handle scale](https://github.blog/2021-09-27-partitioning-githubs-relational-databases-scale/) which describes their process of what this post calls "application level sharding."

Although GitHub operates MySQL, there are loads of insights in this post showing how they achieved their results. This post also demonstrates how the terms Sharding and Partitioning can have conflicting and overlapping definitions.

## What is Vertical Sharding?

This section will briefly cover "Vertical Sharding" to differentiate it from "Horizontal Sharding" covered later. What is Vertical Sharding?

Thinking of columns as "vertical" and rows as "horizontal" in a database table, vertical sharding can be thought of as separating some of the columns from a table into a new table, again locating it in a separate database and instance. The end result ends up being the same as application level sharding, where the client application is configured to work with multiple databases and the routing logic lives in the application.

## Replication and Instances

While PostgreSQL has a single primary instance design, commonly many instances are used to meet demand.

Physical or Logical replication is very common to figure replication between a Primary and secondary Instance. The secondary instance runs in a read only mode.

Secondary instances can be added and removed, and scaled independently, providing a degree of horizontal scalability when the read queries for a database are running on the read replicas.

Since Web applications tend to have a much higher proportion of reads to writes, possibly as much as 10:1, web application engineers are often focused on scaling out read queries on replicas, and sizing the primary instance more for the writes workload.

Can writes be distributed in PostgreSQL? Writes cannot be distributed at the database instance level. However, writes can be distributed at the table level.
Read on to learn more about that.

## Table Partitioning

PostgreSQL added a native table partitioning mechanism in version 10 called [Declarative Partitioning](https://www.postgresql.org/docs/current/ddl-partitioning.html). With declarative partitioning, writes can be distributed to multiple partitions that are connected to a partitioned table.

Since these tables are all running on the same instance, the writes will all consume resources on the same instance. However with a partitioned table it's possible to parallelize writes, reads, and background maintenance operations.

Why might you do this? In PostgreSQL smaller tables are easier to work with. Partitioned tables can be faster to add Indexes to, constraints, maintenance can be parallelized, and queries can be faster when they specify the partition.

In a sense, table partitioning offers "table level sharded writes".

## Declarative Partitioning Intro

A Partitioned table is a special kind of table that acts as a parent table. Once created, child tables are attached to it. Partitions can always be attached and detached when they have a matching schema definition.

The parent defines the partition type and column. The partition column acts as like a routing key, telling PostgreSQL which partition a row belongs to.

Three partition types are supported, Range, List, and Hash, and they are all useful for different scenarios. Each child partition declares non-overlapping boundaries (a constraint) that must be matched for a row to placed into the partition.

The data within a partitioned table can be thought of as being "horizontally distributed" since rows are placed into separate tables. These rows would have otherwise been in the same table if it wasn't partitioned.

Distributing rows horizontally into different tables is beginning to sound a lot like a capability from Active Record in Ruby on Rails.

Since I also work with Ruby on Rails on a daily basis, the rest of this post will shift away from PostgreSQL a bit into what's possible with Active Record.

Active Record has a capability in newer versions called "Horizontal Sharding". What's that all about?

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

The powerful combination of technologies are covered in much greater depth in the book "High Performance PostgreSQL for Rails," being published this month by [Pragmatic Programmers](https://pragprog.com). If you're interested, please subscribe at <https://pgrailsbook.com> for updates about when it's published, and some exclusive sneak peek content being sent to subscribers.


## Table Partitioning Presentation

Earlier this year I presented at PGDay Chicago on Table Partitioning. Read more at [PGDay Chicago 2023 Conference](/blog/2023/05/24/pgday-chicago). Join the SF Bay Area PostgreSQL User Group next week virtually to see a live version. Visit ["Partitioned Table Conversion: Concept to Reality" with Andrew Atkinson](https://www.meetup.com/postgresql-1/events/295042365/) to RSVP.


## Table Partitioning Posts

I recently wrote a two part blog post series related to partitioning.

In [PostgreSQL Table Partitioning — Growing the Practice — Part 1 of 2](/blog/2023/07/27/partitioning-growing-practice) there is a general introduction to partitioning.

The second post [PostgreSQL Table Partitioning Primary Keys — The Reckoning — Part 2 of 2](/blog/2023/07/28/partitioning-primary-keys-reckoning) describes a challenging online migration we did on a large partitioned table.

## Podcast

In July of 2023 I joined Jason Swett on the Code With Jason podcast. We discussed PostgreSQL table partitioning among other topics. Check out the episode at [Code With Jason 190 — PostgreSQL and Sin City Ruby 🎙️](/blog/2023/07/28/code-with-jason-postgresql-sin-city-ruby).

Thanks for taking a look. I'd love to hear any feedback you have and what you're building with PostgreSQL! 👋