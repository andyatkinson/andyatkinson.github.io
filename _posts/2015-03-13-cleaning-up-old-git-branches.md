---
layout: post
title: "Cleaning Up Old Git Branches"
date: 2015-03-13
comments: true
tags: [Programming, Productivity, Tips, Scripts]
---

With git commands and bash scripting we can clean up old branches quickly.

The final solution looks like this:

```sh
g old | head -n5 | xargs bash -c 'git branch -D $@; git push origin --delete $@;' bash
```

#### Breaking it down

1. We can list branches by the date they were committed to, with the oldest at the top. This is added as a git alias.
1. Branch names output is limited with `head` and `-n`, for example for 5 items: `head -n5`
1. `xargs` provides each branch name as `$@` substituted in to each of the following git commands.
1. git commands to delete the branch locally and from a remote named `origin` are executed for each branch name.

#### Listing old git branches

Add the following alias to your `~/.gitconfig`.

```sh
[alias]
  old = for-each-ref --sort=committerdate --format='%(refname:short)' refs/heads/
```

#### Deleting a single branch

When I no longer want a branch locally or on the remote server, I use this function to delete both at once:

```sh
function gdel { git branch -D $1; git push origin --delete $1; }
```
