---
layout: post
title: "SaaS on Rails on PostgreSQL — POSETTE 2024"
tags: [PostgreSQL, Ruby on Rails]
date: 2024-07-13
comments: true
---

In this talk attendees will learn how Ruby on Rails and PostgreSQL can be used to create scalable SaaS applications, focusing on schema and query design, and leveraging database capabilities.

We’ll define SaaS concepts, B2B, B2C, and multi-tenancy. Although Rails doesn't natively support SaaS or multi-tenancy, solutions like Bullet Train and Jumpstart Rails can be used for common SaaS needs.

Next we'll cover database designs from the Apartment and acts_as_tenant gems which support multi-tenancy concepts, then connect their design concepts to Citus's row and schema sharding capabilities from version 12.0.

We’ll also cover PostgreSQL's LIST partitioning and how to use it for efficient detachment of unneeded customer data.

We'll cover the basics of leveraging Rails 6.1's Horizontal Sharding for database-per-tenant designs.

Besides the benefits for each tool, limitations will be described so that attendees can make informed choices.

Attendees will leave with a broad survey of building multi-tenant SaaS applications, having reviewed application level designs and database designs, to help them put these into action in their own applications.


<!-- callout box -->
<section>
<div style="border-radius:0.8em;background-color:#eee;padding:1em;margin:1em;color:#000;">
<h2>💻 Slide Deck</h2>
<iframe class="speakerdeck-iframe" frameborder="0" src="https://speakerdeck.com/player/e5764eba28e94c049313cd314fa4d2c7" title="SaaS on Rails on PostgreSQL" allowfullscreen="true" style="border: 0px; background: padding-box rgba(0, 0, 0, 0.1); margin: 0px; padding: 0px; border-radius: 6px; box-shadow: rgba(0, 0, 0, 0.2) 0px 5px 40px; width: 100%; height: auto; aspect-ratio: 560 / 315;" data-ratio="1.7777777777777777"></iframe>
</div>
</section>

<!-- callout box -->
<section>
<div style="border-radius:0.8em;background-color:#eee;padding:1em;margin:1em;color:#000;">
<h2>🎥 YouTube Recording</h2>
<iframe width="560" height="315" src="https://www.youtube.com/embed/RwXJ4s2pw1A?si=H5tSbkPaNiVNLBgl" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>
</div>
</section>
