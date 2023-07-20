---
layout: post
title: "Better Markdown Writing With Vale"
tags: [Productivity, Tips, Open Source]
date: 2023-05-26
comments: true
---

[Vale](https://vale.sh) is a command-line writing assistant I’ve been using to improve my writing quality.
Vale runs as a command line program and accepts a path to a text file. I use it with Markdown formatted text files to check for spelling and grammar errors.

For example to check this post I ran the following command.

```sh
vale _posts/2023-05-26-better-writing-vale.md
```

I've used Vale for blog posts and even for writing book content which has Markdown inside of XML.

It’s configurable and has loads of options.[^engwriting]

I’ve used it on book chapters 25 pages in length and it's able to process that much text in 25 seconds or so on my M1 MacBook Air.

You can find my Vale config for this blog online and part of it is copied below.[^valeconfig]

See below for the `.vale.ini` for this blog.

```
StylesPath = ValeStyles

Vocab = Blog

Packages = write-good

[*.md]
BasedOnStyles = Vale, write-good
```

I’m adding lots of words to `accept.txt` file which is what Vale uses as an allowlist for acceptable words. Words in here are case sensitive.


## How has it helped?
Here are some of the mistakes Vale has identified that I’ve fixed.

* Spelling errors
* Repeated words
* Casing errors
* “weasel words”
* Rewriting passive voice to active voice
* Rewriting words or sentences that are “too wordy”

I don't use 100% of the suggestions but I do use almost all of the items classified as "errors." A lot of items classified as "warnings" serve as good suggestions to consider.

The flagship feature of Vale seems to be the ability to create an externalized writing style and files although I'm using premade packages like [write-good](https://github.com/errata-ai/write-good).

The "linting" part of what Vale calls "prose linting" might be confusing for non-programmers, but programmers may be quite accustomed to linting their code[^proselinting] and a similar process could be followed for technical writing on a team. The linked article shows how to automatically perform linting using a Vale GitHub Action.

If you write a lot of text as Markdown, I recommend trying out Vale!

[^valeconfig]: [Blog commit that adds Vale](https://github.com/andyatkinson/andyatkinson.github.io/commit/637ee2becf4cdc88bfc36ead1fa68d323093d708)
[^engwriting]: [Using Vale to help engineers become better writers](https://engineering.contentsquare.com/2023/using-vale-to-help-engineers-become-better-writers/)
[^proselinting]: [Prose linting with Vale](https://blog.meilisearch.com/prose-linting-with-vale/)
