---
layout: post
permalink: /django-python-postgres-busy-rails-developer
title: 'Django and Postgres for the Busy Rails Developer'
comments: true
date: 2024-11-15
hidden: true
---

Recently I had the chance to work with a team writing Python, building a new app using the Django Python framework.

The team was experienced with Django so I was curious about which libraries they'd chose, code patterns and structure.

In this post, I'll briefly introduce the database related parts of Django, using Postgres of course, highlight some of the library choices, and compare things to Ruby on Rails.

## Ruby versus Python
Ruby and Python are both general purpose programming languages. On the similarity side, they can both be used to write script style code, or organize code into classes using object oriented paradigms.

In local development, it felt like the execution of Python was perhaps faster than Ruby, however I've noticed that new apps are always fast to work with, given how little code is being loaded and executed.

## Language runtime management
As a developer we typically need to run multiple version of Ruby, Python, Node, and other runtimes. In Ruby I use [rbenv](https://github.com/rbenv/rbenv) to manage multiple versions of Ruby, and to avoid using the version of Ruby that was installed by macOS, which is usually outdated compared with the version I want for a new app.

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

For example, sometimes I'd fire up a Django shell and find issues at runtime that ruff would have caught had I ran it.

On this small codebase, ruff ran nearly instantly, so it was a no brainer to bake into the regular workflow or into the code editor.

## Postgres adapter
In Rails and Django, SQLite is the default database, however I wanted to use Postgres.

In Ruby, we have the [pg gem](https://github.com/ged/ruby-pg) which connects the application to Postgres as a driver. This does work at a lower level than the application like sending TCP requests, mapping Postgres query result responses into Ruby data types, and much more.

In Python, we used the [psycopg2 library](https://pypi.org/project/psycopg2/) and I found it pretty easy to use.

Besides being used by the framework ORM, I created a wrapper class using psycopg2 to use for sending SQL queries outside of models.

For example, we inspected Postgres system catalog views to capture certain data as part of the product features.

## Migrations in Rails
Both Ruby on Rails and Django have the concept of [Migrations](https://guides.rubyonrails.org/active_record_migrations.html), which are Ruby or Python code files that describe a database structure change, and have a version.

These are Ruby or Python code files will generate SQL DDL statements.

For example, to add a table in Rails typically there will be a migration file using the `create_table` Ruby helper.

Adding or dropping an index or modifying a column type are other types of DDL statements that typically are deployed via migrations.

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

## Postgres details
The books app models are Author, Publisher, and Books.
The tables for those models are contained in a custom schema `booksapp`.

The application connects to Postgres as the user `booksapp`, and local dev database is `books_dev`.

## No migration safety concept
No concept of safety, adding indexes (blocking writes) doesn’t use concurrently by default.

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

Since Python is a whitespace and indentation sensitive language, we’d need to space our attributes below into a “create” statement 4 spaces, but this is what a create looks like:
```py
Thing.models.create(
    attr1=val,
    attr2=val
)
```

## Previewing DDL
The generated SQL DDL isn't displayed when running `migrate` by default.

However, unlike Rails, Django provides a mechanism to preview it.

To do that, run the `sqlmigrate` command instead of `migrate`.
