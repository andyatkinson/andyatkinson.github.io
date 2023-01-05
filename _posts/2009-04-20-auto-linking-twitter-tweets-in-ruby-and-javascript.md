---
layout: post
title: Auto-linking Twitter Tweets in Ruby and JavaScript
date: 2009-04-20
comments: true
tags: [Programming, Ruby, JavaScript, Tips, Scripts, RegExp]
---

Ruby on Rails introduced me to the concept of an `auto_link` helper method, which finds and hyperlinks URLs within text.

How do we write our own auto-link in Ruby and JavaScript?

#### Ruby

`ActionView::Helpers::TextHelper#auto_link` auto-links URLs in Rails, but what if we want twitter usernames to be linked? Duplicating the twitter style involves putting the "@" symbol immediately before the anchor tag, and linking the username. A Rails helper to do this, might look like:

```ruby
  def auto_link_username(username)
    auto_link username.gsub(/@(\w+)/, %Q{@<a href="http://twitter.com/\\1">\\1</a>})
  end
```   

To test the helper use `assert_match` with a regular expression to validate the hyperlinked username.

```ruby
  require File.dirname(__FILE__) + '/../../test_helper'
  class TwitterHelperTest < ActionView::TestCase
    def test_auto_link_username
      tweet = "thanks @twitter, this is awesome."
      assert_match /@<a href=\"http:\/\/twitter.com\/\S+\">\S+<\/a>/, auto_link_username tweet
    end
  end
```

If you aren't using Rails, the following regular expression will hyperlink URLs.

```ruby
  tweet = "have you seen this awesome search engine? http://google.com"
  tweet.gsub /((https?:\/\/|www\.)([-\w\.]+)+(:\d+)?(\/([\w\/_\.]*(\?\S+)?)?)?)/, %Q{<a href="\\1">\\1</a>}
```

#### JavaScript

The regular expression methods are different in JavaScript than Ruby. I used the search and replace methods to check for the presence of a pattern, then update the tweet if the pattern was found. The "/g" option handles multiple matches.

```javascript
  tweet = "this search engine from @google is awesome: http://www.google.com";

  if(tweet.search(/(https?:\/\/[-\w\.]+:?\/[\w\/_\.]*(\?\S+)?)/) > -1) {
    tweet = tweet.replace(/(https?:\/\/[-\w\.]+:?\/[\w\/_\.]*(\?\S+)?)/, "<a href='$1'>$1</a>")
  }

  if(tweet.search(/@\w+/) > -1) {
    tweet = tweet.replace(/(@)(\w+)/g, "$1<a href='http://twitter.com/$2'>$2</a>");
  }
```
