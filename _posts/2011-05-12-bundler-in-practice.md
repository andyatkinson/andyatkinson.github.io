---
layout: post
title: Bundler In Practice
date: 2011-05-12
comments: true
tags: [Ruby, Programming, Tips]
---

We recently deployed a Rails 3 application that uses [Bundler](http://gembundler.com/) to manage dependencies. We freeze the gems in the application so it can be deployed on the same boxes as other applications that have different gems. It is best to start with a gemset with zero gems, then install only the bundler gem, then let bundler install everything else. Installing gems *should* be as simple as `bundle install`. Built gems will have a `.gem` file stored in vendor/cache. We tried a few options before getting things right with Bundler, and did notice some fixes related to freezing gems that were present in `1.0.12` which is what we're using now.

## Lock file
The lock file (Gemfile.lock) will write the specific version numbers of gems where version numbers were not already provided, as well as write out the name and version number of any gem that is declared as a dependency of a gem. In this way you know that your coworkers will get the right gems installed when they run `bundle install`. This is an improvement where different developers could have different versions of gems and not have any issues until runtime. I still specify the version number in the `Gemfile` explicitly, since it is an opportunity to check the version numbers in use in other applications, and I feel it is good practice to be aware of which versions are in use.

## Config file
Sort of like the `.git/config` file which has some git repository metadata, the bundler config file will store some settings here. This file should not be version controlled. Contents of a `.bundle/config` file might look like the following.

```ruby
--- 
BUNDLE_FROZEN: "1"
BUNDLE_DISABLE_SHARED_GEMS: "1"
BUNDLE_BIN: bin
BUNDLE_PATH: vendor/bundle
```

## Bundler in practice
One of the most frequent problems team members have with bundler (especially where it is not used) is remembering to run executables with `bundle exec` in front of the command (when gems need to be loaded by bundler first). A rake command may need to load the Rails environment, and rails may be loaded by bundler, so `bundle exec rake` would be necessary instead of `rake` in that case.

The other problem is adding new gems in an application where they are all frozen. Previously I had been running `bundle install` with the `--deployment` option (it seems to have the same effect as package, i.e. building a `.gem` file in vendor/cache), but the bundler documentation says to not use `--deployment` on a development machine. However running `bundle install` first, then  again with the `--deployment` option, fixes the issue.

The [bundler documentation on packaging](http://gembundler.com/bundle_package.html) says to run `bundle package` to build the `.gem` files in vendor/cache. 

## Editing a gem locally
If you have local edits to a gem, you probably want to keep the source in a separate location from where bundler would put it (`vendor/bundle`). To store the gem source in another location, specify the `--path` option to `bundle install`, e.g. `bundle install --path vendor/gems`. Another option is to specify a git repository with the `:git` option on a per-gem basis in the `Gemfile`. In one case bundler downloads and builds a gem from a project fork on GitHub using this option in our project. We have a lot of internal gems behind the firewall using [Gem in a box](https://github.com/geminabox/geminabox) with the internal gem host added to the project `Gemfile`.

## Binaries or other executables
Accessing binaries or other executables like Ruby scripts with Bundler is a little different. Bundler provides a `--binstubs` option which generates binaries for each one in the project. Refer to the [bundler man page](http://gembundler.com/man/bundle-exec.1.html) for more details. We used this option with Jammit (an asset packager) for a while and had to call `bin/jammit` from Rails root instead of just `./jammit`.

## Conclusion
I hope some of these tips help you get started or out of a jam with Bundler. Bundler had some critics early but it is an improvement over the previous method of managing dependencies for Ruby projects.
