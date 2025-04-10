---
layout: post
title: "How to Code Review a Repository with GitHub"
date: 2013-10-16
comments: true
tags: [Tips, Git]
---

Recently I was asked to do a code review on an entire repository. Normally I review a pull request where I can leave a comment on a specific line.

There are probably other ways to accomplish this, but I came up with the following steps to review the repository in a non-destructive way.

## Fork the Repo
First I forked the repository so that I didn't introduce any commits on the main repo. The repository was private and I have a paid GitHub account, so forking the repo created a private repository. I am not sure whether a private repository is created when forking without a paid account.

## Create a `code_review` Branch
I created a `code_review` branch (`git branch -d code_review`) off master. This branch was pushed to my fork (`git push andy code_review`).

## Remove all the files on master
On `master` I removed all the files git knows about with `git rm -rf *`. Next I pushed `master` to my fork with `git push andy master`.

## Create a pull request
Using the GitHub interface, I created a pull request comparing `andy/master` with `andy/code_review`. This makes it look like all the files are being added.

Now I can make line comments and general comments with the author via the pull request link. If any additional commits are pushed to the fork, the original author can cherry pick the commits with `git cherry-pick sha`. When the author is happy with the code review, the fork can be deleted.
