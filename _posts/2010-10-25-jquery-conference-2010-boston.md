---
layout: post
title: jQuery Conference Boston 2010
date: 2010-10-25
comments: true
tags: [Events, JavaScript, Conferences]
---

jQuery Conference took place in Boston over two days in October. John Resig kicked it off with a keynote and the sessions generally covered testing and large-scale JavaScript applications, jQuery UI, (the just-released) jQuery Mobile, and widgets and effects. Below are my raw notes from the sessions I attended. Towards the end of the first day I started having a lot more hallway discussions and skipped some sessions.

## Keynote, John Resig
- Grow the framework contributor base, legal accomplishment: join software freedom conservancy, CLA (contributor license agreement)
- 1.4.3: Passes jslint with some modifications (differences outlined and put on website), helps to enforce style guideline, modularizing the source, core, ajax, selectors etc. (can be loaded dynamically and individually, `require.js` or `lab.js` to load chunks of jQuery)
- massive rewrite of CSS module, plugins using it already: jQuery rotate, new CSS stuff, `querySelectorAll`, working on traversal performance (closest, find, etc.) (browser provides query engine), major browser vendors (even Internet Explorer) added native filter capability with is responsible for a big performance improvement
- official jQuery plugins announced
* first plugin: 1) `jquery.data-linking` (keeps form in sync with javascript object), $.data (introduced change event)
* official plugin for templating: jquery-templ  ${} - template object can be fetched from last item
- **new release**: jQuery mobile, opera mobile and opera mini, blackberry browser is still very popular, jQuery mobile attempts to provide an experience to all mobile browsers through progressive enhancements. Will be interesting to see the performance in mobile browsers as lots of javascript and CSS is loaded based on custom data attributes that describe style and functionality. jQuery project references Yahoo! browser grading: A grade is a browser that supports media queries, though that doesn't mean that the JS is good.
- "shipping a stripped down jQuery is not possible" (differences in webkit, different mobile browsers), using testswarm to test various mobile browsers (mobile webkit does not support fixed positioning), scrolling discussion 
show/hide title bar
- shooting for 1.0 jQuery Mobile release for January 2011

## jQuery Mobile, Todd Parker
Todd Parker seemed to have a strong usability background. jQuery Mobile in general has great design, and a lot of attention was paid to usability, accessibility, and support across a huge number of devices.

- (smartphones and tablets)
- iPhone accessibility with voiceover, one codebase, all platforms
- transitions from jqtouch, use custom data-transition attribute
- dialogs are actually a new page, made to look like they are floating on top of the content
- themes and swatches, bar styles and block styles
multiple heading styles to build widgets
- data-role="footer" (determines how the div is styled), data-icon="delete"
- data attributes for various things. option elements inside select for a flip switch
- iPhone tip: 2 finger scroll works inside textareas
- read-only list, list items don't have links inside them
- collapsible/expandable row level control
- touch events (swipe, swipe left and right), orientation change, they do detect orientation change and reflow the page


## funcunit javascript testing, Brian Moschel 
- funcunit testing tool
- env.js, rhino
- problems: low fidelity event simulation, QA license may be more expensive
- funcunit uses qunit for display output
- syn.js functional testing tool

## Rapid testing and development session, Menno Van Slooten
Menno described some approaches he uses to stay productive, specifically during development of heavy JavaScript applications with lots of user interface state that may be time-consuming to recreate.

- use your feedback loop
- use static html to shorten test cycle
- web developer plugin firefox: "view generated source"
- tools: mockjax, mockjson
- $.autorun trigger events on elements - automate a UI flow and can save a lot of time for edits
- tip: block comment, add a slash character on bottom block, makes it easier to do C-style multi-line comments, and comment and uncomment blocks
- Mockjax, MockJSON: create template to randomly choose from values to test various conditions, "fathers|5-10" or "married|0-1" (will choose from these values)
- create random dates, numbers, strings, arrays
- simulate user interaction
- asked why these tools aren't better known: "I tweeted about it and no one retweeted me" (laughs)

## Code organization, Rebecca Murphy
- official title: functionality focused code organization
- object literals
- module pattern
- revealing module pattern (talk she gave last year)
- YQL yahoo query language
- book recommendation: javascript patterns
- "Write code that is readable by someone else"
- tool: diversion, does pub sub as an alternative to custom events
- require.js (covered in jQuery and friends talk)
- require.def(fn) defines a function when a module is included
- app mediator, page mediator, services (searches, results)

## Various topics, Alex Sexton
Alex's talk covered a number of tools that might be useful for large JavaScript projects.

- html5 r0cks
- module loader: requireJS
- commonJS compatible: standards organization
- Lab.js (loading and blocking js) (load a script and run code after it is loaded)
- Yepnope: conditional loader from Alex
- Modernizr: feature test the future
- Polyfills: implement something in an older browser that is not there
- templates
- Underscore.js: js utility tool
- PubSub library to decouple design, alternative to custom events
- EasyXDM makes it easier to do cross domain requests
- Backbone.js (just released that week, Alex recommended investigating it)
- $.widget from jQuery UI
- json2 and closure compiler

## Widgets talk
- cleanslate.css: like reset but targets a specific widget
- blocking scripts - don't do it

## jQuery Effects: beyond the basics, Karl Swedberg
- cannot animate certain properties: z-index, backgroundImage
- animate properties with a relative unit or a fixed unit
- check the position property
- gotchas: animating both bottom/top or left/right
- stand-alone easing plugin
- use the queue method to control the order of animations
- repeating callbacks, make a self executing function and keep a counter
- use :animated pseudo-selector
- use stop() method to control animations

## SproutCore talk Yehuda Katz
Yehuda Katz recently joined the Sproutcore team. He shared that Sproutcore uses jQuery as a core. His talk positioned jQuery as the standard library of the web, and he talked about how Sproutcore optimizes for performance to create desktop experiences in a web browser.

- SC ideas, performance is a big idea
- advantage of full page load: (wait until full page is loaded, then take action (vs. partial load))
- batched jQuery (addClass and removeClass on a buffer, removing the DOM from the picture)
- jQuery.subclass  (work on a shadow jQuery object), check deadlyicon work on GitHub (makes it possible to do buffered jQuery)
- Concept of a Runloop, borrowed from Apple's Cocoa framework
- Observer in sproutcore: if this property changes, update something
- Bindings: jquery-datalink
- binds an object to a field

## JavaScriptMVC session
JavaScriptMVC is a heavier framework that "has it all" for large JavaScript projects, more like Rails than Sinatra. For example, it has conventions for breaking up functionality, organizing files, and testing tools built-in.

- not strong conventions in JavaScript projects when you start to break things up into several files. JavaScriptMVC does dependency management
- StealJS is what JMVC uses
- "resources" are third party scripts
- "controller" controls a dom element, uses pubsub to communicate
- "dev.js" script for debugging that is available in the development environment

## Super Awesome jQuery Interactions, Matt Kelly
Matt works at ZURB in San Francisco. I love some of their projects, particularly their design and attention to user details. Unfortunately I had to leave early to catch my flight home. One thing I did catch was that ZURB has a jQuery plugin that adds event support for "cut" and "paste" in the browser I wanted to investigate further.

## Conclusion
jQuery Conference was a great conference and it was fun to visit Boston for the first time.
