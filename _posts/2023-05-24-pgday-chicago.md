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
* Pre-conference
- My presentation experience
- The conference and venue
* What could have been better
- What’s next

![Presenting at Pg Day Chicago](/assets/images/pgday-chicago-andrew-atkinson-2023.jpg)
<small>Andrew Atkinson Presenting at PGDay Chicago 2023</small>

## Call For Papers
The Call for Papers was open way back in the Winter, and I submitted a proposal based on a project I expected to do, but hadn’t yet done! This motivated me to get the project done! I knew I’d need to know the content well enough to teach others and didn’t want the talk to be theoretical.

This was a risky move because there were organizational factors beyond my control that could have blocked the project. In the end it worked out although it was a down to the wire, as we only completed the project a week before the deadline!

I had also submitted the talk to RailsConf 2023 and unfortunately it was not accepted. This talk was originally intended more for Rails developers. The pitch was to use table partitioning more and perform a conversion using a CLI Ruby gem called pgslice [^pgslice]. The gem codebase would be friendlier than a PostgreSQL extension for Rails developers.

In the end, the talk was more for PostgreSQL users, who are more familiar with pg_partman. [^pgpart] This set the stage for a comparison and investigation of the trade-offs between the tools.


## Dry Run with Crunchy Data
Elizabeth Garrett Christensen ([@sqlliz](https://twitter.com/sqlliz)) and I were messaging and  we discussed doing a dry run, and opening it up to her team members at [Crunchy Data](https://www.crunchydata.com)!

Elizabeth and I have supported each other with some reviews of talks we’re giving and rubber ducking on some concepts.

Liz set up a Friday tech talk over lunch and there was a good turnout and helpful feedback. Liz also introduced me to Chris, Keith, and other team members. Thanks Liz!


## Pre-conference Chicago
I arrived the day before and caught up with some co-workers in Chicago for lunch and dinner! This was awesome. As a remote based employee, having that in-person connection time is meaningful.

The speaker’s dinner was great and I appreciated the opportunity to meet the other presenters in a one on one setting.


## My presentation experience
I felt prepared to give the presentation. It was a big relief to have completed the project the presentation was based on. 😅

We manage around 10 production databases, but one is 10x the size of the next biggest one. Although the table partitioning was applied to all of the databases, the benefits partitioning would bring were intended mostly for this larger database.

The large database was about 4 TB in total, with the table being converted consuming around 1.5 TB with 2 billion rows.

Once partitioned by month, each child table was around 20 GB in size and had around 50 million rows, which was more manageable.

## The conference and venue
The conference was well done. It’s a 1 day conference and my expectations were lower since I expected a small budget and staff. On the contrary, the conference was well conducted and for me competitive with larger conferences with more funding.

Kudos to all the planning that went into it and the staff, signage, organization, timing, everything was very smooth from my perspective.

The [Convene](https://convene.com/locations/chicago/) venue was very nice. I over estimated how easy it would be to walk there being unfamiliar with the area and being the first presenter at 9 AM!

Although I woke up early to exercise and prepare, my timing was cutting it close. I walked in, set my laptop up, plugged in the HDMI, and had 30 seconds to spare before being announced as the presenter! 😅


## Community
At the smaller conferences for me it's easier to meet people and form new professional relationships.

These relationships have paid off in my career.

Having the benefit of the speaker’s dinner also helps to create something in common to connect with other speakers about.

One attendee I met and hit it off with was Brian. When Brian said his website was [Brian Likes Postgres]([Brian Likes Postgres](https://www.brianlikespostgres.com/)) I was so excited! Not only does Brian like PostgreSQL (woo!), he’s also an educator and advocate.

I asked Brian to be a Technical Reviewer for my [PostgreSQL for Rails book](https://pgrailsbook.com) and I was so happy to hear he was interested!

This opportunity would not have happened without PGDay Chicago. Brian is awesome member of the community and I'm so glad we met!

## What could have been better
I thought everything about the conference was excellent. My only suggestion is to record the conference talks if there is a budget to do so.

As a presenter, having my talk recorded helps me grow my online presence and credibility. Since PGDay Chicago was a multi-track conference I had to miss sessions in the same slot and don't have a recording to check.

Although I don't have a recording to share, I have more resources in this post.

Use the short link <http://bit.ly/PartPG2023> [^bitly] for the slides. Download the PDF for links. Search Twitter with [#PartPG2023](https://twitter.com/search?q=PartPG2023) to find tweets. The slides are also embedded below!


## What’s next
* I’m going to keep telling people how awesome PostgreSQL Declarative Partitioning is, and why developers should use it more. With PostgreSQL 16 coming up later this year, I’m curious to see if there are more enhancements on the way.
* I’m working on more proposals and hope to present or attend another conference with these same organizers.

I'm writing a book called [High Performance PostgreSQL for Rails](https://pgrailsbook.com) published by [Pragmatic Programmers](https://pragprog.com), and arriving in 2023. Please subscribe to get more information!

Thanks!

[^pgpart]: <https://github.com/pgpartman/pg_partman>
[^pgslice]: <https://github.com/ankane/pgslice>
[^bitly]: <http://bit.ly/PartPG2023>

<iframe class="speakerdeck-iframe" frameborder="0" src="https://speakerdeck.com/player/8c1c25764d7d4158b89556c998c141f1" title="Partitioning Billions of Rows Without Downtime" allowfullscreen="true" style="border: 0px; background: padding-box rgba(0, 0, 0, 0.1); margin: 0px; padding: 0px; border-radius: 6px; box-shadow: rgba(0, 0, 0, 0.2) 0px 5px 40px; width: 100%; height: auto; aspect-ratio: 560 / 314;" data-ratio="1.78343949044586"></iframe>
