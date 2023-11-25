---
layout: post
title: Moving A Rails App to Heroku
date: 2010-07-26
comments: true
tags: [DevOps, Ruby, Rails]
---

This website runs on an open source blogging application I developed called Rehash. The application has always been deployed on a virtual private server but I wanted to try moving it to Heroku. 

#### Initial experience

Creating the Heroku app `heroku create` and pushing it up `git push heroku master` worked great. Heroku installed Rails 2.3.3 gems since that is what the app is using now. I have created a handful of Heroku apps over the last year or so but the initial experience of creating, pushing, and booting an app works so smoothly it is still a thrill.

#### Git submodules

Git submodules are not supported by Heroku and Rehash was using submodules to manage plugin code. Heroku has instructions on how to bring submodules in a project into the main repository, and the Heroku scripts made it easy. ([Heroku docs on submodules](http://docs.heroku.com/constraints#git-submodules))

#### Gems

The following gems were not installed so the app did not immediately boot. [Heroku documentation on managing gems](http://docs.heroku.com/gems)

    haml, acts_as_markup, friendly_id, thoughtbot-paperclip, mislav-will_paginate, gravtastic  

Paperclip and will_paginate needed to be updated to the versions found on [Rubygems.org](http://rubygems.org). Rehash was looking for the versions of the gems that were hosted on GitHub, which no longer hosts gems.

First successful boot console output:

``` bash
    -----> Heroku receiving push
    -----> Rails app detected
    -----> Detected use of caches_page
           Installing caches_page_via_http plugin... done

    -----> Installing gem rails 2.3.3 from http://rubygems.org
           Successfully installed activesupport-2.3.3
           Successfully installed activerecord-2.3.3
           Successfully installed actionpack-2.3.3
           Successfully installed actionmailer-2.3.3
           Successfully installed activeresource-2.3.3
           Successfully installed rails-2.3.3
           6 gems installed

    -----> Installing gem haml >= 2.2.2 from http://rubygems.org
           Successfully installed haml-3.0.13
           1 gem installed

    -----> Installing gem acts_as_markup 1.3.3 from http://rubygems.org
           Building native extensions.  This could take a while...
           Building native extensions.  This could take a while...
           Successfully installed wikitext-1.12
           Successfully installed RedCloth-4.2.3
           Successfully installed acts_as_markup-1.3.3
           3 gems installed

    -----> Installing gem friendly_id 2.1.3 from http://rubygems.org
           Successfully installed activesupport-2.3.8
           Successfully installed friendly_id-2.1.3
           2 gems installed

    -----> Installing gem paperclip 2.3.1.1 from http://rubygems.org
           Successfully installed paperclip-2.3.1.1
           1 gem installed

    -----> Installing gem will_paginate 2.3.14 from http://rubygems.org
           Successfully installed will_paginate-2.3.14
           1 gem installed

    -----> Installing gem gravtastic 2.1.3 from http://rubygems.org
           Successfully installed gravtastic-2.1.3
           1 gem installed

           Compiled slug size is 10.2MB
    -----> Launching........ done
           http://evening-night-54.heroku.com deployed to Heroku

    To git@heroku.com:evening-night-54.git
     * [new branch]      master -> master
```

#### Sass

Rehash uses Haml and SASS for the view layer. Support for SASS was added in August of 2009 to Heroku. Heroku added a plugin that writes the generated files into the tmp directory. I added this plugin to Rehash. ([Heroku blog post on SASS support](http://blog.heroku.com/archives/2009/8/18/heroku_sass/))

#### Data

The next error to work on was fixing the database. No schema is present (or any data). At this point I thought I needed to supply a `database.yml` file since none is checked in to version control.

Using the `taps` gem, Heroku pushes or pulls the schema and data from one server to another. I created some dummy data in a local Rehash installation and pushed this up `heroku db:push`. At the time of this writing I needed to install an older version of taps than the latest available `sudo gem install taps -v 0.2.26`.

At this point the app was installed and running! However the Projects feature uses Paperclip to store uploaded screenshots, and Rehash was configured to use the local filesystem to write the uploads to disk. Heroku writes the following error into the log file.

``` bash
    Read-only file system - /disk1/home/slugs/245277_5ddf65b_804f/mnt/public/system - Heroku has a read-only filesystem.  See http://docs.heroku.com/constraints#read-only-filesystem
```

#### Read-only filesystem

Various guides exist to configure Paperclip to use S3 for storage, I’ll skip that here, you can always refer to the Rehash source code. In the end I decided to use the local filesystem storage with Paperclip in development, and S3 in production. 
[Heroku has the following guide on using S3](http://docs.heroku.com/s3). 

I started by using a S3 configuration file to track Amazon S3 credentials, both a public version checked in to git, and a private version. Heroku uses "config vars" which need to be set up with the Amazon S3 credentials instead of configuration files. ([Documentation on config vars](http://docs.heroku.com/config-vars))

Initially adding the config vars failed on my development machine. I updated my Heroku gem installed locally and it fixed the issue. I'm running version 1.9.12 of the Heroku gem. 

Managing the config vars from a local terminal window is easy. If you want to replace a variable, you can delete the variable and re-add it, the Heroku app is immediately restarted to reflect the change. In the end I decided to remove the S3 configuration files altogether [following this blog post](http://blog.heroku.com/archives/2009/4/7/config-vars/).

#### Rails page caching

Rehash was also using the `caches_page` page caching feature of rails to cache particular controller actions like `index` and `show`. Rails page caching doesn't work with Heroku. I decided to remove usages of `caches_page` as a quick fix since it would sometimes serve stale caches anyway. Heroku will use their own plugin which is detected and installed at deploy time for `caches_page`, however the performance is fine for me with the built in HTTP caching Heroku offers. [Heroku docs on HTTP caching](http://docs.heroku.com/http-caching)

#### Email

Now that file uploads are taken care of in production with S3, another piece of infrastructure to address is the mail server. Heroku offers a Sendgrid add-on with a free account level. The free account level allows up to 200 emails per day to be sent, which is more than enough for Rehash. [Heroku Sendgrid documentation](http://docs.heroku.com/sendgrid) 

Almost like magic, after adding the sendgrid add-on, email just works! Rehash uses the "owner email address" used when the site is initially configured as the sender address. Email is generated by users either leaving a message through the contact form, or when a user leaves a comment. In my first test, it took less than one minute for the email to arrive from the application.

#### Domain name and DNS

In order to make the move from Slicehost really complete, I need to move my domain name from my slice to point at my Heroku app. The domain name add-on from Heroku is free as well. I chose to leave DNS with my domain registrar and point it at Heroku. [Heroku custom domains add-on](http://docs.heroku.com/custom-domains)

#### Production data

Pulling the data from the production system into the Heroku app database will complete the transition. In this way I can get the system up and running before updating the domain name, allowing me to do a zero downtime switch. For my blog I wouldn't care if it was down for a while, but for a company website, it is neat to be able to pull data via the taps gem from the current production database and test everything out first. [Blog post on the taps gem](http://adam.heroku.com/past/2009/2/11/taps_for_easy_database_transfers/)

I needed to update RubyGems on my slice and I opened a port on my firewall with iptables following the Slicehost instructions: 

The format of the mysql URL string confused me, here is what I used to get it working:
$ `taps server "mysql://localhost/rehash_webandy_production?user=root&password=password" tmpuser tmppassword`

I had to surround the connecting string in quotation marks. I also had the rack gem version 1.2.1 installed on my system which prevented the taps server from starting. Installing version 1.1.0 of the rack gem resolved that issue.

In the end I skipped the taps gem for pulling from my production MySQL database to my local MySQL database due to problems. I was able use the mysqldump tool to load the data locally, then use `heroku db:push` to push the changes up to the Heroku app. The following three commands show dumping the data on the remote server, pulling the dump file down to the local server, then loading the data from the local file into the local database.

``` bash
    mysqldump -h localhost -u root --password=password dbname > dumpfilename
    scp -P myport admin@server.com:/home/user/public_html/site/current/dumpfilename .
    mysql -u user local_db_name < dumpfilename
```
    
#### Conclusion

Heroku is a great platform. Moving the Rehash application from a VPS server to Heroku means I have to maintain a lot less, it is easier for others to try it out, and it is much less expensive as well.
