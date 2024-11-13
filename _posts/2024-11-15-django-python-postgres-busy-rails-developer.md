---
layout: post
permalink: /django-python-postgres-busy-rails-developer
title: 'Django and Postgres for the Busy Rails Developer'
comments: true
date: 2024-11-15
hidden: true
---

Recently I had the chance to work with Python helping build a Django-framework backed app. The team was experienced with Django, so I was curious about the libraries they’d add, code patterns, and how to structure the app.

For this post, I thought it would be interesting to briefly overview Django for the Rails developer, and briefly compare similarities and differences.

## Ruby versus Python
Ruby and Python are both general purpose programming languages. On the similarity side, they can both be used to write script style code, or organize code into classes using object oriented paradigms. In local development, it felt like the execution of Python was perhaps faster than Ruby, but any time I’m creating a new small app, the performance is always very good as there is not a lot of code being loaded up.

## Language runtime version management
As a developer we typically need to run multiple version of Ruby, Python, Node, and other runtimes. In Ruby I typically use [rbenv](https://github.com/rbenv/rbenv) to manage multiple versions of Ruby and avoid using the version of Ruby installed by macOS, and adding libraries there, which can be problematic.

In python, I used [pyenv](https://github.com/pyenv/pyenv), which seems quite similar. They both have concepts of a local and global version, and roughly similar commands to install new versions.

## Library management
In Ruby on Rails, [Bundler](https://bundler.io) has been the de facto standard forever, as a way to pull in Ruby library code and make sure it’s loaded and accessible in the Rails application.

In Python, the team selected the [poetry dependency management](https://python-poetry.org) tool.

Commands are similar to bundler commands, for example `poetry install` is about the same as `bundle install`.

## Linting and formatting
In Ruby on Rails, although I personally resisted rule detection etc. for years, Rubocop has become probably the de facto option, with configurable rules that can automatically reformat code or lint code for issues. Formatters are catching on as well like the Ruby [standard](https://github.com/standardrb/standard) format.

For this app, the team selected [ruff](https://github.com/astral-sh/ruff), which offers both formatting of code, and checks for issues like missing imports. I found ruff fast and easy to use, and genuinely helpful. For example, sometimes I’d fire up a Django shell and find issues, and realize that ruff would have caught them first. Since it runs nearly instantly on this small codebase, it’s a no brainer to run all the time, even automatically within your editor.

## Postgres adapter
In Ruby, we have the [pg gem](https://github.com/ged/ruby-pg) which connects the application to Postgres as a driver. This does work at a lower level than the application like sending TCP requests, mapping Postgres query result responses into Ruby data types, and much more.

In Python, we used the [psycopg2 library](https://pypi.org/project/psycopg2/) and I found it pretty easy to use. Besides being used by the framework ORM, I created a wrapped class around psychopg2 to issue arbitrary SQL queries, such as inspecting schema elements of a database, which was one part of one of the features of the product.

## Running migrations
Both Ruby on Rails and Django have the concept of [Migrations](https://guides.rubyonrails.org/active_record_migrations.html), which are Ruby or Python code files that describe a database structure change, and have a version.

These Ruby or Python code files will generate SQL DDL statements.

For example, adding a table in Rails uses the `create_table` Ruby method helper. Adding or dropping an index or modifying a column type are other types of DDL statements to put into production using the migrations mechanism.

The Django approach has noteworthy differences and a slightly different workflow, that I enjoyed more in some ways.

For example, changes are usually started in a models file, which is where all the application objects are, but is focused on the persistence details.

This means this file has database data types for columns, unique constraints, indexes, etc.

The interesting difference compared with Rails is that after making model file changes, the Django developer runs the `makemigrations` command which *generates* the Python migration files.

In Rails, a developer would generate the migration file first, although it's often empty to start, then fill it in.

In Django, the generated migration file can be inspected and then run using a second command `migrate`, which is nearly identical to the Rails command `db:migrate`.

For a new project where we were rapidly iterating on the model, I felt this approach of driving changes from the model files, where I generated migrations then applied them, to be faster and enjoyable.

## Command line vibes
Here are some commands like running poetry, or running manage.py commands like `shell`, `makemigrations`, etc.
```python
poetry install
poetry run python manage.py dbshell   # psql in postgres
poetry run python manage.py shell # Django shell
Poetry run python manage.py makemigrations   # Generates Python migration files, can be customized
Poetry run python manage.py migrate # runs them. Doesn’t show SQL by default.
```

## Interactive console (REPL)
Fortunately both Django and Rails use interpreted languages, Python and Ruby, that both suppoert interactive console environment.

This interactive environment is called a Read, eval, print loop or REPL for short.

In Rails, the Ruby REPL "irb" is launched and the Rails source code is loaded by running [rails console](https://guides.rubyonrails.org/command_line.html). Code is auto-loaded.

In Django, the equivalent command is running [shell](https://docs.djangoproject.com/en/5.1/ref/django-admin/#shell), however application code will need to be imported before it can be used, using a series of `import` statements.

Both frameworks also support opening a database command line client, by running `dbconsole` in Rails or `dbshell` in Django, both opening psql when Postgres is configured as the application database.

## Inspecting objects in the console
Rails:
```rb
object.inspect
```

Django:
```python
Object.__dict__
```

## Adding a constraint
In models, add unique=True to a field definition. After running makemigrations a migration for a unique index will be created.

In Active Record we might generate the migration file first, then fill in the create statement for a unique index.

In both cases, we don’t really see the generated SQL DDL command though.


## Active Record vs. Django ORM
Between the Ruby on Rails ORM - Active Record, and the Django ORM, there are some interesting similarities and differences. As a developer, a lot of time is spent describing the model objects, how they’re related to the database persistence layer, writing data into the database and reading it back out.

## Django models
In Django, model definitions are kept in a “models.py” file, with each named model. For example, Book, Author, etc.

When querying a model like Book, we’d use “objects”, which returns a QuerySet object with one or more books. There are also methods like “filter()” or “all()” which would generate a WHERE clause to filter down the rows, or reads all rows for the backing table.

These look like this:

```python
Model.objects.filter()
Model.objects.first()
Model.objects.all()
```

Since Python is a whitespace and indentation sensitive language, we’d need to space our attributes below into a “create” statement 4 spaces, but this is what a create looks like:

```python
Thing.models.create(
    attr1=val
    attr2=val
)
```


For filtering, I found the attribute filtering syntax a bit odd. The use of underscores here is significant. 

Attribute_


Maintain in models files


## Issues I see
SQL is hidden by default. This includes DDL that’s useful for devs like create index statements.


## Doesn’t use concurrent index creation by default
No concept of safety, adding indexes (blocking writes) doesn’t use concurrently by default.


## ViewSet

## QuerySet


## Celery
Tasks  Use annotations like @task
Signals  (triggering mechanisms)


## Testing 
Pytest
Testing tools like mocks, factories built in
Poetry run pytest 

Annotation to mark tests that access DB  @pytest.mark.django_db
@patch("psycopg2.connect")


## Apps
Can have applications within the application

## Debugging
```python
import pdb
pdb.set_trace()
```
