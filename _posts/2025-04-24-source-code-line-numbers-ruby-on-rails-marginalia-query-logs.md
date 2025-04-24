---
layout: post
permalink: /source-code-line-numbers-ruby-on-rails-marginalia-query-logs
title: 'Source code line numbers for database queries in Ruby on Rails with Marginalia and Query Logs'
hidden: true
---

Back in 2022, we covered how to log database query information using the `pg_stat_statements` extension for Postgres.
<https://andyatkinson.com/blog/2022/10/07/pgsqlphriday-2-truths-lie>

We're usually using `pg_stat_statements` to identify costly queries from our web application ORM (Active Record for Ruby on Rails), and then work on improvements at the source code level, to generate more efficient SQL.

To make it easier to find where the source code is, we want to know context from the application, like the application name, any associated source code objects like MVC controllers or actions.

Fortunately we can add that application context as SQL query text "annotations." These are SQL-compatible comments added to the front or back of the SQL query text.

These annotations are structured data, which means they have segments of information that can be expanded or reduced.

## What have we had?
For Ruby on Rails, we've been able to add these annotations for a while using the [Marginalia](https://github.com/basecamp/marginalia) Ruby gem.

Specifically, by enabling the `:line` option in Marginalia, we get the most rich information, which is the exact source code line number where the query was generated.

Without the line-level specificity, we're limited to controller names and action names which are useful, but that means the developer still needs to start there and do some digging and speculating about what exactly is generating the query.

Given how dynamaic Ruby code can be, including dynamic code introduced at runtime, even with MVC action name context, without line numbers it can still be quite difficult to find exactly where the source code location is.

For that reason, I view the line-level information as critical into making this query performance optimization process successful and sustainable.

## What have we gained since then?
In Rails 7.1, Ruby on Rails gained similar functionality as what Marginalia provides, directly into Ruby on Rails.

However, while being great to have natively, as this improves adoption and integration ease, the initial version didn't have the line-level functionality.

Now that's changed. Starting from the merged PR below, available in Rails 7.2.0 and 8.0.2, we now have a `source_location` option for [Active Record Query Logs](https://api.rubyonrails.org/classes/ActiveRecord/QueryLogs.html) that's equivalent to the `:line` option in Marginalia.

These versions have been out for a while now so upgrade to them if you’re on 7.x or 8.x.

PR: Support `:source_location` tag option for query log tags by fatkodima
<https://github.com/rails/rails/pull/50969#issuecomment-2797357558>

Further, contributor Dima Fatko describes how the Marginalia `:line` configuration option can be costly in production to use. Dima worked to lessen the overhead associated with line-level logging in this PR.

## Safe Logging Locally or in Production
Adding line-level logging does incur more processing overhead.

If you’re concerned about that, a great place to start use to enable this logging only in local development.

In the examples below, we're showing how an environment variable could be used to make the option available in certain environments.

For Marginalia:
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

In Query Logs:
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

This configuration above was tested with Rails 7.2.2.

According to Dima, what's more is that the changes made to line-level log information were made to be safe for production use.

If your team is using Query Logs `source_location` in production, I'd love to know!

## What's next?
This is really useful information for developers, so they can use aggregated query group statistics to discover impact, identifying heavy queries, then go backwards into the source code to redesign, refactor, or restructure the query, improving efficiency.

The `pg_stat_statements` extension is critical for this workflow, but it's not without opportunities for improvement.

One issue is that entries in `pg_stat_statements` can be duplicates or near-duplicates. Fortunately, fixes are coming for that too! Stay tuned for a future post where we'll cover this.

Consider subscribing to my newsletter, where I send out occasional issues linking to blog posts, conferences, industry news, and more.

Thanks!
