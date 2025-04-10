---
layout: post
title: Rails Deployments
date: 2008-10-01
comments: true
tags: [DevOps, Ruby, Rails]
---

This September I deployed two Rails applications with different stacks, and I wanted to share the details.

## Personal project
- Ubuntu Gutsy (7.10) [slicehost](http://www.slicehost.com/) image
- Apache 2.2 with [Passenger](http://www.modrails.com/)
- MySQL 5
- [Hoptoad](http://www.hoptoadapp.com) exception reporting

A 256MB slice runs this low traffic application OK. For two or more applications, more memory is preferred. I developed this application with [Git](http://git.or.cz/) version control, the repository was hosted on [github](http://github.com/).

## Work project
- Ubuntu Hardy (8.04) [Amazon EC2 image](http://aws.amazon.com/ec2/) (customized an existing AMI)
- Asset storage on [Amazon S3](http://aws.amazon.com/s3/) via the <a href='http://github.com/technoweenie/attachment_fu/tree/master'>attachment_fu</a> plugin
- [nginx](http://nginx.net/) web server (static assets and load balancing)
- [PostgreSQL 8.3](http://www.postgresql.org/) on separate instance
- cluster of [mongrel](http://mongrel.rubyforge.org/) application servers
- [Sphinx](http://www.sphinxsearch.com) 0.9.8 search engine
- server monitoring with [monit](http://tildeslash.com/monit/)
- server backups via [s3sync](http://s3sync.net/wiki)

The staging server for the development initially ran a [CentOS](http://www.centos.org/) Linux image, before I realized how painful it was to have separate production and staging environments.

The Amazon EC2 "Small Instance" has 1.8GB RAM as of this writing.  Our application puts a very small load on the server, even with many mongrels running. This application was developed with [Subversion](http://subversion.tigris.org/) version control, the repository was hosted internally.

Both applications send email. For my personal project I configured [postfix](http://www.postfix.org/). [Capistrano](http://www.capify.org/) was used for deployment in both applications.
