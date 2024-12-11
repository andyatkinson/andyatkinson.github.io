---
layout: post
permalink: /django-python-postgres-busy-rails-developer
title: 'Django and Postgres for the Busy Rails Developer'
comments: true
date: 2024-12-10
tags: [Python, Django, PostgreSQL]
---

About 10 years ago I wrote a post [PostgreSQL for the Busy MySQL Developer](/blog/2014/01/02/postgres-for-the-busy-mysql-developer), as part of switching from MySQL to Postgres for my personal and professional projects, wherever I could.

Recently I had the chance to work with Python, Django, and Postgres together, as a long-time and busy Rails developer.

There were some things I thought were really nice. So am I switching?

The team I worked with was experienced with Django, so I was curious to learn from them about popular libraries, idiomatic code, and tooling.

In this post, I'll briefly cover the database parts of Django using Postgres of course, highlight some libraries and tools, and compare things to Ruby on Rails. You'll find a small Django repo towards the end as well.

## Ruby versus Python
Ruby and Python are both general purpose programming languages. On the similarity side, they can both be used to write script style code, or organize code into classes using object oriented paradigms.

In local development, it felt like the execution of Python was perhaps faster than Ruby, however I've noticed that new apps are always fast to work with, given how little code is being loaded and executed.

## Language runtime management
As a developer we typically need to run multiple versions of Ruby, Python, Node, and other runtimes, to support different codebases, and to avoid modifying our system installation.

