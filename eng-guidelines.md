---
layout: page
permalink: /engineering-guidelines
title: Engineering Guidelines
---

This is a collection of articles and topics about senior engineering.

## IC, EM, High Performing teams

### Engineering Manger (EM) vs. Individual Contributor (IC)

I really like this post called the [Engineer/Manager Pendulum](https://charity.wtf/2017/05/11/the-engineer-manager-pendulum/).
Everything in this post resonates with my career, including how different the roles are, moving between them is lateral or even how a senior IC first-time manager is a "junior" EM.
And how "There’s nothing worse than reporting to someone forced into managing."

### Technical Leadership, Influence not Authority

* [Thriving on the Technical Leadership Path](https://keavy.com/work/thriving-on-the-technical-leadership-path/)

This is a great article and description of laddering up in organizations on the senior engineer path. Some of the ways that the benefit of having more autonomy and influence, can be used to make more strategic and broader impact contributions.

### Favorite Books

Some favorite engineering books I have read. If a newer version exists I've linked that first.

* Sandi Metz on Object Design with Ruby. Newer Book (2018): [Practical Object-Oriented Design: An Agile Primer Using Ruby](https://www.amazon.com/Practical-Object-Oriented-Design-Agile-Primer-dp-0134456475/dp/0134456475/ref=dp_ob_title_bk). [POODR (2012)](https://www.amazon.com/Practical-Object-Oriented-Design-Ruby-Addison-Wesley/dp/0321721330/ref=sr_1_4?crid=3ACLQ7Q5L3P3F&keywords=sandi+metz+practical+object+oriented+design+in+ruby&qid=1638803814&sprefix=sandi+metz+practical%2Caps%2C268&sr=8-4).
* [PostgreSQL 9.0 High Performance](https://www.amazon.com/PostgreSQL-High-Performance-Gregory-Smith/dp/184951030X/ref=sr_1_1?keywords=high+performance+postgres+9.0&qid=1638803942&s=books&sr=1-1)
* [Staff Engineer: Leadership beyond the management track](https://staffeng.com/book)
* [Accelerate: The Science of Lean Software and DevOps: Building and Scaling High Performing Technology Organizations](https://code.likeagirl.io/the-one-book-every-tech-leader-should-read-8d78dfdc5e0e)

### DevOps Research and Assessment (DORA) Metrics

<https://harness.io/blog/continuous-delivery/dora-metrics/>

* Lead Time
* Deployment Frequency
* Mean Time To Restore (MTTR)
* Change Failure Rate

## Generic Backend Web Development Guidelines

Software Engineering as it relates to backend web development.

### Vendor everything

Cache the dependencies in the application.

### On Naming Things

* Prefer full words over acronyms.
* Prefer verbosity when the audience is a human and not a machine.
* Avoid shortening or abbreviating a word and combining it with an acronym.
* Prefer snake case over camel case unless camel case is idiomatic or conventional.
* Adjust the specificity and complexity of the language depending on where it appears.

### Benchmarking

Provide quantitative evidence supporting a change. Using a benchmarking tool as a before/after change is one way.

* For web requests, something like [wrk2](https://github.com/giltene/wrk2)
* For Ruby code changes, something like [benchmark](https://github.com/ruby/benchmark)
* For database changes, something like [pgbench](https://www.postgresql.org/docs/10/pgbench.html)

### Occam's razor

When faced with a tough problem and formulating hypotheses about various causes, the [simplest explanation is likely the actual explanation](https://en.wikipedia.org/wiki/Occam%27s_razor).

### Security

When creating role-based access, follow the [Principle of least privilege](https://en.wikipedia.org/wiki/Principle_of_least_privilege).

### Guessability

When writing code maintained by oneself and others, prefer following the [Principle of Least Surprise](https://en.wikipedia.org/wiki/Principle_of_least_astonishment) as opposed to overly clever alternatives.

For example, prefer to make something explicit and avoiding dynamic programming when implicit or metaprogramming may make that component more difficult to understand.

### Reversibility

To lower the risk of a change, prefer techniques or strategies that are reversible. If the change introduces problems, it can be reverted.

Along these same lines, I like the advice to optimize more for [Mean time to recovery (MTTR)](https://en.wikipedia.org/wiki/Mean_time_to_recovery) as opposed to Mean time between failures (MTBF).

### Prefer to test for positive conditions

When writing conditional statements, prefer to test for positive conditions because they are easier to read.

`if object.has_thing?; end` tests that the object has a thing (positive).

The inverse might be that the object is "not missing" the thing which would be: `if !object.missing_thing?; end`

Ruby also supports `unless` and a double negative can be made, which is difficult to read: `unless object.missing_thing?; end`

These two could be converted to testing for a positive condition.

### Robustness Principle

The [Robustness principle](https://en.wikipedia.org/wiki/Robustness_principle) states "be conservative in what you do, be liberal in what you accept from others".

Applied to a Ruby method signature, accepting an optional argument with a default value of an empty hash provides caller side consistency over time, but specific keys and values can be checked within the method implementation.

In this way I feel like it satisfies the definition of being liberal in what is accepted, but conservative in how what is accepted is actually handled.

This also creates an opportunity to both defensively guard against the method being mis-used but also an opportunity to self-document acceptable keys and values for maintainers.


## Pull Request Guidelines

The review process is a balancing act that attempts to provide constructive feedback that helps with knowledge sharing, lessening maintenance, improving self-documenting, discoverability, least surprising, reducing complexity, while also not blocking a team member accomplish the goal of releasing their code change.

This is somewhat of an art and science process.

Here are some guidelines I've found helpful over the years:

* Try to understand the primary purpose of the PR and not lose sight of that
* Look for evidence that the code works and ask the author to confirm they've manually tested it in at least one pre-release environment. This could be test coverage or a description of how something was tested manually.
* Look for potential accidental mistakes: mismatching method names, variable names, files, constants, etc.
* Make suggestions that might improve readability or maintainability improvements in the code itself, the PR title or description. Add a ticket number, related issue or PRs, external API documentation or other links that help tell the story. PRs are referred back to when investigating a bug or refactoring. PRs have "conversation" on them. The more information co-located on the PR the better.
* If there is test coverage, consider whether there are positive and negative tests. Consider avoiding test environment dependencies if possible (mocks, stubs, contract-based testing).
* Consider the potential for a performance issue that may not surface until there is a higher scale, when changing mature code.

A human is working on this:

* Be nice
* Have a bias towards an "approve" given functionality is confirmed as working. List comments as suggestions. A PR that has comments but no explicit approval or rejection is unclear.
* Look for (and ask for) patterns to encourage shared use.
* Be mindful that evidence, examples, other code etc. (a link, a blog post etc.) or a brief explanation on reasoning will be more easily consumable for the author and help them and others learn.

Create a Pull Request template for the project that lists important pre-flight checks.
