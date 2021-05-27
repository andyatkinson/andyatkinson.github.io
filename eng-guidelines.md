---
layout: page
permalink: /engineering-guidelines
title: Engineering Guidelines
---

### Vendor everything

Cache the dependencies in the application.

### On Naming Things

Prefer full words over acronyms.

Prefer verbosity when the audience is a human and not a machine.

Avoid shortening or abbreviating a word and combining it with an acronym.

Prefer snake case over camel case unless camel case is idiomatic or conventional.

Adjust the specificity and complexity of the language depending on where it appears.

### Benchmarking

Provide quantitative evidence supporting a change. Using a benchmarking tool as a before/after change is one way.

For web requests, something like [wrk2](https://github.com/giltene/wrk2)

For Ruby code changes, something like [benchmark](https://github.com/ruby/benchmark)

For database changes, something like [pgbench](https://www.postgresql.org/docs/10/pgbench.html)
