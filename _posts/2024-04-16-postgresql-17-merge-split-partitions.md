---
layout: post
title: "Use Cases for Merging and Splitting Partitions With Minimal Locking in PostgreSQL 17"
tags: [PostgreSQL, Open Source]
date: 2024-04-16
comments: true
---

This post looks at some interesting new capabilities managing [Partitioned Tables](https://www.postgresql.org/docs/current/ddl-partitioning.html) coming in PostgreSQL 17, expected for release Fall 2024. The current major version is 16.

## Current Table Partition Commands

Prior to Version 17, workflow options for partition management are limited to creating, attaching, and detaching partitions.

Once we’ve designed our partition structure, we couldn't redesign it in place.

This applies to all partition types, whether we're using `RANGE`, `LIST`, or `HASH`.

To combine multiple partitions into a single one, or to "subdivide" a single partition into multiples, we'd need to design a new structure then migrate all data rows to it. That's a lot of steps!

## What's New?

From version 17, we have more options. We can now perform a `SPLIT PARTITION` operation on an existing singular partition, into two or more new ones.

If we wish to do the reverse, we've got that option as well. Starting from two or more partitions, we can perform a `MERGE PARTITIONS` (plural) operation to combine them into one.

An aside: don't confuse this with the upsert-like [SQL `MERGE`](https://www.postgresql.org/docs/current/sql-merge.html) command which uses the same "merge" verb (oof)!

The new DDL commands are:

- [`MERGE PARTITIONS`](https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=1adf16b8fba45f77056d91573cd7138ed9da4ebf)
- [`SPLIT PARTITION`](https://git.postgresql.org/gitweb/?p=postgresql.git;a=commit;h=87c21bb9412c8ba2727dec5ebcd74d44c2232d11)

Here are tweets from [Nori Shinoda](https://twitter.com/nori_shinoda) that link to PostgreSQL git commits:

- Ability to merge two existing partitions: <https://twitter.com/nori_shinoda/status/1776841440167121057>
- Ability to split a partition into two or more: <https://twitter.com/nori_shinoda/status/1776865005704499331>

Let's test the new commands out and think about use cases for them.

We'll need a way to run pre-release PostgreSQL 17. Fortunately, I've recently [compiled PostgreSQL from source code on my macOS laptop](/blog/2024/04/09/compiling-postgresql-macos-docs-patches), and will use that instance and some test tables within the default `postgres` DB.

I use Postgres.app to run PostgreSQL 16 for most of my local development, and instances on different ports. I stop the instance on port 5432 so I can start up the one based on the compiled source code like this:

```sh
/usr/local/pgsql/bin/pg_ctl \
    -D /usr/local/pgsql/data \
    -l logfile \
    start

waiting for server to start.... done
server started
```

## Terminology Notes

Previously I wrote about table partitioning in a two-part post. Here's the first post: [PostgreSQL Table Partitioning — Growing the Practice — Part 1 of 2](/blog/2023/07/27/partitioning-growing-practice) if you'd like a refresher on general information.

I’ll use "children" below referring to "partitions" of a partitioned table. The top-most table has the partition constraints, and tables that correspond to those constraints are added as "children".

The term "children" can also show up when discussing foreign keys, when foreign key columns refer to the primary key of another table. The table with a foreign key can be said to be a child table.

For this post, "children" refers solely to partitions "of" (the `PARTITION OF` syntax below) a parent table.

## What do these look like?

Imagine we had a multi-tenant application where tenants are identified as "accounts." Tables with mixed account data have an `account_id` column with a value that identifies their account, meaning we can partition on it using `LIST` partitioning.

We’d normally have one account per customer. However, in my real-world working experience at startup companies, this isn’t always the case.

At a past employer with a B2B SaaS, an account was created to demo to a customer prospect.

When the customer joined the platform many months later, a new account was created for them, creating a situation where they had primary data under two accounts. There were also primary key conflicts, so we couldn't easily combine the data without some manual efforts, but that's a different story.

If this table had been created as a partitioned table with `LIST` partitioning, we could identify all rows by their `account_id`, and each would have its own partition.

On PostgreSQL 17 in that scenario, we could leverage `MERGE PARTITIONS` to combine those partitions that we would to group under one account, choosing one or the other.

What would that look like?

## Merging Partitions

The table below has an `account_id` and no real data columns, since we're just looking to demo the partition management aspect.

The `id` uses a generated sequence value, which means each row will have a unique value across partitions.

```sql
CREATE TABLE t (
  id INT GENERATED ALWAYS AS IDENTITY,
  account_id INT NOT NULL
) PARTITION BY LIST (account_id);
```

Imagine we have the following two partitions for `account_id` 1 and `account_id` 2.

```sql
CREATE TABLE t_account_1 PARTITION OF t FOR VALUES IN (1);
CREATE TABLE t_account_2 PARTITION OF t FOR VALUES IN (2);
```

Let’s insert 10 records for `account_id` 1, and 100 records for `account_id` 2. We have 110 records total, but they’re split across two partitions. We want to merge these together.

```sql
INSERT INTO t (account_id) SELECT 1 FROM GENERATE_SERIES(1,10);
INSERT INTO t (account_id) SELECT 2 FROM GENERATE_SERIES(1,100);
```

Now we want to merge them together using `MERGE PARTITIONS`:

```sql
ALTER TABLE t
MERGE PARTITIONS (t_account_1, t_account_2)
INTO t_account_1_2;
```

Cool. That combined `t_account_1` and `t_account_1` into a single partition called `t_account_1_2` with 110 records.

What about splitting partitions? How does that work?

## Splitting Partitions

We’ve seen how to merge partitions. We can also split partitions using the new `SPLIT PARTITIONS` command.

For this example let's use the `RANGE` partitioning type.

Imagine that we had decided to create partitions for one week's worth of data for an "events" style table that receives a lot of records. We'll call the table `t_events` below.

We've decided with a one week boundary, the tables are large and unwieldy. We'd like to move to daily partitions so that the table for a day's worth of data is smaller and more manageable.

Let's look at the SQL commands for how we might achieve that.

## Split Partitions Events Table

Create the `t_events` table using the `RANGE` partitioning type, initially with weekly partitions to demonstrate the current configuration.

```sql
CREATE TABLE t_events (
  id INT GENERATED ALWAYS AS IDENTITY,
  event_at TIMESTAMP WITHOUT TIME ZONE NOT NULL
) PARTITION BY RANGE (event_at);
```

Here are partitions for "last week," "this week," and "next week."

```sql
CREATE TABLE t_events_last_week PARTITION OF t_events
FOR VALUES FROM ('2024-04-08 00:00:00') TO ('2024-04-15 00:00:00');

CREATE TABLE t_events_this_week PARTITION OF t_events
FOR VALUES FROM ('2024-04-15 00:00:00') TO ('2024-04-22 00:00:00');

CREATE TABLE t_events_next_week PARTITION OF t_events
FOR VALUES FROM ('2024-04-22 00:00:00') TO ('2024-04-29 00:00:00');
```

Now we'd like to take "next week's partition" called `t_events_next_week`, and divide it into 7 daily partitions, one for each day.

Since it's an upcoming week, we'll assume it has no data in it, but is a pre-created partition.

When designing your own change like this, keep in mind the resulting boundaries you come up with *must* have equivalent start and end boundaries to the current configuration.

If the boundaries are off, you'll get an error like this:

```
ERROR:  partition bound for relation "t_events_next_week" is null
```

Here's the `SPLIT PARTITION` DDL command to split the single week command, into 7 daily partitions:

```sql
ALTER TABLE t_events SPLIT PARTITION t_events_next_week INTO (
  PARTITION t_events_day_1 FOR VALUES FROM ('2024-04-22 00:00:00') TO ('2024-04-23 00:00:00'),
  PARTITION t_events_day_2 FOR VALUES FROM ('2024-04-23 00:00:00') TO ('2024-04-24 00:00:00'),
  PARTITION t_events_day_3 FOR VALUES FROM ('2024-04-24 00:00:00') TO ('2024-04-25 00:00:00'),
  PARTITION t_events_day_4 FOR VALUES FROM ('2024-04-25 00:00:00') TO ('2024-04-26 00:00:00'),
  PARTITION t_events_day_5 FOR VALUES FROM ('2024-04-26 00:00:00') TO ('2024-04-27 00:00:00'),
  PARTITION t_events_day_6 FOR VALUES FROM ('2024-04-27 00:00:00') TO ('2024-04-28 00:00:00'),
  PARTITION t_events_day_7 FOR VALUES FROM ('2024-04-28 00:00:00') TO ('2024-04-29 00:00:00')
);
```

Nice. If we run `\d+ t_events` to describe `t_events`, we'll see the two remaining weekly partitions, and the new 7 daily partitions.

There's a catch. Performing this operation requires a lock on the parent table, which could be a long lock.

Is there a workaround?

## Detach, Split, Reattach

As long as the structure of the table stays the same, partitions can be detached and reattached.

Those operations can both be performed in a non-blocking way by using `CONCURRENTLY`.

Unfortunately we can't perform a `SPLIT PARTITION CONCURRENTLY`, which would make this even more convenient because we wouldn't be worried about blocking writes while the exclusive lock was in effect. Perhaps we'll get that in a future version of PostgreSQL.

Let's consider a workaround. We know that we can detach partitions, split them while detached, then re-attach them. Would that work?

This is a lot of operations, and requires a "new fake parent" (my own name below) to work, so these steps should be considered more a proof of concept, not a recommendation. The goal is to avoid a potentially long lock blocking writes, by allowing the lock to occur on a detached table hierarchy. Essentially "offline."

This was my idea when I first saw these new capabilities and the required access exclusive lock they acquire:

<blockquote class="twitter-tweet"><p lang="en" dir="ltr">MERGE PARTITIONS is cool! But exclusive lock on parent is limiting. Workaround idea: concurrent detachment of two, then merge, then “reattach concurrently” on consolidated partition? cc <a href="https://twitter.com/andrewkane?ref_src=twsrc%5Etfw">@andrewkane</a> <a href="https://twitter.com/keithf4?ref_src=twsrc%5Etfw">@keithf4</a> <a href="https://twitter.com/brandur?ref_src=twsrc%5Etfw">@brandur</a> <a href="https://twitter.com/nori_shinoda?ref_src=twsrc%5Etfw">@nori_shinoda</a> <a href="https://t.co/fF9nJEL9ip">https://t.co/fF9nJEL9ip</a></p>&mdash; Andrew Atkinson (@andatki) <a href="https://twitter.com/andatki/status/1776856813230600428?ref_src=twsrc%5Etfw">April 7, 2024</a></blockquote> <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>

Trying to run `SPLIT PARTITION` on a detached partition with no parent doesn't work. However, we can add a "new fake parent" table to stand-in temporarily.

Here's the detach operation:

```sql
ALTER TABLE t_events
DETACH PARTITION t_events_next_week CONCURRENTLY;
```

Here's the "fake" stand-in parent table definition. Once we've created this, we need to attach our detached partitions to it in order to perform the split.

We'll only use the "fake parent" table for the split operation. When that's done, we'll detach the partitions again, and then re-attach them to the original parent `CONCURRENTLY`. At that point we can drop the "fake" parent.

```sql
CREATE TABLE t_events_fake_new (
  id INT GENERATED ALWAYS AS IDENTITY,
  event_at TIMESTAMP WITHOUT TIME ZONE NOT NULL
) PARTITION BY RANGE (event_at);
```

Running the `SPLIT PARTITION` on a separate parent avoids a long lock on the original parent, since it's a completely separate table.

```sql
ALTER TABLE t_events_fake_new SPLIT PARTITION t_events_next_week INTO (
  PARTITION t_events_day_1 FOR VALUES FROM ('2024-04-22 00:00:00') TO ('2024-04-23 00:00:00'),
  PARTITION t_events_day_2 FOR VALUES FROM ('2024-04-23 00:00:00') TO ('2024-04-24 00:00:00'),
  PARTITION t_events_day_3 FOR VALUES FROM ('2024-04-24 00:00:00') TO ('2024-04-25 00:00:00'),
  PARTITION t_events_day_4 FOR VALUES FROM ('2024-04-25 00:00:00') TO ('2024-04-26 00:00:00'),
  PARTITION t_events_day_5 FOR VALUES FROM ('2024-04-26 00:00:00') TO ('2024-04-27 00:00:00'),
  PARTITION t_events_day_6 FOR VALUES FROM ('2024-04-27 00:00:00') TO ('2024-04-28 00:00:00'),
  PARTITION t_events_day_7 FOR VALUES FROM ('2024-04-28 00:00:00') TO ('2024-04-29 00:00:00')
);
```

Since the table structures have not changed, and since we're not introducing any overlapping partition constraints, we can reattach to the original parent.

## Alternatives

What about simply creating new partitions to move data rows into?

While it might be less work to create new partitions and move data rows, we couldn't introduce new partitions that overlap with the boundaries/constraints of any existing one. PostgreSQL enforces this and would prevent the partition creation.

To avoid the overlap limitation, `SPLIT PARTITION` seems necessary when our goal is to modify a structure in-place like this.

However, in a similar way to the workaround above, we could follow the same tactic and detach the overlapping partition to work around the conflict.

With that approach, we might achieve the same end result and not need the `SPLIT PARTITION` command.

What are your thoughts?

## Resources and Thank You

Here are some people to thank, and more resources on these new commands to check out.

- Nori Shinoda for posting the latest and greatest from PostgreSQL source code
- [PostgreSQL 17: Split and Merge partitions](https://www.dbi-services.com/blog/postgresql-17-split-and-merge-partitions/) by Daniel Westermann
- Creston Jamison for covering the split and merge partition commands in [Scaling Postgres #311](https://www.scalingpostgres.com/episodes/311-max-group-by-performance/)

I'm curious to see how merging and splitting partitions commands get used in the wild.

In the future, if we can perform these operations `CONCURRENTLY`, they will be even more useful. The introduction of these features may be a step towards modifying an unpartitioned table in place.

Having something like `SPLIT TABLE CONCURRENTLY` would be very nice for tables that weren't originally partitioned, became huge, and to lessen the work needed to migrate their data into more manageable partitions.
