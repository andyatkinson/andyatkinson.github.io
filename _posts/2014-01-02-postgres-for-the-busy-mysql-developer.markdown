---
layout: post
title: "PostgreSQL for the Busy MySQL Developer"
date: 2014-01-02
comments: true
tags: [MySQL, PostgreSQL, Productivity, Databases]
---

For a new project I'll be using PostgreSQL. I have more experience with MySQL so I wanted to quickly learn PostgreSQL and port over some of my skills.

In this post I'll be sharing what I learned! Statements should be run using the psql command line client.

## Roles

Users in PostgreSQL are called "roles". To "describe" all the "users" type `\du` in psql. These are meta commands.

Roles have Privileges in order to perform various operations.

Type `\list` to see all databases and `\c database` to connect to a database named "database". `\dt` will "describe" all "tables".

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

Type `\d customers` to "describe" the table you just created.

Using the same CSV file from an earlier article (or create a couple sample rows like below), load it into PostgreSQL using the COPY command.

The file should look like this. Create it in your editor (`vim /tmp/customers.txt`) using an absolute path, if you don't already have the file in this location.

It only needs a couple of rows for demonstration purposes.

```bash
% cat customers.txt
bob@example.com,Bob Johnson
jane@example.com,Jane Doe
```

With the file in place, load it using the Copy command into the table you've just created.

```sql
COPY customers(email, full_name)
FROM '/tmp/customers.txt'
DELIMITER ',' CSV;
```

If it was successful, you'll see `COPY 2` as output.


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

The Copy command can be used for loading and dumping data.

## Running Queries

Running a query from the command line and combining the output with `grep` is powerful.

Here is quick search in the "customers" database for columns named like "email":

``` bash
psql -U andy -d company_stuff -c "\d customers" | grep email
```

This can be used to quickly check a particular database, whether a table has a particular column.

That's it for now!

## Mysql to PostgreSQL Resources

* [Useful guide on equivalent commands in postgres from mysql](http://granjow.net/postgresql.html)
* [PostgreSQL quick start for people who know MySQL](http://clarkdave.net/2012/08/postgres-quick-start-for-people-who-know-mysql/)
* [PostgreSQL for MySQL users](http://www.coderholic.com/postgresql-for-mysql-users/)
* [How To Use Roles and Manage Grant Permissions in PostgreSQL on a VPS](https://www.digitalocean.com/community/articles/how-to-use-roles-and-manage-grant-permissions-in-postgresql-on-a-vps--2)
