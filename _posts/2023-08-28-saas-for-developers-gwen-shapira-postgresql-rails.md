---
layout: post
title: "SaaS for Developers with Gwen Shapira &mdash; Postgres, Performance and Rails with Andrew Atkinson 🎙️"
tags: [Podcast, Ruby on Rails, Open Source, PostgreSQL]
date: 2023-08-28
comments: true
---

A few months ago I joined the [SaaS Developer Community](http://launchpass.com/all-about-saas) to learn more about challenges SaaS developers face.

The community has a podcast series with guests discussing technical topics related to SaaS.

I recently had the chance to join the host Gwen on the podcast series in an episode discussing PostgreSQL, Ruby on Rails, and high performance for web applications.

In this post I'll recap and expand on some points from our discussion.

## Outline

* SaaS Developer Community
* Why did I choose to write about PostgreSQL and Rails?
* Advocating for PostgreSQL and Rails
* Database Skills for Developers
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

I've worked with this stack for many years and more recently with a focus on PostgreSQL. This is a mature and reliable open source stack of tools, that's also productivity centric. I like working with Ruby and I also like SQL!

I also think there's an opportunity in the market to help teach PostgreSQL skills to developers. At the same time, Active Record keeps gaining features that help big companies scale their Rails applications.

## Advocating for PostgreSQL and Rails

A confluence of factors happened in 2020 for me that sparked my interest in these topics.

The first was a curiosity to learn PostgreSQL in greater depth than what I'd done so far as an application developer.

The second was the opportunity to put what I learned into practice right away at a business operating a high scale Rails application.

The application was suffering from common PostgreSQL operational problems like high bloat from Autovacuum falling behind, so that's where we started.

The team did not have a dedicated DBA that might have otherwise already solved the problem. Our team needed to develop some specialized database operational skills but we were all application developers, so there was an opportunity there to expand outside the comfort zone.

I've since learned that small teams and startups running without dedicated DBAs is quite common. In fact, I've also found that skills for database operational excellence seem to be less prevalent compared with the latest buzzy technology, despite being more critical to the business and practical for software engineers.


## Database Skills for Developers

What if database skills could be made more accessible to web application developers? That became my mission.

Eventually that turned into [High Performance PostgreSQL for Rails](https://pgrailsbook.com) as a proposal to publishers, but before that there were blog posts, newsletters, and presentations as part of my journey into technical writing and developer education.

After removing company specific information, I took a chance and boiled down our optimization projects into a case study conference CFP pitch to PGConf NYC 2021. This became my first ever PostgreSQL conference and speaking opportunity at a database conference.

Check out [PGConf NYC 2021 Conference](/blog/2021/12/06/pgconf-nyc-2021) to see that presentation.

## ORMs and Writing SQL

Are ORMs needed at all? Object Relational Mappers (ORMs) like Active Record in Ruby on Rails are the conventional way to write application queries.

What about writing SQL directly? Active Record supports writing SQL directly as well.

The book attempts to meet readers where they are by acknowledging that most Ruby on Rails teams write Active Record for their application query layer, and there are many optimizations within Active Record. A chapter is dedicated to Active Record optimizations, then a later chapter focuses on SQL query optimization.

## N+1 Query Problem

Gwen wasn't familiar with this so we briefly recapped it.

The problem in a nutshell is considered "excessive" queries when queries to the same table are repeated that could be consolidated into a single query.

Active Record allows developers to write code that is lazily evaluated before a SQL query is generated. This is a nice feature but it opens up this N+1 query pattern possibility.

Gwen and I discussed a newer feature in Active Record called "Strict Mode." Strict Mode prevents lazy loading either for an entire model or in particular call sites.

One mistake from the podcast was I said "to prevent eager loading" but meant to say that Strict Loading (See: [PGSQL Phriday #001 — Query Stats, Log Tags, and N+1s](/blog/2022/10/07/pgsqlphriday-2-truths-lie)) prevents "lazy loading," thus requiring eager loading to fetch data needed.


## Read and Write Splitting

Ruby on Rails supports Multiple Databases since [version 6 released in 2019](https://guides.rubyonrails.org/6_0_release_notes.html).

One of the use cases this unlocks is Read/Write splitting, which means read only queries can be run on a read replica instead of the primary instance. This works natively with Rails without requiring a third party Ruby gem.

Writers and readers are configured as "Roles" in Ruby on Rails. Developers might switch some query code then to use the Reader role.

Manually switching code to the reader role works well, but Active Record can even automatically do this.

The feature is called [Automatic Role Switching](https://guides.rubyonrails.org/active_record_multiple_databases.html#activating-automatic-role-switching) in Active Record.


## High Request Volume

We used the "Requests Per Minute" (RPM) metric from the New Relic APM to quickly gauge traffic volume.

This metric covers total HTTP requests and most of them involved a database query, although requests that can be served from another database like Redis, or from Rails cache, might never touch PostgreSQL.

We also referred to this scalability as "single instance" PostgreSQL, but technically there were at least 2 instances because read queries were run on a second read replica instance receiving physical replication.

Here are some of the figures we observed:

* More than 450K (7500 requests/second) RPM for the main Ruby on Rails monolith at peak
* 550K RPM (9200 requests/second) for the main Rails monolith plus other smaller Rails services which had their own database instances
* RDS Proxy used to scale client connections into the thousands
* Huge fleet (many dozens) of EC2 instances running the multi-threaded Puma web application server
* PostgreSQL 10 on RDS with minimal database parameter tuning

## PostgreSQL Instance Resource

We used an instance class family available in 2020 on AWS RDS with the following specs:

* 96 vCPUs
* 768GB memory
* Provisioned IOPS

Physical (streaming) replication from the primary instance to multiple replicas.

## Community Links

- YouTube: <https://youtu.be/0wtOKD7iJT8>
- Podcast: <https://podcasters.spotify.com/pod/show/saas-for-developers/episodes/Postgres--Performance-and-Rails-e28dks8>
- SaaS Developer Slack, where Andrew may share secret discounts: <http://launchpass.com/all-about-saas>
- Andrew's YouTube playlist with all his content: <https://youtube.com/watch?v=W8d3roay29w&list=PL9-zCXZQFyvqhkrefUXAfC4FYntQX9SC9>


## Full Interview

To see the full interview check out the YouTube embed below or jump over to YouTube. Leave a comment if you found it helpful or interesting.

<iframe width="560" height="315" src="https://www.youtube.com/embed/0wtOKD7iJT8?si=TG2ubliJpaxRV24R" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" allowfullscreen></iframe>


Thanks!
