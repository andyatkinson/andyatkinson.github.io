---
layout: post
permalink: /postgresql-scaling-aws-christmas-day-traffic-surge
title: Scaling RDS Postgres for Massive Holiday Traffic (#1 in App Store)
hidden: true
---

<div class="summary-box">
<strong>📌 Overview</strong>
<p>
On Christmas Day 2024, the Postgres instance powering the Aura Frames app API went down for three hours under surging client application load. A year later, the reworked approach not only survived, but thrived. </p>
<p>
Queries per second (QPS) peaked at 225,000 across the instances, with more than 100K QPS sustained over 10 hours for multiple days, and an average response time of 25 microseconds.
</p>
<p>Postgres handled <em>more</em> traffic, without issues, helping the app reach #1 in the U.S. and Canadian Apple and Android App Stores.</p>
<p>
In this post we’ll look behind the scenes at the months of planning and execution that resulted in this outcome.
</p>
<p>
A follow-up post will dig into the Ruby on Rails side, while this one will focus on Postgres. Let’s dive in!
</p>
</div>

## What’s Aura?
Aura Frames produces modern, stylish, wi-fi connected digital photo frames. The company has been around for more than 10 years and customers love adding the frames to their homes.

The frames are easy to gift as the're easy to use, don't require a subscription, and offer unlimited storage for photos and videos.

Aura keeps a relatively low profile in the tech community, but was previously featured on the [AWS blog post in October 2024](https://aws.amazon.com/blogs/storage/how-aura-improves-database-performance-using-amazon-s3-express-one-zone-for-caching/) for how it uses AWS S3 Express One Zone.

I also happen to be a fan of the products of the company and recommend them. I have paid for frames on my own as gifts for family, friends, and as donations for my kid’s school fundraiser.

## Disclosures
I began working with Aura in 2025. Aura does not have a public space for technical blog posts so we discussed me writing this post on my own site where I regularly write about Postgres and Ruby on Rails.

This post was written by me and I do not speak for the company. The company had the opportunity to review and edit the post before publication.

With those disclosures out of the way, let’s get into the technical details.


## Where does the surge in traffic come from?
On Christmas Day, tens of thousands of customers set up new frames. It's critical they have a good experience, which means the platform needs to be scalable and reliable.

The rate of new frames being set up with new photos being added is predictable given the gifting behavior, but does increase pressure on all systems as traffic increases by 3x or more from normal levels.


## Scaling over the years
The team has executed a variety of scaling tactics over the last half decade by employees and in conjunction with Postgres consultants. Scaling efforts often focused on reducing pressure on Postgres, due to the limits of a single primary instance, and preserving that operational simplicity as long as possible.

Scaling is more straightforward on the stateless, HTTP side. Aura uses AWS and has leveraged Auto Scaling Groups (ASGs), which can scale up to thousands of EC2 instances running the web application stack, image processing, PgBouncer, and other services.

For Postgres, vertical scaling was leveraged as long as possible.

Here's a look at the primary database instance serving application traffic from the prior year, Christmas 2024.
<table class="styled-table">
  <thead>
    <tr>
      <th>Instance class</th>
      <th>vCPU</th>
      <th>Memory (GiB)</th>
      <th>Storage type</th>
      <th>DLV</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>db.r6g.48xlarge</td>
      <td>192</td>
      <td>1536</td>
      <td>io2</td>
      <td></td>
    </tr>
  </tbody>
</table>

Without a larger instance class to move to, and having faced a 3 hour downtime during Christmas day 2024, the team was looking to heavily invest in reliability for Postgres ahead of Christmas 2025.

## Postgres Scaling Challenges and Solutions
The use of Postgres by Aura faces all kinds of common Postgres scaling challenges.

- Insert latency. To help reduce latency, foreign key constraints are not used. All possible indexes are removed. Indexes are periodically rebuilt.
- Replication. Due to needing to read after write and high replication lag years ago, read queries were not run on replicas. Replication of write ahead logs (WAL) remained a challenge.
- Buffer cache and high cache hit rates. It was critical to have as much memory as possible for buffer cache to achieve sub-millisecond query executions, in order to have enough throughput to reach more than 100K TPS.
- IOPS consumption exceeded quota. It was critical to avoid high storage device queueing and latency, in part by over provisioning PIOPS on io2 storage.
- The team faced unexplained CPU spikes that were reproducible in a load testing environment. The CPU use spikes caused temporary but widespread increased latency.
- Using Postgres via RDS means the team was limited on debugging tools. Linux host OS debugging tools like “perf” were not available. Even “enhanced metrics” and with tons of CloudWatch metrics, consuming events from the Postgres log like verbose vacuum logs, logging lock waits, as many [system catalog statistics](https://www.postgresql.org/docs/current/monitoring-stats.html) as possible like pg_stat_slru or pg_stat_io, sometimes was not enough to prove certain theories with hard evidence. 
- During the surge events, the Postgres database faced very high client connections into the 10s of thousands. Thank goodness for pgbouncer, and many instances of it! (More on that later)
- The application design involved per-user counts that were constantly changing. This could be social media style likes, comments, activity feeds, and more. The backend relies heavily on memcached for this with HAProxy helping manage memcached connections.
- Disruptive vacuum during busy periods. The team relies on throttling down vacuum and running manually scheduled vacuum jobs in the middle of the night, to avoid disruptive IO from contending with user IO.
- Index bloat. The database uses a primary key data type that isn’t 100% ideal for minimizing bloat, this index bloat (and table bloat) can creep up and make indexes large and scans not perform as well. For this reason indexes are periodically rebuilt.
- Configuration complexity. Postgres parameters (GUCs) are not heavily modified beyond what RDS provides.

## Christmas 2024 Retrospective
Unfortunately on Christmas Day 2024, the surging client application traffic outpaced what the Postgres instance could handle. A root cause analysis revealed that one of the main contributors to downtime was the growth of the write ahead log (WAL) exceeding the available space. This was due to the log not being consumed fast enough by the replica.

As a fix for that going forward, the team introduced a higher bandwidth solution: a [dedicated log volume (DLV)](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_PIOPS.dlv.html) which offered a higher SLA for WAL log replay.

That wasn't the totality of the problem though, and the team wanted more reliability.

The team was able to reproduce problematic high CPU usage under synthetic load testing. A variety of theories for the high CPU use was analyzed over the summer of 2025, but ultimately none had very strong evidence. RDS Postgres limits access to the underlying host OS making it impossible to directly use [Linux profiling tools like perf](https://perfwiki.github.io/main/).

To increase reliability, the team began creating proofs of concept for distributing Postgres traffic (sharding). Various Postgres sharding approaches were explored, but with the team heavily preferring mature solutions, a high degree of operator ownership and deep understanding, that limited the options.

Ruby on Rails’ [Horizontal Sharding](https://guides.rubyonrails.org/active_record_multiple_databases.html#horizontal-sharding) was partially built out and could have been a viable solution, but ultimately was not chosen.

With about half of the months gone of 2025, the expected further traffic increase for Christmas 2025 was approaching. A major constraint on the plan was what could be built on a small team within a few months. We wanted to leave time for load testing to validate changes.

## Postgres Christmas 2025
The solution that seemed to fit the best would be a custom solution, rewriting a lot of the application query layer, taking direct control of key queries and making changes needed to distribute the tables.

To prepare, the top 10 tables by write volume were analyzed and grouped up. All queries for those tables would need to be analyzed for incompatible elements that don't work across a database boundary, like joins and some subqueries.

Ultimately the 10 tables were distributed to 7 different primary instances, some with as few as 1 table. All reads and writes continued to flow from the same Ruby on Rails codebase, not new microservices. To achieve that we’d use [Active Record Multiple Databases](https://guides.rubyonrails.org/active_record_multiple_databases.html) support. That meant that each primary database would get the full accoutrement, including its own named config, the option of a read replica, the ability to manage schema definition DDL changes (Rails "Migrations"). The production configuration would be mirrored in all lower environments so that the extensive unit test suite would run across all with 7 databases. The only difference in developer environments was these 7 databases would exist within one Docker based Postgres instance, instead of being on their own server instances.

With the plan in place, it was time to start coding, and the clock was ticking! We got started in earnest around August 2025 with 3-4 months available to execute and validate the plan.

With each instance dedicated to one or a couple of tables, their was much more CPU, Memory, and IOPS available for their work. This allowed us to scale up the instances before Christmas, over-provisioning them to add extra headroom for increased reliability. We determined the query workload for the biggest table by size, row count, call frequency, and % of IO, would still fit ok on a single big instance.

Here's how it looked through Christmas 2025.

<table class="styled-table">
  <thead>
    <tr>
      <th>Instance class</th>
      <th>vCPU</th>
      <th>Memory (GiB)</th>
      <th>Storage type</th>
      <th>DLV</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>db.r6g.48xlarge</td>
      <td>192</td>
      <td>1536</td>
      <td>io2</td>
      <td>✔️</td>
    </tr>
    <tr>
      <td>db.r6g.48xlarge</td>
      <td>192</td>
      <td>1536</td>
      <td>io2</td>
      <td>✔️</td>
    </tr>
    <tr>
      <td>db.r6g.48xlarge</td>
      <td>192</td>
      <td>1536</td>
      <td>io2</td>
      <td>✔️</td>
    </tr>
    <tr>
      <td>db.r6g.16xlarge</td>
      <td>64</td>
      <td>512</td>
      <td>gp3</td>
      <td></td>
    </tr>
    <tr>
      <td>db.r6g.16xlarge</td>
      <td>64</td>
      <td>512</td>
      <td>gp3</td>
      <td></td>
    </tr>
    <tr>
      <td>db.r6g.16xlarge</td>
      <td>64</td>
      <td>512</td>
      <td>gp3</td>
      <td></td>
    </tr>
    <tr>
      <td>db.r6g.16xlarge</td>
      <td>64</td>
      <td>512</td>
      <td>gp3</td>
      <td></td>
    </tr>
    <tr>
      <td>db.r6g.16xlarge</td>
      <td>64</td>
      <td>512</td>
      <td>gp3</td>
      <td></td>
    </tr>
  </tbody>
  <tfoot>
    <tr class="summary-row">
      <td><strong>Totals</strong></td>
      <td><strong>832 vCPU</strong></td>
      <td><strong>6656 GiB</strong></td>
      <td></td>
      <td></td>
    </tr>
  </tfoot>
</table>

This capacity powered Christmas well, but of course was expensive to operate. We'll look at how we reigned in costs after Christmas coming up.

## Workload driven “whole table sharding”
We ended up using the term “whole table sharding” and the tables picked tended to have the most writes, the most rows, and be the most challenging to vacuum quickly or rebuild indexes for.

We were able to gradually modify all the application queries and get everything rolled out in such a way it was compatible with the old and new approach.

To actually transition the row data we tried using [AWS pglogical](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Appendix.PostgreSQL.CommonDBATasks.pglogical.html) and logical replication directly, but did not successfully replicate data in a reasonable amount of time.

We may revisit that in the future, however we ultimately decided on physical replication to copy the whole instance, cutting over to the new location. We knew we could operate that approach reliably and with a minimal amount of downtime. The major downside of this approach was that we had to repeat it 6 times, duplicating the entire database each time, consuming a ton of extra space temporarily.

We decided it would be ok to temporarily allow for the excess space consumption on the new instances, then scale the provisioned space back down after Christmas by using the [AWS Blue/Green deployments](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/blue-green-deployments.html). B/G Deployments made the process pretty smooth. We’ll cover that more in a bit.

## Postgres and Infra Key Metrics Christmas 2025

All Postgres instances upgraded to 17.x in the Fall of 2025. TPS and QPS measured by [Odarix](https://odarix.com/). PgBouncer and Memcached are other key pieces of infrastructure.
<table class="styled-table">
  <thead>
    <tr>
      <th>Metric</th>
      <th>Low</th>
      <th>Christmas Peak</th>
      <th>Total</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>Main DB TPS</td>
      <td>40K</td>
      <td></td>
      <td></td>
    </tr>
    <tr>
      <td>Main DB TPS</td>
      <td></td>
      <td>133K (<strong>3.3x increase</strong>)</td>
      <td></td>
    </tr>
    <tr>
      <td>Sum DB TPS</td>
      <td></td>
      <td>225K</td>
      <td></td>
    </tr>
    <tr>
      <td>Average query latency</td>
      <td></td>
      <td>25 microseconds</td>
      <td></td>
    </tr>
    <tr>
      <td>Largest table</td>
      <td></td>
      <td></td>
      <td>7 TB</td>
    </tr>
    <tr>
      <td>Total space</td>
      <td></td>
      <td></td>
      <td>30 TB</td>
    </tr>
    <tr>
      <td>Largest row count</td>
      <td></td>
      <td></td>
      <td>7B</td>
    </tr>
    <tr>
      <td>PgBouncer Clients</td>
      <td></td>
      <td>~40K</td>
      <td></td>
    </tr>
    <tr>
      <td>Biggest Dead Tuple Growth</td>
      <td></td>
      <td>80M</td>
      <td></td>
    </tr>
    <tr>
      <td>Memcached Instances</td>
      <td></td>
      <td>36</td>
      <td></td>
    </tr>
    <tr>
      <td>Memcached Clients</td>
      <td></td>
      <td>~30K</td>
      <td></td>
    </tr>
  </tbody>
</table>

The weekend before Christmas is a higher traffic as new gifts are being opened and set up. The surge period gets started on Christmas eve, another common time a lot of folks celebrate Christmas

Christmas day (December 25) is when traffic really gets cooking. The main surge period was over 10 hours where the main DB sustained more than 100K TPS from 10:00:00 to 20:00:00 US Central Time.

Excitement grew seeing the app rise into the top 10 and reach #1. I grabbed a screenshot myself at around 11:30 PM CT December 25.

![Aura Frames #1 App U.S. App Store Christmas Day](/assets/images/aura-christmas-2025.jpg)
<br/>
<small>Screenshot showing the Aura Frames app at the #1 rank in the U.S. Apple App Store</small>

## Aura Customer Metrics
Customers adding photos and videos to their frames are very busy on Christmas Day. Peak upload rate was nearly 6 million photos and videos per hour.

The end of the year has a flurry of activity. From December 22 to the end of year period, customers added 100 million photos to the platform. Over all of 2025, customers added over 1 billion photos!


## Reflecting back on the plan
Some of the contributors to success:
1. Having an extensive test suite to catch regressions as code was refactored
1. Although making all changes at once prior to release, releasing small chunks at a time as PRs for easier review and post-release monitoring
1. Using canary releases to validate higher risk changes on a single production instance
1. Having an extensive pre-production load testing mechanism to validate wide changes
1. Gradually roll outs in staging
1. Having a big AWS infrastructure budget 😅 to work with, thanks to a profitable company, so we could over provision and over-allocate (temporarily)
1. Having a very comprehensive set of CloudWatch metrics, dashboards, analyzable web and Postgres log files ([AWS Athena](https://aws.amazon.com/athena/)), time-series metrics galore (StatHat RIP), and best-in-class Postgres observability ([PgAnalyze](https://pganalyze.com))
1. Having experienced colleagues helping guide and review changes (invaluable!)

## Thank You and Looking Forward
The biggest reward was seeing a stable Postgres platform during the holiday surge. All the preparation paid off. We were glued to the CloudWatch dashboards and had practiced some load shedding maneuvers, but fortunately there were no significant customer interruptions.

It was rewarding to work with great engineers and also benefit from the accumulated code patterns and database scaling practices that past platform engineers had put in place.

For 2026 we’re forming our plans to further improve reliability, scalability, and cost efficiency.

If these types of posts are interesting to you, please consider subscribing to my blog or buying my book (links below).

If you are an engineer interested in working on these types of challenges, please get in touch.

Thanks for reading!
