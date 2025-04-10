---
layout: post
title: 10 iOS Open Source Projects
date: 2011-12-16
tags: [Programming, Tips, Objective-C, iOS]
---

Working independently on personal iOS projects, I'd used a couple of Objective-C open source libraries and wanted to share what they are. 

**SBJSON**[^1] converts JSON text responses from a web API to NSDictionary objects, and **MBProgressHUD**[^2] provides a loading animation that can be used to improve the user experience during long running processes. 

I had the opportunity to do some development on the primary consumer iOS app where I work (a top 10 app (!) in the free "lifestyle" category), and it uses a lot more open source projects than the 2 mentioned above. The list below contains some of those libraries in use by the application, which is iOS 4 or earlier as of this writing.

I don't have direct experience with all of the libraries below, but I wanted to share the list as a starting point for further investigation by myself or by you, and to provide a little extra advertising for the projects since we're finding them useful.

- **TTStyle and TTUrlRequest** - Part of Three20[^3] from Facebook. `ttstyle` provides various UIView features like borders, fills, text and more. I typically used Interface Builder to lay views out, but have seen the flexibility and control of building views programmatically, and now prefer that approach, having some help from my colleague. `tturlrequest` is an HTTP request library, from the creator: "a replacement for NSURLRequest which supports a disk cache." A cached web request response on disk would be available between application restarts.
- **GRMustache**[^4] - Objective-C implementation of Mustache. Mustache templates can be used to share view-layer templates between a web browser and an iOS view. Personally I think the Mustache style of templating makes a lot of sense. In Ruby on the server, having a hash of the attributes going to the template is very explicit and clear, I like it better than ERB, and Mustache is implemented in a lot of languages. The template and data can be rendered in objective-c on the device, or in the browser in JavaScript.
- **FTUtils**[^5] - Animation library. Ships with some canned UIView animations. I have not used this personally.
- **Google Toolbox for Mac**[^6] [^7]. Various features. Has OAuth connection controller code for iOS.
- **oauthconsumer** [^8] - OAuth consumer library. I have not used this.
- **regexkitlite** [^9] - Adds additional regular expression functionality beyond what objective-c provides, to NSArray and many more objects, through categories.
- **KIF** [^10] - User interface-level (integration/"outside-in") testing from Square. I have not built a KIF test script yet, but testing a happy path flow through the application would be a valuable regression test.
- **Google Analytics SDK for iOS** [^11] - Track activity in google analytics, "pageviews", events, and more.

## Conclusion
So there you have it, 10 open source iOS libraries to check out for your project. I hope this introduction was somewhat useful. Please leave a comment if you have some favorite libraries of your own.

 [^1]: [SBJSON](http://stig.github.com/json-framework)
 [^2]: [MBProgressHUD](https://github.com/jdg/MBProgressHUD)
 [^3]: [Three20](https://github.com/facebook/three20)
 [^4]: [GRMustache](https://github.com/groue/GRMustache)
 [^5]: [FTUtils](https://github.com/neror/ftutils)
 [^6]: [Google Toolbox for Mac #1](https://github.com/jkp/gtm)
 [^7]: [Google Toolbox for Mac #2](http://code.google.com/p/google-toolbox-for-mac)
 [^8]: [OAuth Consumer](https://github.com/jdg/oauthconsumer)
 [^9]: [RegExKit Lite](http://regexkit.sourceforge.net)
 [^10]: [KIF](https://github.com/square/KIF)
 [^11]: [Google Analytics SDK iOS](http://code.google.com/apis/analytics/docs/mobile/ios.html)
