---
layout: post
title: "Open the Current File in GitHub Enterprise from Vim"
date: 2013-10-28
comments: true
tags: [Scripts, Vim, Tips, Git, Productivity]
---

## fugitive.vim
The fugitive.vim plugin [^plugin] for Vim has a nice feature to open a file in GitHub. It is even possible to have a range or line highlighted from a visual selection!

From the README:

> Use `:Gbrowse` to open the current file on GitHub, with optional line range (try it in visual mode!). If your current repository isn't on GitHub, git instaweb will be spun up instead.

But what if your team uses the GitHub Enterprise version of GitHub or a private git server? We are in luck, the `Gbrowse` feature still works, it just requires a little configuration.

First on OS X, I had to tell git that I want web URLs to open with the `open` command. By default they were being opened with a command line browser.

```bash
git config --global web.browser open
```

Next, the GitHub domain can be set via a variable that the plugin reads. This was set to our private GitHub Enterprise URL. 

To keep this private URL out of my public Vim configuration [^vim_config], I made a `workvimrc` file and called `source ~/.workvimrc` to "source" it into my main config. Now the value is read when new Vim instances are started.

```bash
let g:fugitive_github_domains = ['http://secret_github_enterprise_url']
```

## Opening Files
In a new Vim instance or after reloading the main Vim config, `:Gbrowse` opens the current file at the correct URL in GitHub enterprise! This is a nice time saver when sharing links to code with colleagues. 

To have one or more lines automatically highlighted on the opened page, type `Gbrowse` after making a range selection (e.g. `Shift-v j/k`), which should look like this`:'<,'>Gbrowse`, then press return.

Another nice tip [^tip] to copy the path to the clipboard without opening the browser, is `:Gbrowse! -`.

## Conclusion
Have any other time savers in your workflow to share?

[^plugin]: [fugitive.vim plugin](https://github.com/tpope/vim-fugitive)
[^vim_config]: [My Vim config](https://github.com/andyatkinson/dotfiles)
[^tip]: [Your GitHub URLs should be timeless](https://coderwall.com/p/j-dlsq)
