---
layout: post
title: "Remote Ruby — Unleashing the Power of Postgres with Andrew Atkinson 🎙️"
tags: [Podcast, Ruby on Rails, Open Source]
date: 2024-01-05
comments: true
---

Back in October I joined Jason, Andrew, and Chris, as a guest on [Remote Ruby](https://www.remoteruby.com/).

Remote Ruby is a podcast I listen to regularly, so it was a lot of fun to be a guest.

Some of the topics we discussed were my process of writing the book [High Performance PostgreSQL for Rails](https://pragprog.com/titles/aapsql/high-performance-postgresql-for-rails/), what’s trending in PostgreSQL now, storage access and database concepts, and of course some new things in Ruby on Rails.

Listen to the episode here 👉 <https://remoteruby.com/2260490/14003765-unleashing-the-power-of-postgres-with-andrew-atkinson>

## Exciting times in PostgreSQL

PostgreSQL popularity continues to rise. While it [sits at #4 per the DB-Engines ranking](https://db-engines.com/en/ranking), DB-Engines recently announced:

> PostgreSQL is the DBMS of the Year 2023
<cite>DB-Engines</cite>

[Read more about the announcement](https://db-engines.com/en/blog_post/106)

This announcement ties into a portion of the podcast conversation about innovation and excitement in PostgreSQL.

Since I’m heavily subscribed to companies and products in the PostgreSQL ecosystem I thought it might be nice to share some examples for listeners that might be unfamiliar with these developments.

Besides well-established hosted PostgreSQL providers (which also continue to innovate) like AWS, Google Cloud Platform, and Microsoft Azure, there are startups and smaller companies pushing the boundaries of what’s possible with PostgreSQL.

These companies are targeting new niche areas, building on top of the permissively-licensed and open source PostgreSQL engine.

## PostgreSQL startups and small companies

Companies and products like Supabase, Tembo, Neon, Hydra, Crunchy Data, and Nile, to name a few, are innovating and shipping new products built on PostgreSQL.

I’ve had the chance to meet founding engineers and co-founders for some of these companies. Earlier in 2023, Gwen Shapira hosted me on [SaaS for Developers with Gwen Shapira — Postgres, Performance and Rails with Andrew Atkinson 🎙️
](http://andyatkinson.com/blog/2023/08/28/saas-for-developers-gwen-shapira-postgresql-rails).

Since then, Gwen has launched [Nile Database](https://www.thenile.dev/) as a co-founder, a new database product targeting the challenges SaaS companies face like cost efficiency, data movement and more. Nile handles many of the complexities that multi-tenant databases face. Check it out.

Another exciting company is [Tembo](https://tembo.io/), which recently announced a big fundraising round, and they’re taking a different approach.

Tembo’s approach is to take PostgreSQL - a general-purpose database - and turn it into a special-purpose offering as “stacks”. The stacks leverage the extensibility of PostgreSQL, by bundling extensions, parameters, and more, to produce a feature and cost competitive offering while still being “just Postgres” behind the scenes.

For PostgreSQL fans, this is exciting because it means they’re able to leverage their hard-earned knowledge and skills operating PostgreSQL, for additional types of work that might have otherwise been performed on heterogeneous special-purpose databases.

## Topics in PostgreSQL and Rails

In the episode, we dove into specific topics in PostgreSQL and Rails.

- Unlogged tables, and using them in your test environment
- PostgreSQL as a cache store. What’s changed in hardware over the last 10 years that makes this more viable now?
- Basics of storage access (input/output or IO), and how storage access relates to query performance
- Adding restrictions to queries to reduce IO, and how that improves performance
- When to invest in performance engineering work

At the end, we touched on a non-tech interest of mine, which is a sport Jason and I follow and have a fun mini-rivalry going as smaller Midwest-market fans. Can you guess the sport? You’ll have to listen to find out!

## Social shares

- We shared the episode on [/r/rails Reddit](https://www.reddit.com/r/rails/comments/18j7gi0/unleashing_the_power_of_postgres_with_andrew/) where it got some reactions and comments

## Another Remote Ruby PostgreSQL Episode

A week later, a second PostgreSQL-theme Remote Ruby episode dropped, this time featuring Craig Kerstiens!

Craig’s episode is called “Decoding Postgres: A Journey Through User-Friendly Database Experiences” and is worth checking out. How cool to have back-to-back PostgreSQL-themed Remote Ruby episodes!

Check out the episode here 👉  <https://www.remoteruby.com/2260490/14084712-decoding-postgres-a-journey-through-user-friendly-database-experiences-with-craig-kerstiens>


## Wrapping Up

That’s it for now. I appreciated the chance to be a guest on Remote Ruby, and hope the conversation topics are useful for listeners.

Thanks for checking out the episode, and let me know what you think. 

