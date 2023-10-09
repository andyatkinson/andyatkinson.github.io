---
layout: post
title: "PostgreSQL pgbench Workload Simulation"
tags: [PostgreSQL, Databases, Ruby on Rails]
date: 2021-08-10
comments: true
---

We operate a high scale API application that relies on a single primary PostgreSQL instance. We have scaled up the DB instance vertically, acquiring more CPU, Memory, and disk IO over time.

For the workload on the primary, the workload is more write oriented by design (`INSERT` and `UPDATE` statements) as we use a read replica (standby) that is intended for any read only queries to execute against to take load off the primary.

We configure this write and read separation manually in Rails which has supported multiple databases natively since Rails 6. Rails lets us configure different roles for writing and reading and we can switch between them from one line of code to another if needed.

## Using pgbench

pgbench allows us to set up a benchmark set of queries that can be run against a database. The benchmark input is SQL queries. These statements can be customized to add some diversity into the SELECT statements so that rows are not always selected that exist in the same page.

[pgbench](https://www.postgresql.org/docs/10/pgbench.html) is built in to PostgreSQL. I run pgbench local on macOS and then make a connection to a remote PG database, which then executes the benchmark.

## Workload Simulation

We have just recently started to attempt to simulate our workload. I did this by grabbing some of the Top SQL (from RDS Performance Insights), selecting a mix of INSERT, UPDATE and SELECT statements. These queries are parameterized, meaning placeholder values like question mark need to be replaced with real values.

In order to create the values we can use a `RANDOM()` function and give it an upper bound that roughly matches the table row count.

## Shell Script

To run a pgbench benchmark, create a shell script like `my_benchmark.sh`.

Using bash we can create a script that creates 10 SELECT statements each with a random value for `blog_id`.

```bash
#!/bin/bash

# disable asterisk expansion
# https://askubuntu.com/a/1301124
set -f

# for Mac OS, uses `jot`
# Prereq: loaded 1000+ comments
for run in {1..10};
do
  sql="SELECT * FROM comments "
  sql+="WHERE blog_id = $(jot -r 1 1 1000);"
  echo $sql >> queries.bench
done
```

We can create a mix of UPDATE statements as well for example setting `CURRENT_TIMESTAMP` on a timestamp column.

Here is an example UPDATE statement:

```bash
sql="UPDATE comments SET view_count = 0 "
sql+="WHERE blogs.id = 1"
echo $sql >> queries.bench
```


The last line of the shell script will actually call `pgbench` and it will read in the `queries.bench` file that was written to earlier.

Here are some configuration options:


```sh
# `-T/--time` time seconds
# `-j/--jobs` number of threads
# `-c/--client` number of clients
# `-M/--protocol` querymode = prepared
# `-r/--report-latencies`
#

pgbench --host localhost --port 5432 --username root \
--protocol prepared --time 60 --jobs 8 --client 8 \
--file queries.bench --report-latencies my_database_name"
```

Once we put that all into `my_benchmark.sh` and `chmod +X my_benchmark.sh` now we can run it like `./my_benchmark`.

This technique may be useful to use to help tune memory parameters like `shared_buffers` to understand how changing the parameter affects the performance.

Another tool for PostgreSQL benchmarking is [HammerDB](https://github.com/TPC-Council/HammerDB). HammerDB may have a more realistic workload test environment out of the box.

This form of database benchmarking is best for testing parameter changes, system resource usage and that sort of thing.

A more realistic test of a web application workload might use HTTP load testing tools and API endpoints that can be hit concurrently.


## Summary

* Benchmark your database server with pgbench
* Create a variety of SQL statements to simulate the workload
* Experiment with number of clients and threads to put more or less load on server depending on what your goals are
* Use a database that is separate from production
* Use a benchmark to determine the effect of tunable parameters on Transactions per second (TPS)
* For web applications a HTTP benchmarking tool hitting API endpoints concurrently will produce a more realistic workload
