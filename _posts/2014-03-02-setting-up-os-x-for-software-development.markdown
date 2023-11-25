---
layout: post
title: "Setting up OS X for Software Development"
date: 2014-03-02
comments: true
tags: [OS X, Productivity, Tips, Tools, Vim]
---

I do software development on my Mac, mostly web application development with Ruby on Rails. Code is stored on either GitHub or BitBucket.

#### Dependencies

Everything below depends on having these installed.

 * Homebrew
 * Xcode and Command Line Tools (starts automatically)
 * Git (I installed with Homebrew `brew install git`)
 * Run `sudo xcodebuild -license` and agree to the terms

#### Ruby

I use rbenv and ruby-build to manage multiple versions of ruby. 

 * Install rbenv (git clone)
 * Install ruby-build (git clone)
 * Install rbenv-bundler (git clone)
 * rbenv install 2.0.0-p353

#### dotfiles

My configuration files and installation scripts are stored publicly on GitHub in my [dotfiles](https://github.com/andyatkinson/dotfiles) project. I keep my work and personal source code in a directory called `~/Projects`. 

 * `mkdir ~/Projects`
 * brew install macvim
 * Clone dotfiles repository, and run various installation rake tasks. (`rake dotfiles`), install Homebrew formulas manually or with the rake task, install npm packages, install OS X defaults (`rake os_x_defaults`)

#### OS X apps

Download these `.dmg` files. Some may be available through the OS X App Store.

 * Google Chrome
 * Vimium in Chrome web store
 * iTerm2
 * Alfred
 * Dropbox (sign-in, start syncing data)
 * GitX (open and choose File > Enable Terminal Usage)
 * Google Hangouts plugin for Chrome
 * Install Adobe Source Code Pro font, configure iTerm2 to use it
 * Install Chrome Markdown Preview extension
 * Jing for screencasts
 * Install LibreOffice (or MS Office)
 * Skype

#### OS X App Store

 * Install Cloud App (for linking to screenshots)

#### OS X system preferences

 * in keyboard, change caps lock to control (for vim)
 * enable tap to click on trackpad
 * Under Accessibility, check "use scroll gesture with modifier keys to zoom". (hold control and zoom with mouse scroll)

#### Databases and caching

 * `brew install mysql`
 * `brew install postgres`
 * `brew install redis`
 * `brew install memcached`

#### Vim

 * install vundle (git clone)
 * Open vim and run `:BundleInstall` (vundle)

#### Misc

 * Generate SSH keys and add public key to GitHub, BitBucket
 * `brew install tmux`
 * `brew install python`
 * Install Java JRE or JDK

What else is part of your workflow? Please leave a comment.
