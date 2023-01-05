---
layout: post
title: Working with Large Amounts of Data using MySQL
date: 2012-11-27
comments: true
tags: [Productivity, MySQL, Databases, Performance]
---

MySQL [LOAD DATA INFILE](http://dev.mysql.com/doc/refman/4.1/en/load-data.html) can be used to load thousands or millions of records very quickly. Each row in a CSV text file will be created as a record in the database.

Let's say a developer needs to load thousands of customer records from another system, and receives a CSV file representing the customer records. A couple of example records of customer data might look like this:

```sh
$ cat customers.txt 
bob@example.com,Bob Johnson
jane@example.com,Jane Doe
```
    
This example will use a database called `company_stuff` and a table called `customers`. The customers table has columns for email and full_name.

```sql
mysql> create database company_stuff;
mysql> use company_stuff;

mysql> CREATE TABLE customers (
  id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  email VARCHAR(100),
  full_name VARCHAR(100)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
```

Using LOAD DATA LOCAL INFILE it is possible to load these rows from the CSV file as records in the customers table. If the CSV file contains a header row that should be skipped at import time, add `IGNORE 1 LINES` after the `LINES TERMINATED BY` clause.

```sql
mysql> LOAD DATA LOCAL INFILE 'customers.txt'
INTO TABLE customers
FIELDS TERMINATED BY ','
ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
(email, full_name);
```

Verify the records were created.

```sql
mysql> select * from customers;
+----+------------------+-------------+
| id | email            | full_name   |
+----+------------------+-------------+
|  1 | bob@example.com  | Bob Johnson |
|  2 | jane@example.com | Jane Doe    |
+----+------------------+-------------+
2 rows in set (0.00 sec)
```
    
Instead of loading customer records, what if the developer had to export customer data? MySQL has the ability to write the results of a SQL query to a file. By reading and writing data to and from a CSV file, large amounts of data can be manipulated very quickly. The SQL commands to interact with the data can be scripted from a language like Ruby to automate the process further.

To export the customer database to a file in the tmp directory `/tmp/my_customers.txt`:

```sql
mysql> SELECT email, full_name
INTO OUTFILE "/tmp/my_customers.txt"
FIELDS TERMINATED BY ',' 
LINES TERMINATED BY '\n'
FROM customers;
```

Finally, verify the contents in the new CSV file are the records from the customers table as follows:

```sh
$ cat /tmp/my_customers.txt 
bob@example.com,Bob Johnson
jane@example.com,Jane Doe
```
