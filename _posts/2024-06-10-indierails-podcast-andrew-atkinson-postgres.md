---
layout: post
title: "🎙️ IndieRails Podcast — Andrew Atkinson - The Postgres Specialist"
tags: [Podcasts, PostgreSQL]
date: 2024-06-10
comments: true
---

I loved joining [Jeremy Smith](https://www.indierails.com/people/jeremy-smith) and [Jess Brown](https://www.indierails.com/people/jess-brown) as a guest on the [IndieRails](https://www.indierails.com) podcast!

I hope you enjoy this episode write-up, and I'd love to hear your thoughts or feedback.

## Early Career
I got my start in programming in college, and my first job writing Java. This was the mid 2000s so this was Java Enterprise Edition, and I worked in a drab, boring gray cubicle, like Peter has in the movie [Office Space](https://www.imdb.com/title/tt0151804/).

I was so excited though to have a full-time job writing code as an *Associate Software Engineer*. For me this validated years of work learning how to write code in college, represented a huge pay increase, and felt like something I could make a career out of.

## Build a Blog in 15 Minutes
Somewhere along the way I saw the Ruby on Rails [15-minute build a blog video](https://www.youtube.com/watch?v=Gzj723LkRJY). This was a turning point for me, seeing what, and how an individual developer could build a full-stack web app.

## Train Brain
Later in the 2000s, I took a side mission from Ruby on Rails, and taught myself Objective-C and iOS, and launched an app for train riders in Minneapolis. I called the app [Train Brain](https://www.minnpost.com/minnov8/2009/09/new-train-brain-app-should-ease-life-light-rail-riders/) and partnered with [Nate Kadlac](https://www.kadlac.com) who designed the app icon, and all of the visuals for the app and website. Nate turned out to be a great connection, as we’ve remained friends over the years. When I asked Nate to do the cover illustration for my book, I was thrilled to hear it would work out because I know Nate is a talented designer, but also because I think we both love to support each other how we can.

## Spicy Chicken at Wendy’s
I told a story of learning Ruby on Rails using the [Michael Hartl book: RailsSpace](https://www.amazon.com/RailsSpace-Building-Networking-Addison-Wesley-Professional/dp/0321480791). This was a favorite book of mine, because it had readers build a social networking app, which was a hot space to be in at the time. Readers built the app up as they went along, which is a great way to learn any new technology! I was working in a job I wasn’t loving out in the suburbs at this point, and didn’t really have work friends. On my lunch breaks, I’d take lunch myself at Wendy’s, and my usual order was a spicy chicken sandwich. I’d read RailsSpace in the restaurant or even in my car, and would look forward to being back at my computer to type and run the code samples.

## LivingSocial
My partner and I moved out to Baltimore-Washington, D.C. in 2010, and I had a good job based in Minneapolis, and they allowed me to switch to working remotely. This was perhaps my first remote job, which is interesting because I’ve done remote for more than a decade now!
While it was a good job, I really wanted to get something in-person and local, making Baltimore my new local community.

RailsConf came to Baltimore in 2010 just after we arrived, and I was able to attend in 2010 and 2011. I also attended tech events a lot in this era, and I attended a Washington DC Bootstrap Maryland event, where I met [LivingSocial](https://en.wikipedia.org/wiki/LivingSocial) co-founder Aaron Battalion, and other early or founding engineers like Patrick Joyce and Doug Ramsay. From that original introduction and more conversations, I was able to secure an interview and eventually a job at LivingSocial, which turned out to be a hockey stick, rocketship, whatever-big-growth-metaphor-you-prefer, a true high-growth company, built on a very straightforward idea and business model.

This was a formative experience, writing code while seeing huge engineer headcount growth, subdivision of work, teams, hack-a-thons, “vertical” areas of the business, acquisition of US and non-US based companies, the launch of an in-house incubator ([Hungry Academy](https://www.prnewswire.com/news-releases/livingsocial-launches-hungry-academy-to-train-next-generation-of-software-development-champions-135994418.html)), to name a few things!

Although I hadn’t worked much with PostgreSQL at this stage, and we used MySQL at LivingSocial, this was my first exposure to a popular, global consumer brand, with big scale. While the business was centered mostly around deals delivered by email, the purchase experience was all on the web, and there were some crushing blows of traffic at times, including a particularly large one for the [LivingSocial Superbowl ad in 2011](https://www.youtube.com/watch?v=nGN939P6YAo)!

## OrderUp
OrderUp was a food delivery company started in Baltimore, back when food delivery was a hot trend. I met an engineer at LivingSocial, also based in Baltimore at the time, Paul Barry, who became the CTO at OrderUp. I was able to join that team for several years through the [acquisition by Groupon](https://investor.groupon.com/press-releases/press-release-details/2015/Groupon-Acquires-OrderUp-to-Power-Nationwide-Food-Ordering-and-Delivery/default.aspx)! For OrderUp, food orders from customers were dispatched to active drivers.

A formative experience there was Paul rewriting the dispatcher code as a “wall of SQL.” Paul was very skilled with SQL queries, common table expression, query optimization, and administrative tasks like identifying problematic queries and canceling or terminating them. As an aside: those administration skills stuck with me, and made their way into the book!

I wasn’t very knowledgeable about this stuff at the time, but it was some of my first exposure to the importance of good control over your database operations when scaling up a business, and getting into the SQL, outside of common boundaries of the Active Record ORM.

Later when I arrived at Groupon, although I wrote Ruby on Rails as well, I primarily worked on Java service codebases (See: [Microservice Frameworks for Java](http://andyatkinson.com/blog/2019/07/16/microservice-frameworks-java)) to start.

The common part of the stack between all the client applications whether they were written in Ruby or Java, was PostgreSQL!

## Flipgrid
The most formative experience for me with PostgreSQL, was a few years ago after joining Flipgrid. Flipgrid, later called Flip, was a video-based social learning platform used primarily in a K-12 educational setting. News broke very recently [Flip is being shut down, sadly](https://x.com/BeckyKeene/status/1797653933722316986). Microsoft Flipgrid, or Flip, followed the acquisition of a startup company based in Minneapolis.

When the COVID pandemic happened, schools closed for in-person learning. The teachers needed a way to connect with their students online. Flipgrid experienced an explosion of growth as a result, as teachers sent and received Flipgrid videos with their students.

As measured by the New Relic APM, our main monolith Rails backend app received 450K requests per minute (RPM) at peak, powered by a single "beefy" PostgreSQL 10 instance running on AWS RDS (See: [SaaS for Developers with Gwen Shapira — Postgres, Performance and Rails with Andrew Atkinson 🎙️](http://andyatkinson.com/blog/2023/08/28/saas-for-developers-gwen-shapira-postgresql-rails)).

We scaled the instance vertically, had read replicas, added connection pooling, but on a small team of back-end engineers with no DBA and no DB-focused engineer, we needed to dive into the database operations themselves, the schema design, index design, and maintenance operations, to unlock more scale, reliability, and predictability.

I took this challenge on, as it was a budding interest of mine, and there was an opportunity. I picked up [High Performance PostgreSQL by Gregory Smith](https://www.amazon.com/PostgreSQL-High-Performance-Gregory-Smith/dp/184951030X), and learned and applied as much as I could, as quickly as possible.

Later I learned it’s somewhat common to be an [Accidental DBA](https://charity.wtf/2016/10/02/the-accidental-dba/), and that there's such a thing as an [Application DBA](https://hakibenita.com/sql-tricks-application-dba). I found a niche community!

## Consulting and Coaching
Now that I’ve done PostgreSQL performance optimization, scalability, and reliability work a few times, I felt interested and qualified to try and earn a living out of doing this kind of work for more teams.

My hypothesis was that successful web product application teams can’t, or don’t want to hire a full-time DBA or DB-focused backend engineer, but for ones that are successful, that means there's typically an unmet need for performance and optimization work and design guidance. Teams might "get by" until things blow up. That could take the form of timeouts, errors, disruptions to code releases, inability to upgrade instances, overloaded instances, replication problems, or myriad other issues.

My goal is for them to find me, and to make it easy for them to hire me, finding a good fit for price point, availability, engagement model, so we can partner up and solve their challenges.

In terms of income goals, my thought was if I had a few clients hiring me on a part-time basis, I could make full-time equivalent levels of income, while doing work I love, with more schedule flexibility, while avoiding some of the unpredictability of the tech industry.

This means I’m targeting teams in a middle area for size, they're likely smaller and don’t have a databases team, but are big enough that their database size and transaction volume is fairly large, and they're likely running into issues.

## Family, mortgage, bills to pay
With that all said, unfortunately I’m not independently wealthy, and probably like you, I have bills to pay. [Lifestyle creep](https://www.investopedia.com/terms/l/lifestyle-creep.asp) is a thing. Since I’m launching a new consulting business, I would expect to not immediately make similar levels of income to a full-time equivalent salary, as I need to find clients, get engagements signed, perform the work, and collect payment.

Plus there are lots of new expenses to figure out, filing taxes, balancing income generating activities and future investments like podcast appearances or conference presentations.

That all means, this is all somewhat of an experiment, on a limited timeline. I can afford some risks for a while, but not forever!

## Death by obscurity
My mentality is that one of the biggest risks to me consulting successfully, over the long haul, is that I’m a unknown person relative to the total addressable market size for my services.

For that reason, it's critical to promote my book, ask people to buy it to support me, ask for references, promote myself on social media, for sales of my book, as it's all part of long-term sustainability in continuing to make this career path work as an indie consultant.

The balancing act though with promoting myself through podcast appearances, conference presentations, and newsletters, is to continue to perform income-generating client work!

## Industry churn
I feel fortunate to be side-stepping the stressful processes of interviewing for jobs, and avoiding some of the layoffs still occuring in the tech industry now.

On the indie path, I’m my own boss. It’s on me to manage my time, current client committments, and investments in my future success. Nothing is really given, and I need to find new clients, earn their trust, and deliver on my value prop they signed up for.

Fortunately, I really like writing, and have been successful in finding new clients, that I have the chance for indie consulting to be a long-term sustainable path!

## Presenting at PostgreSQL Events
My big break as a first-time PostgreSQL presenter, was [PGConf Conference NYC 2021](PGConf NYC 2021 Conference). I presented on the work I did, along with the team, at Flipgrid, as we worked on optimizing all aspects of our PostgreSQL instances and database-usage from the application. My perspective was one of a practitioner, “accidental DBA,” and Application DBA.

## Book Proposal
After PGConf NYC, an acquisitions editor reached out, said they’d seen that I’d presented, that I blog on PostgreSQL topics, and asked whether I’d considered writing a book about PostgreSQL. The publisher was looking to publish PostgreSQL books, as it was growing in popularity. Over the next few months, I submitted proposals to that published and ultimately successfully matched with [The Pragmatic Programmers](https://pragprog.com)!

## A hands-on book
Going all the way back to RailsSpace, I wanted to write a hands-on book with examples and exercises. Although the book has a narrative style, the emphasis is on code examples and exercises when possible, and getting the reader working on their own computers, so they can develop the skills and confidence to solve future challenges they face.

## Database book for application developers
I felt there was a need for a database book for Rails developers, and more generally, web application developers. Database books might typically be written more for a reader with a background in systems administration or infrastructure, who is not writing backend application code.

## Being an expert
Do book authors needs to be experts in the topic? For me, *expert* is a complicated word.

In the podcast, I talked about how when writing a book and looking at a topic, there’s a continuum of skill levels for readers. When targeting a skill level on that continuum, we can expand the coverage of the topic left or right.

For example, we cover Active Record topics, and PostgreSQL features like exclusion constraints or domains, but connect them under the umbrella of data quality, consistency, and integrity checks. There isn't a single correct answer, but different trade-offs.

Authors Noel Rappin, Vladimir Dymentev, and myself recently were on stage at RailsConf (See: [RailsConf 2024 Conference — The Long Goodbye](http://andyatkinson.com/blog/2024/05/17/railsconf-conference-2024-detroit)), discussing our thoughts on writing tech books with publishers, for an audience of 20 or so, as part of a "Meet the Authors" event.

Noel described how being too much of an expert might mean the author can no longer relate to the learner, their struggles, and their perspectives. The suggestion was for tech book authors to have a kernel of expertise, but that it's not necessary to be the world's leading export to write a book.

Of course, we still want to write a book that's free of technical errors, is useful, and enjoyable to read.

## On promoting the book
In my experience, most of the promotion of my book has been left up to me. The publisher provides a lot of services as part of the package, and those costs are shared by the publisher and author.

Those services include having a developmental editor reading the book and providing feedback, helping get technical reviewer feedback organized and incorporated, and in the end stages, copy editing and layout. The publisher also has a distribution network so that the book appears for sale on Amazon, Barnes & Noble, as well as retailers like Target and Wal-Mart, and a zillion smaller book shops.

## Promotion by way of conference presentations
Spring 2024 for me has been the greatest effort (and results for that effort) I've ever put in to submitting proposals to present at conferences.

It helps that I enjoy attending conferences, the travel part, meeting people, learning, and expanding my network. However, as an author and consultant, I've realized the conference presentations now are one of the best ways to help make my name, products, and services, less obscure.

Regularly presenting also helps with confidence. After the RailsConf workshop I gave, I was reflecting on how I had so little nerves, which is a long way from where I came from.

In the past I’d be excited to present, but more anxious. I'd prepare probably to an excessive degree (beyond where it's necessary to improve the quality), then before the "performance" itself I'd be using deep breathing, and sweating it out to cope.

I’ve become much more comfortable speaking publicly on Postgres topics now, which for me has been this whole mix of things, experience, writing, and simply experience giving more talks.

## Consulting offerings
My two main offerings now (always changing), are Consulting with longer engagements, with more time committed upfront. This represents a bigger (but predictable) cost for a company to make that kind of investment, but covers my time to partner up with them.

My other offering is Coaching and Advisory sessions, which are low cost, and could be a good fit for smaller companies, solo founders, or companies wanting to try out work with me a bit.

## Episode

<!-- Callout box -->
<section>
<div style="border-radius:0.8em;background-color:#eee;padding:1em;margin:1em;color:#000;">
<h2>Podcast</h2>
<p>🎧 <a href="https://www.indierails.com/35">Andrew Atkinson - The Postgres Specialist</a></p>
</div>
</section>

## Let’s Connect

- [LinkedIn: in/andyatkinson](https://www.linkedin.com/in/andyatkinson/)
- [Website: andyatkinson.com](https://andyatkinson.com)
- [Newsletter: pgrailsbook.com](https://pgrailsbook.com)
- [X/Twitter: andatki](https://x.com/andatki)
- [Mastodon: https://mastodon.social/@andatki](https://mastodon.social/@andatki)
- [Bluesky: andatki](https://bsky.app/profile/andatki.bsky.social)

Thanks for reading!
