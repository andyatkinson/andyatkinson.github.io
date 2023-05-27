---
layout: post
title: "Better Markdown Writing With Vale"
tags: [Productivity, Tips, Open Source]
date: 2023-05-26
comments: true
---

[Vale](https://vale.sh) is a command-line writing assistant tool I’ve been using to improve my writing quality.
Vale runs as a command line program, and accepts a path to a text file, where you might have Markdown formatted text to check for spelling and grammar errors.

For example to check this post, I run the following command from the root directory.

```sh
vale _posts/2023-05-26-better-writing-vale.md
```

I've used it for blog posts on this blog, my company's work blog, and for writing book content which has Markdown within XML.

It’s a configurable tool and has loads of options.[^engwriting]

I’ve used it on book chapters that are 25 pages in length and it's able to chew through that much text content in about 25 seconds on my M1 MacBook Air.

I have pushed up my Vale config for this blog.[^valeconfig]

The `.vale.ini` for this blog is below.

```
StylesPath = ValeStyles

Vocab = Blog

Packages = write-good

[*.md]
BasedOnStyles = Vale, write-good
```

I’m adding lots of words to `accept.txt` file, which is an allowlist of acceptable words that's case sensitive.


## How has it helped?
Here are some of the things I’ve fixed thanks to Vale.

* Spelling errors
* Repeated words
* Casing errors
* “weasel words”
* Rewriting passive voice to active voice
* Rewriting words or sentences that are “too wordy”

I don't take 100% of the suggestions, but most of the items classified as "errors" are legitimate, and a lot of the "warnings" serve as good suggestions to consider.

The flagship feature of Vale seems to be the ability to create an externalized writing style.

The website features the writing styles of many companies. So far I've just tried the [write-good](https://github.com/errata-ai/write-good) package but I am interested in trying more of them.

Automatic checking is called "prose linting," similar to the linting process for code.[^proselinting] In the linked article, they discuss how to perform checks automatically using the Vale GitHub Action.

If you write a lot of text as Markdown, I highly recommend trying out Vale in your workflow!

[^valeconfig]: [Blog commit that adds Vale](https://github.com/andyatkinson/andyatkinson.github.io/commit/637ee2becf4cdc88bfc36ead1fa68d323093d708)
[^engwriting]: [Using Vale to help engineers become better writers](https://engineering.contentsquare.com/2023/using-vale-to-help-engineers-become-better-writers/)
[^proselinting]: [Prose linting with Vale](https://blog.meilisearch.com/prose-linting-with-vale/)
