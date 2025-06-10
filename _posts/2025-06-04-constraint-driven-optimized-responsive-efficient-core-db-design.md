---
layout: post
permalink: /constraint-driven-optimized-responsive-efficient-core-db-design
title: "CORE Database Schema Design: Constraint-driven, Optimized, Responsive, and Efficient"
date: 2025-06-09
tags: [PostgreSQL, Databases]
---

## Introduction
In this post, we'll cover some database design principles and package them up into a catchy mnemonic acronym.

Software engineering is loaded with acronyms like this. For example, [SOLID principles](https://en.wikipedia.org/wiki/SOLID) describe 5 principles, Single responsibility, Open-closed, Liskov substitution, Interface segregation and Dependency inversion, that promote good object-oriented design.

Databases are loaded with acronyms, for example "ACID" for the properties of a transaction, but I wasn't familiar with one the schema designer could keep in mind while they're working.

Thus, the motivation for this acronym was to help the schema designer, by packaging up some principles of good design practices for database schema design. It's not based in research or academia though, so don't take this too seriously. That said, I'd love your feedback!

Let's get into it.

## Picking a mnemonic acronym
In picking an acronym, I wanted it to be short and have each letter describe a word that's useful, practical, and grounded in experience. I preferred a real word for memorability!

The result was "**CORE**." Let’s explore each letter and the word behind it.

## Constraint-Driven
The first word (technically two) is "constraint-driven." Relational databases offer rigid structures, but the ability to be changed while online, a form of flexibility in their evolution. We evolve their structure through [DDL](https://en.wikipedia.org/wiki/Data_definition_language). They use [data types](https://www.postgresql.org/docs/current/datatype.html) and [constraints](https://www.postgresql.org/docs/current/ddl-constraints.html) to make changes, as entities and relationships evolve.

Constraint-driven refers to leveraging all the constraint objects available, designing for our needs today, but also in a more general sense applying constraints (restrictions) to designs in the pursuit of data consistency and quality.

Let's look at some examples. Choose the appropriate data types, like a numeric data type and not a character data type when storing a number. Use `NOT NULL` for columns by default. Create foreign key constraints for table relationships by default.

Validate expected data inputs using check constraints. For small databases, use `integer` primary keys. If tables get huge later, no problem, we can migrate the data into a bigger more suitable structure.

The mindset is to prefer rigidity initially, design for today, then leverage the flexibility available to evolve later, as opposed to designing for a hypothetical future state.

## Optimized
Databases present loads of optimization opportunities. Relational data is initially stored in a normalized form to eliminate duplication, but later *denormalizations* can be performed when read access is more important.

When our use cases are not known at the outset, plan to iterate on the design, changing the structure to better support the use cases that emerge. This will mean evolving the schema design.

This applies to tables, columns, constraints, indexes, parameters, queries, and anything that can be optimized to better support real use cases.

Queries are restructured and indexes are added to reduce data access. Strive for highly selective data access (a small proportion of rows) on high cardinality (uniqueness) data to reduce latency.

Critical background processes like [VACUUM](https://www.postgresql.org/docs/current/sql-vacuum.html) get optimized too. Resources (workers, memory, parallelization) are increased proportionally.

## Responsive
When problems emerge like column or row level unexpected data, missing referential integrity, or query performance problems, engineers inspect logs, catalog statistics, and parameters, from the core engine and third party extensions to diagnose issues.

When DDL changes are ready, the engineer applies them in a non-blocking way, in multiple steps as needed. Operations are performed "online" by default when practical.

DDL changes are in a source code file, reviewed, tracked, and a copy of the schema design is kept in sync across environments.

Parameter (GUC) tuning (Postgres: `work_mem`, etc.) happens in a trackable way. Parameters are tuned online when possible, and scoped narrowly, to optimize their values for real queries and use cases.

## Efficient
It's relatively costly to store data in the database, compared with file storage! The data consumes limited space and accessing data unnecessarily adds latency.

Data that's stored is queried later or it's archived.

To minimize space consumption and latency, tables, columns, constraints, and indexes are removed continually by default, when they no longer are required, to reduce system complexity.

Server software is upgraded at least annually so that performance and security benefits can be leveraged.

Huge tables are split into smaller tables using table partitioning for more predictable administration.

## CORE Database Design
There's lots more to evolving a database schema design, but these principles are a few I keep in mind.

Did you notice anything missing? Do you have other feedback? Please [contact me](/contact) with your thoughts.

## Thank You
Over the years, I've learned a lot from [Postgres.fm](https://postgres.fm) hosts [Nikolay](https://postgres.ai) and [Michael](https://www.pgmustard.com), and other community leaders like [Lukas](https://pganalyze.com) and [Franck](https://dev.to/franckpachot), as they've shaped my database design choices.

I'm grateful to them for sharing their knowledge and experience with the community.

Thanks for reading!
