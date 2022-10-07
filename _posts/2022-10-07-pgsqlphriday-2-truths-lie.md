---
layout: post
title: "#PGSQLPhriday 001 - Query Stats, Log Tags, and N+1s"
tags: [Ruby on Rails, PostgreSQL, Open Source]
date: 2022-10-07
comments: true
featured_image_thumbnail:
featured_image: /assets/images/pages/andy-atkinson-California-SF-Yosemite-June-2012.jpg
featured_image_caption: Yosemite National Park. &copy; 2012 <a href="/">Andy Atkinson</a>
featured: true
---

In this post you will be presented with 2 truths and a lie related to PostgreSQL and Ruby on Rails, as part of the first #PGSQLPhriday series.

Visit the [PGSQL Phriday #001 – Two truths and a lie about PostgreSQL post](https://www.softwareandbooz.com/pgsql-phriday-001-invite/) to learn more about the blog post series.

Without further ado, here are 2 truths and a lie:

- I can easily find the worst SQL queries from my Rails app
- I can easily find where in the app the queries came from
- The Active Record ORM cannot be prevented from producing N+1 queries [^1]

## Analyzing All App Queries

Taking a macro perspective with PostgreSQL by looking at the queries that consume the most resources is possible using a couple of tools and a bit of connecting the dots.

The main tool we've used is the `pg_stat_statements` module [^2]. PGSS normalizes queries removing the specific parameters, and collects statistics about unique queries.

We can query the statistics data (thanks [Crunchy Data](https://github.com/andyatkinson/pg_scripts/blob/master/list_10_worst_queries.sql) for this query) that's been collected, or interact with the data via PgHero [^3]. PgHero presents the data in a tabular format and displays an impact percentage.

```sql
-- Top 10 Worst Queries

select
  total_exec_time,
  mean_exec_time as avg_ms,
  calls,
  query
FROM pg_stat_statements
ORDER BY mean_exec_time DESC
LIMIT 10;
```

## Linking SQL Queries to Application Code

In our Ruby on Rails application, we've configured the Marginalia gem [^7] (pre Rails 7) to add annotations as comments to all SQL queries.

Whether the query is coming from a Controller action (an MVC [^5] controller) or a background job like Sidekiq [^6], we can see where the query came from.

Different components can be displayed like the application name, controller action, and action name.

In Rails 7, Rails gets Marginalia functionality natively [^8] via Query Logs [^9]. 🎉


## Active Record Always Produces N+1 Queries

In Rails and the Active Record ORM, it is common to lazily load records by traversing model associations. Part of the joy of Active Record is the fluent interface [^11].

However, when lazily loading associated records, an excessive amount of database queries can be created. In those situations, associated data should be eagerly loaded to avoid introducing excessive queries.

Imagine a `Vehicle` model with many reservations (`VehicleReservation`). Accessing vehicles in a loop and loading all the reservations generates a vehicle reservations query for every loop iteration.

How can we prevent the repetitive queries? Active Record provides a `strict_loading` option that can be used to prevent lazily loading associated records and introducing N+1 queries.

```
vehicles = Vehicle.strict_loading.all
vehicles.each do |vehicle|
    vehicle.vehicle_reservations.first.starts_at
end
```

With `strict_loading`, lazy loading associated records raises an `ActiveRecord::StrictLoadingViolationError` exception.

```
`Vehicle` is marked for strict_loading. The VehicleReservation association named `:vehicle_reservations` cannot be lazily loaded. (ActiveRecord::StrictLoadingViolationError)
```

Combining `strict_loading` and eager loading using `includes`, you are able to avoid N+1 queries now *and* prevent them from happening in the future.

```
vehicles = Vehicle.strict_loading.includes(:vehicle_reservations).all
```

So this one was the lie! Active Record is not doomed to always allow N+1 queries with lazy loading. A properly informed programmer can prevent N+1s via lazy loading using built-in functionality. Fewer queries keeps your PostgreSQL database happy!

Strict Loading can even be enabled globally. [^15]

```
# config/application.rb

config.active_record.strict_loading_by_default = true
```


## In Summary

This was a quick look at some ways I use #PostgreSQL and Ruby on Rails.

I enjoyed participating in the first [#PGSQLPhriday](https://twitter.com/hashtag/PGSQLPhriday?src=hashtag_click) and putting my spin on it by discussing both PostgreSQL and Ruby on Rails.

In summary:

* Use `pg_stat_statements` to focus on high impact queries. Query the statistics data or view the data with PgHero.
* Annotate your SQL queries with context from the application using Marginalia or Query Log Tags
* Use Strict Loading to prevent lazily loaded associated data from generating N+1 queries

Thanks for reading!

[^1]: [Rails N+1 queries and eager loading](https://dev.to/junko911/rails-n-1-queries-and-eager-loading-10eh)
[^2]: [PostgreSQL: Documentation: pg_stat_statements](https://www.postgresql.org/docs/current/pgstatstatements.html)
[^3]: [GitHub - ankane/pghero: A performance dashboard for Postgres](https://github.com/ankane/pghero)
[^5]: [Model–view–controller - Wikipedia](https://en.wikipedia.org/wiki/Model%E2%80%93view%E2%80%93controller)
[^6]: [Sidekiq](https://sidekiq.org)
[^7]: [marginalia: Attach comments to ActiveRecords SQL queries](https://github.com/basecamp/marginalia)
[^8]: [Rails 7 adds Marginalia to Query Logs](https://blog.saeloun.com/2021/09/15/rails-maginalia-query-logs.html)
[^9]: [ActiveRecord::QueryLogs](https://api.rubyonrails.org/classes/ActiveRecord/QueryLogs.html)
[^11]: [Fluent Interfaces in Ruby ecosystem](https://blog.arkency.com/2017/01/fluent-interfaces-in-ruby-ecosystem/)
[^15]: [Kill N+1 Queries For Good with Strict Loading](https://mattsears.com/articles/2021/05/23/kill-n-plus-one-queries-for-good-with-strict-loading/)
