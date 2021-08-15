---
layout: post
title: "PostgreSQL pgbench Workload Simulation"
tags: [PostgreSQL, Databases]
date: 2021-08-10
comments: true
featured_image_thumbnail:
featured_image: /assets/images/pages/andy-atkinson-California-SF-Yosemite-June-2012.jpg
featured_image_caption: Yosemite National Park. &copy; 2012 <a href="/">Andy Atkinson</a>
featured: true
---

We operate a high scale API application that relies on a single primary PostgreSQL instance as many applications do. We have scaled up the DB instance vertically, acquiring more CPU, Memory, and disk IO over time.

For the workload on the primary, the workload is more write oriented by design (`INSERT` and `UPDATE` statements) as we use a read replica (standby) that is intended for any read only queries to execute against to take load off the primary.

We configure this write and read separation manually in Rails which has supported multiple databases natively since Rails 6. Rails lets us configure different roles for writing and reading and we can switch between them from one line of code to another if needed.

### Using pgbench

pgbench allows us to set up a benchmark suite that can be run against a database server. The benchmark input is SQL statements. These statements can be customized to add some diversity into the SELECT statements so that rows are not always selected that exist in the same page. We do this by supplying a random value to the lookup column.

[pgbench](https://www.postgresql.org/docs/10/pgbench.html) is built in to PostgreSQL. I run pgbench local on OS X and then make a connection to a remote PG database, which then executes the benchmark.

### Workload Simulation

We have just recently started to attempt to simulate our workload. I did this by grabbing some of the Top SQL (from RDS Performance Insights), selecting a mix of INSERT, UPDATE and SELECT statements. These queries are parameterized, meaning placeholder values like question mark need to be replaced with real values.

In order to create the values we can use a `random` function and give it an upper bound that roughly matches the table row count.


#### Shell script

To run a pgbench benchmark, create a shell script like `my_benchmark.sh`.

Using bash we can create a script that creates 10 SELECT statements each with a random value for blog_id, that we want to query on.

```
for run in {1..10}; do
  echo '\set blog_id random(1, 1000000)' >> queries.bench
  echo "select * from comments where blog_id = :blog_id;" >> queries.bench
done
```

We can create a mix of UPDATE statements as well, and potentially INSERT statements if it's ok to create benchmark data (or clean it up later) in the target database.

Here is an example UPDATE statement:

```
echo "UPDATE comments SET view_count = 0 WHERE blogs.id = :blog_id" >> queries.bench
```


The last line of the shell script will actually call `pgbench` and it will read in the `queries.bench` file that was written to earlier.

Here are some configuration options:


```
# -T time seconds
# -j threads
# -c clients
# -M querymode prepared
# -r report latencies
pgbench -h my-super-cool-rds-database.us-east-1.rds.amazonaws.com -d db-name -U db-user -M prepared -T 60 -j 32 -c 32 -f queries.bench -r
```

Once we put that all into `my_benchmark.sh` and `chmod +X my_benchmark.sh` now we can run it like `./my_benchmark`. The generated queries with random values should exist in a file called `queries.bench` in the same directory.

In the example above, we run it for 60 using 32 clients where each client has 32 threads of execution. This may put considerable load on your DB, which may be the goal.

This technique may be useful to use to help tune memory parameters like `shared_buffers` to understand how changing the parameter affects the maximum number of transactions per second that can be processed.


## Summary

* Simulate your workload with pgbench
* Create a diverse set of SQL statements that are similar to your workload
* Experiment with number of clients and threads to put more or less load on server depending on what your goals are
* Use a database that is separate from your production workload
* Use a benchmark to determine the effect of tunable parameters on TPS
