---
layout: post
title: "Getting Started with Tmux"
date: 2013-10-14
comments: true
tags: [Tips, Tools, Productivity]
---

I started learning tmux and highly recommend the book **_tmux: Productive Mouse-Free Development_** [^book] as a guide. My `tmux.conf` [^conf] configuration file is available as well.

## Keyboard Tips
* `Ctrl-b` is the default prefix which I kept so that I could continue to use `Ctrl-a` to move the cursor to the front in bash and vim. 
* On OS X I remapped my caps lock key to be the control key
* `Ctrl-b z` can be used to toggle a pane into a window, and back to a pane. 
* To scroll back through output `Ctrl-b [` enters copy mode. I use vim navigation to move around (`Ctrl-u` and `Ctrl-d` up and down 1/2 page, `Shift j/k` to move a line at a time). If I know I need to read back though, I usually tail the log file in a separate terminal window and use the mouse since I find it to be faster.

## Shortcuts
* `tmux ls` when detached, lists any running tmux sessions. `tmux attach -t X` can be used to attach to an existing session, where X is the number of the session.
* `Ctrl-b d` detaches from an existing session
* `Ctrl-b c` creates a new window within a session. `exit` will close the window. `Ctrl-b ,` (comma) can be used to rename the window.
* To split a window into panes, following the guidelines the book recommends, the shortcut `Ctrl-b |` (pipe) splits the window vertically into two panes next to each other, while `Ctrl-b -` (hyphen) splits the window into two panes stacked on top of each other horizontally. To move back and forth between panes `Ctrl-b h/j/k/l` can be used, or to apply a new layout entirely to the panes within a window, `Ctrl-b spacebar` can be used.
* `Ctrl-b w` displays a list of the open windows, and the h/j/k/l keys can be used to move up and down the list. `Ctrl-b X` where X is a number can be used to jump to a specific numbered window.

## Issues
One of the issues when resizing a window from a small size to a large size is that dots would be drawn around the main content area. Detaching and re-attaching to the window seems to fix it. [^1]

At this time it is not possible to give names to panes within windows. I tried having multiple applications running with their log file being tailed, one application per pane within a window, but it became too difficult to tell what application was running in a given pane. As a workaround I mostly limit a window to a single running application, and don't use multiple panes.

## Conclusion
Do you have any favorite tmux tips or tricks? Please get in touch.

[^book]: [tmux: Productive Mouse-Free Development](http://pragprog.com/book/bhtmux/tmux) by Brian P. Hogan The Pragmatic Programmers
[^1]: [Stack overflow answer on switching window size with tmux session](http://stackoverflow.com/a/7819465/126688)
[^conf]: [tmux.conf configuration file](https://github.com/andyatkinson/dotfiles/blob/master/tmux.conf)
