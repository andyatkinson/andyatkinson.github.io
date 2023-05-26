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

I had also submitted the talk to RailsConf 2023 and unfortunately it was not accepted. This talk was originally intended more for Rails developers. The talk makes the case for how table partitioning helps, and how to perform an online non-destructive conversion using a CLI Ruby gem called pgslice [^pgslice]. Being a Ruby gem codebase, it might be friendlier than a PostgreSQL extension for Rails developers to pick up and customize if needed.


## Dry Run with Crunchy Data
Elizabeth Garrett Christensen ([@sqlliz](https://twitter.com/sqlliz)) and I were messaging and we discussed doing a dry run, and opening it up to her team members at [Crunchy Data](https://www.crunchydata.com)!

Elizabeth and I have supported each other with presentation reviews and rubber ducking on PostgreSQL topics.

I gave the talk first there and received helpful feedback. Liz also introduced me to Chris, Keith, and other team members. Thanks Liz!


## Pre-conference Activities
I arrived the day before and caught up with some co-workers in Chicago for lunch and dinner! This was great!

The speaker’s dinner was a nice hang and I appreciated meeting other presenters in a small group setting.


## My Presentation Experience
I felt prepared to give the presentation. It was a big relief to have completed the project that the presentation was based on 😅 and I was excited to share our experience.

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

This opportunity would not have happened without PGDay Chicago. Brian is awesome member of the community and I'm glad we met!

Let me highlight some more of the great people at the conference.

- Alfredo (founder of [Wolfgres](https://wolfgres.com)) gave a great talk on High Availability, Disaster Recovery, RTOs and RPOs. Drako gave handmade gifts to the presenters from Mexico as well which was very thoughtful!
- [Derk van Veen](https://www.linkedin.com/posts/derk-van-veen-database-specialist_pgday-chicago-adyen-activity-7057618679085031424-qw3J?utm_source=share&utm_medium=member_desktop) spoke after me on his experience using Declarative Partitioning at [Adyen](https://www.adyen.com/).
- Henrietta, conference organizer, [Chicago PostgreSQL Meetup Group](https://www.meetup.com/chicago-postgresql-user-group), and author! Buy her book (Recommended!): [PostgreSQL Query Optimization](https://www.amazon.com/PostgreSQL-Query-Optimization-Ultimate-Efficient/dp/1484268849)
- Stephen Frost and David Christensen presented on [Transparent Data Encryption](https://wiki.postgresql.org/wiki/Transparent_Data_Encryption) (TDE).
- Phillip Merrick and Denis Lussier. They're cofounders of a new company called [pgEdge](https://www.pgedge.com) and PostgreSQL open source product [Spock](https://github.com/pgEdge/spock). Really interesting challenges being solved in PostgreSQL at the network edge, using multi-primary architecture, and Logical Replication.
- Michael - HA and Patroni, Michael is also a Prince fan and interested to know that Paisley Park is a museum open to visitors here in Minnesota!
- Jimmy gave a fun talk on ["Don't Do This"](https://postgresql.us/events/pgdaychicago2023/sessions/session/1206-dont-do-this/) in PostgreSQL.
- I met the Community Slack legend [Robert Treat](https://www.linkedin.com/in/robtreat/)!

See the [full schedule](https://postgresql.us/events/pgdaychicago2023/schedule/).

## What could have been better?
I thought everything about the conference was excellent. My only suggestion would be to record the sessions if there is a budget to do so.

As a presenter, I'd like to have the talk recorded so that I can share it online, as I'm trying to grow my presence and credibility. Since PGDay Chicago was a multi-track conference, I could only pick one session per slot, so having recordings for the sessions I missed to see later would be nice.

## Slides

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
