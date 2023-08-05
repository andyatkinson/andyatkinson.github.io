---
layout: post
title: "PGSQL Phriday #009 &mdash; Sharding and Partitioning"
tags: [PostgreSQL, Rails, Open Source]
date: 2023-07-31
comments: true
---

This month's [PGSQL Phriday topic](https://engineering.adjust.com/post/pgsql_phriday_011_-_partitioning_vs_sharding_in_postgresql/) prompts bloggers to discuss Sharding and Partitioning.

Let's dive in! 🤿

## Is Sharding Offered Natively?

PostgreSQL does not offer a native Sharding solution where Sharding is defined as being a single database distributed among multiple machines (or server instances, or "nodes"). This basic definition is from ["What is database sharding?"](https://aws.amazon.com/what-is/database-sharding/).

While distributed databases offer a horizontally scalable architecture, they are complex. PostgreSQL has a simpler single primary Instance architecture.

Distributed databases like Elasticsearch have multiple Nodes coordinating together receiving writes and reads. The main criticism of single primary database architecture is that it is less scalable because of there will eventually be a maximum instance size that's reached and due to hardware resource limitations, or budget limitations, the single instance can no longer be vertically scaled any higher. Is this a problem in practice?

Clever developers have worked around this limitation in all sorts of ways, and for many organizations and businesses, this limitation is perfectly acceptable. Besides that, a single database may be split and run on separate instances including writes, just controlled at the client application level.

## What is Vertical Sharding?

What about table-level Vertical Sharding? Splitting portions of columns from a table and defining them in another table running on another instance is certainly possible.  While possible, there isn't built-in support for that in the open source community version of PostgreSQL that this post focuses on.

## Replication and Instances

While PostgreSQL has a single Primary instance architecture, very commonly there are multiple Instances of PostgreSQL working together. A common configuration sets up physical replication between a Primary instance to one or more secondary Instances running in Read Only mode.

Secondary instances can be added and removed, and scaled independently, as the read query workload grows or shrinks. Web applications tend to have a much higher proportion of read queries compared with write queries. Given that I primary work with web applications, I typically am more concerned about shifting queries to a read replica.

While read queries can be distributed to one or more replicas, there is no built-in way to distribute Writes (DML) in PostgreSQL on an instance. However, writes could be distributed if we bend the definition a bit and consider how table partitioning distributes writes into multiple tables.

This is where the industry terminology and PostgreSQL terminology can overlap heavily and cause confusion, which is part of what inspired this PGSQL Phriday topic in the first place.

You haven't yet seen table partitioning but you'll dive into that next.

## Table Partitioning

Using the native Declarative Partitioning capability of PostgreSQL since version 10, writes can be distributed to multiple tables. Since these tables are all running on the same instance, this isn't really "Sharded writes" though. However, in a sense table partitioning offers "table level sharded writes" given that the partitioning mechanism coordinates the writes into one more partitions, and partitions can be added. The partitioning type that matches this most closely might be the least common type, the Hash type (added in PostgreSQL 11). With Hash partitioning, a static set of partitions are added to a parent. Running a modulo operation on the primary key value and by using the remainder, one of the hash partitions receives the writes. The writes are "distributed" in a sense.

Besides the write operations themselves, Vacuum workers can be scheduled to run in parallel across partitions.

With that description of Sharding out of the way, which in a nutshell sharded writes to multiple instances is not supported in PostgreSQL, it's time to dive more into partitioning. 

## Native Partitioning

In case you're new to PostgreSQL [Declarative Partitioning](https://www.postgresql.org/docs/current/ddl-partitioning.html), what is the gist?

Partitioning is a special kind of table that typically replaces a large unpartitioned table, effectively splitting the original table into smaller tables. The smaller tables are arranged as children that all point to the same parent. The parent defines the partition type, and any Primary Keys on the partition must include the column being used to partition (or "divide up") the table rows. The partition column acts as like a routing key, telling PostgreSQL which partition a row should go into or can be found.

Three partition types are supported. Partitioning by time range (Range) or by some kind of identifier column (List) are more popular types. Each partition must have non-overlapping boundaries expressed as partition constraints, and with those boundaries in place, PostgreSQL knows where to send the writes.

One child or up to thousands of child partitions can be added to the parent table. As the PostgreSQL operator, you declare (hence the "Declarative" part of the name) the parent partitioned table and add child partitions (using the `PARTITION OF` keyword) as needed, likely automating the process of adding more partitions prior to when they're needed for rows.

How can Partitioning be used to achieve Sharding? Partitioning can't be used to run partitions on separate Instances to my knowledge. The typical definition of Sharding means to run different nodes in a distributed architecture working together.

However the data within a partition can be "horizontally distributed" by being placed into separate tables that would have otherwise been the same table had the table not been partitioned.

Since these rows in different (child partition) tables must have the same schema, that definition sounds a lot like how Active Record in Ruby on Rails defines "Horizontal Sharding". What's that all about? Read on to learn more.

## Active Record Horizontal Sharding

In Active Record (the ORM for Ruby on Rails), support for Multiple Databases was added in the last few years opening up a number of use cases natively supported in the framework. One of the use cases since version 6.1 is called [Horizontal Sharding](https://edgeguides.rubyonrails.org/active_record_multiple_databases.html#horizontal-sharding), which can be used to place separate out rows that would otherwise be in the same table, into a separate identical table in another database.

This capability can be used to split out a second same-schema database to run on the same instance or a different server instance. The database routing, knowing which one to write and read to is all handled at the application layer.

A possible use case for this is sometimes called "customer database level tenancy (or sharding)" where a customer of a SaaS platform has their own database. The customer database has the exact same schema and definition, just with a set of rows that are unique to the customer.

The "Horizontal" part of Horizontal Sharding refers to the rows that would otherwise have been in the same database, are treated as a "shard" that is moved to another database.

The separated database could be on the same PostgreSQL server Instance, however it is more likely to run on a separate instance that can be scaled independently.

Splitting rows out this way is not limited to Customer isolated databases. Active Record refers to these "shards" more generically as any addressable configuration that could be a range of rows or a condition that isolates rows.

And what about combining all of these capabilities. That's certainly possible! A PostreSQL partitioned table can exist on a "Shard" with Active Record, meaning that Horizontal Sharding is in effect.

This combination of capabilities leveraging PostgreSQL native Declarative Partitioning, and Active Record Horizontal Sharding, is a great way to scale applications.

I happen to really like this topic and am even writing a book about it. Please read on to the next section to learn more.


## High Performance PostgreSQL for Rails

If you'd like to read even more of my writing on this topic, please visit and subscribe to <https://pgrailsbook.com>. Once subscribed, you'll get occasional updates and exclusive content for my new book "High Performance PostgreSQL for Rails" being published (in Beta) this month by [Pragmatic Programmers](https://pragprog.com).


## Table Partitioning Presentation

Earlier this year I presented at PGDay Chicago on Table Partitioning. Read more about it and find links to the slide deck at [PGDay Chicago 2023 Conference](/blog/2023/05/24/pgday-chicago). This presentation will be given at the SF Bay Area PostgreSQL User Group virtual meetup next week! Please visit ["Partitioned Table Conversion: Concept to Reality" with Andrew Atkinson](https://www.meetup.com/postgresql-1/events/295042365/) to RSVP.


## Table Partitioning Posts

If you'd like to read more about table partitioning, I recently wrote a two part blog post series on partitioning.

Check out [PostgreSQL Table Partitioning — Growing the Practice — Part 1 of 2](/blog/2023/07/27/partitioning-growing-practice) for a general introduction followed by [PostgreSQL Table Partitioning Primary Keys — The Reckoning — Part 2 of 2](/blog/2023/07/28/partitioning-primary-keys-reckoning) which tells the story of a challenging online migration we performed for a big and busy partitioned table.

## Podcast

In July of 2023 I joined Jason Swett on the Code With Jason podcast, discussing PostgreSQL table partitioning among other topics. Check out the episode at [Code With Jason 190 — PostgreSQL and Sin City Ruby 🎙️](/blog/2023/07/28/code-with-jason-postgresql-sin-city-ruby).

Thanks for taking a look and I'd love to hear any feedback you have. 👋