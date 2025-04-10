---
layout: post
title: Node Knockout
date: 2010-09-01
comments: true
tags: [Events, JavaScript, Programming]
---

This past weekend I participated in Node Knockout with three teammates: Paul Armstrong, Zach Johnson, and Nate Kadlac. Nate and I have worked together on [Train Brain](http://trainbrainapp.com/), I met Paul through work at a previous employer, and Zach through Paul, and at [MinneDemo](http://minnedemo.org/).

## Competition
We all signed-up because we'd heard that Node was a big deal and wanted to try and build something with it. Node Knockout is a 48-hour programming competition where participants build something on top of [Node.JS](http://nodejs.org/). Check out our [competition team page here](http://nodeknockout.com/teams/jackalope).

## Technology
At work we’re using WebSockets in our web application to push data to connected web clients from a Rails application. My coworker John added Node to hold on to incoming WebSocket client connections, and Redis to communicate between Rails and Node.

I added a project to my GitHub account that uses a similar stack of tools, the start of a checkers game, to push checker moves between clients. With that experience, and the extremely valuable [Node.JS Peepcode screencast](http://peepcode.com/products/nodejs-i) ($9, highly recommended), we organized our virtual team (1 person in Maryland, 2 in Minnesota, 1 in California) via Basecamp and Skype ahead of the competition. During the competition we used the Campfire chat app and had Skype conference calls during the weekend to report on progress and assign new tasks.

## Getting started
I started with the organization structure from the Peepcode screencast, vendoring Node modules in a `vendor` directory keeping the main `server.js` file small, and our application code in a `lib` directory. I also set up deployment on a Joyent instance since the other available host Heroku did not support WebSocket connections. 

While I was getting the server set up, Zach worked on code to capture mouse cursor position and click data, and Paul worked on adding a visualization tool (originally [Protovis](http://vis.stanford.edu/protovis/), which was later abandoned), and optimized the performance of it so that it would re-render very fast. Nate started on some UI mockups that he shared in Campfire throughout the weekend for us to give feedback on.

## The project details
The project we selected was "realtime heatmaps of visitor traffic", so I knew we would want WebSockets to send and receive data. Browser support is getting better: Safari 5 and Chrome work now, and the latest beta of Firefox 4 worked as well.

The project would show off the benefits of an asynchronous web server (requests do not block), since we planned to have lots of concurrent clients. On the Websocket side I first tried to use Socket.IO but had trouble. Then I added Faye which is the library in the Peepcode screencast, but we really didn’t need publish/subscribe functionality yet, since we were working towards one website sending data to one admin interface initially. I wasn’t able to get it working as quickly as I wanted, so I bailed for plain Websocket connections on both the data-sending end (we called this `clientStats.js`), which used the `send` method of the Websocket connection to push data to the server. 

On the admin end (we called this `adminInterface.js`), the code responded to the `onmessage` event, where the data was displayed as a heatmap (both cursor position, and clicks). 

Meanwhile Zach and Paul decided to go another route and use a different Heatmap as a starting point, from which they added several optimizations to improve client-side performance. Mid-way through the first day Nate had something close to the final design that we all liked and started doing the front-end development work on.

## Refining the project scope
We hoped that visitors could get heatmaps of any page they included some JS on, but that added significant complexity to the admin interface (choosing a site), and the back end (routing data), so we moved that out of our initial scope. We decided to make a test web page and include the snippet there. Paul designed and built that page, and deployed it as a GitHub page from a public repo. 

We also planned to use a screenshot web service to insert a screenshot of the page being tracked on the page dynamically, but since we had just one test web page, we added a screenshot to the admin interface of the test website manually. Zach was also able to add some code towards the end to count the number of open connections, and we added that to the interface to see how many others were sending data at the same time. 

## Technical details of the project
In the end, the Node code is fairly simple. It uses [node-websocket-server](http://github.com/miksago/node-websocket-server) to simplify management of websocket connections, and [node-static](http://github.com/cloudhead/node-static) to serve static resources (JS, CSS, image files). The client-side code on both ends responds to events as opposed to polling, so the whole experience is very fast. 

## Next steps towards a real product
In order to turn this into a product, we would need to hold on to data for particular sites, and make sure admin side browsers only receive data for sites they are authorized on.

I’d love to add some tests using the [Vows framework](http://vowsjs.org/) to our application code as well. We would also throttle the send rate a bit and have to work on client-side performance as the visualization is CPU intensive when more than a few visitors are generating data concurrently.

Part of the reason we selected this project was because it was useful and could make money as a product. Some of the reviewers in the competition felt the same way, so we have received good scores in the "Utility" category.

The competition was a good experience overall. We have gotten some great reviews from friends and expert judges, and "Jackalope" was even featured as a favorite entry on [TechCrunch](http://techcrunch.com/2010/09/01/nodejs-knockout/)! 

## Closing thoughts
This was a ton of fun and very satisfying technically. It was great to come together as a team and make contributions on what could be a real product. It was very exciting to see our scores going up from public voting, and see Jackalope mentioned a ton on Twitter by various people around the world. I really enjoyed working with my teammates and was proud of our team!
