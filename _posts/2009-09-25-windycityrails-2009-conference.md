---
layout: post
title: WindyCityRails Conference 2009
date: 2009-09-25
comments: true
tags: [Ruby, Rails, Conferences, Events]
---

I attended WindyCityRails in Chicago this year. [Videos of the sessions are available here](http://windycityrails.org/videos).

## Better Ruby through Functional Programming by Dean Wampler
- difficulty is sharing access to variables. add immutability. work with (frozen) copies of variables.
- don't use mutators (e.g. bang methods in Ruby)
- substitute the value for the function call for the same inputs
- object should have well-defined states and state transitions
- compose domain models from simple classes
- fold/reduce: convert to smaller representation. smaller representation of integers would be adding them together.

## Super-easy PDF Generation with Prawn and Prawnto by John McCaffrey
The most popular option lately in the Ruby community seems to be Prawn. John enlightened me to other options and different styles of PDF conversion.

- PrinceXML best in class, but server license is nearly $4,000
- wkhtmltopdf (webkit)
- PDF templates, like an Erb template, binding data to it. e.g. "itext" (Java)
- PDF generation, ruport, prawn, supports TTF fonts
- PDF::Inspector to test PDF generation
- Prawn-to is a view builder
- grid based layout. 
- had a great PDF conversion use case graphing twitter data with google charts in a web app, then making a attractive printable copy.
- Prawn-format, leverage html/css for styling
- pdftk

## Comics Is Hard: On Domains and Databases by Ben Scofield
The first two thirds of Ben Scofield's presentation was a whimsical discussion of comic books and biology taxonomy. He basically made the point that they are difficult to segment and organize within a relational data store.

- recommendation is to use a SQL-less datastore. A few options exist, key value stores, recommended reading is EY posts on k/v data stores. Options include tokyo cabinet, redis, cassandra (from facebook). Use a document-oriented datastore such as CouchDB or MongoDB. MongoDB is getting some traction now, check out MongoMapper to map model classes to Mongo documents. 
- the "new new hotness," "graph databases" e.g. neo4j, allegrograph

## UI Fundamentals for Programmers by Ryan Singer
Same talk given at RailsConf 2009. [Course notes here](http://development.courseadvisor.com/2009/05/07/notes-on-ui-fundamentals-for-programmers-by-ryan-singer/) and [RailsConf blog post here](http://onrails.org/articles/2009/05/06/railsconf-2009-day-one).

- UI is a software layer, don't build it at the end 
- start with the interface, start modeling right away
- "lots of function, no explanation" (a programmer smell i.e. UI designed by a programmer)
- recommended reading "domain driven design"

## Screens
- skip the chrome, work on the body first, spec this out
- answer the question "what matters to the person using this screen?" or "what are people trying to do?"
- talked about the concept of "least effective difference" which is "just enough contrast"
- take one UI concept and double it, see how it scales within the UI.
- Users' attention has a halo, it grabs the attention of stuff around it

## Flows
- Actions have a beginning, middle, and end

Keep templates clear and intention focused.

## How To Test Absolutely Anything (in Rails) by Noel Rappin
Noel moved through various parts of the Rails stack and described techniques for testing. He also covered things outside of Rails like unit testing JavaScript.

- Test anything with a regex
- test for semantic structure, `assert_select` e.g. `assert_select "li:not(#edit)", :count => 2`
- Referenced the `ActionController::RecordIdentifier#dom_id` method for view testing
- suggested the Cucumber email spec for testing email delivery
- mentioned `ActionController::Integration::Runner#open_session` to create session instances for session testing
- Suggested using mock objects to test third party sites, mentioned Timecop gem to manipulate time
- Mentioned `ActionController::TestProcess#fixture_file_upload` which may be useful testing file uploads
 
## Optimizing Perceived Performance by David Eisinger
David advocated for UI snappiness to improve user experience. He used jQuery to load and display content and submit forms. His sample app is funny, [the code for dbdb is on GitHub](http://github.com/dce/dbdb).

## Rails 3 Update by Yehuda Katz
Yehuda spent some time introducing himself and discussing the Rails and Merb merger. Yehuda presented the previous year at WindyCityRails introducing Merb, which was approaching its 1.0 release at that time.

A significant part of the talk was about framework design philosophy, RESTful design, caching at various tiers, and the "integrated philosophy" you won't find in other web frameworks.

Application developers are able to work on "their problems" and "share work on common problems." Rails 3.0 should not become more difficult to learn for beginners than previous versions, "make the on-ramp really smooth."

At that point he moved into more features and recommendations:

- Use asset hosts so cookies are scoped to your app, less HTTP requests
- Talked about Rails 3 worker queues
- Rails 3 will be JS framework agnostic. JavaScript will use generated markup.
- persistence agnosticism, not bound to ActiveRecord, could use Hibernate, Cassanda, or MongoDB for example
- block_helpers are reworked
- asset bundler
- `config.gem` reworking
- activemodel
- generators are rewritten. allow more configuration, e.g. specify `--rspec`

## More conference coverage
- [neotericdesign blog](http://www.neotericdesign.com/blog/2009/09/windy-city-rails.php)
- [Ben Scofield summary](http://benscofield.com/2009/09/windycityrails-recap/)
- [John Yerhot notes](http://www.johnyerhot.com/2009/09/13/thoughts-from-windycityrails-2009/)
- [Ray Krueger blog](http://raykrueger.blogspot.com/2009/09/windy-city-rails-2009.html)

## Ruby Inside
I was also able to contribute my first article to Peter Cooper's Ruby Inside as a [writeup on this year's Windy City Rails](http://www.rubyinside.com/7-video-presentations-from-the-windycityrails-2009-conference-2592.html).
