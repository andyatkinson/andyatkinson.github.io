---
layout: post
title: "PGDay Chicago 2023 Conference"
tags: [PostgreSQL, Open Source, Conferences, Events]
date: 2023-05-24
comments: true
---

I had the chance to present on Table Partitioning this year at [PGDay Chicago 2023](https://2023.pgdaychicago.org), and had a great time. I wanted to recap my experience.

Outline

* Call For Papers
* Dry Run with Crunchy Data
* Pre-conference Activities
- My presentation experience
- The Conference and Venue
- Community and Sessions
* What could have been better?
- Session Slides
- What’s Next

![Presenting at Pg Day Chicago](/assets/images/pgday-chicago-andrew-atkinson-2023.jpg)
<small>Andrew Atkinson Presenting at PGDay Chicago 2023</small>

## Call For Papers
Since the Call for Papers was open back in Winter, and I submitted a proposal based on an upcoming project that I expected to do but wasn't yet done! This motivated me to get the project done. I wanted the talk to be based on real world experience, with the good and the bad, so I was very motivated to get the project done.

This was risky because there were organizational factors beyond my control that could have blocked the project. In the end it worked out but it was down to the wire, as we only completed the project a week before the deadline!

I had also submitted the talk to RailsConf 2023 and unfortunately it was not accepted. This talk was originally intended more for Rails developers. The talk makes the case for how table partitioning helps, and how to perform an online non-destructive conversion using a CLI Ruby gem called pgslice [^pgslice]. Being a Ruby gem codebase, it might be friendlier than a PostgreSQL extension for Rails developers to pick up and customize.


## Dry Run with Crunchy Data
Elizabeth Garrett Christensen ([@sqlliz](https://twitter.com/sqlliz)) and I were messaging and I mentioned doing a dry run. Elizabeth offered to open it up to her team members at [Crunchy Data](https://www.crunchydata.com)!

Elizabeth and I have supported each other with presentation reviews and rubber ducking on PostgreSQL topics, and I really recommending building a community of peer reviewers.

I gave the talk first there and received helpful feedback. Liz also introduced me to [Chris](https://www.crunchydata.com/blog/author/christopher-winslett), [Keith](https://github.com/keithf4), and more team members. Thanks Liz!


## Pre-conference Activities
I arrived the day before and caught up with some [Fountain](https://www.fountain.com) team members in Chicago for lunch and dinner! This was great!

The speaker’s dinner was a nice hang and I appreciated meeting other presenters in a small group setting.


## My Presentation Experience
I felt prepared to give the presentation. It was a big relief to have completed the project that the presentation was based on. 😅 I was excited to share our experience and learn from feedback.

We manage around 10 production databases, but one is 10x the size of the next largest. Although the table partitioning was applied to all 10, the benefits were intended mainly for the large database.

The large database was about 4 TB in size with the unpartitioned table being 1.5 TB and having 2 billion rows.

Once partitioned by month, each child table was around 20 GB in size with around 50 million rows. More manageable.

## The Conference and Venue
The conference was organized well. It’s a 1 day conference with 3 tracks, and jam packed full of content.

Kudos to all the planning that went into it and the staff, signage, organization, timing, everything was very smooth from my perspective.

The [Convene](https://convene.com/locations/chicago/) venue was very nice.

Although I woke up early to exercise and prepare, my `\timing` cut things close. I walked in, set up my laptop, and was announced about 30 seconds later as the next presenter! 😅


## Community and Sessions
At the smaller conferences it's easier to meet people and form new professional relationships.

These relationships have paid off in my career.

One attendee I met and hit it off with was Brian. When Brian said his website was [Brian Likes Postgres]([Brian Likes Postgres](https://www.brianlikespostgres.com/)) I was so excited! Not only does Brian like PostgreSQL (woo!), he’s also an educator and into PostgreSQL advocacy.

I asked Brian to be a Technical Reviewer for my [PostgreSQL for Rails book](https://pgrailsbook.com) and he accepted!

This opportunity would not have happened without PGDay Chicago. Brian is an awesome member of the community and I'm glad we met!

Speaking of great people at the conference, let me highlight some more folks.

- [Alfredo Rodriguez](@AlfredoDrakoRod) (founder of [Wolfgres](https://wolfgres.com)) gave a great talk on High Availability, Disaster Recovery, RTOs and RPOs. Alfredo gave handmade gifts to the presenters from Mexico as well which was very thoughtful!
- [Derk van Veen](https://www.linkedin.com/posts/derk-van-veen-database-specialist_pgday-chicago-adyen-activity-7057618679085031424-qw3J?utm_source=share&utm_medium=member_desktop) spoke just me also on Table Partitioning at the Dutch company [Adyen](https://www.adyen.com/).
- Henrietta, conference organizer, [Chicago PostgreSQL Meetup Group](https://www.meetup.com/chicago-postgresql-user-group), and author! It was nice to catch up a bit with her about writing her book. (Recommended!) [PostgreSQL Query Optimization](https://www.amazon.com/PostgreSQL-Query-Optimization-Ultimate-Efficient/dp/1484268849)
- Stephen Frost and [David Christensen](https://postgresql.life/post/david_christensen/) presented on [Transparent Data Encryption](https://wiki.postgresql.org/wiki/Transparent_Data_Encryption) (TDE). Missed this and need to catch up on this useful capability.
- Phillip Merrick and Denis Lussier have cofounded a new PostgreSQL company called [pgEdge](https://www.pgedge.com), including an open source product [Spock](https://github.com/pgEdge/spock). Really interesting challenges being solved in PostgreSQL at the network edge, using multi-active architecture and Logical Replication.
- [Michael Banck](https://twitter.com/mbanck/status/1649104464698015748) gave a talk on HA and Patroni deployment patterns. Michael is also a Prince fan and was interested to know that [Paisley Park](https://www.paisleypark.com) is now a museum open to visitors here in Minnesota!
- Jimmy gave a fun talk on ["Don't Do This"](https://postgresql.us/events/pgdaychicago2023/sessions/session/1206-dont-do-this/) in PostgreSQL.
- I met the Community Slack legend [Robert Treat](https://www.linkedin.com/in/robtreat/)!
- [Lætitia](https://twitter.com/l_avrot) gave a fun talk exploring advanced PostgreSQL concepts by solving Advent of Code puzzles.
- Bruce Momjian gave an amazing introduction to [Window Functions](https://www.postgresql.org/docs/current/tutorial-window.html).

See the [full schedule](https://postgresql.us/events/pgdaychicago2023/schedule/).

## What could have been better?
I thought everything about the conference was excellent. My only suggestion would be to record the sessions if there is a budget and resources to do so. I'd happily give my consent.

As a presenter, I'd like having recorded talks that I can share online to help grow my presence and credibility. Since PGDay Chicago was a multi-track conference, I also could only pick one session per time slot and without recorded sessions, can't go back and see the ones I missed.

## Slides

I do have the slides posted and would love feedback. Please leave a comment or [contact me](/contact).

Use the short link <http://bit.ly/PartPG2023> [^bitly] for the slides. Download the PDF for links. Search Twitter with [#PartPG2023](https://twitter.com/search?q=PartPG2023) to find tweets. The slides are also embedded below!

## What’s next
* I’m going to keep telling people how awesome PostgreSQL Declarative Partitioning is, and why developers should use it more. With PostgreSQL 16 coming up later this year, I’m curious to see if there are more enhancements on the way.
* I’m working on more proposals and hope to present or attend another conference with these same organizers, they did a great job!

And while I have your attetion: I'm writing a book called [High Performance PostgreSQL for Rails](https://pgrailsbook.com) to be published by [Pragmatic Programmers](https://pragprog.com) in 2023. Please subscribe to get more information!

Thanks!

[^pgpart]: <https://github.com/pgpartman/pg_partman>
[^pgslice]: <https://github.com/ankane/pgslice>
[^bitly]: <http://bit.ly/PartPG2023>

<iframe class="speakerdeck-iframe" frameborder="0" src="https://speakerdeck.com/player/8c1c25764d7d4158b89556c998c141f1" title="Partitioning Billions of Rows Without Downtime" allowfullscreen="true" style="border: 0px; background: padding-box rgba(0, 0, 0, 0.1); margin: 0px; padding: 0px; border-radius: 6px; box-shadow: rgba(0, 0, 0, 0.2) 0px 5px 40px; width: 100%; height: auto; aspect-ratio: 560 / 314;" data-ratio="1.78343949044586"></iframe>
