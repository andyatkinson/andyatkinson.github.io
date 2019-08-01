---
layout: post
title: "Using rbenv To Manage Multiple Ruby Versions"
tags: [Tips, Ruby, Rails]
date: 2019-08-01
comments: true
---

When switching between multiple Ruby applications, `rbenv` makes it easy to find, install, and use the appropriate version for the project. Let's take a look at how it is used.

#### Install

Upgrade or install [ruby-build](https://github.com/sstephenson/ruby-build):

```rb
brew upgrade ruby-build # or `install` if ruby-build is not already installed
```

#### Add Ons

The plugin [rbenv-bundler](https://github.com/carsomyr/rbenv-bundler) makes it possible to not have to type `bundle exec` in front of every command. This can be installed with `brew install rbenv-bundler`.

#### Check Local Versions

Run `rbenv versions` to see available Ruby versions, and `rbenv version` to see the current version being used.

#### Check Installable Versions

`rbenv install --list` to list all installable versions. Rails requires version `2.2.2` or greater per the [Rails Guides](https://guides.rubyonrails.org/getting_started.html) at the time of publication. Let's install version `2.5.5`.

#### Install A Ruby

`rbenv install 2.5.5`

### Use The Ruby

Let's make sure our Rails application is using `2.5.5` by specifying that version in the `.ruby-version` file in the application root directory of our Ruby project.

Now when we `cd` into the application root directory, and type `ruby -v`, we expect to see `2.5.5` as `rbenv` and other version managers have adopted the convention of looking for this file. Rails 5.2 officially supports this convention [^1].


[^1]: [Rails 5.2 sets Ruby version in Gemfile and adds .ruby-version file by default](https://blog.bigbinary.com/2018/05/07/rails-5_2-adds-ruby-version-file-and-ruby-version-to-gemfile-by-default.html)
