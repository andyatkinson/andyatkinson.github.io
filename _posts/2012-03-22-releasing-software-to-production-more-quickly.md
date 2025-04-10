---
layout: post
title: Ship It Quicker
date: 2012-03-22
comments: true
tags: [Tips, Ruby, Rails, Productivity, Lean Startup]
---

Shipped software can provide A/B test results and behavior data, which can help clarify whether a feature is worth enhancing or abandoning. It is important for the team to embrace shipping software (without hurting quality) to keep planning meetings short and on-topic. In my experience an iterative development style is the best way to build web apps. What follows are some ways to release code while reducing risk.

## Show the feature conditionally
* Show a feature if a URL param like `?show_feature=1` is present.
* Show a feature to employees only. For logged-in users, check the email domain.
* Show the feature to employees having a certain role.
* Segment users into some behavior and limit the feature to users with that behavior. In our case it might be users that subscribe to deals in a particular city, are viewing a specific deal or category, have a home address in a particular city, or are browsing with a particular language.
* Add a cookie for some visitors and show a feature if the cookie is present. We might write a cookie that lasts for a week to avoid showing a feature to the same user (in the same browser) during the week the cookie is present. A cookie means there is less to evaluate on the server, and the cookie can be set to expire automatically by the browser.
* Show a feature to a user that is part of a cohort of behavior you want to target: subscribers from last year, purchasers after a certain date, heavy sharers, or users with connected social networks.

## Reducing risk
Risk for a particular feature can be reduced by releasing the feature to a small group initially, then gradually increasing the size of the group. One type of risk is performance regressions, in our case this is usually from new database queries.

## Externalize configuration
Something we did was create a configuration file of keys and values that was used with performance sensitive code. The configuration file keys could be referenced in code, and the values could be easily tweaked in the file to turn something off, or increase or decrease it, without code changes. This was also a good spot for cache TTLs, under high load, cache fragments could be kept around longer, where stale data was ok.

## Limit the traffic
A Ruby gem for conditionally releasing features that may be useful for your project is [rollout](https://github.com/jamesgolick/rollout). In our case we'd usually write a lot of this code straight into our templates, then clean it up later.
