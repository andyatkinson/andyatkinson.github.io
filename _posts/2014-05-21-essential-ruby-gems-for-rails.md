---
layout: post
title: "Essential Ruby Gems for Rails"
date: 2014-05-21
comments: true
tags: [Ruby, Rails, Tips, Programming]
---

This is my recommend list of Ruby gems for Rails apps.

## Debugging
The [pry](https://github.com/pry/pry) gem works really well for debugging. Add the line `require 'pry'; binding.pry` where you want execution to stop, and you get access to a full Rails console. Pry can also be used as a traditional stepping debugger.

## Background processing
Code that blocks the user or takes a long time to execute should be run from a background job. We used Resque and [Sidekiq](https://github.com/mperham/sidekiq) in production at LivingSocial. Sidekiq seems like the better choice these days because of the support options and because it uses less memory.

## Exception notification
The [exception_notification](https://github.com/rails/exception_notification) gem provides an easy way to notify the engineering team when an exception occurs by sending an email. We want to be notified about exceptions in production as soon as possible so we can work on a fix and deploy it.

## Factory objects for automated tests
Rails' built-in fixtures are fine for objects that don't change. Fixtures are loaded once at test boot time, which will be useful for some types of tests. For objects that require specific configuration, we have found the factory approach to work well. [factory_girl](https://github.com/thoughtbot/factory_girl) makes it easy to set up objects with real values, that can be easily customized in tests. Factory objects also serve as documentation of related objects and values.

## Authentication
The [devise](https://github.com/plataformatec/devise) gem works well as a drop-in solution for most registration and authentication needs. Devise provides forms, email templates, controllers and more, for things a user would want to do like sign up, sign in, or reset their password.

## File uploads
The [paperclip](https://github.com/thoughtbot/paperclip) gem has been very useful for file uploads for many years across many versions of Rails. Typically we configure paperclip to store file uploads in S3. File uploads could be profile avatars or documents associated to a user.

## Periodic jobs
We have found the [whenever](https://github.com/javan/whenever) gem to be a nice way to manage crontab files. By expressing the periodic task details with a Ruby DSL, the file is easier to read and change. Whenever also supplies Capistrano hooks to make it easy to update the crontab on each deploy.

Much thanks to the authors and maintainers of these gems! What are your essential Ruby gems for Rails apps? Please leave a comment or get in touch by email.
