---
layout: post
title: "PostgreSQL for the Busy MySQL Developer"
date: 2014-01-02
comments: true
tags: [MySQL, PostgreSQL, Productivity, Databases]
---

For a new project I will be using PostgreSQL. I have more experience with MySQL so I wanted to quickly learn about PostgreSQL and port over some of the skills I have.

#### Roles

Permissions are managed with "roles". To see all roles, type `\du`. To see the privileges for all tables, run `\l`. Here is a [list of privileges](http://www.postgresql.org/docs/9.0/static/sql-grant.html).

#### Working with Rails

For a Rails application, create a `rails` role and make it the owner:

``` bash
createdb -O rails app_name_development
```

From a psql prompt, type `\list` to see all databases, and `\c database` to connect to a database by name. `\dt` will show all the tables.

If the user did not have privileges to create a database there will be an error running `rake`. To add the `createdb` permission for the `rails` use:

``` sql
alter role rails createdb
```

To verify this role is added run the following query. A [role full list](http://www.postgresql.org/docs/9.1/static/sql-alterrole.html) is here.

``` sql
select rolcreatedb from pg_roles where rolname = 'rails';
 rolcreatedb
-------------
 t
```

#### Working with CSV

Like MySQL PostgreSQL supports working with data from CSV files. The following example uses a `company_stuff` database with a `customers` table. First we need to create the database, connect to it and create the table.

``` sql
create database company_stuff;

\c company_stuff;
create table customers 
    (id serial not null primary key, 
    email varchar(100), 
    full_name varchar(100)); 
```

Type `\d customers` to verify the table is set up correctly.

Assuming we have the same CSV file from the previous article when I covered how to work with CSV files using MySQL, we can load it into PostgreSQL using the `copy` command.

This example specifies the column names. The primary key ID column is set automatically.

``` bash
% cat customers.txt
bob@example.com,Bob Johnson
jane@example.com,Jane Doe
```

``` sql
copy customers(email, full_name) 
from '/tmp/customers.txt' 
delimiter ',' CSV;
```

Verify the contents of the customers table.

``` sql
select * from customers;
 id |      email       |  full_name
----+------------------+--------------
  1 | bob@example.com  |  Bob Johnson
  2 | jane@example.com |  Jane Doe
```

Now we can insert a new record, then dump all the records out again as a new CSV file.

``` sql
copy customers(email, full_name) 
to '/tmp/more_customers.csv' 
with delimiter ',';
```

Verify the output of the CSV file:

``` bash
~ $ cat /tmp/more_customers.csv
bob@example.com, Bob Johnson
jane@example.com, Jane Doe
andy@example.com,andy
```

#### Running Queries

Running a query from the command line and combining with `grep` is very useful.

Here is quick search in the "customers" database for columns named like "email":

``` bash
~ $ psql -U andy -d company_stuff -c "\d customers" | grep email
     email     | character varying(100) |
```

That's it for now!

#### More Mysql-to-PostgreSQL Links

 * [Useful guide on equivalent commands in postgres from mysql](http://granjow.net/postgresql.html)
 * [PostgreSQL quick start for people who know MySQL](http://clarkdave.net/2012/08/postgres-quick-start-for-people-who-know-mysql/)
 * [PostgreSQL for MySQL users](http://www.coderholic.com/postgresql-for-mysql-users/)
 * [How To Use Roles and Manage Grant Permissions in PostgreSQL on a VPS](https://www.digitalocean.com/community/articles/how-to-use-roles-and-manage-grant-permissions-in-postgresql-on-a-vps--2)


## More PostgreSQL Posts

Some of my blog posts on PostgreSQL

* [PostgreSQL Indexes: Prune and Tune](blog/2021/07/30/postgresql-index-maintenance)
* [PostgreSQL pgbench Workload Simulation](/blog/2021/08/10/pgbench-workload-simulation)
* [Views, Stored Procedures, and Check Constraints](/blog/2018/10/19/database-views-stored-procedures-check-constraints)
* [A Look at PostgreSQL Foreign Key Constraints](/blog/2018/08/22/postgresql-foreign-key-constraints)
* [Intro to PostgreSQL generate_series](/blog/2016/09/20/intro-postgresql-generate_series)
