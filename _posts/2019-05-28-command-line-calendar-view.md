---
layout: post
title: "Calendar Events from the Command Line"
tags: [Tips, CLI]
date: 2019-05-28
comments: true
---

This is quick command line tip to view upcoming calendar events in a compact form on the command line, with a single command.

I set up [icalBuddy](https://hasseg.org/icalBuddy/) with my personal and work Google calendars (On macOS with Homebrew, run `brew install ical-buddy`), along with an alias `today`.

I've customized the output of icalBuddy with data and formatting using this alias:

```bash
alias today='icalBuddy -f -iep "title,datetime" -po "datetime,title" -df "%RD" eventsToday'
```

Now when I run the `today` alias, I get output like this. Handy!

```bash
$ today

• Car appointment (wife's personal calendar)
• 12:00 PM - 12:15 PM
    Frontend stand-up meeting (work calendar)
• 12:15 PM - 12:30 PM
    Backend stand-up meeting (work calendar)
```
