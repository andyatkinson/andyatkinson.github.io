---
layout: post
title: "🎙️ Hacking Postgres 🐘 podcast - Season 2, Ep. 1 - Andrew Atkinson"
tags: [Podcast]
date: 2024-04-15
comments: true
---

Recently I joined Ry Walker as a guest on the [Hacking Postgres](https://www.youtube.com/playlist?list=PL11N188AYb_Z04oQJgllNEY5m7gCcY8tH) podcast, produced by Tembo, where Ry is the CEO.

Hacking Postgres has had a lot of Postgres contributors on the show, so it was an honor to be a guest. Ry asked me about when I got started with PostgreSQL and what my role looks like today. Besides completing work individually, my great role with PostgreSQL has been advocacy and education with teams I’m part of, through writing, conference presentations, and now with clients that hire me.

## PostgreSQL Origin

Ry is also a Ruby on Rails programmer, so that was a fun background we shared. We both started on early versions of Ruby on Rails in the 2000s, and were also early users of Heroku in the late 2000s.

Since PostgreSQL was the default DB for Rails apps deployed on Heroku, for many Rails programmers it was the first time they used PostgreSQL. Heroku valued the fit and finish of their hosted platform offering, and provided best in class documentation and developer experience as a cutting edge platform as a service (Paas). The popularity of that platform helped grow the use of PostgreSQL amongst Rails programmers even beyond Heroku. 

## The Tembo Team

Besides Ry, I’ve also had the chance to meet more folks from Tembo. Adam Hendel is a founding engineer and also based here in Minnesota. I also met Samay Sharma, PostgreSQL contributor and now CTO of Tembo, at PGConf NYC 2023 last Fall. While not an employee or affiliated with the company at all, it’s been interesting to track what they’re up to, and get little glimpses into starting up a whole company that’s focused on leveraging the power and extensibility of PostgreSQL.

If you’d like to learn more, Adam was the guest for the Season 1, Episode 2 episode, which you can find here: <https://tembo.io/blog/hacking-postgres-ep2>

## PostgreSQL via Ruby on Rails

Ruby on Rails as a web development framework has great support via the ORM - Active Record - for basic and advanced Postgres.

There’s support for composite primary keys (CPK), common table expressions (CTE), and if you don’t like the SQL that Active Record generates, you can always write your own as query text within strings, binding parameters as needed. If your work is scaling up, Active Record helps by offering writer and role separation, and the ability to run copies of your DB via Horizontal Sharding.

There’s even a page dedicated to PostgreSQL support by Active Record on the official Ruby on Rails documentation here: <https://guides.rubyonrails.org/active_record_postgresql.html>

Looking at things the other way around, from the perspective of PostgreSQL, Ruby on Rails is "just another client application." We might see some non-ideal patterns as client requests like N+1 queries, overly broad queries without restrictions on columns, rows, the number of tables joined etc., but I’d argue most of those things aren’t specific to Active Record as they are more of a shortcoming of application developers having limited understanding of how their queries are planned and executed.  That’s something I’m hoping to help improve!

The Ruby on Rails app the book uses is called Rideshare and is here: <https://github.com/andyatkinson/rideshare>. Within the source code, besides the Ruby code, you’ll see a lot of sample PostgreSQL files like `.pgpass`, `pg_hba.conf`, pgbouncer configuration, and these are all used in examples and exercises in the book. You’ll also see a couple of Docker instances that get provisioned and connected to each other, as readers work through examples and exercises setting up physical and logical replication, then configuring it with Active Record.

I’m pretty sure this is the only book of its kind that goes into as much depth both with PostgreSQL and Active Record!

## Hacking Postgres

There have been a lot of great episodes on the podcast.

[Marco Slot](https://tembo.io/blog/hacking-postgres-ep1) was the first guest. I remember the episode coming out around the time of PGConf NYC 2023. Marco is the creator of the `pg_cron` <https://github.com/citusdata/pg_cron> extension which I’ve used professionally, and included in examples in Rideshare for the book.

Phillippe Noee, CEO of ParadeDB, <https://tembo.io/blog/hacking-postgres-ep8>, `pg_bm25` for Elasticsearch-like search in Postgres. <https://blog.paradedb.com/pages/introducing_search>

Recently I listened to this episode with Burak Yucesoy of Ubicloud. Burak has worked on various extensions too like postgres-hll, "high cardinality estimates" using the HyperLogLog data structure. This extension is also mentioned in the book.

Bertrand Drouvot

- pgsentinel <https://github.com/pgsentinel/pgsentinel>
- explain.dalibo.com for plan visualization. <https://explain.dalibo.com/>
- `pg_directpaths` <https://github.com/bdrouvot/pg_directpaths> with some super speed inserts, even much faster than inserting into unlogged tables!

I like these ideas Bertrand shared for more capabilities in Postgres for DBAs:

- For a long running query, the ability to see which part is being processed. For example buffers/pages could be accessed, there could be filtering, there could be sorting going on.  For OLTP we typically have short queries, but even then they can go long and appear to be stuck.
- For a normalized query from pg_stat_statements, the ability to see the query plans used for that query. It would be interesting to look back and see whether a bad plan popped in at some point.

## More Podcasts

Here’s a collection of recent podcasts or podcast episodes I’d like to recommend:

- postgres.fm is a favorite! I appeared recently as a guest on Rails + Postgres <https://postgres.fm/episodes/rails-postgres>
- Scaling Postgres with Creston Jamison <https://www.scalingpostgres.com/>
- NetApp OnTech <https://twitter.com/andatki/status/1776459512687231352>
- Ruby For All <https://twitter.com/andatki/status/1776392158674821288>
- YAGNI <https://twitter.com/andatki/status/1776391049205927953>


## Just Use Postgres
Ry and I briefly touched on database sprawl, which is something I’ve seen at most places I’ve worked. That last chapter in my book addresses this, brining a lot of things together the reader has learned from earlier chapters.

Redis is a very popularly used second database in the Ruby on Rails community. Commonly, Redis is used for cache data, background job or message queue style data that’s small in size and transient, or for storing other small bits of data with high write and read speed and without the need for indexing, like user session data.

While Redis works well for those things, it does carry more cost, expands the operational topology meaning it’s another piece of infrastructure to provision, patch, upgrade, and observe. What if we used Postgres for those things instead?

We explore these approaches, using concrete implementations and open source code:

- Background jobs without Redis
- Full text search within PostgreSQL, tsquery, tsvector
- Caching without Redis
- Vector similarity search

## Resources

- Episode video: <https://www.youtube.com/watch?v=CAbGPydw_NY>

## Wrapping Up

This was fun to be a part of. I’m glad the Tembo team is offering Postgres and shaking things up by customizing it, offering various stacks, providing an extension registry, and more contributions to the greater ecosystem. Having more choices will benefit developers.

The Hacking Postgres is a fun way to get to know more about the community and their contributions. 
