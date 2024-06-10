---
layout: post
title: "Podcast: Code and the Coding Coders who Code it! Episode 27 Andrew Atkinson 🎙️"
tags: [Podcasts, PostgreSQL, Ruby on Rails, Open Source]
date: 2023-08-22
comments: true
---

I had the chance to join Drew Bragg on his podcast "Code and the Coding Coders who Code It" and we had a great conversation.

Primarily we talked about my experience over the last year writing a PostgreSQL book aimed at Ruby on Rails developers.

👉 [Episode 27 - Andrew Atkinson](https://podcast.drbragg.dev/episodes/episode-27-andrew-atkinson/)

## Outline

* Book Promotion
* Writing and Coding
* Book Writing
* Balancing Book, Job, Family Commitments
* Technical Topics (Rails)

I met Drew in person at Sin City Ruby 2022 in Las Vegas where he presented *Who Wants to Be a Ruby Engineer?*. Drew's presentation was filled with Ruby trivia and he used a game show style for it and made it really fun.

For his podcast, Drew does a 3-question format that's familiar to software developers.

The questions are: What are you currently working on? Do you have any current blockers? What's something you're currently excited about?

Let's dive in.

## Book Promotion

Part of my goal with the podcast was to promote my upcoming book launch: [High Performance PostgreSQL for Rails](https://pgrailsbook.com).

For one more week I'm sending out summaries of 10 Ruby gems and PostgreSQL extensions mentioned in the book. Subscribers will also get an exclusive discount code from the publisher once the book launches in Beta on August 30, 2023.

If that interests you, please subscribe at 👉 [pgrailsbook.com](https://pgrailsbook.com).

Besides the book, we got into a variety of other topics like writing and editing technical books, and similarities between writing code and prose.

## Writing and Coding

Writing code and writing books have some shared design goals.

* Aim for High cohesion
* Aim for Low coupling

High cohesion in software code means the class or object has a narrow scope. Things in the class go together. In prose a "chapter" should also have clear and single subject matter and all the sections that relate to the chapter.

"Low coupling" when describing objects and classes, refers to minimizing dependencies to other classes or objects. Objects with low coupling can be isolated, tested more easily, or moved in a refactoring stage.

Similarly for prose and Chapters, there shouldn't be a lot of back and forward references to other chapters in the book. I am thinking of this as a form of "coupling".

When I started writing we talked about how I added a lot of references all over the book but it turned out that's worse for the reader. Removing the references was something I learned from the editor Don I've been working with who has been great.

Generally speaking, chapters should stand on their own but also contribute to the overall purpose of the book.

## Book Writing

Regarding writing the book, we didn't discuss this as much in the podcast, but there are a number of other similarities to software development.

* With Pragmatic Programmers, the book is managed like source code and written in Markdown and XML. Changes are checked in to Subversion version control.
* Command line programs are provided and used to “build” PDF versions of the book, and there is a continuous integration server
* In my personal workflow, I use the [Vale command line program](/blog/2023/05/26/better-writing-vale) for spell checking and grammar checking

The flow of writing and editing with these writing tools ends up feeling similar to writing code or creating database examples.

For PostgreSQL, I might pop into psql and create a table and insert some rows, to show how to create an index or how a query uses an Index.

The book uses the same Rails app and PostgreSQL database throughout for examples and exercises.

## Balancing Book, Job, Family

Around the 25 minute mark, we dove more into how the book writing has impacted my personal life.

Drew asked about how I managed the book responsibilities, a full-time job, family responsibilities, and my own personal mental and physical health.

The truth is that over the last year of writing and editing &mash; at times it has been a struggle to keep these responsibilities in balance.

I’ve also let my personal health slide a bit. As the book writing and editing load has lessened, I'm reinvesting more in my personal health and relationships.

I shared some of techniques I use to help mitigate getting overwhelmed or burned out. I write a lot of lists and have a very "scheduled" personal life with family commitments.

I shared a trick I learned from Ryan Bates about getting back into the context of writing or coding as well, where something "easy" is left intentionally unfinished.

The idea is to more quickly pick up the original state by finishing the easy thing, and getting some momentum going.


## Technical Topics

In the last interview question about "something cool", I decided to mention a couple of things from the book I learned that are broadly applicable to Rails developers.

* [Prosopite](https://github.com/charkost/prosopite) - This is a Ruby gem for N+1 detection. Prosopite can be configured to detect the N+1 query pattern. Consider adding this to your Rails app!
* [Strict Loading](https://rubyonrails.org/2020/2/21/this-week-in-rails-strict-loading-in-active-record-and-more) mode in Active Record. Strict Loading can be used to prevent Lazy Loading and require Eager Loading data. This makes the N+1 query pattern impossible. With use of Strict Loading, you may not even need prosopite or have excessive N+1 style queries.

See: [PGSQL Phriday #001 — Query Stats, Log Tags, and N+1s](/blog/2022/10/07/pgsqlphriday-2-truths-lie) for more details on Strict Loading.

## Wrap Up

The episode was a lot of fun and I wanted to thank Drew for the opportunity!
