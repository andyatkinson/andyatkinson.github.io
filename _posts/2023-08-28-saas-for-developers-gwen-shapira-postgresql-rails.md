---
layout: post
title: "SaaS for Developers with Gwen Shapira &mdash; Postgres, Performance and Rails with Andrew Atkinson 🎙️"
tags: [Podcast, Ruby on Rails, Open Source]
date: 2023-08-28
comments: true
---

A few months ago I joined the [SaaS Developer Community](http://launchpass.com/all-about-saas) to learn more about challenges SaaS developers face.

The community has a podcast series with guests discussing technical topics related to SaaS.

I recently had the opportunity to join Gwen as a guest where we discussed PostgreSQL and Ruby on Rails.

In this post I'll recap some of the discussion points and provide extra context.

Since Gwen knew I was writing a book on PostgreSQL and Ruby on Rails, we started off with questions about what inspired the book.

## Outline

* SaaS Developer Community
* Why did I choose to write about PostgreSQL and Rails?
* Advocating for PostgreSQL and Rails
* ORMs and SQL
* N+1 Query Pattern Problem
* Read and Write Splitting
* High Request Volume
* PostgreSQL Resources
* Community Links
* Full Interview


## SaaS Developer Community

First I wanted to highlight the SaaS Developer Community.

The community is run by Gwen Shapira, co-founder and CPO of Nile, and has a couple of thousand members. There is also a [video podcast series on YouTube](https://www.youtube.com/@saas-dev).

Check it out!

## Why did I choose to write about PostgreSQL and Rails?

I've worked with this stack for many years and more recently with an infrastructural and administrator level focus on PostgreSQL. I felt qualified to write about this combination of technologies from having used them in production at a variety of companies.

I also felt a pull to advocate for PostgreSQL and Ruby on Rails as they offer a great balance of productivity, open source licensing friendliness, reliability, and practicality.

Part of the goal with the podcast was to promote my book [High Performance PostgreSQL for Rails](https://pgrailsbook.com).

## Advocating for PostgreSQL and Rails

A confluence of factors happened in 2020 for me that sparked my interest in these topics.

The first was a curiosity to learn PostgreSQL in greater depth than what I'd done so far as an application developer.

The second factor was a challenge our team faced with high bloat and other common operational problems. I was able to take on these challenges and quickly iterate on solutions, putting them into practice immediately. I learned a lot from others as well in a short period of time.

It was critical to not only learn but apply findings, experimenting and iterating.

Our team did not have a Database Administrator so a lot of common operational problems from growth like high bloat existed that might have otherwise been something a DBA fixed.

Small teams running without DBAs I think is quite common. In addition, Infrastructure engineers may also lack the product context or database knowledge needed to work on optimizations.

The projects I took on were turned into a presentation, that I pitched to a PostgreSQL conference and had accepted.

Check out [PGConf NYC 2021 Conference](/blog/2021/12/06/pgconf-nyc-2021) to see that presentation. Following the presentation, I was approached by a book publisher and the rest is history.

## ORMs and Writing SQL

Are ORMs needed at all? Object Relational Mappers (ORMs) like Active Record in Ruby on Rails are the conventional way to write application queries.

What about writing SQL directly? Active Record supports writing SQL directly as well.

The book attempts to meet readers where they are by acknowledging that most Ruby on Rails teams write Active Record for their application query layer, and there are many optimizations within Active Record and for SQL queries.

## N+1 Query Problem

The problem in a nutshell is "excessive" queries that are repeated queries to the same table with a varying id value, from inside a loop in code.

The pattern is considered an excessive amount of queries because the multiple queries can be replaced with a single query to the table earlier.

Historically Active Record has allowed developers to lazily evaluate parts before generating a final SQL query and this is a nice feature.

Lazy evaluation is a double edged sword though, because the lazy evaluation can hide these excessive queries.

Gwen and I discussed something called "Strict Mode" that disables lazy loading either for an entire model or at particular call sites.

One mistake I said in the podcast was that I said "to prevent eager loading" and meant to say that Strict Loading (See: [PGSQL Phriday #001 — Query Stats, Log Tags, and N+1s](/blog/2022/10/07/pgsqlphriday-2-truths-lie)) prevents "lazy loading" (not eager loading).


## Read and Write Splitting

Ruby on Rails supports Multiple Databases since [version 6 released in 2019](https://guides.rubyonrails.org/6_0_release_notes.html).

One of the use cases this unlocks is splitting out read only queries to run them on a read replica instance. This works natively within Rails without the need for a third part Ruby gems.

Normally you might configure each writer and reader instance via "Roles" in Ruby on Rails. Then switch read only queries to the Reader role.

Active Record supports automatic switching as well. Automatic switching is called "Automatic Role Switching" in Active Record.


## High Request Volume

Folks on Twitter and YouTube wondered more about the numbers for the single instance performance figures that were claimed.

We used the Requests Per Minute (RPM) as the main metric to assess total requests in New Relic.

This metric is for total HTTP requests, and most of them involve a database query, but it's worth noting that not all requests involve the relational database.

Also worth noting that we talk about this as single instance PostgreSQL, but in reality there are at least 2 instances in a replication pair. A read only instance receiving replication can and should be used to run read only queries on whenever possible.

Additional read replicas can be added to distribute the workload associated with read only queries in a horizontal fashion.

* At least 450K RPM was observed on the main Ruby on Rails monolith (7500 requests/second)
* 550K RPM observed across all services (9200 requests/second) including the Rails monolith and other Rails services with their own databases
* RDS Proxy was put into production to scale client connections well beyond what RDS PostgreSQL would have allowed
* Huge fleet of application server processes (and multiple threads per process) on bare EC2 orchestrated with Elastic Beanstalk running the Puma web application server
* PostgreSQL 10 on RDS with minimal database parameter tuning outside of Autovacuum settings

## PostgreSQL Resources

We used an instance class family available in 2020 on AWS RDS that met the following criteria:

* 96 vCPUs
* 768GB memory
* Provisioned IOPS beyond what was available for the instance

We set up Physical (streaming) replication from the primary instance to several read only replicas. The read replicas were configured with the Rails application for SELECT queries.

## Community Links

- Youtube: <https://youtu.be/0wtOKD7iJT8>
- Podcast: <https://podcasters.spotify.com/pod/show/saas-for-developers/episodes/Postgres--Performance-and-Rails-e28dks8>
- SaaS Developer Slack, where Andrew may share secret discounts: <http://launchpass.com/all-about-saas>
- Andrew's YouTube playlist with all his content: <https://youtube.com/watch?v=W8d3roay29w&list=PL9-zCXZQFyvqhkrefUXAfC4FYntQX9SC9>


## Full Interview

To see the full interview check out the YouTube embed below or jump over to YouTube. Leave a comment if you found it helpful or interesting.

<iframe width="560" height="315" src="https://www.youtube.com/embed/0wtOKD7iJT8?si=TG2ubliJpaxRV24R" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" allowfullscreen></iframe>



Thanks!
