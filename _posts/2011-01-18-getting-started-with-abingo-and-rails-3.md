---
layout: post
title: Getting Started with A/Bingo and Rails 3
date: 2011-01-18
comments: true
tags: [Tips, Lean Startup, Ruby, Rails]
---

[A/Bingo](http://www.bingocardcreator.com/abingo) is a "A/B" or "split" testing framework to try out different text or images (or other things) and see how they perform relative to each other. [Vanity](https://github.com/assaf/vanity) is the another a/b testing option for Rails applications, and is probably more popular as of this writing. However A/Bingo is a nice library as well and is perhaps a bit simpler. Ryan Bates did a great job explaining the basic idea and implementation of [A/Bingo in a Rails 2 app here](http://railscasts.com/episodes/214-a-b-testing-with-a-bingo), but what about Rails 3?

This article attempts to help people get started with A/Bingo in Rails 3. Assuming you have Rails 3 gems installed, the following commands will generate a new app, install the plugin, and add database tables the plugin uses.

```bash
rails create abingo_app
cd abingo_app
rails plugin install git://git.bingocardcreator.com/abingo.git
rails generate abingo_migration
rake db:migrate
```

I'm using Sqlite3 in development. A/Bingo adds "experiments" and "alternatives" tables, you can verify they are present (`rake db:migrate` will show them as well) after your migration has run:

```bash
sqlite3 db/development.sqlite3
.schema
```

Next I added the application controller code in the sample instructions. The idea here is to show each user one of the alternatives for the experiment (there can be more than two alternatives), but show the same alternative to the same user across page loads (give them a session, stored as a cookie, or use their database ID to track them). This controller code did not change for Rails 3.

I'm creating a Subscription resource for my app with a RESTful controller that has `new` and `create` actions. In the create action I'll record a successful conversion using the A/Bingo `bingo!` method. Again, this isn't different for Rails 3, except for the routing. Also, if you use the A/Bingo dashboard, you'll need a Rails 3-style route to get to it.

Create a controller for the A/Bingo experiment results dashboard (with no actions):

```sh
rails generate controller abingo_dashboard
```

Include the module from the plugin in `app/controllers/abingo_dashboard_controller.rb`:

```ruby
include Abingo::Controller::Dashboard
```

Add routes for our new controller and the A/Bingo dashboard:

```ruby
resources :subscriptions, :only => [:new, :create]
match 'abingo(/:action(/:id))', :to => 'abingo_dashboard', :as => :abingo
```

Now we can create a simple experiment to alter some copy on the site. I'll use a variant of the example Ryan Bates created for the A/Bingo RailsCast episode. In my case I'm putting the abingo test code into the `new.html.erb` template for the Subscription resource. The view code to measure which of the three alternatives creates the most Subscriptions would be the following. For this sample app, clicking the button (which posts to the create action) is a conversion.

```ruby
<%= button_to ab_test("signup_title", ["Sign up", "Registration", "Free Sign up"], :conversion => 'subscription') %>
```

Run `rm public/index.html` and `rails server` then navigate to `http://localhost:3000/subscriptions/new`. Verify that multiple page reloads show the same button text. In order to track the conversion, we specify the name of the conversion to the `bingo!` method in the Subscriptions controller `create` action.

```ruby
bingo! 'subscription'
```

I navigated to `http://localhost:3000/subscriptions/new` in a couple other browsers (or cleared the cookie storing the session) to create more fake visitor data. Navigating to the abingo dashboard at `/abingo`. I can see which alternatives converted best within the experiment. Without having a lot of visitor data though, the results aren't that useful. The documentation for A/Bingo talks about how to end an experiment and clean up the code.


I hope this helps you get started with A/Bingo a/b testing in your Rails 3 app.
