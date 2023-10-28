---
layout: post
title: "PGSQL Phriday #009 — Database Change Management"
tags: [PostgreSQL, Rails, Open Source]
date: 2023-06-02
comments: true
---

This month's PGSQL Phriday topic prompts writers to discuss how their team manages PostgreSQL database schema changes.

As usual, I'll write about Ruby on Rails and PostgreSQL since I work with these tools every day.

I'm even writing a book on PostgreSQL and Rails called [High Performance PostgreSQL for Rails](https://pgrailsbook.com). Please check it out!

Here are my past posts in the PGSQL Phriday series.

- [PGSQL Phriday #008 — pg_stat_statements, PgHero, Query ID](/blog/2023/05/17/pgsql-phriday-008)
- [PGSQL Phriday #001 — Query Stats, Log Tags, and N+1s](/blog/2022/10/07/pgsqlphriday-2-truths-lie)

On with the show! 🪄

## Database Change Management

This time I'll use the questions from the [invitation](https://www.pgsqlphriday.com/2023/05/pgsql-phriday-009/) as the content for this post.

#### How does a change make it into production?

A little background context. I work on a team of Rails developers that are constantly modifying a monolithic Rails application. These applications use PostgreSQL and changes often include both application code and schema modifications.

In Rails schema changes are made by developers. There has always been a built-in mechanism to do this as a core part of the Rails framework.

This is different from other frameworks that need an additional tool like [Flyway](https://flywaydb.org).

For PostgreSQL administrators that aren't used to developers making schema changes all the time, this can be surprising!

Most of the time schema changes are low impact, like adding a nullable column.

Do application developers sometimes make schema changes that cause errors? Yes. Although this risk exists, the benefits of having developers move faster making schema changes outweigh the risks.

We also attempt to mitigate the risks of application errors in a couple of ways.

Here is the normal workflow.

1. A developer generates a new [Active Record Migration](https://guides.rubyonrails.org/active_record_migrations.html) file using the `bin/rails` executable
2. They use the `generate` command (shortened to "g" below) and `migration` option. Read more about [Rails Generators](https://guides.rubyonrails.org/generators.html#generate).

    An example is below.

    ```sh
    bin/rails g migration CreateUserCountsTable rider_count:integer driver_count:integer
    ```

    This example creates a migration file and content. The content is a new table which has certain columns with type information.

    The generated file name includes a unique schema version number.  In this way developers generating schema migrations at the same time get unique schema versions.

3. The developer adds their change as Ruby or SQL to the generated file. This change could add a table, column, index, or really be any PostgreSQL DDL change (or even DML).

    Rails tracks schema changes in a Ruby file or SQL.[^proscons]

    I recommend using the SQL formatted file which is primarily generated from `pg_dump`.

    Besides the structure dumped from `pg_dump` Active Record schema "versions" are added.

    With the structure and the versions, developers apply any schema versions they don’t have already when they `git pull` new code.

    The migration files contain the incremental modifications, and the schema versions help keep things in sync.

4. The developer runs `bin/rails db:migrate` to apply the schema change to their local PostgreSQL database. From this point they do all the development testing needed before releasing their change. The change is included in a Pull Request that must be reviewed before merge.
5. When the Pull Request is approved, merged, and deployed, the schema change is applied to all deployment destination databases automatically as part of the deployment process.

The deployment process takes care of restarting application instances since they'd need to know about schema changes. Rails keeps a cache of the schema so that cache must be invalidated or application instances must be restarted.

#### Do you have a dev-QA-staging or similar series of environments it must pass through first?

Developers test their changes including schema modifications on their local development machines. Each Pull Request has a CI build associated with it with a separate database and builds must pass before merge. Each Pull Request must receive at least one review.

Developers may test their changes in a couple of pre-production test environments where they apply their schema modifications and deploy their code changes. This is not required but is a good practice.


#### Who reviews changes and what are they looking for?

Team members review all Pull Requests. A Databases group is tagged when a Pull Request includes Migrations.

I'm in this group and I mainly look for modifications that might cause long lived locks and block queries. See: [PostgreSQL rocks, except when it blocks: Understanding locks](https://www.citusdata.com/blog/2018/02/15/when-postgresql-blocks/)

I use what I know about row counts and query patterns when reviewing Pull Requests, making a risk assessment.

Our team does not have a easy way to test the effect of long duration locks in pre-production.

#### What’s different about modifying huge tables with many millions or billions of rows?

We do modify tables with billions of rows, but ideally we've partitioned the table before it reaches that point!

Schema changes can be more difficult on tables that size. As a SaaS B2B app, customers rely on our app to help run their businesses.

To help identify potentially unsafe changes as early as possible, we use [Strong Migrations](https://github.com/ankane/strong_migrations) which hooks into the Rails Migration flow.

For huge tables we look for changes that cause long locks on a table. Write locks could block concurrent modifications and cause user facing errors in the application.

We’d create the SQL for the modification  and test it locally and on  a lower environment. For visibility that the change is occurring, we would write it in a Jira ticket and share it on the team so that a second reviewer can approve it. We may plan to perform the modification during a low activity period.

If a change is made manually, we then backfill a Rails migration to prevent schema "drift", keeping everything in sync.

#### How does Postgres make certain kinds of change easier or more difficult compared to other databases?

The [Transactional DDL feature](https://wiki.postgresql.org/wiki/Transactional_DDL_in_PostgreSQL:_A_Competitive_Analysis) is a nice feature to experiment a bit with schema modifications and know that they’re rolled back. For Rails Migrations that fail to apply due to exceeding a lock timeout or for another reason, it’s nice to know the modification will be rolled back cleanly.

Rarely there can be a consistency problem between the Rails application and PostgreSQL. I covered this in the post [Manually Fixing a Rails Migration](/blog/2021/08/30/manual-migration-fix).


#### Do you believe that "rolling back" a schema change is a useful and/or meaningful concept? When and why, or why not?

I don’t normally roll back a schema change. We’d do a lot of pre-release testing in local development, CI, lower environments, and among multiple developers. However rolling back a transaction that contained a DDL modification is a nice safeguard.

What is a normal process in the evolution of a schema is that columns are no longer needed because they related to a feature that has been retired or relocated. This could even be entire tables or collections of tables.

In those cases it’s nice to remove the columns and tables entirely. This can have some risk as well and there are safeguards we use.


#### How do you validate a successful schema change? Do you have any useful processes, automated or manual, that have helped you track down problems with rollout, replication, data quality or corruption, and the like?

When Rails manages a database it gets a `schema_version` table. The schema version for a Migration (a number) is inserted into this table when it's applied.

We can confirm the schema change was applied by querying the table. We can view the table fields or indexes with `\d tablename` and similar commands.

A nice pattern is to release the schema changes in advance of their code usage. This provides an opportunity to verify schema changes where applied before new tables or columns are actively used.

For quality confirmation, we'd do basic checks. We'd make sure an Index built `CONCURRENTLY` completed and is not marked `INVALID`.

As a small team that's not dedicated to PostgreSQL we rely on AWS RDS Backups and Snapshots.

Besides backups, we also mitigate some disaster scenarios by using Physical and Logical replication in various ways.

For example we could promote a replica if needed or run replicas in multiple availability zones.

We also have a copy of rows and modifications in a data warehouse.

[Postgres.fm covered Corruption](https://postgres.fm/episodes/corruption) in a recent episode!

#### What schema evolution or migration tools have you used? What did you like about them, what do you wish they did better or (not) at all?

Active Record (Ruby on Rails) Migrations in Ruby.

Flyway with Java. See: [Building Microservices at Groupon](/blog/2019/11/04/building-java-microservices).


## Wrap Up

Thanks for reading!


[^proscons]: Pros and Cons of Using structure.sql in Your Ruby on Rails Application <https://blog.appsignal.com/2020/01/15/the-pros-and-cons-of-using-structure-sql-in-your-ruby-on-rails-application.html>
