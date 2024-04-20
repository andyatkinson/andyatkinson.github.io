---
layout: post
title: "PostgreSQL for the Busy MySQL Developer"
date: 2014-01-02
comments: true
tags: [MySQL, PostgreSQL, Productivity, Databases]
---

For a new project I'll be using PostgreSQL. I have more experience with MySQL so I wanted to quickly learn PostgreSQL and port over some of my skills.

First I reviewed some of the equivalent commands.

## MySQL to PostgreSQL Resources

* [Useful guide on equivalent commands in postgres from mysql](http://granjow.net/postgresql.html)
* [PostgreSQL quick start for people who know MySQL](http://clarkdave.net/2012/08/postgres-quick-start-for-people-who-know-mysql/)
* [PostgreSQL for MySQL users](http://www.coderholic.com/postgresql-for-mysql-users/)
* [How To Use Roles and Manage Grant Permissions in PostgreSQL on a VPS](https://www.digitalocean.com/community/articles/how-to-use-roles-and-manage-grant-permissions-in-postgresql-on-a-vps--2)

This post will cover:

- Working with users in PostgreSQL
- Working with CSV files
- Running queries from the command line

In this post, I'll share what I learned!

## Roles

Users in PostgreSQL are called "roles". To "describe" all the "users" type `\du` (describe users) in psql. These are "meta-commands," and they start with a backslash (it tilts backwards) not a forward slash. 😊

Roles have Privileges, which give them the ability to perform various operations.

Type `\list` (or `\l`) to see all databases and `\c database-name` to connect to a database (replacing "database-name" with your database name).

The `\dt` meta-command describes all tables, and `\d` with a table name argument, describes a specific table.

## Working with CSV

Like MySQL, PostgreSQL supports working with data from CSV files.

Create a `company_stuff` database and connect to it. Once connected, create a `customers` table. Run the following commands from psql.

```sql
CREATE DATABASE company_stuff;

\c company_stuff

CREATE TABLE customers (
    id BIGSERIAL NOT NULL PRIMARY KEY,
    email TEXT,
    full_name TEXT);
```

Type `\d customers` to "describe" the customers table you just created.

Using the same CSV file from an earlier article (or create a couple sample rows like below), load it into PostgreSQL using the COPY command.

Create it in your editor (`vim /tmp/customers.csv`) using an absolute path, if you don't already have the file in this location.

The file has no header row and a couple of data rows for demonstration purposes.

```bash
% cat customers.csv
bob@example.com,Bob Johnson
jane@example.com,Jane Doe
```

With the file in place, load it using the COPY command into the users table you've just created.

```sql
COPY customers (email, full_name)
FROM '/tmp/customers.csv'
DELIMITER ',' CSV;
```

If the rows loaded successfully, you'll see `COPY 2` as output.

View the rows in the customers table.

```sql
SELECT * FROM customers;
 id |      email       |  full_name
----+------------------+--------------
  1 | bob@example.com  |  Bob Johnson
  2 | jane@example.com |  Jane Doe
```

Insert another record and then dump all the records out again as a new CSV file.

```sql
INSERT INTO customers (email, full_name) VALUES ('andy@example.com', 'Andrew Atkinson');

COPY customers(email, full_name)
TO '/tmp/more_customers.csv'
WITH DELIMITER ',';
```

Verify the output of the CSV file.

```bash
~ $ cat /tmp/more_customers.csv
bob@example.com,Bob Johnson
jane@example.com,Jane Doe
andy@example.com,Andrew Atkinson
```

We can follow the basics shown here with the COPY command to efficiently load and dump data.

## Running Queries

Running a query from the command line allows us to script operations.

Here is quick search of the "customers" table content for text that matches "email":

``` bash
psql -U andy -d company_stuff \
  -c "\d customers" | grep email
```

This is a quick way to check whether the table has a column named "email."

Running ad hoc queries and commands is useful for scripting operations.

That's it for now!

