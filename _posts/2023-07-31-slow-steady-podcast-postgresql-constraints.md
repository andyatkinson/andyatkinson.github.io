---
layout: post
title: "Slow & Steady &mdash; Database constraints with Andrew Atkinson 🎙️"
tags: [PostgreSQL, Rails, Ruby, Podcast]
date: 2023-07-31
comments: true
---


[Benedikt Deicke](https://benediktdeicke.com) (co-founder of UserList) recently hosted me on the Slow & Steady podcast where we discussed Database Constraints.

The podcast is co-hosted by [Benedicte Raae](https://queen.raae.codes) but they weren't able to join.

Benedikt and I had a mutual connection in [Michael C.](https://michristofides.com) (founder of [PgMustard](https://www.pgmustard.com)) and had been following each on social media for a long time, so it was fun to meet.

Recently, Benedikt tweeted about how a database constraint helped prevent a very visibile error in a critical part of their system. The team had the foresight to add it.

We planned on a topic within PostgreSQL and databases, so we used this experience as the basis for the episode topic.

Our idea was to have a conversation about how Database Constraints can help developers. We'd discuss what they are, their benefits, and some challenges in adding them.

How did we do?

Give it a listen and let us know.

If you're not familiar with the Slow & Steady podcast you might be wondering what it's all about.

## Slow & Steady Podcast

The Slow & Steady Podcast is co-hosted by technical founders building in public and sharing their struggles, wins, and everything in between.

They've been running it for 4 years!

Check out their catalog of episodes. <https://www.slowandsteadypodcast.com>

## Episode Overview

Eventually we got into an overview of the constraint types available in PostgreSQL.

- Default
- Not Null
- Primary Key and Foreign Key
- Check
- Exclusion

Before we got into that though we discussed the historical lack of support for database constraints in Ruby on Rails and Active Record.

In the earlier days of Ruby on Rails in the 2000s, in my opinion more emphasis was placed on database "portability," in order words moving from one RDMBS to another and not investing in features specific to an RDMBS.

In my career experience most companies I've worked for have not switched their RDBMS. For a company performing that kind of migration, besides the schema and data rows, the database constraints would be part of the migration.

MySQL for example also supports Default, Not Null, Primary Key, Foreign Key, and Check constraints. A database migration would involve re-creating PostgreSQL Check Constraints as MySQL Check Constraints. The SQL DDL may even be identical depending on which source and target database is being migrated.

MySQL does not support Exclusion Constraints.

Check Constraints can be used to write simple boolean expressions using SQL that must be validated at row insert, update, or delete time.

Exclusion constraints can compare two separate rows. An example comparison to enforce might be making sure two rows don't have overlapping rows, such as when a time range is expressed.

What are the benefits of constraints?

## Benefits

- Constraints describe characteristics and relationships about columns and tables in SQL
- Constraints enforce those characteristics and relationships once added

## Challenges

Constraints are validated immediately unless otherwise configured. Some constraints don't support the ability to defer validation.

For big tables this causes the table to be locked for a long time while the constraint is added, which blocks other queries for the table.

Constraints can be added without immediate verification for existing rows, to make them easier to add.

Constraint types NOT NULL don't have the ability to disable verification of existing rows.

Foreign Key and Check constraints do have this ability.

To get around that, a Check constraint can stand in and perform this job first and then be replaced by a Not Null constraint.

Active Record has continued to add support with new methods for Check Constraints.


## Application Level Constraints

Active Record provides developers the ability to express their data relationships via their model layer.

Daniela Baron wrote a highly detailed post [Understanding ActiveRecord Dependent Options](https://danielabaron.me/blog/activerecord-dependent-options/) describing all of the Active Record lifecycle callbacks. The post also describes a bad scenario of orphaned records where the parent record is removed.

- Delete Destroy
- Before Delete


- Soft Delete
- Audit table for modifications including deletes

GDPR "Right To Be Forgotten"

Destroy async and single delete statements per record and multiple records 


## Recommendations and Resources

- Strong Migrations. Helps you add constraints and avoid riskier Migrations using safer alternatives.
- Active Record Doctor: help identify missing foreign key cosntraints and missing unique constraints based on your Active Record model configuration
- Database Consistency: helps identify missing constraints
- [Postgres Constraints for Newbies](https://www.crunchydata.com/blog/postgres-constraints-for-newbies)
- Check Constraints support in Active Record
- "Async Delete" support in Active Record


## Wrap Up

Thanks for reading! 👋
