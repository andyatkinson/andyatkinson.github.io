---
layout: post
title: Process Monitoring with Bluepill
date: 2010-10-07
comments: true
tags: [DevOps, Ruby, Rails, CLI]
---

On our current project my colleague chose [Bluepill](http://github.com/arya/bluepill) for process monitoring. Bluepill has been working well so I wanted to recommend it and share some notes. 

## Configuration
Configuration is kept in a `.pill` file, which is a Ruby source file with a DSL syntax to define processes and their configurations. For each process we define how to start it, the pid file for it, a log file to send standard out and standard error to, and whether to daemonize the process. We're currently monitoring Redis and Node.JS (which acts as our WebSocket server). 

Pill files are organized by environment. We have a pill file for the development, production, and staging environments. Unfortunately we don't have a lot of production experience with Bluepill yet, but the authors have stated that Bluepill itself will consume a low amount of memory.

## Load a configuration

``` bash
sudo bluepill load config/bluepill/development.pill
```

## Start the services

``` bash
sudo bluepill start
```

## Check the service status

``` bash
sudo bluepill status
redis-server(pid:40945): up
websocket-server(pid:40950): up
```
I hope this helps you get started with Bluepill. Do you use something else to monitor your processes?
