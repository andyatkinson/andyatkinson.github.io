---
layout: post
title: Facebook Timeline JS API Development Tips
date: 2012-01-05
comments: true
tags: [API, JavaScript, Productivity, Tips]
---

Facebook has a JS SDK and "open graph" which allow applications to post to users' newsfeeds (and more) with permission from the user. Timeline was announced at the Facebook developer conference in the summer of 2011, which is basically a new design for the profile. Facebook is also rolling out new features to take advantage of new ways to group information on a Timeline profile. This requires new permissions for applications that users can grant via a new dialog.

The "publish_actions" permission can be requested through a new authentication dialog. The dialog demonstrates actions the application has and shows how the content will be aggregated. This is an improvement on posting every item to the news feed. The grouping itself is configurable and data can be grouped in a more useful way. The Timeline features specifies three technical concepts:
* `object`
* `action`
* `aggregation`

These are all pretty straightforward concepts for most programmers. Creating these requires using Facebook's admin tools, which is not necessarily straightforward. I experienced a number of problems getting this set up. Some problems: I wasn't using a "verified" developer account (verify by SMS or by adding a credit card), I never received the developer account verification SMS and I saw misleading error messages (oauth permission error was reported when in one case the real issue was no "content aggregation" had been set up on my test app). 

The debugger tool that said the page incorrectly specified facebook meta tags (e.g. "og:type") despite the facebook social plugins (e.g. the "send" plugin, emails content to someone) working fine, so the debugger did not seem to work correctly.

Eventually after solving the issues, an application can present a "add to timeline" button for the user with XFBML tags, which can either prompt the user to both request authentication *and* grant permission, or just ask for the new "publish_actions" permission. When this is working, there is a pretty good flow, and it is possible to authenticate and grant permissions without opening a second dialog. Make sure you are using the latest Facebook JS SDK code, there may be a beta/nightly type of alternative URL to point at (since the code is loaded from facebook).

## Code suggestions
* Could package the XFBML code in a jquery plugin.
* load the plugin in an async way (with a dynamic script tag), the load needs to happen before parsing the XFBML on the page
* Make a general function to take an action, object, and url to handle your facebook timeline interaction

## Some of the setup steps I needed
* A Facebook account with Timeline enabled. Timeline was not enabled as of this writing, but it is possible to "turn on" Timeline for developer accounts.
* Verified account as a developer account by adding a credit card to my account. SMS verification never worked, the SMS message never arrived.
* Create a test application with my test facebook app credentials 
* establish (and keep open) an SSH tunnel so that facebook can call back into my local development machine and facebook application

## One more tip
*  I kept the Facebook app permissions screen open in one browser window, so that I could remove my test app to test the authentication and authorization flow. If I tried to pop the dialog and the app already had permission, it wouldn't open.

I hope these tips are helpful for others developing Facebook Timeline applications.
