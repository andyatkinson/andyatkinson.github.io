---
layout: post
title: "Code and the Coding Coders who Code it! Episode 27 Andrew Atkinson 🎙️"
tags: [Podcast]
date: 2023-08-22
comments: true
---

I had the chance to join Drew Bragg on his podcast "Code and the Coding Coders who Code It" and we had a great conversation.

👉 [Episode 27 - Andrew Atkinson](https://podcast.drbragg.dev/episodes/episode-27-andrew-atkinson/)

## Outline

* Book Promotion
* Writing and Coding
* Book Writing
* Balancing Book, Job, Family Commitments
* Technical Topics (Rails)

I met Drew in person at Sin City Ruby 2022 in Las Vegas where he presented *Who Wants to Be a Ruby Engineer?*.

This presentation is filled with Ruby trivia and Drew uses a game show style and really makes it fun.

For his podcast, Drew does a 3-question format that's familiar to software developers.

What are you currently working on, any current blockers you have, and what are you currently excited about?

## Book Promotion

Part of my goal with the podcast was to promote my upcoming book launch: [High Performance PostgreSQL for Rails](https://pgrailsbook.com).

For one more week I'm sending out summaries of 10 Ruby gems and PostgreSQL extensions mentioned in the book. Subscribers will also get an exclusive discount code from the publisher once the book launches in Beta.

If that interests you, please subscribe at 👉 [pgrailsbook.com](https://pgrailsbook.com).

Besides the book, we got into a variety of other topics like writing and editing technical books, and the similarities between writing and refactoring code and writing and refactoring prose.

## Writing and Coding

Writing code and writing books have some shared design goals.

* Aim for High cohesion
* Aim for Low coupling

High cohesion means the class, object, or in prose the "chapter" has a clear and single purpose.

Low coupling means there are few dependencies to other classes, objects, or in the case of Chapters, there aren't a mess of back and forward references.

Chapters can stand on their own but also make sense as part of a whole. I don't know if I achieved that, but I tried!

## Book Writing

Regarding writing the book, we talked about a number of topics.

* Writing for Pragmatic Programmers
* Writing is done in Markdown and changes are checked in using Subversion version control.
* Command line programs are used to “build” PDF versions
* I also use Vale for command line spell checking and grammar checking.

The flow of these writing tools can feel similar to writing code at times.

## Balancing Book, Job, Family

Around the 25 minute mark, we dove more into how the book writing has impacted my personal life.

Drew asked about how I managed the book responsibilities, a full-time job, family responsibilities, and my own personal mental and physical health.

Sometimes I have struggled to keep these things in balance, particularly as work became busier, or challenges emerged with childcare or other family responsibilities.

I’m also somewhat on a journey now to improve my personal physical and mental health a bit which I let slide over the last year.

## Technical Topics

In the "what’s cool" section I wanted to mention a couple of things that any Rails project could use.

* [Prosopite](https://github.com/charkost/prosopite) Ruby gem for N+1 detection. This is covered in the book. This can be set up to automatically detect the N+1 query pattern.
* [Strict Loading](https://rubyonrails.org/2020/2/21/this-week-in-rails-strict-loading-in-active-record-and-more) mode in Active Record. This can be enabled in specific call locations to prevent Lazy Loads and require Eager Loading data. When data is eager loaded the N+1 query pattern is not possible. This is covered in the book and I blogged about it as well.

See: [PGSQL Phriday #001 — Query Stats, Log Tags, and N+1s](/blog/2022/10/07/pgsqlphriday-2-truths-lie) which covers Strict Loading

Thanks!
