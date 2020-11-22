---
layout: page
permalink: /postgresql-tuning
title: PostgreSQL Tuning
---

## Autovacuum

PostgreSQL runs an autovacuum process in the background to remove dead tuples. Dead tuples are the result of a multiversion model ([MVCC](https://www.postgresql.org/docs/9.5/mvcc-intro.html)).

At work in order to improve the performance for our largest tables, as an effect of running AV more frequently, and for less time, we've found there are two parameters to tune.

In [routine vacumming](https://www.postgresql.org/docs/9.1/routine-vacuuming.html), the two options are listed:

- scale factor (a percentage of dead tuples) [`autovacuum_vacuum_scale_factor`](https://www.postgresql.org/docs/9.1/runtime-config-autovacuum.html#GUC-AUTOVACUUM-VACUUM-SCALE-FACTOR)
- threshold (a specific number of dead tuples) [`autovacuum_vacuum_threshold`](https://www.postgresql.org/docs/9.1/runtime-config-autovacuum.html#GUC-AUTOVACUUM-VACUUM-SCALE-FACTOR)

The scale factor defaults to 20% (`0.20`) but it has been recommended to optimize for our largest tables, for example setting it to a much lower value of 1% (`0.01`) as the effect on the small tables will be negligible anyway.

## Finding unused indexes

Indexes may have been created for reasons, but have since become unused. These should be cleaned up to reduce unnecessary IO and disk space!

[Get Rid of Your Unused Indexes!](https://www.cybertec-postgresql.com/en/get-rid-of-your-unused-indexes/)

In two of the biggest and easiest opportunities on large tables, we identified two unused indexes taking up 50GB of disk!
