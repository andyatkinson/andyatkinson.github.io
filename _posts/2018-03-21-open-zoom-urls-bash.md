---
layout: post
title: "Open Zoom Meetings from the Command Line"
date: 2018-03-21
comments: true
tags: [CLI, Tips, "Remote Work", Scripts]
---

This is a hacked together bash function, taking advantage of [icalBuddy](http://hasseg.org/icalBuddy/) and Zoom URLs in calendar invitations, making it a bit easier to join meetings.

### Steps

We use Google Calendar and have Zoom meeting URLs in the calendar descriptions.

This was put together quickly and is limited, but it solved my specific problem, and may be useful to you!

#### Install icalBuddy

On OS X with Homebrew, run `brew install ical-buddy`.

Run `icalBuddy eventsToday` and provide permission to your calendars.

#### Bash variable and function

Set a shell variable for the value of the Zoom URL for your company, e.g. `export ZOOM_BASE_URL=my-company`, which would generate a URL like `my-company.zoom.us`. If your function is not shared publicly or you don't wish to parameterize the URL, this step can be skipped.

Now that we have calendar information available, I made hacked together a couple of bash functions to scrape the present the data.

#### List Zoom URLs for Today

The function `zms` (Zoom meetings) scrapes out Zoom meeting URLs.

`function zms { icalBuddy eventsToday | egrep -o 'https:\/\/groupon.zoom.us\/j\/([0-9]+)'; }`

#### Open Current Meeting Zoom URL

The function `zmn` (Zoom meeting now) takes the first URL from the list above and opens it. Note that this may not be the actual meeting URL you want to open.

`function zmn { url=$(echo "$ZOOM_BASE_URL"); icalBuddy eventsToday | egrep -o "https:\/\/
$url.zoom.us\/j\/([0-9]+)" | head -n1 | open $(xargs); }`

An improvement here would be to present the URLs and prompt the user to make a selection, then proceed with opening their selected meeting link.


#### Wrapping Up

This morning I ran `zmn` to open my meeting and this made me happy 🎉. The bash functions are in my [dotfiles here](https://github.com/andyatkinson/dotfiles) and I've love to hear whether this was useful to you or you've made improvements!

Special thanks: open source projects icalBuddy and Homebrew!
