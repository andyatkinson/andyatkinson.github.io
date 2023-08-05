---
layout: post
title: "PGSQL Phriday #009 &mdash; Sharding and Partitioning"
tags: [PostgreSQL, Rails, Open Source]
date: 2023-07-31
comments: true
---

This month's [PGSQL Phriday topic](https://engineering.adjust.com/post/pgsql_phriday_011_-_partitioning_vs_sharding_in_postgresql/) prompts bloggers to write about Sharding and Partitioning, covering what they mean and how they are similar and different concepts.

Let's dive in! 🤿

## Is Sharding Offered Natively?

PostgreSQL does not offer a native Sharding solution. Sharding is a generic term, so the definition being used here is when a single database is distributed among multiple machines, or server instances, or "nodes." This basic definition comes from the article ["What is database sharding?"](https://aws.amazon.com/what-is/database-sharding/).

While distributed databases offer a horizontally scalable architecture, where nodes can be added and removed to scale out and scale in, these architectures carry more complexity for how to keep data consistent among nodes. PostgreSQL while not offering the distributed archicture, has a conceptually simpler single primary Instance design.

The main concern with single primary database architectures are that they might eventually hit a ceiling where hardware resources can no longer be scaled up vertically. At mid-sized startups, and given modern very large cloud provider PostgreSQL instance classes, this limitation has not yet caused an existential crisis like a rapid database migration.

In fact, clever application developers work around this limitation in various ways. One of the main workarounds is to "shard" at the application level, by splitting out a group of tables into their own database, and running the database on a separately scalable instance.

## What is Vertical Sharding?

Considering a database table with columns that are arranged vertically, what is table-level Vertical Sharding? Splitting portions of columns from a table and putting them into another table, in a database on another instance, can be called Vertical Sharding.  There isn't built in support for this in PostgreSQL either, although again it could be supported from a client application level.

## Replication and Instances

While PostgreSQL has the limitation a single Primary instance architecture, certainly in larger scale PostgreSQL installations, many instances are running to meet the demands of the workload.

A common configuration sets up replication (Physical or Logical) between a Primary instance and one or more secondary Instances that are receiving replicated content and running in a read only mode.

Secondary instances can be added and removed, and scaled independently, providing a degree of horizontal scalability for read queries. Since Web applications tend to have a much higher proportion of read queries to write queries, possibly as much as 10 times the level of reads to writes, horizontal scalability is an important and commonly used way to support higher levels of traffic by adding more read only replicas.

You've seen how to distribute read queries. Is there any way to distribute Writes (DML) in PostgreSQL? While writes cannot be distributed to multiple instances running a database, if we bend the definition a bit and consider how writes could be split up into multipel tables, in a sense this is supported using the PostgreSQL table partitioning mechanism.

Read on to learn more about that.

## Table Partitioning

PostgreSQL gained a native table partitioning mechanism in version 10 called [Declarative Partitioning](https://www.postgresql.org/docs/current/ddl-partitioning.html). Using declarative partitioning, writes can be distributed to multiple partitions of a partitioned table.

Since these tables are all running on the same instance, this isn't really "Sharded writes" though, it's just splitting up the writes into multiple tables on the same instance.

Why might you do this? In PostgreSQL smaller tables are easier to work with. Creating indexes, constraints, and being able to parallelize vacuum operations across partitions are some of the benefits of splitting up a large unpartitioned table, into a partitioned table with many smaller partitions distributing the rows.

In a sense, table partitioning offers "table level sharded writes". The partitioning type that matches this most closely might be the least common type, the Hash type (added in PostgreSQL 11). With Hash partitioning, a static set of partitions are added to a parent. Running a modulo operation on the primary key value and by using the remainder, one of the hash partitions receives the writes. The writes are "distributed". Again though the partitions are all in the same database, running on the same instance. There is not a hardware resource scaling advantage with table partitioning.

## Declarative Partitioning Intro

A Partitioned table is a special kind of table that acts as a parent table, where smaller child tables are attached to it.

The parent defines the partition type and column. The partition column acts as like a routing key, telling PostgreSQL which partition a row belongs to.

Three partition types are supported. Partitioning by time range (Range) or by some kind of identifier column (List) are the more popular types, although a third type called Hash partition exists. Each partition declares non-overlapping boundaries so that rows can be routed to only one partition.

The data within a partitioned table can be thought of as being "horizontally distributed" since rows are placed into separate tables. These rows would have otherwise been in the same (unpartitioned) table.

The child partitions all have the same schema since child tables must match the parent partitioned table, and match each other.

Distributing rows horizontally into different tables is beginning to sound a lot like what Active Record in Ruby on Rails calls "Horizontal Sharding".

What's Horizontal Sharding all about?

## Active Record Horizontal Sharding

In Active Record, the ORM for Ruby on Rails, version 6.1 gained a feature called [Horizontal Sharding](https://edgeguides.rubyonrails.org/active_record_multiple_databases.html#horizontal-sharding).

Ruby on Rails can natively work with Multiple Databases at the same time, routing queries, and evolving their databases incrementally using Migrations.

Horizontal Sharding means a second database with the same table and same schema, can be configured to work with the Rails application.

Horizontal Sharding can be leveraged for a few business purposes. The database routing is all handled at the application layer, but by being built in to the Rails framework, there is much less boilerplate and configuration management that developers need to worry about.

A use case for Horizontal Sharding is "customer database level tenancy." A SaaS platform may offer customers a isolated database that contains only rows for the customer. The customer database likely runs on a separate instance as well that can be scaled independently. This also insulates the multi-tenant database from the "noisy neighbor" effect if the customer database instance had a particularly high write or query volume.

The "Horizontal" part of Horizontal Sharding refers to the horizontal rows. They would have otherwise been in the original application database, but instead they're in a "shard" that happens to map to the the customer database.

Active Record refers to these "shards" generically and indeed Horizontal Sharding could be used to create generic named or numbered shards for ranges of rows. This type of sharding could be a general way to scale out writes by creating a new instance, to isolate a high volume of writes to that instance.

All of these capabilities can be combined. Active Record helps developers build scalable applications that can be configured with Multiple Databases with Primary and replica instances for Read and Write splitting, and partitioned tables to help manage high growth rate tables.

I happen to be passionate about this topic area that I've even written a book about it.

## High Performance PostgreSQL for Rails

If you'd like to read more about these topics, please subscribe to <https://pgrailsbook.com> where you can receive occasional updates about "High Performance PostgreSQL for Rails," being published this month by [Pragmatic Programmers](https://pragprog.com).


## Table Partitioning Presentation

Earlier this year I presented at PGDay Chicago on Table Partitioning. Read more at [PGDay Chicago 2023 Conference](/blog/2023/05/24/pgday-chicago). Join the SF Bay Area PostgreSQL User Group next week virtually to see a live version. Visit ["Partitioned Table Conversion: Concept to Reality" with Andrew Atkinson](https://www.meetup.com/postgresql-1/events/295042365/) to RSVP.


## Table Partitioning Posts

I recently wrote a two part blog post series related to partitioning.

In [PostgreSQL Table Partitioning — Growing the Practice — Part 1 of 2](/blog/2023/07/27/partitioning-growing-practice) there is a general introduction to partitioning.

The second post [PostgreSQL Table Partitioning Primary Keys — The Reckoning — Part 2 of 2](/blog/2023/07/28/partitioning-primary-keys-reckoning) describes a challenging online migration we did on a large partitioned table.

## Podcast

In July of 2023 I joined Jason Swett on the Code With Jason podcas. We discussed PostgreSQL table partitioning among other topics. Check out the episode at [Code With Jason 190 — PostgreSQL and Sin City Ruby 🎙️](/blog/2023/07/28/code-with-jason-postgresql-sin-city-ruby).

Thanks for taking a look. I'd love to hear any feedback you have and what you're building with PostgreSQL! 👋