In Ruby I use [rbenv](https://github.com/rbenv/rbenv) to manage multiple versions of Ruby, and to avoid using the version of Ruby that was installed by macOS, which is usually outdated compared with the version I want for a new app.

In Python, I used [pyenv](https://github.com/pyenv/pyenv) to accomplish the same thing, which seemed quite similar in use.

Both have concepts of a local and global version, and roughly similar commands to install and change versions.

## Library management
In Ruby on Rails, [Bundler](https://bundler.io) has been the de facto standard forever, as a way to pull in Ruby library code and make sure it’s loaded and accessible in the Rails application.

In Python, the team selected the [poetry](https://python-poetry.org) dependency management tool.

Commands are similar to Bundler commands, for example `poetry install` is about the same as `bundle install`.

Dependencies can be expressed in a `pyproject.toml` file and poetry creates a lock file with specific library versions. [TOML](https://toml.io/en/) and YAML are similar.

## Linting and formatting
In Ruby on Rails, although I personally resisted rule detection etc. for years, [Rubocop](https://github.com/rubocop/rubocop) has become the standard, even being built in to the most recent Rails version 8.

Rubocop has configurable rules that can automatically reformat code or lint code for issues.

Formatters like [standardrb](https://github.com/standardrb/standard) are commonly used as well.

For the Django app, the team selected [ruff](https://github.com/astral-sh/ruff), which performed formatting of code and also linted for issues like missing imports.

I found ruff fast and easy to use and genuinely helpful.

For example, sometimes I'd fire up a Django shell, skipping ruff, only to realize there are issues it would have caught.

On this small codebase, ruff ran instantly, so it was a no-brainer to run regularly, or even include in my code editor.

## Postgres adapter
In Rails and Django, SQLite is the default database, however I wanted to use Postgres.

In Ruby, we have the [pg gem](https://github.com/ged/ruby-pg) which connects the application to Postgres as a driver. This does work at a lower level than the application like sending TCP requests, mapping Postgres query result responses into Ruby data types, and much more.

In Python, we used the [psycopg2 library](https://pypi.org/project/psycopg2/) and I found it pretty easy to use.

Besides being used by the framework ORM, I created a wrapper class using psycopg2 to use for sending SQL queries outside of models.

For example, we inspected Postgres system catalog views to capture certain data as part of the product features.

## Migrations in Rails
Both Ruby on Rails and Django have the concept of [Migrations](https://guides.rubyonrails.org/active_record_migrations.html), which are Ruby or Python code files that describe a database structure change, and have a version.

From the Ruby or Python code files, SQL DDL (or DML) statements are generated which are run against the configured database.

For example, to add a table in Rails typically a developer uses the `create_table` Ruby helper as opposed to writing a `CREATE TABLE` SQL statement.

Adding or dropping an index or modifying a column type are other types of DDL statements that typically are performed via migrations.

## Migrations in Django
The Django approach has noteworthy differences and a slightly different workflow that I enjoyed more in some ways.

For example, changes are started in a `models.py` file, which contains all the application models (multiple models in a single file), and the database layer details about each model attribute.

This means that we specify database data types for columns, whether fields are unique, indexed, and more in the models file.

The interesting difference compared with Rails is that the next step in Django is to run `makemigrations`, which *generates* Python migration files.

This is different from Rails, where Rails developers would first generate a migration file to place changes into.

In Django, the generated migration file can be inspected or simply applied using the `migrate` command. This command is nearly identical to the Rails equivalent command `db:migrate`.

For a new project where we were rapidly iterating on the models and their attributes, I preferred the way Django works here to how Rails works.

## Command line vibes
Here are some commands like running `poetry install`, or running `manage.py` commands like `shell` or `makemigrations`, to give you a flavor.
```python
poetry install
poetry run python manage.py dbshell   # psql in postgres
poetry run python manage.py shell # Django shell
Poetry run python manage.py makemigrations   # Generates Python migration files, can be customized
Poetry run python manage.py migrate # runs them. Doesn’t show SQL by default.
```

## Interactive console (REPL)
Both Django and Rails use interpreted languages, Python and Ruby respectively, that each support an interactive execution environment.

This environment is called a *read, eval, print loop* or REPL for short.

In Rails, the Ruby REPL "irb" is launched and Rails application code is loaded automatically when running the [rails console](https://guides.rubyonrails.org/command_line.html) command.

In Django, the equivalent command is running [shell](https://docs.djangoproject.com/en/5.1/ref/django-admin/#shell), however application code needs to be imported before it can be used, using `import` statements.

Both frameworks also support opening a database client, by running `dbconsole` in Rails or `dbshell` in Django.

When Postgres is configured, these both open a psql session.

## Projects and Apps
In Django, projects and applications are separate concepts.

In my experimental project, I made a "booksproject" project and a "books" app.

Check out the [booksproject repo](<https://github.com/andyatkinson/booksproject>).

## Postgres details
The books app models are Author, Publisher, and Books.

The tables for those models are contained in a custom schema `booksapp`, and Django is configured to access it.

The application connects to Postgres as the `booksapp` user and the dev database is called `books_dev`.

## No migration safety concept
There's no concept of what I'd call "safety" for migrations for either framework out of the box.

Operations like adding indexes in Postgres don't use the concurrently keyword by default for example.

We can add safety using additional libraries. At a smaller scale of data and query volume, even unsafe operations will be fine, but I think some visibility into blocking operations would still be helpful earlier.

## Adding a constraint
In models, add `unique=True` to a field definition. After running `makemigrations` a migration for a unique index will be created.

In Active Record we might generate the migration file first, then fill in the create statement for a unique index.

## Django models
When querying a model like Book, we’d use `objects`, which returns a QuerySet object with one or more books.

The `filter()` method will generate a SQL query with a `WHERE` clause to filter down the rows, or all rows can be accessed using `all()`.

For example:
```python
Model.objects.filter()
Model.objects.first()
Model.objects.all()
```

Since Python is a whitespace and indentation sensitive language, we’d indent the attributes within `create()` by 4 spaces, as shown below:
```python
Thing.models.create(
    attr1=val,
    attr2=val
)
```

## Previewing DDL
The generated SQL DDL isn't displayed when running `migrate` by default.

However, unlike Rails, Django provides a mechanism to preview it.

To do that, run the `sqlmigrate` command instead of `migrate`.

For example, to print the 0001 migration DDL:
```sh
python manage.py sqlmigrate books 0001
```
```sql
BEGIN;
--
-- Create model Author
--
CREATE TABLE "books_author" ("id" bigint NOT NULL PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY, "first_name" varchar(200) NOT NULL, "last_name" varchar(200) NOT NULL);
COMMIT;
```

Note that Django uses an identity column for the primary key, and as of Rails 8 Active Record does not. 

## Resources
For the basics of an Author, Publisher, and Books models, or Postgres configuration including a custom schema and user, check out [booksproject](https://github.com/andyatkinson/booksproject) repo.

To collect random Django tips, I've created a [django-tips](/django-tips) page, to be used in a similar way as my [rails-tips](/rails-tips) and [postgresql-tips](/postgresql-tips) pages, mostly as a reference for myself, and possibly as a useful resource for others.

## Wrap Up
Do you have any similarities and differences between Django and Rails to share? I'd love to hear from you.

😅 And no, I'm not "switching" from Rails and Ruby, but I did enjoy working with Python and Django.

Thanks for reading.
