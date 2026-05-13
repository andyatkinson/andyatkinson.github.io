---
layout: post
permalink: /postgresql-rds-scaling-aws-christmas-day-peak
title: Scaling RDS Postgres for Peak Christmas Traffic (#1 in App Store)
hidden: true
---

<div class="summary-box">
<strong>📌 Overview</strong>
<p>
On Christmas Day 2024, Postgres infrastructure powering the Aura Frames API had problems under peak load, being unavailable for three hours and disrupting the experience for new customers. With Christmas being the biggest day of the year, the team knew it would need improvements for 2025 and beyond.</p>
<p>
One year later, much of the resource intensive data access was reworked, the Postgres infrastructure was upsized, and this approach not only survived, but thrived, providing reliable service through the holiday season. </p>
<p>
Total Queries per second (QPS) peaked at 225,000 (226K TPS), with 100K QPS sustained over 10 hours for multiple days, and an average response time of 25 microseconds.
</p>
<p>The improved reliability meant customers could smoothly set up new frames and add photos, and they did it more than ever, with the Aura Frames app reaching #1 in U.S. and Canadian Apple and Android App Stores on Christmas Day.</p>
<p>
In this post we’ll look behind the scenes at months of engineering planning and execution that went into achieving that!
</p>
<p>
A follow-up post will dig into the Ruby on Rails side, while this one will focus on Postgres. I hope you'll be back for part 2!
</p>
</div>

## What's Aura Frames?
[Aura Frames](https://auraframes.com) (Aura Home, Inc.) is the company behind modern, high-quality, Wi-Fi connected digital photo frames that customers love.

The frames are easy to use via free iOS and Android apps, don't require a subscription, and offer unlimited cloud storage for photos and videos. Once set up, family members can be invited to contribute photos and videos via the app from anywhere. Typically Aura frames have an average of 4 contributors adding content.

In 2025, more than 1 billion photos were shared to Aura frames globally.

While public engineering blog posts are limited, Aura was featured on the AWS Storage Blog in the past. Link: [How Aura improves database performance using Amazon S3 Express One Zone for caching](https://aws.amazon.com/blogs/storage/how-aura-improves-database-performance-using-amazon-s3-express-one-zone-for-caching/).

## Disclosures
I began working with Aura in 2025. Aura does not have a public engineering blog, so we discussed writing a post here, where I regularly write about Postgres, Ruby on Rails, and scaling databases.

This post was written by me and I do not speak for the company. The company had the opportunity to review and make minor edits before publication.

The Christmas Day outage was a painful reality of scaling fast, and I appreciate Aura's willingness to discuss it here.

I'm biased, but from my view the company is dedicated to continually improving the customer experience, in part with strategic investments in technical infrastructure to achieve higher levels of reliability.

With that covered, let's take a look at how the frames are used and what drives the traffic.

## What causes the sharp increase in traffic?
On Christmas Day, tens of thousands of customers set up new frames. It's critical they have a good experience from their first moments with the product, which means the backend platform needs to be reliable.

While the holiday timing is predictable, the rate of new frames and new photos added each year increases, and adds significant pressure to all infrastructure components. Postgres is not easily horizontally scalable, and is costly to operate.

The average amount of increased peak TPS on Christmas Day was around ~4.5x, with the biggest increase on a DB being ~18x the normal value! To meet this demand, advanced capacity and financial planning was necessary, along with provisioning the resources ahead of time and shrinking them back down afterwards.

## Scaling over the years
The team has executed a variety of scaling tactics over the last half decade by employees and in conjunction with Postgres consultants. Scaling efforts often focused on reducing pressure on Postgres, due to the limits of a single primary instance, while preserving the operational simplicity of a single primary instance as long as possible. ([Squeeze the hell out of the system you have](https://blog.danslimmon.com/2023/08/11/squeeze-the-hell-out-of-the-system-you-have/)).

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
      <td>⚠️</td>
    </tr>
  </tbody>
</table>

Without a larger instance class to move to, the team was looking to heavily invest in reliability for Postgres ahead of Christmas 2025.

⚠️ Although a Dedicated Log Volume (DLV) was in place for 2024, the configuration was not optimal.

## Postgres Scaling Challenges and Solutions
The use of Postgres by Aura faces all kinds of common Postgres scaling challenges.

- Insert latency. To help reduce latency, foreign key constraints are not used. All possible indexes are removed. Indexes are periodically rebuilt.
- Replication. Due to needing to read immediately after write operations and the possibility of high replication lag, read replicas have historically not been used for read queries.
- Buffer cache and high cache hit rates. It was critical to have as much memory as possible for buffer cache to achieve sub-millisecond query executions, in order to have enough throughput to reach more than 100K TPS.
- IOPS consumption exceeded quota. It was critical to avoid exceeding the provisioned IOPS (PIOPS) allocation, otherwise queuing and high latency resulted.
- The team faced unexplained CPU spikes that were reproducible in a load testing environment. The CPU use spikes caused temporary but widespread increased latency.
- During the high load period, the Postgres database faced very high client connections into the tens of thousands.
- The application design involved per-user counts that were constantly changing. This could be social media style likes, comments, activity feeds, and more. The backend relies heavily on memcached for this with HAProxy helping manage connections.
- Disruptive table vacuums during busy periods. The team relies on various tactics to minimize disruption from vacuum. Primarily vacuum is throttled to run slower, and tables with very high dead tuple growth are scheduled to run overnight during the lowest activity period.
- Index bloat. The database uses a primary key data type that isn’t 100% ideal for minimizing bloat. Index bloat occurs meaning indexes occupy more space and aren't as efficient to scan. To solve that, indexes are periodically rebuilt, but rebuilding adds a lot of IOPS pressure so the timing needs coordination.
- Configuration complexity. Postgres parameters (GUCs) are not heavily modified beyond what RDS provides.

## Christmas 2024 Retrospective
Unfortunately on Christmas Day 2024, the client application demand outpaced what Postgres could handle. A root cause analysis revealed that one of the main contributors to downtime was the growth of the write ahead log (WAL) exceeding the available space. This was due to the log not being consumed fast enough by the replica.

As a fix for that going forward, the team purchased and began using a higher bandwidth solution, the [Dedicated Log Volume (DLV)](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_PIOPS.dlv.html) offering with higher SLA for WAL log replay.

That wasn't the totality of the problem though, and the team wanted more reliability.

The team was able to reproduce problematic high CPU usage under synthetic load testing. A variety of theories for the high CPU use were analyzed over the summer of 2025, but ultimately none had very strong evidence. RDS Postgres limits access to the underlying host OS making it impossible to directly use [Linux profiling tools like perf](https://perfwiki.github.io/main/).

To increase reliability, the team began creating proofs of concept for distributing Postgres traffic (sharding). Various Postgres sharding approaches were explored, but with the team heavily preferring mature solutions, a high degree of operator ownership and operator understanding, the team preferred something custom to something off the shelf.

Ruby on Rails [Horizontal Sharding](https://guides.rubyonrails.org/active_record_multiple_databases.html#horizontal-sharding) was partially built out and could have been a viable solution, but ultimately was not chosen.

With about half of 2025 gone, preparedness for the Christmas 2025 holiday peak was looming and daunting. An additional significant constraint on planning was, what could be built on the small team, in time before Christmas? We wanted to leave time for load testing to validate changes.

The clock was ticking!

## Postgres Christmas 2025
The solution that seemed to fit the best would be a custom solution, rewriting a lot of the application query layer, taking direct control of key queries and making changes needed to distribute the tables.

To prepare, the top 10 tables by write volume were analyzed and grouped up. All queries for those tables would need to be analyzed for incompatible elements that don't work across a database boundary, like joins and some subqueries.

Ultimately the 10 tables were distributed to 7 different primary instances, some with as few as 1 table. All reads and writes continued to flow from the same Ruby on Rails codebase, not new microservices. To achieve that we’d use [Active Record Multiple Databases](https://guides.rubyonrails.org/active_record_multiple_databases.html) support. That meant that each primary database would get the full <em>accoutrement</em>, including its own named config, the option of a read replica, the ability to manage schema definition DDL changes (Rails "Migrations"). The production configuration would be mirrored in all lower environments so that the extensive unit test suite would run across all 7 databases. The only difference in developer environments was the 7 databases ran on one Docker Postgres instead of being on their own server instances.

With the plan in place, it was time to start coding! We got started in earnest around August 2025 with 3-4 months available to execute and validate the plan.

With each instance dedicated to one or a couple of tables, there was much more CPU, Memory, and IOPS available in total. This allowed each of the instances to be over provisioned temporarily before Christmas, adding headroom, availability, and reliability.

We determined the query workload for the biggest table by size, row count, call frequency, and % of IO, would still fit ok on a single big instance, without needing to shard the table rows.

Here's what the instances were scaled up to for Christmas 2025.
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
      <td>✅</td>
    </tr>
    <tr>
      <td>db.r6g.48xlarge</td>
      <td>192</td>
      <td>1536</td>
      <td>io2</td>
      <td>✅</td>
    </tr>
    <tr>
      <td>db.r6g.48xlarge</td>
      <td>192</td>
      <td>1536</td>
      <td>io2</td>
      <td>✅</td>
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
      <td>832 vCPU (<strong>~4.3x ↗</strong>)</td>
      <td>6656 GiB (<strong>~4.3x ↗</strong>)</td>
      <td></td>
      <td></td>
    </tr>
  </tfoot>
</table>

This capacity powered Christmas well, but of course was expensive to operate. We'll look at how we scaled down and reigned in costs after Christmas.

## Workload-driven "Whole table sharding"
We ended up using the term “whole table sharding” and the tables picked tended to have the most writes, the most rows, and be the most challenging to vacuum quickly or rebuild indexes for.

We were able to gradually modify all the application queries and get everything rolled out where it was backwards compatible, then we could cut over.

To transition the row data, wanting to initially replicate it, we tried using [AWS pglogical](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Appendix.PostgreSQL.CommonDBATasks.pglogical.html) and logical replication directly but were not able to successfully replicate the data in a reasonable amount of time.

We may revisit that in the future, however we ultimately decided on <em>physical</em> replication which copied the whole instance, before cutting over to the new one. While more wasteful initially, we knew we could operate that approach reliably and with a minimal amount of downtime.

The major downside of this approach was that we had to repeat it 6 times, duplicating the entire database each time, consuming a ton of extra space temporarily.

We decided it would be ok to temporarily allow for the excess space consumption on the new instances, then scale the provisioned space back down after Christmas by using the [AWS Blue/Green deployments](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/blue-green-deployments.html). B/G Deployments made the process pretty smooth. Once we'd cleaned up all the unneeded tables, we provisioned the new (green) instance with less space, and cut over to it, discarding the old (blue) instance.

## Postgres and Infra Metrics Christmas 2025
All Postgres instances upgraded to 17.6 in the Fall of 2025. TPS and QPS measured by [Odarix](https://odarix.com/). PgBouncer, Memcached, HAProxy metrics from CloudWatch. Query and schema details from PgAnalyze.

![Main DB 133K TPS Peak Christmas Day Odarix Screenshot](/assets/images/aura-tps-peak-christmas-2025.jpg)
<small>Main DB 133K TPS Peak Christmas Day Odarix Screenshot</small>

<table class="styled-table">
  <thead>
    <tr>
      <th>Metric</th>
      <th>Normal</th>
      <th>Christmas Day</th>
      <th>Notes</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>Main DB TPS Peak</td>
      <td>40K</td>
      <td>133K (<strong>3.3x ↗</strong>)</td>
      <td></td>
    </tr>
    <tr>
      <td>All DB TPS Peak Sum</td>
      <td>50K</td>
      <td>226K (<strong>4.5x ↗</strong>)</td>
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
      <td>7TB</td>
    </tr>
    <tr>
      <td>Total space</td>
      <td></td>
      <td></td>
      <td>30TB</td>
    </tr>
    <tr>
      <td>Largest row count</td>
      <td></td>
      <td></td>
      <td>7B (Billion)</td>
    </tr>
    <tr>
      <td>PgBouncer Instances</td>
      <td>73</td>
      <td>230 (<strong>~3.1x ↗</strong>)</td>
      <td>Across 8 ASGs</td>
    </tr>
    <tr>
      <td>PgBouncer Client Connections</td>
      <td>7.3K</td>
      <td>~40K (<strong>~5.5x ↗</strong>)</td>
      <td>Across 7 ASGs</td>
    </tr>
    <tr>
      <td>Biggest Dead Tuple Growth</td>
      <td>8M</td>
      <td>80M (<strong>~10x ↗</strong>)</td>
      <td>~4 hrs. runtime</td>
    </tr>
    <tr>
      <td>Memcached Instances</td>
      <td>21</td>
      <td>36 (<strong>1.7x ↗</strong>)</td>
      <td></td>
    </tr>
    <tr>
      <td>Memcached Connections</td>
      <td>9.3K</td>
      <td>~30K (<strong>3.2x ↗</strong>)</td>
      <td></td>
    </tr>
  </tbody>
</table>

Traffic grows in the week before Christmas, but on Christmas day (December 25) it really takes a sharp upward trajectory. The main sustained peak load period is over 10 hours on Christmas Day, with the main DB sustaining > 100K TPS from 10:00:00 to 20:00:00 US Central Time.

Employees noticed the Aura iOS and Android apps were moving up in the ranking charts by download. Excitement grew into the evening seeing the app move into the Top 10, all the way to the #1 position. 🎉 I grabbed a screenshot at around 11:30 PM CT December 25.

![Aura Frames #1 App U.S. App Store Christmas Day](/assets/images/aura-christmas-2025.jpg)
<br/>
<small>Screenshot showing the Aura Frames app at the #1 rank in the U.S. Apple App Store</small>

## Switchover to New DBs
To actually switch over to new server instances, effectively relocating the tables, it was critical to not lose any write operations and to minimize user-facing downtime.

The initial plan was to use [pglogical to synchronize data](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Appendix.PostgreSQL.CommonDBATasks.pglogical.html). Unfortunately the sync process was too slow and this plan was abandoned.

The next plan was to directly use native Logical Replication, setting up initially empty tables, a publication and subscription, ideally with an initial copy and then replication to fill in missing updates. This too proved to be too challenging and slow, and this plan was also abandoned.

The next plan which was sort of a fallback, was to use physical replication by first setting up a read replica instance. We knew this would work, but it meant duplicating the entire database which wasn't ideal.

It was the most inefficient plan in terms of space consumption as we had a lot of tables to clean up on both sides, but it worked reliably and repeatedly as we performed it a total of 6 times.

**Initial setup steps:**
1. For the RDS primary database, create a new read replica. It will need as much allocated space as the original instance. Use physical replication.
1. Set up AWS SSM parameters for the new database to be used by Ruby on Rails and PgBouncer.
1. Create a new PgBouncer Auto Scaling Group (ASG) for PgBouncer for the new DB. Set the SSM parameter to the network load balancer endpoint.
1. Route application traffic through the new PgBouncer but have it continue to point at the original DB via an environment variable. This would be the sole change for switch over.

**Switchover steps**:
1. Bring all PgBouncer instances down (set ASG desired capacity to 0). No writes are now happening. Down for users.
1. [Wait for replication lag to reach zero](https://github.com/andyatkinson/pg_scripts/commit/f91b3855a81e1387f1f795d31a7ee8612a2fd394). Promote the read replica to be a primary instance and wait for it to restart. Now it's ready for writes with no operations lost.
1. Change the environment variable PgBouncer uses to point at the database, to now point at the newly promoted primary instance.
1. Bring back PgBouncer instances, setting the ASG desired capacity back to the original value.

This process involved in 5-10 minutes or less of user-facing downtime. We work up early to perform it off-peak in a low-activity time period.

**Clean up:**
1. Drop table from original primary (carefully review this with team members in advance). Initially rename first, double check again, then drop the renamed table.
1. Drop all unneeded tables from the new replacement primary, which was most tables or all but one.

With all the tables cleaned up on the new primary, we now had way more allocated space than needed, and this provisioned space costs money. This used to be more of a pain, but [AWS launched Blue/Green Deployments](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/blue-green-deployments.html) and we used it to help here.

We set up a Blue/Green Deployment where the Blue was the newly promoted primary, and the Green would be a replacement instance with less space provisioned. Once replication was caught up, we cut over to Green, and thus achieved an instance with an appropriate amount of provisioned space.

## Reflecting back on the plan
Some of the key contributors to successfully delivering reliable Postgres:
1. Having an extensive test suite running tests continuously (CI) helping catch regressions as code was refactored, along with PR reviews from seasoned team members
1. As refactorings happened in large batches, slicing out a smaller chunks as smaller PRs for easier review, and less risk as releases
1. Using a canary release process for widespread changes, released to a single instances vs. the whole fleet, helped to validate correctness for issues that were hard to verify outside of the production environment
1. Having an extensive pre-production load testing capability to validate the accumulated changes under high load, across most of the API surface area of the platform, drilling into performance regressions identified in load testing
1. Having a large AWS infrastructure budget 😅 to work with and strategic spending, in order to over-provision instance sizes and IOPS temporarily to gain more reliability, thanks in part to being a profitable company!
1. Having comprehensive CloudWatch metrics, dashboards, web, and Postgres logs for analysis ([AWS Athena](https://aws.amazon.com/athena/)), time-series metrics galore (formerly StatHat), and best-in-class Postgres observability ([PgAnalyze](https://pganalyze.com)), to empower backend engineers with data access layer visibility
1. Having experienced, long-tenured colleagues to guide and review changes, focusing on high leverage opportunities, while generously sharing their knowledge.

## Thank You and Looking Forward
While the biggest payoff was seeing that Postgres operated reliably through the peak traffic holiday season, it was also rewarding to work with great engineers currently on staff and benefit from all the accumulated scalability engineering practices injected into the codebase over many years.

For 2026 we’re forming our plans to further improve reliability, scalability, and cost efficiency.

If these types of posts are interesting to you, please consider subscribing to my blog or buying my book. If you're an engineer interested in working on these types of challenges, please get in touch.

Thanks for reading!
