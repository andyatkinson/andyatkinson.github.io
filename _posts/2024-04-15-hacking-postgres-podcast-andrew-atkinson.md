---
layout: post
title: "🎙️ Hacking Postgres 🐘 Podcast - Season 2, Ep. 1 - Andrew Atkinson"
tags: [Podcast, PostgreSQL, Open Source, Ruby on Rails]
date: 2024-04-15
comments: true
---

Recently I joined Ry Walker, CEO of [Tembo](https://tembo.io), as a guest on the [Hacking Postgres](https://www.youtube.com/playlist?list=PL11N188AYb_Z04oQJgllNEY5m7gCcY8tH) podcast.

Hacking Postgres has had a lot of great Postgres contributors as guests on the show, so I was honored to be a part of it being that my contributions are more in the form of developer education and advocacy.

Ry asked me about when I got started with PostgreSQL and what my role looks like today.

{% include image-caption.html imageurl="/assets/images/posts/hacking-postgres-podcast.jpg" title="Hacking Postgres Podcast" caption="Hacking Postgres Season 2, Ep. 1 - Andrew Atkinson" %}

## PostgreSQL Origin

Ry has also been a Ruby on Rails programmer, so that was a fun background we shared. We both started on early versions of Ruby on Rails in the 2000s, and were also early users of Heroku in the late 2000s.

Since PostgreSQL was the default DB for Rails apps deployed on [Heroku](https://heroku.com), for many Rails programmers it was the first time they used PostgreSQL. Heroku valued the fit and finish of their hosted platform offering, and provided best in class documentation and developer experience as a cutting edge platform as a service (PaaS). The popularity of that platform helped grow the use of PostgreSQL amongst Rails programmers even beyond Heroku. 

For me, Heroku was where I really started using PostgreSQL and learning about some of the performance optimization tactics "basics" as a web app developer.

## Meeting The Tembo Team

Besides Ry, I’ve also had the chance to meet more folks from Tembo. Adam Hendel is a founding engineer and also based here in Minnesota. I also met Samay Sharma, PostgreSQL contributor and now CTO of Tembo, at [PGConf NYC 2023](/blog/2023/10/10/pgconf-nyc-2023) last Fall. While not an employee or affiliated with the company at all, it’s been interesting to track what they’re up to, and get little glimpses into starting up a whole company that’s focused on leveraging the power and extensibility of PostgreSQL.

If you’d like to learn more about Adam's background, Adam was the guest for Season 1, Episode 2 of Hacking Postgres, which you can find here: <https://tembo.io/blog/hacking-postgres-ep2>

## Using PostgreSQL with Ruby on Rails Apps

Ruby on Rails as a web development framework has great support via the ORM - Active Record - for basic and advanced Postgres features.

There’s support for [composite primary keys](https://guides.rubyonrails.org/active_record_composite_primary_keys.html) (CPK), [common table expressions](https://apidock.com/rails/ActiveRecord/QueryMethods/with) (CTE), and if you don’t like the SQL that Active Record generates, you can always write your own as query text within strings, binding parameters as needed. If your work is scaling up, Active Record helps by offering writer and role separation, and the ability to run copies of your DB via [Horizontal Sharding](https://guides.rubyonrails.org/v7.0/active_record_multiple_databases.html#horizontal-sharding).

There’s even a page dedicated to PostgreSQL support by Active Record on the official Ruby on Rails documentation here: <https://guides.rubyonrails.org/active_record_postgresql.html>

Looking at things the other way around, from the perspective of PostgreSQL, Ruby on Rails is "just another client application." We might see some non-ideal patterns as client requests like N+1 queries, overly broad queries without restrictions on columns, rows, the number of tables joined etc., but I’d argue most of those things aren’t specific to Active Record as they are more of a shortcoming of application developers having limited understanding of how their queries are planned and executed.  That’s something I’m hoping to help improve!

The Ruby on Rails app the book uses is called Rideshare and is here: <https://github.com/andyatkinson/rideshare>. Within the source code, besides the Ruby code, you’ll see a lot of sample PostgreSQL files like `.pgpass`, `pg_hba.conf`, pgbouncer configuration, and these are all used in examples and exercises in the book. You’ll also see a couple of Docker instances that get provisioned and connected to each other, as readers work through examples and exercises setting up physical and logical replication, then configuring it with Active Record.

I’m pretty sure this is the only book of its kind that goes into as much depth both with PostgreSQL and Active Record!

## Hacking Postgres Podcast

There have been a lot of great episodes on the podcast.

[Marco Slot](https://tembo.io/blog/hacking-postgres-ep1) was the overall first guest, Season 1, Episode 1. I remember the episode coming out around the time of PGConf NYC 2023.

Marco is the creator of the `pg_cron` <https://github.com/citusdata/pg_cron> extension which I’ve used professionally, and included in examples in Rideshare for the book.

Philippe Noël, CEO of ParadeDB, Season 1, Episode 8: <https://tembo.io/blog/hacking-postgres-ep8>, `pg_bm25` for Elasticsearch-like search in Postgres. <https://blog.paradedb.com/pages/introducing_search>

Recently I listened to this episode with Burak Yucesoy of Ubicloud. Burak has worked on various extensions too like [postgres-hll](https://github.com/citusdata/postgresql-hll), "high cardinality estimates" using the HyperLogLog data structure. This extension is also mentioned in the book.

I also enjoyed the episode with Bertrand Drouvot as the guest: <https://tembo.io/blog/hacking-postgres-ep9>. Bertrand covered some of these items:

- pgsentinel <https://github.com/pgsentinel/pgsentinel>
- explain.dalibo.com for plan visualization. <https://explain.dalibo.com/>
- `pg_directpaths` <https://github.com/bdrouvot/pg_directpaths> with some super speed inserts, even much faster than inserting into unlogged tables!

I like the ideas Bertrand shared for more observability that's useful for Postgres DBAs:

- For a long running queries, seeing which parts are being processed. For example, which part of the processing is happening, buffers access? Filtering? Sorting? For OLTP we typically have short queries, but even then they can go long and appear to be stuck.
- For a normalized query from `pg_stat_statements`, the ability to see the query plans that were for that query. It would be interesting to look back and see whether a bad plan popped in at some point.

## More Podcast Recommendations

Ry likes to ask about podcasts the guest recommends. Here’s a collection of recent podcast episodes or podcasts I’d recommend:

- postgres.fm is a favorite! I appeared recently as a guest on Rails + Postgres <https://postgres.fm/episodes/rails-postgres>
- Scaling Postgres with Creston Jamison <https://www.scalingpostgres.com/>
- NetApp OnTech <https://twitter.com/andatki/status/1776459512687231352>
- Ruby For All <https://twitter.com/andatki/status/1776392158674821288>
- YAGNI <https://twitter.com/andatki/status/1776391049205927953>

## "Just Use Postgres"

Ry and I briefly touched on "database sprawl," which is something I’ve seen in the wild. The last chapter of my book addresses this topic, bringing a lot of things together the reader has learned from earlier chapters, with the goal of using PostgreSQL for more types of work.

For example, Redis is a very popular second database in the Ruby on Rails community. Commonly, Redis is used to write and read cache data, background job or message queue data that's small and transient, or for storing other small bits of data like user session data.

While Redis works well for those things, operating a Redis instance or cluster does carry more operational cost for the team, as it's another piece of infrastructure to provision, patch, upgrade, and observe. What if we used Postgres for those things instead?

We explore specific tactics for doing that with use cases like:

- Background jobs without Redis
- Full text search within PostgreSQL, tsquery, tsvector
- Caching without Redis
- Vector similarity search

## Resources

- Here's the Hacking Postgres episode video: <https://www.youtube.com/watch?v=CAbGPydw_NY>

The tweet is embedded below.

<blockquote class="twitter-tweet"><p lang="en" dir="ltr">Hacking Postgres Season 2 is here!<br><br>We&#39;re releasing new episodes every Thursday through the end of May, so stay tuned for more great Postgres content!<br><br>First up, we&#39;ve got Andrew Atkinson (<a href="https://twitter.com/andatki?ref_src=twsrc%5Etfw">@andatki</a>) a Software Engineer who specializes in building high-performance web applications… <a href="https://t.co/q22nc8WQg1">pic.twitter.com/q22nc8WQg1</a></p>&mdash; Tembo - Multi-Workload Postgres (@tembo_io) <a href="https://twitter.com/tembo_io/status/1776044934002270390?ref_src=twsrc%5Etfw">April 5, 2024</a></blockquote> <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>

## Wrapping Up and Thank You

Hacking Postgres with Ry was a good time! I’m glad the Tembo team is offering Postgres as a server in new ways, by customizing it with curated sets of extensions as various stacks, providing an extension registry, and contributing to the greater PostgreSQL ecosystem. Having more choices benefits developers, providing new solutions for long-standing challenges.

I recommend the "Hacking Postgres" podcast as a great way to get to know some of the PostgreSQL contributor community, and tech innovations in the greater ecosystem.

Thank you to Ry for hosting and interviewing me, Adam for recommending me, and Jonathan and the production team behind the scenes for your support in the process.
