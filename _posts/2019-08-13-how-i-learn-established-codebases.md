---
layout: post
title: "How I Learn Established Codebases"
tags: [Productivity, Tips]
date: 2019-08-13
comments: true
---

Learning a new codebase can be a challenging task. Unfortunately at times the original developers are no longer around and the documentation may be outdated or missing entirely.

This post will focus on a few strategies I have used to learn about an established codebase, typically a web application or web service in Ruby or Java in my case. Let's get started.


#### Database Schema

Before looking at the application code, I like to look at the database schema. I will browse the table names, fields, and data types.

I will also look at the indexes, whether a column may be null, and explore foreign key relationships. This helps give me an idea of what data is required (although nullability may be specified in the application code), and some of the collaborating objects (however not all objects will have corresponding database tables).

If polymorphism is being used, multiple types of related objects may be stored in a single table.


#### Database Queries

In addition to looking at the schema, running queries and looking at real data can be very helpful. For example, I like to check the count of records or how recently the last record was created or updated. Knowing whether a table is active is useful for the purposes of changing it. Knowing how many rows a table has can help inform how easy or difficult it will be to modify it.

For polymorphic types, `group` and `count` can be used to see various types and how many of them there are.

For example, to get a count of the owner types, we could do:

```sql
select owner_type, count(*) from delivery_zones group by owner_type order by count(*) desc;
```

#### Configuration, Constants, Dependencies

Configuration files provide information about the runtime dependencies the application has, for example database or cache servers. There may be information about how logging is performed.

Application code may have constants defined that are clues about important systems or features of the product. The constants may also represent opportunities to be turned into first class features.

I will also browse the code dependencies (for example the `Gemfile` in a Rails app or the `pom.xml` in a Java app), checking how recent the versions are, and browse the Git history of that file. More recent versions will have less security risk and will be easier to upgrade.

Another type of configuration file would be a schedule file or cron file. Any scheduled tasks that run in the background will be kicked off from here. This file will describe how frequently and when those jobs are run, which may be helpful in learning the domain.


#### Local Development Data

When working with a new model that has a database table, having real data available locally can help aid understanding and further development.

Assuming this is feasible from a security perspective, and that a database connection string exists and is usable, the below commands use PostgreSQL `pg_dump` and `pg_restore` to dump and load a single table.


```sh
pg_dump --verbose --compress=6 -Fc --no-acl --no-owner -h localhost `db_connection_string` -t table_name > tmp/table_dump_file_name.sql
```


```sh
pg_restore -d database_name tmp/table_dump_file_name.sql
```

To dump an entire graph of real data for a user, that can be easily maintained over time, check out my [Seedster gem](https://github.com/groupon/seedster) (for Rails and PostgreSQL).


#### Reading Test Cases

Documentation may be incomplete or outdated, but unit and integration tests help serve as documentation as well.


#### Random Scripts Junk Drawer

Applications may have a "junk drawer" of random scripts, meaning they are unrelated to each other. These may also exist as developer gists, or in a dedicated scripts repo. For example data-only migrations, configuration for a set of objects in lieu of a user-facing admin, or generating a one-off report in lieu of a self-service reporting tool are some examples.

Scripts of this type may have served their purpose and are now dead code that could be deleted. If the scripts are in active use, they would be helpful in learning about the domain, and act as a starting point for building an application feature to replace the functionality of the script.


#### Developing Domain Knowledge By Building Something

To build domain knowledge, my ideal situation is to build a small feature. This way I am able to review what is there, talk with stakeholders, and find out how to make an additive and not duplicative change. This is preferable to learning the domain while solving a production issue or bug.
