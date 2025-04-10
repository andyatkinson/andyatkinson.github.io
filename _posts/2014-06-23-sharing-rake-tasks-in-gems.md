---
layout: post
title: "Sharing Rake Tasks Defined in a Gem"
date: 2014-06-23
comments: true
tags: [Ruby, Tips]
---

This tip describes how to write a rake task in a gem, then use it in another Ruby gem or Rails app.

## Create a rake task in a gem
Create a `lib/tasks` directory in your gem. Create a rake task in that directory with the same syntax it would have in the Rakefile. The file should have the `.rake` extension.

Now include the rake task in the Rakefile for the gem by using `import`. For example: `import "./lib/tasks/downloader.rake"`.

## Use the rake task in another gem
In the second gem, create a `Rakefile` for the project and load it using the `load` method. As an example, we can load the "downloader" rake file from the *corenlp* gem [^gem] with this snippet:

```rb
spec = Gem::Specification.find_by_name 'corenlp'
load "#{spec.gem_dir}/lib/tasks/downloader.rake"
```

Verify the task shows up when running `rake -T` (make sure the task has a description!) and can be invoked as expected.

## Use the rake task in a Rails app
We used `load` in the Rakefile for a Rails app in the same way. Working with the [Railtie](http://api.rubyonrails.org/classes/Rails/Railtie.html) [^railtie] could be another way to include the task.

## Conclusion
Sharing rake tasks between Ruby apps keeps your code DRY. If you found this tip useful let me know! Thanks for checking it out.

[^gem]: [CoreNLP gem](https://github.com/andyatkinson/corenlp)

[^railtie]: [Railtie API docs](http://api.rubyonrails.org/classes/Rails/Railtie.html)
