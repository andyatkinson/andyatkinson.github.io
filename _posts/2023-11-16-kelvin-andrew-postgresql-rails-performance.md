---
layout: post
title: "Teach Kelvin Your Thing (TKTY) — High Performance PostgreSQL for Rails 🖥️"
tags: [Open Source]
date: 2023-11-16
comments: true
---

I was honored to join [Kelvin Omereshone](https://dominuskelvin.dev), based in Nigeria, on his show *Teach Kelvin Your Thing* (TKYT). What's that?

> **Teach Kelvin Your Thing** was created out of a need for me to learn not just new technologies but how folks who know these technologies use them.

Kelvin has more than 50 sessions recorded, and they all focus on JavaScript and web development, until this one! Kelvin let me know this was the first TKYT session that wasn't based on JavaScript technologies. Maybe we'll inspire some more people to try Ruby!

Besides being a podcaster, Kelvin is a prolific blogger, YouTuber, producer, writer, and an upcoming author! As an experienced **Sails framework** programmer, Kelvin also was honored recently by becoming the [*lead maintainer of the project*](https://twitter.com/Dominus_Kelvin/status/1669063700144070662). 🥳

Kelvin and decided to talk about *High Performance PostgreSQL with Rails*. We recorded a session together, and my only regret is that my fancy microphone wasn't used for the recording. With my apologies for the audio on my side, I hope some people still find the content useful! 😅

Check out *High Performance PostgreSQL for Rails applications with Andrew Atkinson* on YouTube below. We barely scratched the surface of the topic suggestions Kelvin had. Learn more about those below.

<iframe width="560" height="315" src="https://www.youtube.com/embed/90pWCR9O10Q?si=O_1n4P8qBQC0-rEt" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" allowfullscreen></iframe>

## Q&A

Prior to the session, Kelvin and I discussed a lot of possible questions to cover. With a one hour session, we only made it through a few.

I decided to write out some answers to Kelvin's questions. We may cover these in a future session!

#### How do you optimize PostgreSQL for high performance in a Rails application?

Achieving and sustaining high performance for a web application, requires deliberate and focused effort on eliminating latency from anywhere possible in the request and response cycle. For the database portion, to do that you'll want to understand your queries well, and make sure they're narrowly scoped, that your indexes support your queries, and that the physical server instances have appropriate sizes for CPU, memory, and disk.

While there are dozens of things to check, if I had to choose one thing to focus on, I'd recommend focusing on writing efficient queries. Developers can write efficient queries, but they'll need to learn SQL, the query planner, and how to use indexes well. They'll need to understand their data model and the distribution of the data. They'll need to understand how the PostgreSQL query planner interprets their queries. This is a lot to learn, but it can be learned over time.


#### Can you share specific strategies for indexing tables to improve query performance?
While adding indexes is straightforward, getting them to be really efficient across all of your queries requires broad visibility and diligence. There are whole books about this topic, and there are consultants that can help you out (contact me). The gist is that you'll want to study your queries, learn how the query planner works, and then you can start optimizing and iterating. Indexes are data structures for fast retrieval, that help your queries run quickly. Indexes are where you want your queries to read from.


#### What database design considerations are crucial for achieving optimal performance with PostgreSQL in a Rails environment?

Try to "Keep it simple", by using traditional approaches. Prefer "simple data types" over complex ones. Consider denormalization when it makes sense. Have a sensible number of columns. Avoid tables that are super wide. Only add indexes when they're needed by queries.

When querying data, think about any aspect of the query where you can filter down further, to minimize storage accesses. Try and use data types that can be sorted like numerical types.

When you're using PostgreSQL for web applications, you'll want to minimize the IO needed (storage access) for your query. The database can help you enforce referential integrity too. You can also use PostgreSQL for storing huge blobs of text, up to 1GB, or JSON data. This works but there are performance trade-offs.


#### Are there common pitfalls developers face when working with PostgreSQL in a high-performance Rails application?

Yes. Pitfalls in Rails might be avoiding learning SQL, how to use indexes, or the query planner. If you have a need to improve performance on your server instance, without spending more money for a large one, you'll need to dive into the SQL queries, indexes, and the query planner at a minimum.


#### How do you handle large datasets efficiently, and what tools or techniques do you recommend for database maintenance in such scenarios?
To better handle very large individual tables within PostgreSQL, table partitioning provides a lot of benefits. For maintenance on very large databases, you'll want to learn about Autovacuum, the effects of high levels of bloat, and how to eliminate it. Common maintenance operations are Vacuum, Analyze, and Reindex. Maintenance concerns aren't usually affecting operations until your database is very large, and it's serving a high amount of queries.


#### Could you discuss the impact of caching mechanisms on PostgreSQL performance, particularly in the context of a Rails application?
PostgreSQL has caching concepts built in. For Ruby on Rails, you'd want to leverage built in cache stores. <https://guides.rubyonrails.org/caching_with_rails.html>


#### What are some advanced features or settings in PostgreSQL that developers may not be fully leveraging for performance gains in a Rails project?
Developers may not be leveraging Full Text Search (FTS) in PostgreSQL, which can be used for fuzzy searching. PostgreSQL also supports vector similarity search, to use algorithms and indexes to find similar text that's been "embedded" using Large Language Model APIs.

PostgreSQL supports native Table Partitioning, which helps you break up very large tables into more management pieces.


#### How do you approach query optimization? Are there specific query patterns that developers should be mindful of for better performance?
Try and minimize data access as much as possible. Join fewer tables, select from less tables, and select fewer columns.


#### Can you share experiences or examples where database sharding or partitioning has significantly improved performance in a Rails application using PostgreSQL?
Sharding splits up the work that would happen on one server instance, into multiple. When you need to isolate the data, or isolate a single customer from the other customers, "sharding" your database by placing a customer into their own database, running on a separate instance, is a common and powerful technique.

Replication is a built in concept as well, and it can be a critical way to scale up read only queries, by running read only queries on separate read replica instances.


#### Given the evolving landscape of PostgreSQL and Rails, are there any recent advancements or features that developers should be aware of to enhance performance?
Both are mature frameworks, and after decades of investment, there are fewer earth shattering features these days. Ruby on Rails is known for productivity, there's been a renewed focus on how much work an individual developer can get done with Ruby on Rails, which is still a MVC full-stack framework.

PostgreSQL continues to release new features with an annual release cadence, but as core system software, it's critical that it continues it's long track record of reliability, durability, and resilience. While these features aren't related directly to performance, Active Record continues to integrate features like Common Table Expressions (CTE) and Composite Primary Keys (CPK), that are important for larger teams and organizations to have, and are now natively supported within the framework.


## Wrap Up

Thanks!



## Links

- Rideshare app: <https://github.com/andyatkinson/rideshare>
- Ruby on Rails Documentary: <https://www.youtube.com/watch?v=HDKUEXBF3B4>
- Rails World conference: <https://rubyonrails.org/world>
- Rails World 2023 Recorded YouTube session playlist: <https://www.youtube.com/playlist?list=PLHFP2OPUpCeY9IX3Ht727dwu5ZJ2BBbZP>
- Learning PostgreSQL: <https://www.postgresql.org/docs/online-resources/>
- Caching in Rails: <https://guides.rubyonrails.org/caching_with_rails.html>