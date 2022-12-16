---
layout: post
title: "PostgreSQL, Ruby on Rails, Rails Guides"
tags: [PostgreSQL, Rails]
date: 2022-12-12
comments: true
---

Hello. I [recently tweeted](https://twitter.com/andatki/status/1601292470205444096) asking the following question.

> Hey Rails + #PostgreSQL devs, what's one #PostgreSQL thing you wish you knew more about, that's not covered deeply (or at all) in the [Rails Guides](https://guides.rubyonrails.org)? Thanks!

This tweet was more popular than I expected and got a lot of interesting replies. I appreciated the responses! I've summarized them below.

### Summarized Topics and Tweets

* DB types, network types, `cidr` , time based, interval, `tsrange`, `timestamptz` [@allizad](https://twitter.com/allizad/status/1601632620919463936), [@gordysc](https://twitter.com/gordysc/status/1601647517435064321)
* JSON querying, JSON operators [@BijanRahnema](https://twitter.com/BijanRahnema/status/1601535710452154368), [@nstajio](https://twitter.com/nstajio/status/1601593160517681152) [@42s_video](https://twitter.com/42s_video/status/1601481503245971456)
* The "right" indexes, indexing topics [@dorianmariefr](https://twitter.com/dorianmariefr/status/1601548000543010817), [@godfoca](https://twitter.com/godfoca/status/1601681808675901441)
* Views and materialized views [@everybody_kurts](https://twitter.com/everybody_kurts/status/1601639296146243586), [@dmissikowski](https://twitter.com/dmissikowski/status/1601615582994268161)
* Query planning, [EXPLAIN](https://www.postgresql.org/docs/current/sql-explain.html) [@rubemazenha](https://twitter.com/rubemazenha/status/1601616303047184386)
* Full text search [@tiegz](https://twitter.com/tiegz/status/1601603470964187136)
* Concurrency, auto-vacuum setups [@godfoca](https://twitter.com/godfoca/status/1601582858011041794), [@honzasterba](https://twitter.com/honzasterba/status/1601559014856269824)
* Tuning statistics collector for large tables [@katafrakt_pl](https://twitter.com/katafrakt_pl/status/1601558812074602497)
* DB triggers management [@adrienpoly](https://twitter.com/adrienpoly/status/1601491599816798208)
* [hyperloglog](https://www.citusdata.com/blog/2017/06/30/efficient-rollup-with-hyperloglog-on-postgres/) type [@jonathandenney](https://twitter.com/jonathandenney/status/1601644590985281537)
* Query performance for array column [@dangoslen](https://twitter.com/dangoslen/status/1602300527185895424)
* Denormalization [@TomaszM89477675](https://twitter.com/TomaszM89477675/status/1602218247947960321)
* Partitioning [@cm_richards](https://twitter.com/cm_richards/status/1601503915580981249)
* Migrating a few big tables to their own database (functional sharding, or application level sharding), minimizing downtime [@jessethanley](https://twitter.com/jessethanley/status/1601714248463175680)
* CTEs within Active Record, [Modern SQL](https://modern-sql.com/) [@S_2K](https://twitter.com/S_2K/status/1601655304907001856)
* [dexter](https://github.com/ankane/dexter) (automatic indexing) and [HypoPG](https://github.com/HypoPG/hypopg). Dexter can automatically generate indexes from a connection [@brightball](https://twitter.com/brightball/status/1602342185852350469)
* Integrating PostgreSQL features not supported in Active Record [@alexanderadam__](https://twitter.com/alexanderadam__/status/1601462107832487936)
* Connection pooling [@fredngo](https://twitter.com/fredngo/status/1601595824315969536)


### Links From Tweets

* [Safe Ecto Migrations · Fly](https://fly.io/phoenix-files/safe-ecto-migrations/)
