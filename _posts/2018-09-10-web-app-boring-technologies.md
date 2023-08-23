---
layout: post
title: "Building a Web App with Boring Technologies (2017 Edition)"
date: 2018-09-10
comments: true
tags: [Ruby, Rails, Databases, Programming, PostgreSQL]
---

This post was written in February 2017 and I'm just getting around to posting it now in September of 2018. These technologies are not new or flashy but they are proven and have a lot of documentation and tooling support.

## Ruby on Rails

Ruby on Rails is old now relatively speaking, but it still works well! We rely on the framework for typical things a web framework provides, working with a database (a nice ORM/nice abstraction on relationships and joins), building APIs (internal APIs for our JS and native front-ends), building our admin app (server rendered HTML), sending emails, processing background jobs and more.

## Sidekiq

We make heavy use of Sidekiq for running web tasks offline, and periodic scheduled tasks. Sidekiq Pro has a [Batches feature](https://github.com/mperham/sidekiq/wiki/Batches) that we're using in a handful of places. A batch has many jobs, the jobs are processed concurrently to speed things up, and the batches API provides callbacks that can be used to put a pipeline of workers together.

## Cron

We have a lot of scheduled jobs at OrderUp! We use the [Clockwork](https://github.com/Rykian/clockwork) gem to more easily manage the configuration. What I like mainly is not having to use cron syntax, and instead writing the schedule for when the job runs in English.

Some of the things we do as scheduled jobs:

* Compute summary tables, statistics, and scores. We run these at off-peak times since there are a lot of slower database reads and writes.
* Build and send summary emails
* Send notifications (SMS and Push Notifications) to independent contractors when they have scheduled upcoming work
* Check on an interval for bad user behavior (fraud) and take action

## PostgreSQL

We have some extensions and functions that are specific to PostgreSQL, but the features I work on are mostly database agnostic. We use Active Record migrations to manage schema changes like adding tables, changing column defaults, adding indexes, constraints etc. We have read-only replicas that are used for ad hoc querying and generating data dumps. Some features written originally with Active Record tend to get re-written as big blobs of SQL.

## Logging

We send our logs to [Logentries](http://logentries.com/). This allows us to live tail logs, and search through hours or days of logs quickly. Logging can be used to collect positive and negative evidence about the execution of some bit of code.
