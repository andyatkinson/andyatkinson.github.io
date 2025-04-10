---
layout: post
title: A/B Testing with Vanity
date: 2011-05-11
comments: true
tags: [Ruby, Tools, Lean Startup]
---

Vanity is an A/B Testing framework for Ruby on Rails applications. I covered A/Bingo previously which is a similar framework. We have moved to Vanity at work as our A/B testing tool for a number of reasons. We are using Redis already and Vanity does its metrics and metric tracking in Redis. One of my colleagues has a good understanding of the internals of the Vanity source code as well. 

The Vanity documentation is pretty good but I thought this post could help for those getting started. Read the [labnotes blog documentation](http://vanity.labnotes.org/) and the 2-minute demo instructions first. We have used Vanity with Redis, which is the single data store it originally supported, but it has since been expanded to support ActiveRecord (RDBMS) and MongoDB. Keeping experiment and participant tracking in a separate data store like Redis was better than the database in terms of speed. We have also been able to develop some patches to disable Vanity if Redis goes down without taking the (database-backed) site down as well.

## Getting started
**Create the experiment directory and files**. A generator would be useful here. This example creates an experiment that presents multiple prices for a commerce website. In vanity each experiment requires a Ruby source file in the `experiments` directory, which is at the root of the Rails app. Run the following from the Rails root:

```sh
mkdir -p experiments/metrics          
touch experiments/price_options.rb
```
Add the following configuration to the `price_options.rb` file that you just created.

```ruby
ab_test "Price options" do
  description "Which price is the best price?"
  alternatives 19, 29, 39
end
```

Now the experiment can be referenced by its name using the `ab_test` method (a downcased, underscorized, and symbolized version). You can call `ab_test` from views, controllers, helpers, and even model files.

**Create a metric**. When a website visitor of yours is participating in an experiment, they will see one of the alternatives defined by that experiment. An experiment should have some goal associated with it, such as making a purchase. Vanity will handle showing the alternatives randomly, tracking the alternative a given participant saw, and ensuring participants continue to see the same alternative on subsequent visits. We need to instrument the application code at specific places to indicate where a goal has been completed. Create a metric file in the `experiments` directory you created earlier:

```bash
touch experiments/metrics/signup.rb
```

Add the following to your metrics file. You could have a "database-backed" model by using a model class from the Rails application where Vanity is used, but this example will be a simple metric without a database model.

```ruby
metric "Purchase" do
  description "Tracks the performance of various prices in terms of how many purchases their participants produce"
end
```

Site visitors need to be identified in some way for Vanity to work properly. This is a bit easier with logged-in users, because they probably have a database record that identifies their account uniquely, which could be used with Vanity. Without a database record, you can create a session to identify each user, or use their IP address, or some other way that makes sense for your application. In the project I'm working on, we have visitors that do not have accounts yet. I use the `use_vanity` method from Vanity without any arguments, which creates a `vanity_id` for that visitor. The `vanity_id` for a user is available across multiple requests since it is available as a cookie and sent with each request.

## Reporting
When participants have viewed alternatives and you're ready to look at report output, you can generate results to a output file or use a dashboard. As of this writing, the report output does not work. You will need to have your data store running (Redis in our case) since it will use the datastore to pull participant data. Typically we just use the dashboard to view participation counts.

```sh
vanity report --output vanity.html
```

## Dashboard
Vanity reports are available with some controller and view code provided by the gem. The documentation has you create a vanity controller, but you can also move these controller actions and view code around in your application. If you follow the instructions, the gem has actions that make assumptions about the controller being there and being named a certain way, and a route being available to route to the vanity controller. The following syntax works in Rails 3.

```ruby
match '/vanity(/:action(/:id(.:format)))', :controller=>:vanity 
```

Create the vanity controller to report results:

```sh
touch app/controllers/vanity_controller.rb
```

Inside your controller (to get the actions) make sure to `include Vanity::Rails::Dashboard`. We ended up using the vanity template Erb files directly by copying them into the main application code so we could edit them and have more control over the presentation.

Viewing the vanity controller dashboard won't work if the experiment object has a nil value for `created_at`. By default in development Vanity won't record participants for the experiment, so without recording turned on, the experiment doesn't set `created_at` at load time, which breaks the dashboard when you try and load it. To enable tracking in the development environment, I set:

```ruby
Vanity.playground.collecting = true
```

Now when the server starts up, it connects to Redis to set the experiment `created_at` first, this is the data in redis that backs the experiment model file. You should see something in the Redis log like the following:

```sh
+1297968800.845316 "setnx" "vanity:experiments:price_options:created_at" "1297968800"
```

I'm planning to write more about Vanity as we have some ideas for additional tooling, and have some commits that help make it more robust that we can hopefully push up to the project. I have had a couple minor patches merged in to the main Vanity source, so I know the maintainer is open to adding new features and bug fixes.

Are you doing A/B testing? Are you using Vanity or something else? Hopefully this article helps you get started doing some A/B testing in your project.
