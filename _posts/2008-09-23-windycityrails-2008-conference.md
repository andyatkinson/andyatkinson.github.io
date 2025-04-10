---
layout: post
title: WindyCityRails Conference 2008
date: 2008-09-23
comments: true
tags: [Ruby, Rails, Conferences, Events]
---

My notes from the [WindyCityRails 2008 1-day conference](http://windycityrails.org) held Saturday September 20th, 2008 in Chicago. This conference was for the Ruby on Rails framework. I traveled from Minneapolis for the conference.

## DHH Q&A
David (DHH) had a 30-minute morning Q&A session. Recently 37Signals publicly discussed performance-improvement work to Basecamp, so it did not surprise me that performance was a theme of David's discussion.  David said "optimize for HTTP" to improve the user experience most.  Do this by setting long expiration headers, gzipping static content, and using etags. Follow guidelines from tools like the Y!Slow plugin.  David discussed an upcoming addition in Rails, a [fresh?](http://ryandaigle.com/articles/2008/8/14/what-s-new-in-edge-rails-simpler-conditional-get-support-etags) method available on `request` which prevents generation of a page if the etag has not changed.

When asked about guarding intellectual property (Ruby code) in Rails apps, David suggested trying to host it (like Basecamp). Regarding upcoming thread safety in Rails 2.2, David said this is like free ice cream, everyone loves it. However for most applications, using the Matz Ruby interpreter (MRI), there wouldn't be much performance improvement ("but hey, it's still free ice cream"). JRuby (or other alternative Ruby interpreters) will benefit more because they [have true system native threads](http://blog.headius.com/2008/08/qa-what-thread-safe-rails-means.html).

David discussed some `ActiveModel` work forthcoming in Rails that would replace cache sweepers.  He also discussed internationalization support.  A `translate` function is how a developer will look up a language string. He discussed language peculiarities the Rails core team has discovered as a result of adding internationalization support, describing how in Russian, the month is said differently depending on the format of the date string. 

One person asked David what he was excited about in web development in general, he replied CouchDB (and document databases) are interesting.

## Metrics and testing
A testing tool "flog" was demonstrated.  It assigns numbers to Ruby methods, where higher numbers indicate more complex methods.  More complex methods could be good candidates for refactoring. [Saikuro](http://saikuro.rubyforge.org/) is a testing tool that analyzes cyclomatic complexity. Semi-related, one presenter mentioned a "developer card" which could be part of a user story approach to project planning. A developer card builds explicit time into the project for developer activities like refactoring.  "Source control churn" was mentioned, with the idea being that files that are checked in very often are a "smell" and potential candidates for refactoring.  <a href='http://metric-fu.rubyforge.org'>metric_fu</a> is a Rails plugin for metrics and reports.

## Web development on iPhone
iPhone Mobile Safari supports CSS3 properties like -webkit-box-shadow.  Using Safari on the desktop? Use XRAY for CSS and DOM help.  [Tank Engine](http://github.com/noelrappin/tank-engine/tree/master) was announced by the creator Noel Rappin, a successor to plugin `rails_iui`, addressing issues he has faced with prior tools.  Many developers will be excited to hear it is built on jQuery.

## Sleight of Hand for the Ruby man
Aaron Bedra demonstrated writing a configuration file parser using metaprogramming techniques.  He mentioned the [Inspector tool](http://github.com/spicycode/the-inspector/tree/master) that lets developers run `Inspector.where_is_this_defined` in script/console to find where a method has been redefined.  He recommended the Pragmatic Programmer screencast series on metaprogramming.

## Merb
Yehuda Katz overviewed [Merb](http://merbivore.com/), a Ruby web development framework (an alternative to Rails) approaching its "1.0" release.  Small points I noted: "plugins stay stable" and code like <code>logged_in?</code> could be moved to the router (equivalent to `routes.rb` in Rails) instead of the application controller. Merb can detect whether a page is page cacheable or action cacheable, and do that automatically.  

Yehuda demonstrated managing Merb as a single process with Ruby Enterprise Edition while still having multiple Mongrel instances to which requests were routed (he had nginx doing load balancing), providing easier management (similar to Apache with Passenger Rails deployment), however this is built-in to Merb.  Some of the above features may not be available until the 1.0 release.

## RSpec
[Cucumber](http://cukes.info/), a replacement for StoryRunner from RSpec, was briefly discussed and demonstrated.

I enjoyed the conference and visit to Chicago. I hope to attend again in the future.
