---
layout: post
title: "PostgreSQL pgbench Workload Simulation"
tags: [PostgreSQL, Databases]
date: 2021-08-10
comments: true
featured_image_thumbnail:
featured_image: /assets/images/pages/andy-atkinson-California-SF-Yosemite-June-2012.jpg
featured_image_caption: Yosemite National Park. &copy; 2012 <a href="/">Andy Atkinson</a>
featured: true
---

We operate a high scale API application back-end that replies on a single primary PostgreSQL instance. The workload on the primary database tends to be heavy on `INSERT` and `UPDATE` statements.

Where possible we direct our `SELECT` (reads) to a read replica which uses physical replication.

Recently we've started to have the ability to simulate part of our workload. One of the key tools is using [pgbench](https://www.postgresql.org/docs/10/pgbench.html) which is a benchmarking tool built in to PostgreSQL.

## Using pgbench

Pgbench




## Summary

* Find, test and drop unused and duplicate indexes that don't impact queries
* Fix invalid indexes
* Re-index bloated indexes concurrently (use pg_repack if reindex concurrently is not natively supported)
* Adjust Autovacuum settings to prevent excessive bloat from recurring


If you have any other index maintenance tips, I'd love to hear them. Thanks for reading.
