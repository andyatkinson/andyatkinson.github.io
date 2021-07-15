---
layout: page
permalink: /rails-tips
title: Rails Tips
---

#### Log SQL queries to console

`ActiveRecord::Base.logger = Logger.new(STDOUT)`

#### Tail test log file when running test

In a separate terminal window:
`tail -f log/test.log`

#### List object methods

`User.methods - ActiveRecord::Base.methods`

#### Warnings

Boot app with `$VERBOSE = true` in `config/application.rb` or somewhere that executes

#### Vendor everything

When vendoring/caching all gems, while developing on OS X but deploying with Alpine Linux, we need to download and cache gems for all platforms. This grabs the Linux version of the Nokogiri gem.

`bundle package --all-platforms`

#### Use the Ruby database schema format

Rails configures [dumping the Active Record database schema](https://guides.rubyonrails.org/active_record_migrations.html) in the development, test and CI environments, out of the box using a Ruby format.

The nice thing about that layer of indirection is that it is more resilient to small differences in different database versions.

Typically what happens for Rails applications at the point a database function, trigger, or some other native item is introduced to the app, is that the `.sql` format is adopted.

That works but can introduce breakages due to slighy differences in PG versions between multiple environments, which can be quite irritating.

A better solution is to use the [fx](https://github.com/teoljungberg/fx) gem. With fx, native database functions can be dumped into the Ruby schema format. Yay!

#### Remove unused indexes

In a Rails migration, check for the existence of the index like: `index_exists?(:table_name, :column_name)` before writing it. Indexes may have different generated names in different environments.

#### Use Strong Migrations

Follow the tips in [strong_migrations](https://github.com/ankane/strong_migrations). Create your own custom checks. Explain your rationale when using `safety_assured`.

#### Bundler platforms

If developing on OS X, deploying on Linux, and vendoring gems, the Darwin pre-built gem will be installed. Add the Linx platform:

`bundle lock --add-platform x86_64-linux`

And then `bundle package --all-platforms` and confirm the Linux version has been added to `vendor/cache`.
