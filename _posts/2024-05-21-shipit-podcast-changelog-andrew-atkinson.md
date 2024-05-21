---
layout: post
title: "🎙️ Ship It Podcast — PostgreSQL with Andrew Atkinson"
tags: [Podcasts, Open Source, PostgreSQL]
date: 2024-05-21
comments: true
---

Recently I joined Justin Garrison and Autumn Nash for episode "FROM guests SELECT Andrew" of [Ship It](https://changelog.com/shipit), a [Changelog](https://changelog.com) podcast.

We had a great conversation! I made bullet point notes from the episode, and added extra details.

Let's get into it!

## PostgreSQL Community
- Autumn shared that she met [Henrietta Dombrovskaya](https://postgresql.life/post/henrietta_dombrovskaya/), who is an [author](https://www.amazon.com/PostgreSQL-Query-Optimization-Ultimate-Efficient/dp/1484268849), DBA, and who organizes [Chicago PostgreSQL](https://www.meetup.com/chicago-postgresql-user-group/) meetup and the [PgDay Chicago](https://2024.pgdaychicago.org/) conference. This was fun to hear since Henrietta has become a friend. Check out my 2023 coverage of [PgDay Chicago](https://andyatkinson.com/blog/2023/05/24/pgday-chicago).
- Justin wasn’t familiar with the Postgres community. I was glad to share that the community events I’ve attended and people I’ve met at them, have been great!
- Justin talked about career goals of trading off less money, for greater happiness. Autumn talked about how remote work provides the opportunity to get to know neighbors and your local community.
- We talked about the longevity of PostgreSQL as an open source project, and the benefits of not being lead by a single big entity hat might be quarterly-profit oriented. Hopefully there's no license “rug pull” in the future. Core team member Jonathan Katz wrote about this topic in [Will PostgreSQL ever change its license?](https://jkatz05.com/post/postgres/postgres-license-2024/)
- I shared that PostgreSQL leaders, contributors, and committers attend community events, and it's been fun to meet some of them.
- Autumn mentioned Henrietta helped give away tickets to [Milspouse Coders](https://milspousecoders.org) (Military Spouse Coders) for PgDay Chicago and that was greatly appreciated.
- Autumn appreciated the explicit goal to bring more women to the Postgres community and PgDay Chicago event.
- Autumn shared how seeing women at Postgres events (Check out a list of [PostgreSQL community events](https://www.postgresql.org/about/events/)) is important. Representation matters.
- I shared some prominent women in the Postgres community I’ve met: Melanie Plageman, [recently by becoming a core committer to PostgreSQL](https://www.postgresql.org/message-id/df222085-2248-4d89-8935-256a9c384878%40postgresql.org), [Lætitia Avrot](https://mydbanotebook.org/), [Karen Jex](https://karenjex.blogspot.com/), [Elizabeth Garret Christensen](https://postgresql.life/post/elizabeth_garrett_christensen/), [Stacey Haysler](https://postgresql.us/team/), [Chelsea Dole](https://chelseadole.com/), [Selena Flannery](https://www.linkedin.com/in/selenaflannery/), [Ifat Ribon](https://www.linkedin.com/in/ifatribon/), [Gabrielle Roth](https://gorthx.wordpress.com/), are a few that come to mind!

## Picking PostgreSQL and optimal designs
- PostgreSQL has support for storing and indexing JSON data, which offers an alternative to [MongoDB](https://www.mongodb.com/) or [DocumentDB](https://docs.aws.amazon.com/documentdb/latest/developerguide/what-is.html) NoSQL alternatives
- I mentioned [PgAnalyze](https://pganalyze.com/) and how founder Lukas Fittl is prominent in the community. Had the chance to catch up with Lukas at PgDay Chicago 2024.
- When would we not use Postgres? If we wanted to scale beyond a single instance for writes or reads, [Citus is a distributed Postgres option](https://www.citusdata.com/), which offers both row-based and schema-based sharding across multiple nodes. I’ll be presenting on Citus and related topics for [SaaS on Rails on PostgreSQL](https://www.citusdata.com/posette/speakers/andrew-atkinson/) at the virtual conference POSETTE: An Event for Postgres 2024.
- Brief discussion of specialized vector databases versus the extensibility of PostgreSQL, and using [pgvector](https://github.com/pgvector/pgvector).
- For single instance reliability and availability, we can leverage physical and logical replication, to keep multiple replicas around that can be promoted to take over the role of the primary writer instance
- Some modern commercial, hosted Postgres offerings, are building “compute and storage separation,” which can greatly reduce or effectively eliminate the concern of “replica lag.” Replica lag is a factor for “read after write” consistency, when we’re separating writes and reads across instances.

Towards the second half, we dove into a variety of different topics.

- Andrew mentioned the [Rideshare app from the book is available publicly on GitHub](https://github.com/andyatkinson/rideshare), no book purchase required.
- There are dozens of companies building on PostgreSQL like Yugabyte, Timescale, and Hadoop, to name a few. Read about [more things built on PostgreSQL](https://wiki.postgresql.org/wiki/PostgreSQL_derived_databases).
- SQL is a fundamental skill that’s worth learning and improving
- Justin point out that whether you’re using a hosting provider or on premises, when it’s data you’re responsible for, it’s critical to protect it
- Autumn pointed out we should “be nice” to DBAs, in the context of companies choosing exiting the cloud, going back to "on prem," and needing more engineering skills from systems administrators and DBAs, which is what we had before the prominence of the cloud.
- Justin pointed out that if you’re going on prem, you gotta pay people. For example, AWS runs “on prem,” there are people behind the scenes helping making it all work.

## Performance and Cost Savings
- Autumn pointed out for OLTP SQL work, and schema design, whether on prem or hosted, if we can really understand query planning, how we put data into and get data out of our databases, we can save millions of dollars.
- Justin asked about the PostgreSQL query planner, whether we've got something like “flamegraphs” or distributed tracing. Andrew said that we’ve got something like that (although not as visual), but we’ve got the query plan break down using EXPLAIN, where we can see how much time is spent in storage access and filtering and similar operations, and what their costs are.

## Outro
- Justin mentioned he likes Terminal User Interface (TUI) programs, and maintains the [awesome-tuis](https://github.com/rothgar/awesome-tuis) repository.
- Justin mentioned he maintains [Awesome Tmux](https://github.com/rothgar/awesome-tmux). I’m a daily Tmux user, and learned it from Brian Hogan’s book [tmux2: Productive Mouse-Free Development](https://pragprog.com/titles/bhtmux2/tmux-2/), which I [recently learned has a new version coming soon](https://x.com/bphogan/status/1783939076149621216).

## Corrections
- Bluesky was initially built in PostgreSQL, which was mentioned towards the episode end. Apparently since then, the [Bluesky team has moved to ScyllaDB and SQLite](https://bsky.app/profile/andatki.bsky.social).

## Wrap Up
Justin and Autumn were great hosts, and I felt very comfortable as a guest and had a fun conversation connecting on tech and also as parents in tech!

Thanks for reading and listening, and get in touch with any questions or comments!


## Listen to the Episode
<!-- Callout box -->
<section>
<div style="border-radius:0.8em;background-color:#eee;padding:1em;margin:1em;color:#000;">
<h2>Podcast</h2>
<p>👉 <a href="https://changelog.com/shipit/104">Listen to the episode</a></p>
</div>
</section>
