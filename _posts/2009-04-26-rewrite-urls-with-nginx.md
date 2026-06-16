---
layout: post
title: Rewrite URLs with Nginx
date: 2009-04-26
comments: true
tags: [Tools, Tips, Programming, Scripts, DevOps]
---

A previous work project involved changing our blog software and server configuration. Date-based URLs would no longer be used, and the blog would be run within the main site instead of on a subdomain. The "slug" (which is `this-is-the-page-slug` in this example) would be retained for blog posts in the new app.  

Mapping URLs from the old format of `http://subdomain.domain.com/2007/3/19/this-is-the-page-slug` to the new format of `http://www.domain.com/blog/this-is-the-page-slug` (at the nginx level) involved using the the [NginxHttpRewriteModule](http://wiki.nginx.org/NginxHttpRewriteModule) and two regular expressions. I wanted to share this configuration as others may have similar needs.

The following snippet was added within a server context to the nginx configuration file:

``` bash
if ($host ~* &quot;^subdomain.domain.com$&quot;){
  rewrite ^.*(?=\/)(.+)$ http://www.domain.com/blog$1 permanent;
  break;
}
```

I developed this with help from a colleague who was formerly a perl programmer, and introduced me to a [lookaround](http://www.regular-expressions.info/lookaround.html), also known as a "zero-width positive look-ahead assertion". 

The "positive lookahead" matches the forward slash (escaped) character: `(?=\/)`, without making it part of the match. The `.*` means any character and since `*` is greedy by default, the whole URL up to the final forward slash character matches. Finally, `(.+)` forms the first backreference `$1` (lookaheads do not create capturing groups), which is used in the new URL as the second argument to `rewrite`. Reload the nginx config and enjoy.

I hope this helped a little with doing a URL rewrite in nginx, and provided some information on regular expressions.
