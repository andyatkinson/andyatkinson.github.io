---
layout: page
permalink: /dev-interviewing
title: Development Interviews
---

### Code Screen

As part of my job, I help evaluate code screen submissions from candidates.

Our code screen process is currently a Ruby on Rails app where we ask candidates to do a few things.

In order to help make the process a bit more objective and build some consensus among the other reviewers and myself, I contributed some evaluation criteria to use in reviewing submissions.

These are mostly around following instructions, and utilizing Ruby standard library, Rails functionality, best practices and idiomatic code where possible.

1. Followed instructions
1. Has model validations that make sense
1. Uses strong parameters
1. Models have Active Record relationships where appropriate
1. Database: Has migrations with appropriate types, indexes, constraints (nullable, uniqueness, foreign keys)
1. Has test coverage. Spec descriptions roughly match the assertions. Tests positive and negative scenarios.
1. All tests pass
1. Besides tests passing and the app booting, other functionality like CSV parsing works
1. Overall sense of written communication skills: Pull Request title, description, commit messages, spec methods, assertions
1. Bonus functionality was implemented and works

### Interview Questions

These are some of the questions I have used in the past when interviewing Software Engineer individual contributor candidates. These are intentionally open ended and somewhat generic, to help assess the experience of the candidate and how they communicate.

* What sorts of things do you look for when reviewing Pull Requests from your team members?

* What sorts of techniques have you used to build consensus with other engineers on technical approaches?

* In the quality and speed trade-off, what things do you do to improve the quality of your code?
What sorts of things do you do to improve your iteration speed?

* What are some common web application performance problems?

* What are some common techniques to solve or mitigate web application performance problems?

* What are some development best practices you might look for on your ideal team?
