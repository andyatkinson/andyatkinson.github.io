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
