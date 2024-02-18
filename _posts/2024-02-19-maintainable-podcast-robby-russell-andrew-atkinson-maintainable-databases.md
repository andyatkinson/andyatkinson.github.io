---
layout: post
title: "Maintainable Podcast — Maintainable…Databases? 🎙️"
tags: [PostgreSQL, Podcast, Ruby on Rails]
date: 2024-02-19
comments: true
---

Recently I appeared as a guest on the [Maintainable Podcast with Robby Russell](https://maintainable.fm/). I’ve admired this podcast for a long time based on the guests, conversations, and focus on software maintenance.

Much of what a software engineer does is evolve and maintain existing systems. I’m glad Robby created this podcast to explore maintenance topics, and has gathered the perspectives of many practitioners.

## What is Maintainable Software?

Robby starts each episode by asking the guest what maintainable software is in their perspective.

I wanted to give an authentic response and avoid cliches, and hopefully provide something original and tangible.

My answer was that “the level of effort required should be proportional to the impact.” Despite attempting for this to be an original answer, I probably read it in some software book earlier. But this is definitely something I’ve “felt” when it’s not going well.

By making a change, I’m referring to the whole process of writing the code, writing a test or otherwise verifying the correctness, then getting the change released to production.

While this might sound simplistic, in my experience this can be a complex challenge when processes and systems make this seemingly simple set of steps exceedingly tedious.

What are some of the ways that happens? Having a development environment that’s difficult to initially set up and maintain, having a test suite that’s unreliable and slow, having an onerous code review process, or having a slow or unreliable release process, are all some of the ways.

Check out the podcast for more on this!

## Well Maintainable Databases

Although guests on the podcast normally talk about software maintenance related to the software and code they maintain, given my background with databases, why not consider what a well-maintained database that we operate could look like? We discussed this in part by discussing some undesirable things we might find in a production system.

- Is the database software a recent major version? If not, there’s security patches, performance improvements, and significant features that aren’t being leveraged.
- How is the data described and how is correctness enforced? To do that, we use database-level constraints, and they need to be created by the database user. When constraints are very limited or not present at all, which can happen in my experience, this *could* indicate poorer quality data.  Of course, we can also perform data quality and consistency checks from the application, but they can’t offer the same consistency guarantees that database constraints do. While correlational, I’ve noticed the constraints and database features in general, tends to be correlated with better maintained databases.


- Let’s consider the data within the DB. What are the proportions of unused content like? By content we could consider table rows, indexes, or even whether entire tables have been abandoned by the application, but not removed. We wan’t minimal amounts of unused or inactive content. Tables and indexes and other database objects that aren’t providing any value consume space, lengthen backups and restores, and can add query latency, which negatively affects user experience. A well maintained database would has a low percentage of unused content.


- When using unstructured data like schemaless or JSON formatted content, we’re working without the structure or formality of traditional data types and constraints. PostgreSQL allows us to store a “grab bag” of data in columns. While PostgreSQL allows us to do this, that doesn’t mean we can’t also add some structure and constraints to JSON formatted data. I’ve got recommendations here, but you’ll have to listen to the podcast to learn them!


## Why write this book?

I wrote a book called High Performance PostgreSQL for Rails, that’s been in early-release Beta since late last year, and is currently in production, headed to physical print form in the next few months! (Very exciting!)

Why did I write this book?

- PostgreSQL and Ruby on Rails are very mature and practical technologies that have stood the test of time. They are a powerful combination for building web applications. Having used them for more than a decade at many companies, I wanted to share my experience with them and advocate for their use.
- Another part of why I wrote this book is that I enjoy writing and building my skills as an educator, and this was a great opportunity to do that! Prior to this, I’ve never written something that’s as long or involved as an entire book.
- I’ve liked mentorship and educator opportunities I’ve taken on in the past, including being a [Section Leader for Code In Place in 2021](https://andyatkinson.com/events-and-volunteering), and serving as a mentor at my last employer.
- I wondered if this book might open doors for me for a next job, a promotion, new opportunities, or new challenging projects. I hoped this book could serve that same purpose for readers, growing their engineering career prospects as they acquired new practical skills for their jobs. 

- I felt I had a unique combination of skills with the database and writing code. I’d also worked on very high scale PostgreSQL and Rails applications, in particular at a past job at Microsoft. I’ve also worked with a dedicated database administrator and learned a lot from them, especially what kinds of things they value and how they solve challenges. I’ve worked with many app devs and countless Rails apps over a decade, and wanted to bring in some of the common libraries and patterns I’ve used and found valuable. 

## PostgreSQL and Ruby on Rails

PostgreSQL and Ruby on Rails have longevity, as they’ve attracted a large and renewable open source contributor base that’s improving the core, while also both being very extensible and benefitting from new features and capabilities from open source contributions.

In Ruby that’s the RubyGems system of gem shared libraries.

In PostgreSQL that’s mostly extensions that can hook into PostgreSQL at various points and add behavior, or can be used as a distribution mechanism for sets of functions and behaviors. The PostgreSQL ecosystem also has a lot of growth in forks or PostgreSQL-compatible databases that are expanding the boundaries of what folks might expect from their database system. 



## Unshipping

Getting back to software systems, we also talked about the concept of Unshipping, which means strategic removal of features from systems that aren’t providing enough value, and where removing them helps with maintenance and focus in a long term sense.

The best resource on this I’ve read is the Mixpanel blog post called "The art of removing features and products"[^2] that discusses what mission and vision alignment means, and sometimes identifying underperforming feature areas that aren’t aligned with those things, and intentionally bringing them to an end.

How does Unshipping help with software maintenance?

- The more features and code there is, the more difficult it is to make changes

- Besides direct software we depend on, we have so-called "transitive" dependencies, which are the dependencies of our dependencies. In long-lived open-source software systems that use a lot of open-source libraries, there is a continual challenge to update versions of dependencies based on patches that fix security issues, and this has a cascading effect on other dependencies 

- When removing things, when dependencies are difficult to maintain for developers in their local environments, or in other pre-production environments, we can improve their ability to work efficiently by simplifying the system. We want to preserve that proportional amount of effort to ship changes.

- For a SaaS product that has recurring billing vs. pay once, we’re paying on ongoing cost, possibly per-transaction costs or licensing costs, for subscription services we depend on. To maximize profit margins, we want to keep our platform costs as low as possible and make sure they reflect high-value capabilities.

<blockquote class="twitter-tweet"><p lang="en" dir="ltr">Robby &amp; Andrew Atkinson dive into everything from optimizing database performance with rules to navigating the tricky terrain of advocating for codebase improvements among reluctant stakeholders.<br><br>🎧 Tune in at <a href="https://t.co/GkqJxY57gR">https://t.co/GkqJxY57gR</a><a href="https://twitter.com/hashtag/technicaldebt?src=hash&amp;ref_src=twsrc%5Etfw">#technicaldebt</a> <a href="https://twitter.com/hashtag/legacycode?src=hash&amp;ref_src=twsrc%5Etfw">#legacycode</a> <a href="https://twitter.com/hashtag/technicalpodcast?src=hash&amp;ref_src=twsrc%5Etfw">#technicalpodcast</a> <a href="https://t.co/UFaYfgJtAh">pic.twitter.com/UFaYfgJtAh</a></p>&mdash; Maintainable Software Podcast (@_maintainable) <a href="https://twitter.com/_maintainable/status/1750579772319510589?ref_src=twsrc%5Etfw">January 25, 2024</a></blockquote> <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>


## How to Unship

One of the most impactful things we added to our stack of tools to help remove unused code was setting up instrumentation of the codebase with the Coverband[^1] project. Coverband tracks when lines of code are executed, and persists that information into Redis. Using that instrumentation data with our production systems, we can collect information about which code is called, and critically, which code is *not* called.

We can cross-reference that with APM data from a system like Data Dog. For example, if we see lines of code within classes aren’t invoked at all, we can confirm that the API endpoint caller code was also not invoked. Once some time has passed, we’re quite confident this code can be retired and removed. From that point we can fully unship it including documentation, altering customers, providing alternatives when appropriate and more.

We successfully used Coverband to remove thousands of lines of code from dozens of PRs to our core monolith, representing many features that had been abandoned over time, in a codebase which had around 100K LOC. From those removals we also removed many dependencies. We got knock-on benefits by simplifying the system too, like improving the speed and reliability of the test suite, which helps us review and release changes faster.

## Listen to the episode

<!-- Callout box -->
<section>
<div style="border-radius:0.8em;background-color:#eee;padding:1em;margin:1em;color:#000;">
<h2>Podcast</h2>
<p>👉 <a href="https://maintainable.fm/episodes/andrew-atkinson-maintainable-databases">Listen to the episode</a></p>
</div>
</section>


[^1]: <https://github.com/danmayer/coverband>
[^2]: <https://mixpanel.com/blog/upsides-to-unshipping-the-art-of-removing-features-and-products>


## Thanks

Thanks Robby for having me on! I hope listeners find some useful tidbits in the podcast.
