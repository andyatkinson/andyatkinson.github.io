---
layout: post
permalink: /source-code-line-numbers-ruby-on-rails-marginalia-query-logs
title: 'Source code line numbers for database queries in Ruby on Rails with Marginalia and Query Logs'
tags: [Ruby on Rails, Ruby, PostgreSQL]
date: 2025-04-29
---

Back in 2022, we covered how to log database query generation information from a web app using `pg_stat_statements` for Postgres.
<https://andyatkinson.com/blog/2022/10/07/pgsqlphriday-2-truths-lie>

The application context annotations can look like this. They've been re-formatted for printing:

```
application=Rideshare
controller=trip_requests
source_location=app/services/trip_creator.rb:26:in `best_available_driver'
action=create
```

I use `pg_stat_statements` to identify costly queries generated in the web application, often ORM queries (the ORM is Active Record in Ruby on Rails), with the goal of working on efficiency and performance improvements.

The annotations above are included in the `query` field and formatted as SQL-compatible comments.

Application context usually includes the app name and app concepts like MVC controller names, action names, or even more precise info which we'll cover next.

How can we make these even more useful?

## What's the mechanism to generate these annotations?
For Ruby on Rails, we've used the [Marginalia](https://github.com/basecamp/marginalia) Ruby gem to create these annotations.

Besides the context above, a super useful option is the `:line` option which captures the source code file and line number.

Given how dynamic Ruby code can be, including changes that can happen at runtime, the `:line` level logging takes these annotations from "nice to have" to "critical" to find opportunities for improvements.

What's more, is that besides Marginalia, we now have a second option that's built-in to Ruby on Rails.

## What's been added since then?
In Rails 7.1, Ruby on Rails gained similar functionality to Marginalia directly in the framework.

While nice to have directly in the framework, the initial version didn't have the source code line-level capability.

That changed in the last year! Starting from PR 50969 to Rails linked below, for Rails 7.2.0 and 8.0.2, the `source_location` option was added to [Active Record Query Logs](https://api.rubyonrails.org/classes/ActiveRecord/QueryLogs.html), equivalent to the `:line` option in Marginalia.

PR: Support `:source_location` tag option for query log tags by [fatkodima](https://github.com/fatkodima)
<https://github.com/rails/rails/pull/50969#issuecomment-2797357558>

Dima described how the Marginalia `:line` configuration option was costly to enable in production and even improved on that.

Dima managed to lessen the overhead associated with line-level logging for Query Logs in the scope of this PR. Nice!

## Safe Logging Locally or in Production
A great place to start with this is to use this logging only in local development.

In the examples below, we're showing how an environment variable can be used to enable line level logging in some environments, while not enabling it globally.

For Marginalia, that would look like this:
`MARGINALIA_LINE_NUMBER_ENABLED=true`

In `config/initializers/marginalia.rb`:
```rb
Marginalia::Comment.components = [
  :application,
  :controller,
  :action
]

if ENV['MARGINALIA_LINE_NUMBER_ENABLED']
  Marginalia::Comment.components.append(:line)
end
```

For Query Logs, that could look as follows.

In `config/application.rb` (adjust to be for the environments you prefer):
```rb
config.active_record.query_log_tags_enabled = true
config.active_record.query_log_tags = [
  :application,
  :controller,
  :action,
  :source_location
]
```

The configuration above was tested with Rails 7.2.2. The same conditional enablement of the `:source_location` option could be achieved with an environment variable.

If your team uses Query Logs `:source_location` in development or production, I'd love to know!

## Wrap Up
Having source code line level logging for aggregated query statistics is critical for backend engineers debugging database performance issues.

Equipped with that info, engineers can identify heavy queries then go backwards into the source code to redesign, refactor, or restructure (and in some cases--eliminate) the query.

## What's next?
The `pg_stat_statements` extension is critical for this workflow, but it's not without opportunities for improvement.

One issue that `pg_stat_statements` has is that many of the entries can be duplicates or near-duplicates, making it tougher to sift through.

Fortunately, fixes are coming for that too! Stay tuned for a future post where we'll cover upcoming improvements in future versions of Postgres that will help de-duplicate `pg_stat_statements` entries, as well as options to achieve that with Ruby on Rails even for older versions of Postgres.

Consider subscribing to my newsletter, where I send out occasional issues linking to blog posts, conferences, industry news, and more, so you don't miss that post!

Thanks for reading.
