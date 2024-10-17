---
layout: post
permalink: /rails-world-2024-conference-recap
title: 'Rails World 2024 Conference Recap'
tags: [Ruby on Rails, Ruby, PostgreSQL, Conferences]
comments: true
date: 2024-10-17
image: assets/images/rw2024/rw-10.jpeg
---

This is Part 1 of my Rails World 2024 Conference Recap, a phrenetic two-day event in Toronto, Canada in September 2024.

In this post, I'll describe some sessions from Day 1, and non-session activities outside of that! In Part 2, I'll cover more of the sessions I missed once I've watched the recordings!

As a book author and consultant, the focus for Rails World for me was on meeting people, raising awareness about my book, and generally chatting about how people are using Postgres and Rails. As a long-time Ruby community member, it was great to catch up with a lot of industry friends.

As a first time Rails World visitor, I was really impressed with the energy and vibes.

Let's get into it.

## Arrival - Wednesday

🇨🇦 I Landed in Toronto after a short two hour flight from Minneapolis. I was feeling excited to promote my book, meet attendees, and give away 8 copies over the next few days. I was feeling grateful!

![Rails World Conference 2024](/assets/images/rw2024/rw-1.jpeg)
<small>Landed in Toronto, let's go!</small>

To celebrate my book launch and successfully striking out on my own as an independent Postgres and Rails consultant,
I hosted a happy hour gathering of [Postgres Fans](https://lu.ma/0f7ly7g5). We had a good turnout, conversations, and new and strengthened connections. We didn't talk about Postgres much, but the event was a success! 🙌

![Rails World Conference 2024](/assets/images/rw2024/rw-2.jpeg)
<small>Party time, Postgres fans Happy Hour at The Queen & Beaver Public House</small>

This was my first time hosting an event like this. I was able to sponsor a round of drinks and appetizers thanks to the success in book sales and my consulting business.

It felt great to bring folks together and I appreciated everyone coming out!

Afterwards, most of the group walked over to the Shopify pre-registration event to get badges, hang out, and grab dinner.

![Rails World Conference 2024](/assets/images/rw2024/rw-7.jpeg)
<small>Pre-registration party by Shopify, with John and Jesper</small>

## Conference Day 1 - Thursday

In the kick-off, I appreciated the overview of the Rails Foundation activities, and was excited to see my GitHub handle up on screen briefly along with some friends! In the last year, I made some contributions to the Rails Guides, particularly in the Active Record area. It was a nice surprise to be mentioned!

<blockquote class="twitter-tweet"><p lang="en" dir="ltr">Have to zoom way in 🔍 but honored to see my GitHub handle listed as a contributor to Rails Guides, an important effort lead by awesome people like <a href="https://twitter.com/Ridhwana_K?ref_src=twsrc%5Etfw">@Ridhwana_K</a> <a href="https://t.co/LMrcF307ZN">pic.twitter.com/LMrcF307ZN</a></p>&mdash; Andrew Atkinson (@andatki) <a href="https://twitter.com/andatki/status/1839632502723326236?ref_src=twsrc%5Etfw">September 27, 2024</a></blockquote> <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>

## Session: DHH Keynote

David’s keynote was good. It was a bit of storytelling and individual positions and perspectives, with occasional splashes of tech stuff mixed in. Entertaining! I always appreciate the live demos too.

David announced Rails 8 Beta 1 is now shipping, and even 8.1 was on the horizon. The technical work over the last year made this possible. Earlier this summer, I wrote for AppSignal about new [database related functionality in Ruby on Rails 7.2](https://blog.appsignal.com/2024/07/24/whats-coming-in-ruby-on-rails-7-2-database-features-in-active-record.html?utm_source=blogpost&utm_medium=twitter&utm_campaign=2024-07-24).

I left the keynote with a call to action to be more competent in our roles as software engineers. Although it wasn’t said exactly, I wondered how much of this message was in response to the rise of AI-assisted programming, which has raised the floor perhaps on what's expected from a modern professional software engineer.

## Session: Postgres at Instacart

I was happy this session made it onto the agenda, given that [PostgreSQL is the most popular database used by Rails developers](https://railsdeveloper.com/survey/2024/#databases), and this was the only Postgres related session at RailsWorld.

Attendance was good. Mostafa took on a challenging task, covering advanced concepts in a short period of time, and did a great job. A highlight for me was meeting Mostafa afterwards. I didn’t know Mostafa was a contributor to PgCat, which was cool to find out. Mostafa talked about different approaches they'd used at Instacart over the years from vertically scaling, to replication and routing read queries to replicas, and forms of database sharding.

Note from me: Remember that Active Record natively supports [automatic Read and Write query routing](https://guides.rubyonrails.org/active_record_multiple_databases.html#activating-automatic-shard-switching), and [Horizontal Sharding](https://guides.rubyonrails.org/active_record_multiple_databases.html#horizontal-sharding).

Mostafa covered the [Makara gem](https://github.com/instacart/makara), and briefly the benefits of the [PgCat connection pooler](https://github.com/postgresml/pgcat) over [pgbouncer](https://www.pgbouncer.org).

![Rails World Conference 2024](/assets/images/rw2024/rw-3.jpeg)
<small>Mostafa from Instacart. Scaling Postgres, replication, sharding, PgCat.</small>

## Session: Fireside Chat DHH, Matz, Tobi

This was interesting to see. I knew Matz didn't normally attend Ruby on Rails conferences, so it was exciting to see him attending. I should have taken the opportunity to ask for a picture, but did see plenty of others walking around getting pictures with Matz. Great for the community to see the heroes in person!


## Event: Rails Startups With Evil Martians and Whop

This was a fun event! I appreciated being invited by Irina. I had the chance to meet Jack from [Whop](https://whop.com). Met a lot of other folks in person like [Kir](https://kirshatrov.com), Miles, Yaroslov from [SupeRails](https://superails.com), hung out more with [John](https://www.johnnunemaker.com). Great vibes!

## Conference Day 2 - Friday

On Day 2, the highlight and emphasis for me was Book Signing, handing out books, and talking Postgres + Rails!

![Rails World Conference 2024](/assets/images/rw2024/rw-14.jpeg)
<small>Book Signing at Rails World 2024</small>

Although it was meant to be a 1 hour session from 12pm - 1pm over the lunch period, I was able to meet a lot of people before and after, to generally chat about the book, Postgres, Rails, and hung out for much longer, missing even more sessions (but totally worth it)!

Since Day 2 was filled with meeting people, I'd like to leave you with more pictures. I got more selfies and pictures here than I'd normally do, and I'm really thankful for that. The pictures help me remember all these amazing people in the community, and it's an honor to have spent a bit of time with them.

<blockquote class="twitter-tweet"><p lang="en" dir="ltr">I got a signed copy of High Performance PostgreSQL for Rails from <a href="https://twitter.com/andatki?ref_src=twsrc%5Etfw">@andatki</a> himself! I had read early versions of the book and can comfortably place this book in the “classics” shelf of my library. This is a must-read! <a href="https://twitter.com/hashtag/RailsWorld?src=hash&amp;ref_src=twsrc%5Etfw">#RailsWorld</a> <a href="https://t.co/zUY35TvEiA">pic.twitter.com/zUY35TvEiA</a></p>&mdash; Emmanuel Hayford (@siaw23) <a href="https://twitter.com/siaw23/status/1841488680759804329?ref_src=twsrc%5Etfw">October 2, 2024</a></blockquote> <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>

![Rails World Conference 2024](/assets/images/rw2024/rw-4.jpeg)
<small>Book giveaway winners, Wojciech, Matt</small>

![Rails World Conference 2024](/assets/images/rw2024/rw-5.jpeg)
<small>Book giveaway winners, Allison</small>

![Rails World Conference 2024](/assets/images/rw2024/rw-6.jpeg)
<small>Book giveaway winners, Bart</small>

![Rails World Conference 2024](/assets/images/rw2024/rw-8.jpeg)
<small>Book winners: Ridhwana</small>

## More Pics and Selfies

![Rails World Conference 2024](/assets/images/rw2024/rw-9.jpeg)
<small>With Jesper</small>

![Rails World Conference 2024](/assets/images/rw2024/rw-10.jpeg)
<small>With Emmanuel</small>

![Rails World Conference 2024](/assets/images/rw2024/rw-11.jpeg)
<small>With Dan</small>

![Rails World Conference 2024](/assets/images/rw2024/rw-12.jpeg)
<small>With Julia and Jorge</small>

While waiting for a car to the airport, I had a serendipitous opportunity to join Craig Kerstiens from [Crunchy Data](https://www.crunchydata.com) for a shared ride. Obviously we talked about Postgres!

![Rails World Conference 2024](/assets/images/rw2024/rw-13.jpeg)
<small>With Craig</small>

Rails World 2024 was a blast. Thank you to everyone involved in putting this event on. If we met at Rails World, I hope I've reached out to you on social media by now, but if not, please drop me a line. Let's stay in touch.

## Capping off Ruby events in 2024

I've been privileged to attend a lot of Ruby events and be a guest on podcasts this year, to promote my consulting services and my book. Rails World sort of capped it off for me, as I don't have plans for any more Ruby events in 2024. I'm thinking about 2025 though!

2024 was my first year striking out on my own as an independent consultant. Thank you to all the clients, colleagues, and friends that have helped me make it work. I've got a lot to be thankful for, and I'm excited to keep it going in 2025!

I'd like to briefly look back at the year by sharing some links to past podcasts, conferences, and other content. Thanks for taking a look.

- [Madison+ Ruby 2024 Conference Recap](/blog/2024/08/13/madison-plus-ruby-conference-recap)
- [SaaS on Rails on PostgreSQL — POSETTE 2024](/blog/2024/07/13/SaaS-on-Rails-on-PostgreSQL-POSETTE-2024-andrew-atkinson)
- [🎙️ IndieRails Podcast — Andrew Atkinson - The Postgres Specialist](/blog/2024/06/10/indierails-podcast-andrew-atkinson-postgres)
- [Top Five PostgreSQL Surprises from Rails Devs](/blog/2024/05/28/top-5-postgresql-surprises-from-rails-developers)
- [🎙️ Ship It! Podcast — PostgreSQL with Andrew Atkinson](/blog/2024/05/21/shipit-podcast-changelog-andrew-atkinson)
- [RailsConf 2024 Conference — The Long Goodbye](/blog/2024/05/17/railsconf-conference-2024-detroit)
- [Mastering PostgreSQL for Rails: An Interview with Andy Atkinson](/blog/2024/07/01/mastering-postgresql-phil-smy-andrew-atkinson)
- [Sin City Ruby 2024](/blog/2024/03/25/sin-city-ruby-2024)
- [Rails + Postgres Postgres.FM 086 — Extended blog post edition! 🎙️](/blog/2024/03/07/postgresfm-podcast-rails-plus-postgres)
- [Maintainable Podcast — Maintainable…Databases? 🎙️](/blog/2024/02/19/maintainable-podcast-robby-russell-andrew-atkinson-maintainable-databases)
- [Remote Ruby — Unleashing the Power of Postgres with Andrew Atkinson 🎙️](/blog/2024/01/05/Remote-Ruby-unleashing-power-postgresql-andrew-atkinson)
- [The Rails Changelog — #014: PostgreSQL for Rails Developers with Andrew Atkinson 🎙️](/blog/2024/01/05/Rails-Changelog-Podcast-014-PostgreSQL-Rails-andrew-atkinson)
