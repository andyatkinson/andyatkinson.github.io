---
layout: post
permalink: /source-code-line-numbers-ruby-on-rails-marginalia-query-logs
title: 'Source code locations for database queries in Rails with Marginalia and Query Logs'
tags: [Ruby on Rails, Ruby, PostgreSQL]
date: 2025-04-29
---

## Intro
Back in 2022, we covered how to log database query generation information from a web app using `pg_stat_statements` for Postgres.
<https://andyatkinson.com/blog/2022/10/07/pgsqlphriday-2-truths-lie>

The application context annotations can look like this. They've been re-formatted for printing:

```
application=Rideshare
controller=trip_requests
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

An example of `:source_location` in action looks like this:

<pre><code>
application=Rideshare
controller=trip_requests
➡️ <strong>source_location=app/services/trip_creator.rb:26:<br/>in `best_available_driver'</strong>
action=create
</code></pre>

Nice, now we've got the class name, line number, and Ruby method. In this example, we can get to work optimizing the `best_available_driver` method.

Dima described how the Marginalia `:line` option was costly in production and even managed to improve that with the Query Logs change.

## Safe Logging Locally or in Production
If you're unsure about source code line logging in production, but want to get started using it, a great place to start is using it in your local development enrivonment.

To avoid enabling the option for all environments, we'll use an environment variable that's enabled only for local development.

Here's a real example I use for Marginalia:
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

For Query Logs, in `config/application.rb` (adjust to be for the environments you prefer), the equivalent could look like this:
```rb
config.active_record.query_log_tags_enabled = true
config.active_record.query_log_tags = [
  :application,
  :controller,
  :action,
  :source_location
]
```

The configuration above was tested with Rails 7.2.2.

If your team uses Query Logs `:source_location` in development or production, I'd love to know!

## Wrap Up
Having source code line-level logging for query statistics is critical information that allows backend engineers to quickly zero in on where to fix database performance issues.

With this combo of information, engineers can identify the most heavy queries, then go backwards into the source code to know where to redesign, refactor, or restructure, or even remove costly queries.

## What's next?
The `pg_stat_statements` extension is critical for this workflow, but it's not without opportunities for improvement.

One issue that `pg_stat_statements` has is that many of the entries can be duplicates or near-duplicates, making it tougher to sift through.

Fortunately, fixes are coming for that too! Stay tuned for a future post where we'll cover upcoming improvements in future versions of Postgres that will help de-duplicate `pg_stat_statements` entries, as well as options to achieve that with Ruby on Rails even for older versions of Postgres.

Consider subscribing to my newsletter, where I send out occasional issues linking to blog posts, conferences, industry news, and more, so you don't miss that post!

Thanks for reading.
