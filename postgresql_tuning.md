---
layout: page
permalink: /postgresql-tuning
title: PostgreSQL Tuning
---

## Autovacuum

PostgreSQL runs an autovacuum process in the background to remove dead tuples. Dead tuples are the result of a multiversion model ([MVCC](https://www.postgresql.org/docs/9.5/mvcc-intro.html)).

At work in order to improve the performance for our largest tables, as an effect of running AV more frequently, and for less time, we've found there are two parameters to tune.

In [routine vacumming](https://www.postgresql.org/docs/9.1/routine-vacuuming.html), the two options are listed:

- scale factor [`autovacuum_vacuum_scale_factor'](https://www.postgresql.org/docs/9.1/runtime-config-autovacuum.html#GUC-AUTOVACUUM-VACUUM-SCALE-FACTOR)
- threshold [`autovacuum_vacuum_threshold`](https://www.postgresql.org/docs/9.1/runtime-config-autovacuum.html#GUC-AUTOVACUUM-VACUUM-SCALE-FACTOR)

The scale factor defaults to 20% (`0.20`) but it has been recommended to optimize for our largest tables, setting to a much lower value of 1% (`0.01`) as the effect on the small tables will be negligible anyway.
