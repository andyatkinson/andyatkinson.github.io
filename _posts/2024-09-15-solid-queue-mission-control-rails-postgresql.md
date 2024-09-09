---
layout: post
permalink: /solid-queue-mission-control-rails-postgresql
title: 'Trying out Solid Queue and Mission Control with PostgreSQL'
tags: []
comments: true
---

## Why Solid Queue?
Background jobs are heavily used in Ruby on Rails to perform operations outside of a users request. A classic example is sending an email to a new user. The work of that action like generating the email content, sending it, can all be done in the background.

Over the last decade, Sidekiq became the dominant choice for a background processing framework in Ruby on Rails, although others are used as well, typically persisting their job data in Redis or the relational database.

Ruby on Rails in 4.2+ added a middleware layer Active Job that helped standardized background job processing “back ends”. This meant that Sidekiq or others could be backends. Starting from Rails 8, there will be a new official backend called Solid Queue. What went into its formation?

In PostgreSQL, a great library called GoodJob was created that was called out in the Rails World 2023 presentation as being a great background job framework. However, it only supports PostgreSQL. GoodJob is the system I wrote about and recommended in my book High Performance PostgreSQL for Rails. A Rails developer starting a new app today would be well served by GoodJob. However, given Solid Queue will become the official Active Job backend in Rails 8, it’s worth a look.

Let’s kick the tires!

## Adding Solid Queue to a Rails app
We’ll add Solid Queue to the Rideshare Rails app, currently on 7.1, by adding the solid_queue gem.

