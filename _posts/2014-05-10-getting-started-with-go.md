---
layout: post
title: "Getting Started with Go"
date: 2014-05-03
comments: true
tags: [Go, Programming]
---

I spent some time learning the Go programming language by working through some tutorials and building a small app. The book [An Introduction To Programming in Go](http://www.golang-book.com/) has 14 chapters and covers data structures, HTTP, command line apps, concurrency, and more.

## Project layout
I typed out most of the go example code for practice and have [pushed my code here](https://github.com/andyatkinson/golang-book). Go has specific project layout requirements. The `GOPATH` environment variable points at `~/go` and project source code is in `src` as a subdirectory of `~/go`. For more information refer to `go help gopath`.

## Heroku
To learn Go better, I made a small web app and deployed it to Heroku. This forced me to figure out how to handle form posts, redirects, the MD5 library, and work with a database.

The Heroku part started off easy [thanks to this guide](http://mmcgrana.github.io/2012/09/getting-started-with-go-on-heroku.html). However Heroku deploys failed for me with third-party dependencies like `pq`, using [godep](https://github.com/tools/godep). I wasn't able to get godep working, but I was able to use [gopack](https://github.com/d2fn/gopack) for the same purpose instead.

## Gournay
Gournay is a simple web app that shrinks URLs, written in Go. The [source is on GitHub](https://github.com/andyatkinson/gournay) and the app is deployed at [gournay.herokuapp.com](http://gournay.herokuapp.com/). Gournay depends on the `pq` package to connect to a PostgreSQL database, and uses `godep` to manage its dependencies.

Gournay takes a long URL like `http://www.npr.org/2014/05/17/313142425/a-worldwide-voyage-to-prove-stars-wind-and-waves-are-enough` and makes a short hash from it. The URL and hash are stored in a database table. If the hash is posted back at Gournay, the user is redirected to the original URL.

## Conclusion
I am enjoying learning Go so far, and have plans to spend more time learning the concurrency features. If you have any other tips on Go, or found this useful, please leave a comment.

## Links
* [Simple go webapp on Heroku](http://blog.joshsoftware.com/2014/02/28/a-simple-go-web-app-on-heroku-with-mongodb-on-mongohq/)
* [gopack](https://github.com/d2fn/gopack) for dependencies
* My [stack overflow godep issue](http://stackoverflow.com/questions/23745092/go-project-with-third-party-packages-on-heroku)
* [Gournay source code](https://github.com/andyatkinson/gournay)
* [Gournay Heroku app](http://gournay.herokuapp.com/)
