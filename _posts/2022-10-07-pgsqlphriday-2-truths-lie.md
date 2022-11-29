---
layout: post
title: "#PGSQLPhriday 001 - Query Stats, Log Tags, and N+1s"
tags: [Ruby on Rails, PostgreSQL, Open Source]
date: 2022-10-07
comments: true
---

In this post you will be presented with 2 truths and a lie related to PostgreSQL and Ruby on Rails.

This is my contribution to the first #PGSQLPhriday blog post series aiming to grow community blogging about PostgreSQL. Visit the [PGSQL Phriday #001 – Two truths and a lie about PostgreSQL post](https://www.softwareandbooz.com/pgsql-phriday-001-invite/) to learn more about the blog post series.

Without further ado, here are 2 truths and a lie:

- I can easily find the worst SQL queries from my Rails app
- I can easily link SQL queries to app ORM [^16] code
- Active Record always produces N+1 queries [^1]

## Analyzing App Queries

In taking a macro query analysis perspective with PostgreSQL, we can look at all app queries in terms of how many resources they consume.

The highest consumption queries are worth fixing by reducing their cost. Reducing a query's cost may involve adding a new index for relevant columns, reducing what is being selected, or reducing what is being retrieved (adding a LIMIT).

The main tool we use is the `pg_stat_statements` module [^2]. PGSS normalizes queries, removing specific parameters and then collects statistics about the frequency and duration of those unique queries.

We can then query that statistical data (thanks [Crunchy Data](https://github.com/andyatkinson/pg_scripts/blob/master/list_10_worst_queries.sql) for this query) to focus on the top 10 worst queries. Although the data can be queried via psql, we can also visualize it with PgHero [^3]. PgHero presents a percentage of impact for each query and makes the data interactive and sortable.

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

In Rails and the Active Record ORM, it is common to lazily load associated records by traversing model associations. Part of the joy of Active Record is the fluent interface [^11].

However, when lazily loading associated records, an excessive amount of database queries can be created, such as querying the same table multiple times in a loop. In those situations a technique called "eager loading" should be used, which loads the associated data  earlier, and thus avoids excessive queries due to lazy loading.

Imagine a `Vehicle` model with many reservations (`VehicleReservation`). Accessing vehicles in a loop and loading all the reservations generates a query to the `vehicle_reservations` table for each loop iteration. This is costly and unnecessary, since loading all of the Vehicle Reservations eagerly would result in the same app behavior.

How can we prevent the repetitive queries? Active Record has added a `strict_loading` option in newer versions that developers can use to make lazy loading impossible. Thus, Strict Loading can be used as a means to prevent the excessive N+1 queries that can be common. Some code examples are below.

```rb
vehicles = Vehicle.strict_loading.all
vehicles.each do |vehicle|
    vehicle.vehicle_reservations.first.starts_at
end
```

With `strict_loading`, lazily loading associated records raises an `ActiveRecord::StrictLoadingViolationError` exception. A developer encountering this in new code would now be required to perform eager loading.

```rb
`Vehicle` is marked for strict_loading. The VehicleReservation association
named `:vehicle_reservations` cannot be lazily loaded.
(ActiveRecord::StrictLoadingViolationError)
```

Combining `strict_loading` and eager loading using `includes`, you can avoid N+1 queries *and* prevent them from happening in the future.

```rb
vehicles = Vehicle.strict_loading.
  includes(:vehicle_reservations).all
```

So this one was the lie! Active Record models can be configured to prevent N+1 queries via lazy loading. Fewer queries keeps your PostgreSQL database happy!

Strict Loading can be enabled on model associations and can even be enabled globally. [^15]

```rb
# config/application.rb

config.active_record.strict_loading_by_default = true
```


## In Summary

This was a quick look at some ways I use PostgreSQL and Ruby on Rails, in a 2 truths and a lie format.

I enjoyed participating in the first [#PGSQLPhriday](https://twitter.com/hashtag/PGSQLPhriday?src=hashtag_click) and putting my spin on it by adding Ruby on Rails to the mix.

In summary:

* Enable `pg_stat_statements`. Query the top 10 worst queries and eliminate them to reduce load on your database. Query the data with psql or use PgHero.
* Annotate your SQL queries with Marginalia or use Query Log Tags.
* Use the Strict Loading feature on associations to prevent excessive N+1 queries

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
[^16]: [Active Record ORM Basics](https://guides.rubyonrails.org/active_record_basics.html)
