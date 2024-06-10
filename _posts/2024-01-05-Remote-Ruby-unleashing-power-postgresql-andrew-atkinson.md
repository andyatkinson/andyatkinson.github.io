---
layout: post
title: "Remote Ruby — Unleashing the Power of Postgres with Andrew Atkinson 🎙️"
tags: [Podcasts, Ruby on Rails, Open Source, PostgreSQL]
date: 2024-01-05
comments: true
---

Back in October I joined Jason, Andrew, and Chris, as a guest on [Remote Ruby](https://www.remoteruby.com/).

Remote Ruby is a podcast I listen to regularly, so it was a lot of fun to be a guest.

Some of the topics we discussed were my process of writing the book [High Performance PostgreSQL for Rails](https://pragprog.com/titles/aapsql/high-performance-postgresql-for-rails/), what’s trending in PostgreSQL now, storage access and database concepts, and of course some new things in Ruby on Rails.

<!-- Callout box -->
<section>
<div style="border-radius:0.8em;background-color:#eee;padding:1em;margin:1em;color:#000;">
<h2>Podcast</h2>
<p>👉 <a href="https://www.remoteruby.com/2260490/14003765-unleashing-the-power-of-postgres-with-andrew-atkinson">Unleashing the Power of Postgres with Andrew Atkinson</a></p>
</div>
</section>


## Exciting times in PostgreSQL

PostgreSQL popularity continues to rise. While it [sits at #4 per the DB-Engines ranking](https://db-engines.com/en/ranking), DB-Engines recently announced:

> PostgreSQL is the DBMS of the Year 2023
<cite>DB-Engines</cite>

[Read more about the announcement](https://db-engines.com/en/blog_post/106).

What does this mean? PostgreSQL is exciting today and has a bright future. This announcement ties into part of our conversation about innovation and excitement in PostgreSQL.

Since I’m heavily subscribed to companies and products in PostgreSQL, I thought it might be nice to share some examples of these companies and products for listeners.

Besides well-established hosted PostgreSQL providers that also continue to innovate, AWS, Google Cloud Platform, and Microsoft Azure, startups and smaller companies are pushing the boundaries of what’s possible in PostgreSQL, and customizing it for new niches.

## PostgreSQL startups and small companies

Companies and products like Supabase, Tembo, Neon, Hydra, Crunchy Data, and Nile, to name a few, are innovating and shipping new products built on PostgreSQL.

I’ve had the chance to meet founding engineers and co-founders for some of these companies. Earlier in 2023, Gwen Shapira hosted me on [SaaS for Developers with Gwen Shapira — Postgres, Performance and Rails with Andrew Atkinson 🎙️
](http://andyatkinson.com/blog/2023/08/28/saas-for-developers-gwen-shapira-postgresql-rails).

Since then, Gwen has co-founded and launched [Nile Database](https://www.thenile.dev/), a new database product targeting the challenges SaaS companies face like cost efficiency, data isolation, movement, and more.

Nile Database handles the complexities of multi-tenancy, to free the team up for other challenges.

Another exciting company is [Tembo](https://tembo.io/), which recently announced a fundraising round.

Tembo’s approach is to take PostgreSQL - a general-purpose database - and turn it into a special-purpose offering with [Tembo Stacks](https://tembo.io/docs/category/tembo-stacks/).

Tembo Stacks leverage the extensibility of PostgreSQL, by bundling extensions, parameters, and more, to produce a competitive offering by feature and cost dimensions, that's still “just Postgres” behind the scenes.

For PostgreSQL fans, this is exciting because it means they’re able to leverage their hard-earned knowledge and skills operating PostgreSQL, for types of work that might have otherwise been performed with different database types.

## Topics in PostgreSQL and Rails

In the episode, we dove into specific topics in PostgreSQL and Rails.

- Unlogged tables, and using them in your test environment
- PostgreSQL as a cache store. What’s changed in hardware over the last 10 years that makes this more viable?
- Basics of storage access (input/output or IO), and how storage access relates to query performance
- Adding restrictions to queries to reduce IO, and how that improves performance
- When to invest in performance engineering work

At the end, we touched on a non-tech interest, a sport Jason and I follow, with a fun mini-rivalry between our smaller Midwest-market teams. Can you guess which sport?

## Social shares

- We shared the episode on [/r/rails Reddit](https://www.reddit.com/r/rails/comments/18j7gi0/unleashing_the_power_of_postgres_with_andrew/) where it got some reactions and comments

## Another Remote Ruby PostgreSQL Episode

A week later, a second PostgreSQL-theme Remote Ruby episode dropped, this time featuring Craig Kerstiens!

Craig’s episode is called “Decoding Postgres: A Journey Through User-Friendly Database Experiences” and is a good listen.

How cool to have back-to-back PostgreSQL-themed Remote Ruby episodes!

Check out the episode here 👉 <https://www.remoteruby.com/2260490/14084712-decoding-postgres-a-journey-through-user-friendly-database-experiences-with-craig-kerstiens>


## Wrapping Up

That’s it for now. I appreciated the chance to be a guest on Remote Ruby, and hope the conversation was useful for listeners.

Thanks for checking out the episode, and let us know what you thought.
