---
layout: post
title: Chart Your Console History with Google Charts
date: 2008-04-17
comments: true
tags: [Scripts, Tips, Ruby, JavaScript, Programming]
---

This script was for fun to play around with [Google Charts](http://code.google.com/apis/chart/). There was an internet meme going around where programmers were posting their console history on their blogs. I took the output from that script and made a Ruby hash of commands and their frequencies, then sent that data to a Google Charts URL to display them as a 3d pie chart.

```ruby
    #!/usr/bin/env ruby
    # (c) 2008 Andy Atkinson

    # this awk script is from an internet meme where programmers would post their console history
    # on their blog, it was not made by me, I added sending the results to a google charts 3d pie chart
    # 
    # (1) make a file called "history.rb"
    # (2) RUN THIS:
    #   history 1000 | awk '{a[$2]++}END{for(i in a){print a[i] "=" i}}' | sort -rn | head | ruby history.rb
    #
    output = STDIN.read

    # output should be like:
    #  ["41", "git"]
    #  ["39", "cd"]
    #  ["37", "history"]
    #  ["32", "gs"]

    commands = {}
    output.each do |line|
      count,name = line.chomp.split('=')
      commands[count] = name
    end

    google_charts_url = 'http://chart.apis.google.com/chart?cht=p3&chd=t:'
    url = google_charts_url + commands.keys.join(",") + "&chs=600x200&chl=" + commands.values.join("|")
    `open #{url.dump}`
```
