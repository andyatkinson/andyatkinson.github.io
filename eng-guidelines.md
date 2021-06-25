---
layout: page
permalink: /engineering-guidelines
title: Engineering Guidelines
---

## Software Engineering Guidelines

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