In order to see the background job data visually, we’ll add the [Mission Control gem](https://github.com/rails/mission_control-jobs). We’ll generate a background job, process it, and take a look at what we can see in Mission Control.

## Code to try
Let's give it a try.

```sh
cd rideshare
bundle add solid_queue
bundle add mission_control-jobs
```

```rb
# config/environments/development.rb
config.active_job.queue_adapter = :solid_queue
```

Generate the migrations:
```
bin/rails solid_queue:install
```

The migrations are in a file called `db/queue_schema.rb`.

Running `bin/rails db:migrate` should pick these up and add the tables to your main application database. If you want to run a separate database for Solid Queue, which is not a bad idea, you’ll need additional configuration beyond what's covered here.

Run:
```
bin/rails solid_queue:start
```

Let's generate a "Hello World" type of job just to get something going through:
```
bin/rails g job SolidQueueHelloWorldJob
```

Open rails console and process and scheduled a Hello World job:
```
bin/rails console
SolidQueueHelloWorldJob.set(wait: 1.week).perform_later
```

Navigate to `localhost:3000` and mission control, mounted at `localhost:3000/jobs`, the scheduled job tab, and view the scheduled job.

![Screenshot of Mission Control showing Solid Queue scheduled jobs](/assets/images/posts/2024/mission_control-jobs.png)
<small>Mission Control view of Solid Queue Scheduled Jobs</small>

Let’s look at what Solid Queue is using in Postgres.

## Solid Queue for Postgres
Solid Queue uses a clause when selecting jobs to update called `FOR UPDATE SKIP LOCKED`.

This clause is supported in Postgres. The first part `FOR UPDATE` is a locking statement that creates a row lock. The second part `SKIP LOCKED` means that rows that are already waiting to acquire a lock will be skipped when selected.

With an exclusive row-level lock for rows to be updated, no concurrent updates can run for these rows until this statement finishes and the lock is released.

By default in Postgres, the implicit transaction for this update uses the “Read committed” isolation level, which means that the only committed row updates at the time the transaction starts (at the time the statement runs) will be visible to this transaction.

Since lock acquisition is a queue of potential acquirers, by using `SKIP LOCKED`, we’re avoiding a scenario where the UPDATE transaction gets stuck waiting behind other operations, possibly forever if no `lock_timeout`[^1] is set.

The trade-off though is that skipped rows aren’t processed, so they’ll need to be process again using some kind of polling or retry mechanism.

Is using PostgreSQL for background jobs a good idea?

## Using PostgreSQL for database backed jobs
Using PostgreSQL for background jobs and your application database, means that you can leverage transactional consistency that’s not possible when spanning heterogeneous data stores.

However, there are also trade-offs to be aware of.

Updates and deletes create dead row versions, due to the MVCC design in PostgreSQL. For the Solid Queue tables with heavy updates, the Autovacuum resources available for those tables should be increased proportionally. This means Autovacuum will run more frequently and for longer periods of time so that it can perform its work.

For example, we can see updates and deletes for the table “solid_queue_processes” from the Rails log:

```
SolidQueue::Process Update (1.3ms)  UPDATE "solid_queue_processes" SET "last_heartbeat_at" = '2024-09-06 03:42:29.963811' WHERE "solid_queue_processes"."id" = 3 /*application:Rideshare*/

DELETE FROM "solid_queue_processes" WHERE "solid_queue_processes"."id" = 1 /*application:Rideshare*/
```


## Advanced Postgres concepts worth considering for Solid Queue

If performance is a concern and we want to trade-off data loss for job data in the event Postgres crashes, the Solid Queue Postgres tables could be made `UNLOGGED`.[^2] This disables the WAL logging for those tables. This means that if Postgres restarts, on startup those tables are truncated. This trade-off might be acceptable given the insert rate is much higher.

If we wanted job data to be non-transient, kept forever, we might want to make the primary job data capture table be a partitioned table. We could then segment it by time and maintain good operational speed as the row count grows until the hundreds of millions and beyond

Finally, while we’d lose transactional consistency with a single primary instance, we may want to leverage Active Record Multiple Databases and relocate our Solid Queue tables to their own database. This could be a “queue” database that Active Record reads and writes to as background jobs are processed, but when run on a separate server instance, would have separate resources like CPU, memory, and disk to scale independently. 

What are the benefits of background jobs in Postgres?

## Benefits of job data in Postgres over Redis

- We can use a tool we’re familiar with already: `bin/rails dbconsole` (which is psql) to connect and view the persisted data, as opposed to using the Redis CLI
- We can use SQL to query the job data tables
- We can leverage our schema knowledge if desired and change the schema for job data. Maybe there’s a constraint we want to add, or maybe we want to calculate some extra statistics about job data. Now we’re able to add additional tables that summarize data, and leverage SQL to do that.
- We can leverage our knowledge of backups, restores, and scaling database reads and writes we’ve learned from our application database experience, for our background jobs processing

## Drawbacks of background jobs in the database

- Fault isolation risk: By not segregating background job processing, it’s possible the load from background processing would harm the performance and reliability of the application database use cases.
- Data stores like Redis don’t have the MVCC design of Postgres, which means equivalent data may consume less space and resources

## Features of Solid Queue

In a future post, we’ll dig into these features more. Here are the features listed on the GitHub repo:

- Delayed jobs, see the example above where we’re delaying job processing by 1 week
- Concurrency controls: these are extra options like `max_concurrent_executions` that can be set on individual jobs
- Pausing queues: This can be useful for planned downtime events to temporarily stop processing
- Numeric priorities per job: Jobs will have different priorities in terms of their delivery time, with some needing near real-time, and others not
- Priorities by queue order: Solid Queue supports multiple prioritization schemes
- Bulk enqueuing: When working with bulk operations upstream, being able to bulk enqueue jobs saves processing time over enqueueing single items at at time


## What’s next
Rails World 2024 is happening in a couple of weeks, and will include Solid Queue presentations by Rosa Gutierrez, a lead maintainer.

[Rosa was interviewed in #23 of the Rails Changelog](https://www.railschangelog.com/23) and it’s worth a listen!


## More Solid Queue posts

- <https://www.honeybadger.io/blog/deploy-solid-queue-rails>
- <https://www.bigbinary.com/blog/solid-queue>

[^1]: <https://www.postgresql.org/docs/current/runtime-config-client.html#GUC-LOCK-TIMEOUT>
[^2]: <https://pgpedia.info/u/unlogged-table.html>
