---
layout: post
permalink: /constraint-driven-optimized-responsive-efficient-core-db-design
title: "Introducing CORE Database Design: Constraint-driven, Optimized, Responsive, and Efficient"
hidden: true
---

## Introduction
In this post, we'll coverage some database design principles and package them up into a catchy mnemonic acronym.

Software engineering is loaded with acronyms like this. For example, [SOLID principles](https://en.wikipedia.org/wiki/SOLID) describe 5 principles (Single responsibility, open-closed, Liskov substitution, Interface segregation, Dependency inversion) for good object-oriented design.

Another example is DRY standing for "don’t repeat yourself," describing the process of factoring out common pieces to avoid duplication.

Database design has acronyms like ACID that refer to the properties of a transaction, but I wasn't familiar with an acronym the schema designer can keep in mind.

This acronym encapsulates the rationale and some goals I keep in mind for database schema designs and recommendations. It's not based in research or academia, so don't take it too seriously!

## Picking a mnemonic acronym
Some goals were to keep it short, have each letter describe a word that's useful, practical, and grounded in real world experience. I preferred a real word for memorability!

The result was "**CORE**." Let’s break down each word the letters represent in the context of database design.

## Constraint-Driven
The first word (technically two) is "constraint-driven." Relational databases offer both rigid structures, but the ability to be flexible, evolving the structure through [DDL](https://en.wikipedia.org/wiki/Data_definition_language). They use [data types](https://www.postgresql.org/docs/current/datatype.html) and [constraints](https://www.postgresql.org/docs/current/ddl-constraints.html) to encode rules about the data and the relationships.

Constraint-driven refers to the constraint objects offered and making full use of them, but also more generally to apply constraints and restrictions in designs to increase consistency and quality.

For example, choosing the appropriate data types, like a numeric data type and not a character data type when storing a number. Using `NOT NULL` and Foreign Key constraints by default, validating inputs with Check constraints.

The mindset is to prefer more rigidity initially, then add flexibility later, as opposed to the other way around.

## Optimized
Databases present loads of optimization opportunities. Relational data is initially stored in a normalized form to eliminate duplication, but later may be partially *denormalized* when the importances of read access is more important. This optimization process adjusts the structural design to support how the database is used ("use cases").

Besides tables and columns, indexes can be optimized depending on the query patterns table by table, whether they're write or read centric, and which operations are most common. Query execution plans are continually monitored for opportunities to improve efficiency.

Queries are restructured and indexes are added to optimize data access by reducing it, with highly selective filtering to reduce latency.

Filtering is performed on high cardinality columns. Critical background work like [VACUUM](https://www.postgresql.org/docs/current/sql-vacuum.html) is given more resources over time, to work well while not impacting foreground client application queries.

## Responsive
When problems emerge like column or row level unexpected data, missing referential integrity, or query performance problems, engineers have added logging, statistics, extensions, and tuned metrics so they're able to inspect the database and collect enough information to diagnose the issue.

When DDL changes are ready to make, the engineer applies them in a non-blocking way, in multiple steps when needed, so all operations can be performed on the database while it's running ("online" operations).

DDL changes being applied were created earlier and reviewed and tracked, keeping the schema design in sync across multiple instances of the database.

Parameter (GUC) tuning (Postgres: `work_mem`, etc.), happens in a trackable way and prefers parameters that can be tuned without restarting the database, to iterate on improvements.

## Efficient
Data that's stored is queried later, otherwise it's archived out of the database into low cost file storage.

Unneeded tables, columns, constraints, and indexes are removed continually as the design evolves.

Server software is upgraded at least annually so that the core software and extensions benefit from performance improvements and bug fixes.

Huge tables are split into smaller tables using native capabilities (table partitioning) for more predictable administration.

## CORE Database Design
There's lots more to evolving a database design, but these are a few principles that came to mind for me.

Did you notice anything missing you think should be added? Do you have any feedback on these principles or this acronym? Please contact me with your thoughts.

Thanks!
