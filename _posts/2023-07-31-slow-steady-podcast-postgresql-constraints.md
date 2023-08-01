---
layout: post
title: "Slow & Steady &mdash; Database Constraints with Andrew Atkinson 🎙️"
tags: [PostgreSQL, Rails, Ruby, Podcast]
date: 2023-07-31
comments: true
---


[Benedikt Deicke](https://benediktdeicke.com) (co-founder of UserList) recently hosted me on the Slow & Steady podcast (co-hosted by [Benedicte Raae](https://queen.raae.codes)). Our main topic was Database Constraints, why they're useful and how to use them.

Benedikt and I had a mutual connection in [Michael C.](https://michristofides.com) (founder of [PgMustard](https://www.pgmustard.com)) and had been following each on social media for a long time, so it was fun to meet on Zoom!

Benedikt recently tweeted about how a database constraint prevented an error in a critical part of their system. Since we'd planned to discuss something related to PostgreSQL, that story provided the spark for the episode topic.


## Slow & Steady Podcast

The Slow & Steady Podcast is co-hosted by technical founders building in public and sharing their struggles, wins, and everything in between.

They've been running it for 4 years!

Check out their catalog of episodes. <https://www.slowandsteadypodcast.com>

## Episode Overview

Eventually we got into the main topic for the episode, database constraints in PostgreSQL.

We covered most of them.

- Default
- Not Null
- Primary Key and Foreign Key
- Check
- Exclusion

Before we got into the main topic, we took a detail to discuss the historical lack of support for database level constraints in Ruby on Rails.

In the earlier days of Ruby on Rails in the 2000s there was more emphasis on database "portability," in order words using less RDBMS features to make it easier to move your application from one to another.

In my career experience though most companies don't switch their RDBMS.

Other popular relational databases like MySQL/MariaDB support most of the same constraints as well, including Default, Not Null, Primary Key, Foreign Key, and Check constraints.

What are the benefits of constraints?

## Benefits

- Constraints describe characteristics and relationships about columns and tables, expressed as SQL, and visible as part of your schema/structure
- Constraints are database objects that can be added, removed, dumped, and restored
- Constraints enforce the characteristics and relationships you've defined as rows are inserted, updated, and deleted

## Challenges

The main challenge in working with developers in my experience, is even knowing the constraints exist in general, where to use them, and then the actual process of adding them!

That was part of my motivation to cover this topic in detail for a while chapter in [High Performance PostgreSQL for Rails](https://pgrailsbook.com).

Constraints are validated immediately by default. Some constraints can have their validation deferred, meaning validation only runs for new row changes but not on existing rows.

Not all constraints support this deferred validation though so it can be tricky to add some types to a running system.

When adding constraints on big tables, this can cause the table to be locked for a long time and blocks queries trying to access it. Fortunately these are known scenarios with workarounds.

Strong Migrations (linked below) helps guide Rails developers towards adding constraints safely.

## Recommendations and Resources

- [Strong Migrations](https://github.com/ankane/strong_migrations) - Helps you add constraints and avoid riskier Migrations using safer alternatives.
- [Active Record Doctor](https://github.com/gregnavis/active_record_doctor) - helps you identify missing Foreign Key and Unique constraints based on your Active Record model configuration
- [Database Consistency](https://github.com/djezzzl/database_consistency) - helps you identify missing constraints
- [Postgres Constraints for Newbies](https://www.crunchydata.com/blog/postgres-constraints-for-newbies) - Nice introduction
- [Check Constraints support in Active Record](https://blog.saeloun.com/2021/01/08/rails-6-check-constraints-database-migrations/) (Rails 6.1+)


## Episode and Wrap Up


Listen to the episode here: 👉 [Database constraints with Andrew Atkinson](https://www.slowandsteadypodcast.com/episodes/database-constraints-with-andrew-atkinson)

Thanks for taking a look and we'd love to hear your feedback. If you liked the episode please share it on social media.

Thanks for reading! 👋
