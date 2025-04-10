---
layout: post
title: "Stack Dive with RunKeeper"
date: 2014-12-09
comments: true
tags: [Programming, Productivity, Events]
---

Doug Williams and Joe Bondi from [RunKeeper](http://runkeeper.com/) gave a technical talk at the [WeWork Boston South Station](https://www.wework.com/locations/boston/south-station/) location in December 2014, as part of the [Stack Dive](http://www.stackdive.com/) series. The talk explored the technical stack that supports the app and web site, as well as tools and processes that have worked well for their team. RunKeeper has huge growth, currently at 38.5 million users, using their native mobile apps in the US and around the world.

One of the technical challenges they have faced with apps around the world is translating the app into many languages, and various levels of quality and accuracy for cellular service and position information.

Users in China have been a big part of their growth, after the app was translated to Mandarin.

## Techniques on the devices
One thing they discussed was their use case for geo coordinates was to show users the coordinates in the app on a map, but they didn't need to index that information. So they could push updates to their API and store that information in a less costly way than writes into a database.

The solution they came up with was to queue up and then write coordinates into rows of a file (rows encoded as JSON) and push the files in to S3. JSON encoded rows on S3 gives consumers of the file structured data to work with that is very high performance. They can also control access to the files on S3 using AWS security controls.

In order to keep the app performing well locally, they have implemented queues and workers on the device itself (in addition to queues and workers on their back-end). On the back-end they are making more use of Amazon SQS. They also recommended using native push notifications on devices over SMS.

The talk was filled with recommendations for various services that have worked well for them. Here are some of those services:

* [SmokePing](http://oss.oetiker.ch/smokeping/)
* [Vessel.io](https://www.vessel.io/) -- a/b testing
* [Beta by Crashlytics](http://try.crashlytics.com/beta/) -- beta distributions for iOS and Android.
* [Applause](http://www.applause.com/) -- QA, app testing, distributed external manual testing services. Very highly recommended.
* [Smartling](http://www.smartling.com/) -- Translation services, highly recommended.
* [GM Voices](http://www.gmvoices.com/) -- voice prompts, IVR.

HubSpot will be presenting at the January Stack Dive, check it out!
