---
layout: page
permalink: /rails-tips
title: Rails Tips
---

{% include tag-pages-loop.html tagName='Ruby on Rails' %}

## App Code Tips

### Native `pg` gem dependencies

Run `which pg_config`.

Copy the path as the value for `--with-pg-config` for bundler. [Reference](https://stackoverflow.com/a/35145890/126688).

`bundle config build.pg --with-pg-config=/Applications/Postgres.app/Contents/Versions/latest/bin/pg_config`

### Log SQL queries to console

`ActiveRecord::Base.logger = Logger.new(STDOUT)`

### List object methods

`User.methods - ActiveRecord::Base.methods`

### Get a full backtrace

<https://stackoverflow.com/a/376521/126688>

```
def do_division_by_zero; 5 / 0; end
begin
  do_division_by_zero
rescue => exception
  puts exception.backtrace
  raise # always reraise
end
```

### Warnings

Boot app with `$VERBOSE = true` in `config/application.rb` or somewhere that executes

### Vendor everything

When vendoring/caching all gems, while developing on macOS but deploying with Alpine Linux, we need to download and cache gems for all platforms. This grabs the Linux version of the Nokogiri gem.

`bundle package --all-platforms`

### Bundler platforms

If developing on Mac OS, deploying on Linux, and vendoring gems, the Darwin pre-built gem will be installed. Add the Linux platform:

`bundle lock --add-platform x86_64-linux`

And then `bundle package --all-platforms` and confirm the Linux version has been added to `vendor/cache`.

### Prefer simple dependency specifications

Sometimes there is a minimum version required that has a security fix, a team member recently introduced this:

```
gem 'addressable', '~> 2.8', '>= 2.8.0'
```
This makes `bundle update addressable` easy in the future, grabbing any new patch version of the `2.8` minor version, while still calling out that `2.8.0` should be the minimum patch version that has a security fix.

In general I prefer to avoid specifying versions entirely in the `Gemfile` and rely on the versions in `Gemfile.lock`, which has specific versions for direct and indirect dependencies.

### Caller code source location

This is more of a Ruby tip but you can get a method reference and use source location. For example with an instance of foo:

`Foo.new` the `method` method can be called with a method name like `bar`, e.g. `Foo.new.method(:bar).source_location` and calling source_location will show the line number of the caller.

### Nested Attributes

If there is the option to control the front-end HTTP request payload, take advantage of built-in [nested attributes support](https://api.rubyonrails.org/classes/ActiveRecord/NestedAttributes/ClassMethods.html) to create objects via an association.

Because nested models can be created or updated this way, Active Record lifecycle events like `before_save` can be triggered to create a loosely coupled series of actions.

### Unused

* Identify unused code <https://github.com/unused-code/unused>
* `$ unused`

### Rails Best Practices

* <https://github.com/flyerhzm/rails-bestpractices.com>
* `$ rails_best_practices .`


## Test Code Tips

### Rspec Tips

* Run specific spec: use line number on end like `rspec spec/foo_spec.rb:123` to run line 123

### Compare times at course granularity

`expect(thing.time).to be_within(1.second).of Time.now`

### Tail test log file when running test

In a separate terminal window:
`tail -f log/test.log`

### Sidekiq Content

Sidekiq is a popular background processing framework.

Review my Sidekiq page: [Sidekiq](/sidekiq).

<https://github.com/mperham/sidekiq/wiki/Testing> We use the `inline!` method to test jobs synchronously.



### External web requests

We use [webmock](https://github.com/bblimke/webmock) for 3rd party APIs to capture authentic HTTP stubbed responses.



## Rails and Database Tips

### Statement timeout

Set a `statement_timeout` in config/database.yml to set an upper bound on how long a query can run. We use 5 seconds for our app servers. [Hashrocket: Rails/PG Statement Timeout](https://til.hashrocket.com/posts/b44baf657d-railspg-statement-timeout-)

For queries that are ok to run longer, or migrations, a higher value is appropriate. We use [Strong Migrations](https://github.com/ankane/strong_migrations#migration-timeouts) which raises the statement timeout.

### Checkout timeout

Set a `checkout_timeout` to set how long to wait to check out a connection from the connection pool. The default is 5 seconds but we set it to 4 seconds. [Rails Connection Pool Docs](https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/ConnectionPool.html)

### Connection Pool Stats

```rb
ActiveRecord::Base.connection_pool.stat

# => {:size=>32, :connections=>0, :busy=>0, :dead=>0, :idle=>0, :waiting=>0, :checkout_timeout=>4.0}
```
### Remove unused indexes

In a Rails migration, check for the existence of the index like: `index_exists?(:table_name, :column_name)` before writing it. Indexes may have different generated names in different environments.

### Use Strong Migrations

Follow the tips in [strong_migrations](https://github.com/ankane/strong_migrations). Create your own custom checks. Explain your rationale when using `safety_assured`.

