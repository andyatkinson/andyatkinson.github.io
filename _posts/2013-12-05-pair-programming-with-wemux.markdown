---
layout: post
title: "Pair Programming with Wemux"
date: 2013-12-05
comments: true
tags: [Tools, Productivity, Tips, Programming]
---

[Wemux](https://github.com/zolrath/wemux) is a way to do remote pairing (collaborative code development) with less bandwidth, compared with a full graphical interface. 

With tmux I can have windows and panes dedicated to code, log files, and consoles, and share all of that with a collaborator. 

We used the following steps to set up a remote user on OS X to connect to my tmux session:

* Install tmux and wemux.
* add a "pair" user in OS X, using the control panel. I gave the user an easy password.
* in the "sharing" control panel, enable remote access for user "pair". I disabled access when we were no longer pairing.

At this point I was able to share my external IP address with a co-worker who was able to connect to my tmux session.

## Conclusion
Wemux has a lot of features I hope to try out. If you're interested in pairing on some open source code, let me know!
