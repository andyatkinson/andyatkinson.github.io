---
layout: post
title: "Node Frameworks: Geddy and Express"
date: 2010-08-15
comments: true
tags: [Tips, JavaScript, Programming]
---

In preparation for the [Node Knockout](http://nodeknockout.com/) competition, I decided to look at two frameworks [Geddy](http://geddyjs.org/) and [Express](http://expressjs.com/). 

#### Geddy

Geddy will be familiar to users of Ruby on Rails. Code is organized into model, view, and controller folders, it has a router that maps URLs to controller actions, and built-in generators to create new applications, models or controllers within an application. Geddy also includes Active Record-style model validations.

I tried out the [2-minute geddy app](http://wiki.github.com/mde/geddy/the-two-minute-geddy-app) (accessible through the wiki), which demonstrates CRUD operations on a resource. Overall it worked well. Geddy told me on startup that my Node version was too old, so I built a newer version of Node from source which worked fine. I used SQLite as the data store.

After creating the database with the geddy command, the geddy server wouldn’t start. I forgot to add [node-sqlite](http://wiki.github.com/mde/geddy/install-sqlite-and-node-sqlite) which allowed the server to start. Geddy includes support for other SQL database systems like PostgreSQL and also includes support for CouchDB.

From there I was able to add the model fields, and create records. I did not care for the markup and templating Geddy is using. If I used this in a project I’d investigate [haml-js](http://github.com/creationix/haml-js) for markup and something like [mustache.js](http://github.com/janl/mustache.js/) for templating. 

Geddy even includes an `assert` framework for [unit testing your application JavaScript](http://wiki.github.com/mde/geddy/writing-tests).

#### Express

Express is more like the Ruby Sinatra framework than Rails.

To get started with Express I recommend copying the directories `lib` and `examples/hello-word` out of the framework code into a new project directory. Express will be required this way, and you can start working on your application code.

The "upload" sample app in the Express framework source demonstrates using Haml and Sass for markup and style.

The Express documentation website doesn't have anything on persistent server-side storage options (like SQLite or PostgreSQL). Depending on the application, perhaps an in-memory server-side JavaScript store would be fine. Or perhaps the application doesn't even need server-side persistent storage.

#### Sample app

Let’s store some `SnowDog` objects (from the Geddy sample app) with Express as well, and just store them in memory.  Using the "hello-world" example app from the Express source as a starting point, the following `app.js` demonstrates adding SnowDog objects to memory and serving them to the view layer through the Express `locals` object.

``` javascript
    require('./lib/express')
        
    configure(function(){
      set('root', __dirname)
    })
    
    var MemoryDB = {
      snowdogs: [],
      add: function(snowdog) {
        this.snowdogs.push(snowdog);
      },
      all: function() {
        return this.snowdogs;
      }
    }
    
    function SnowDog(name) {
      this.name = name;
    }
    
    get('/', function(){
      
      var s1 = new SnowDog("bob");
      var s2 = new SnowDog("jane");
      
      MemoryDB.add(s1);
      MemoryDB.add(s2);
      
      this.render('front.html.ejs', {
        locals: {
          title: 'Hello World',
          name: 'Friendly user',
          items: MemoryDB.all()
        }
      })
    })
    
    run()
```
    
#### Conclusion

I hope this helped explain Geddy and Express.
