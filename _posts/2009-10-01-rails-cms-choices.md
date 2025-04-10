---
layout: post
title: Rails CMS Choices
date: 2009-10-01
comments: true
tags: [Tips, Ruby, Rails, Tools]
---

Rails content management system options:

## [Radiant CMS](http://radiantcms.org/)
- Clean administrative UI
- Active development (September 2009)
- A volunteer group I was part of built [americas.org](http://americas.org) with Radiant. Building HTML/CSS templates outside of Radiant first is highly recommended. We noticed varying levels of Radiant plugin quality/maintenance. Radiant seems to be flexible enough and has a usable UI, though it could be fairly heavyweight for a small project or team. It is under active development.

## [Adva CMS](http://adva-cms.org/)
- Seems promising, documentation lacking (August 2009)
- The Rails engines approach is interesting. UI is nice.

## [Browser CMS](http://www.browsercms.com/)
- Workflow features, would be overly complicated for our team.
- Has the most impressive way of editing content visually.

## [Refinery Content Manager](http://refinerycms.com/)
- Simple UI
- Refinery code is within a Rails app as a plugin

## [RubyFlow](http://github.com/Sutto/rubyflow)
- The source code behind RubyFlow and other sites by Peter Cooper, could be useful for a news site but probably not a general CMS.

More choices, didn't try these out though:

## [Zena](http://zenadmin.org/)
- Multilingual may be useful for you. Originally developed in Rails 1.2 timeframe.

## [Seed](http://github.com/desaperados/seed) CMS
- Good out of the box styling

## [Railfrog CMS](http://www.railfrog.com/)
## [Comatose](http://comatose.rubyforge.org/)
If very minimal editing is necessary, [Static](http://github.com/trevorturk/static) may work. Made for easy deployment on Heroku, which does not offer local file storage (outside of `/tmp`), so configuration of an Amazon S3 account is necessary to store uploads. Simple code, zero UI, a starter app.

If editing on the web is not necessary at all, [Marley](http://github.com/karmi/marley) may be an option.

[Nesta](http://effectif.com/nesta) is built on the Sinatra Ruby framework.

Finally, if your website isn't going to change frequently, and technical people can change it, a static site generator could be a good option. 

[Staticmatic](http://staticmatic.rubyforge.org/) lets you build a site with Rails view concepts using Haml and Sass.

I hope this list is useful as a starting point for picking a Rails-based CMS.
