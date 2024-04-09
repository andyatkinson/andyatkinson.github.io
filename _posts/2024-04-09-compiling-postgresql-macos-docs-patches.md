---
layout: post
title: "Compiling PostgreSQL on macOS To Test Documentation and Patches"
tags: [PostgreSQL]
date: 2024-04-09
comments: true
---

This post covers my experience compiling and installing PostgreSQL from source code. Primarily I followed official instructions and this blog post [Setup PostgreSQL development environment on MacOS](https://www.highgo.ca/2023/06/23/setup-postgresql-development-environment-on-macos). Once installed, we’ll look at how to test doc changes and patches from the mailing list.

## Introduction

What are we trying to do? We're trying to compile and install the PostgreSQL database on macOS, then run it with a database in order to test functionality changes or test documentation patches. With that in place, we can even make contributions to PostgreSQL using the mailing list process.

## Background

The PostgreSQL documentation has a chapter called [Chapter 17. Installation from Source Code](https://www.postgresql.org/docs/current/installation.html) that's worth reading through. This section covers various platforms.

There's a section called "Building and Installation with Autoconf and Make" that I'll follow here. Using Autoconf and make are considered the “old way” to build from source, and the new way is to use Meson. A future post may cover Meson, as well as additional ways to compile PostgreSQL, but in this post we’ll use the Autoconf and Make method.

## Mac macOS Machine

Here are the details of the machine I’m working on in April 2024:

- macOS Sonoma 14.4
- Homebrew
- Fish shell

Homebrew is a popular method of getting software for macOS via the “formulae” that it publishes. Fish shell is my preferred shell environment, but is not as popular as Zsh or Bash, however there are still post-install instructions for shell configuration from Homebrew.

## Short version

In the PostgreSQL documentation, they have a short and long version which is a pattern I’ll follow here. Here's the short version:

- I cloned from [postgres/postgres](https://github.com/postgres/postgres) on GitHub which is a mirror of the source code. I can also push my own branches to my own form on GitHub if I want.
- When I want to recompile PostgreSQL, I run `git pull` to get the latest source code versions from upstream. I’m often seeing cool new things coming from [Noriyoshi Shinoda](https://twitter.com/nori_shinoda) who posts new commits on Twitter. I may also check the pgsql-hackers email list, although the volume is so high that it’s difficult to check in on and get a lot of value from.

With that said, now that we have the source code, let’s make sure the machine is prepared. First we’ll need to install build dependencies. I’ll do that with Homebrew.

```sh
brew install icu4c
brew install pkgconfig
```

Next I’ll follow post-install instructions to set up my shell, including creating environment variables.
```sh
fish_add_path /opt/homebrew/opt/icu4c/bin
fish_add_path /opt/homebrew/opt/icu4c/sbin
set -gx LDFLAGS "-L/opt/homebrew/opt/icu4c/lib"
set -gx CPPFLAGS "-I/opt/homebrew/opt/icu4c/include"
```

With that in place, we’re ready to compile PostgreSQL:

```sh
cd postgres
./configure
make && make install
```

This is the simple version, and your experience may not be so simple. You may run into compilation issues. Unfortunately this post isn’t meant to try and solve compilation issues, however I will note some issues I ran into below. Please leave a comment if you’d like, although to debug your compilation issues, I’d recommend searching on Stack Overflow or getting more information about the error using something like ChatGPT.

## Issues

Having recently overhauled my macOS setup, making sure to install the ARM architecture versions and to not use Rosetta at all, and after having recently updated to 14.4, I had to reinstall a number of things almost as if the machine was brand new. I completely reinstalled the command line tools for macOS, Homebrew, and all the formulae I had before that.

To start over with command line tools, I did this:

```sh
sudo rm -rf /Library/Developer/CommandLineTools
xcode-select --install
```

Once that was done, I ran `make clean` in PostgreSQL due to issues I had with a "CPU mismatch." After reinstalling the command line tools and the Homebrew formulae I was back in business.

## Long Version

Before I knew about the icu4c program, I saw issues like this when running `./configure`:

```sh
configure: error: ICU library not found
```

Once I'd installed `icu4c`, and `pkgconfig`, I needed to refer back to their post-install instructions. I used `brew info` with the formula name to get those post-install instructions and confirm the formula was installed. For example running `brew info icu4c` prints out the instructions below.

This will provide shell-specific instructions to add icu4c to your `PATH`. Here’s what it prints for me with Fish shell:

```sh
If you need to have icu4c first in your PATH, run:
  fish_add_path /opt/homebrew/opt/icu4c/bin
  fish_add_path /opt/homebrew/opt/icu4c/sbin
```

Set environment variables `LDFLAGS`, `CPPFLAGS`, `PKG_CONFIG_PATH` for icu4c and pkgconfig in your shell. These are the instructions that are printed for Fish shell:

```sh
For compilers to find icu4c you may need to set:
  set -gx LDFLAGS "-L/opt/homebrew/opt/icu4c/lib"
  set -gx CPPFLAGS "-I/opt/homebrew/opt/icu4c/include"
```

```sh
For pkg-config to find icu4c you may need to set:
  set -gx PKG_CONFIG_PATH "/opt/homebrew/opt/icu4c/lib/pkgconfig"
```

After installing those my machine was prepared, and `./configure` ran successfully.

## Post-compilation of PostgreSQL, Starting It Up

With PostgreSQL compiled, I was ready to create and initialize the data directory.

First we create a directory with this command:

```sh
mkdir -p /usr/local/pgsql/data
```

Next, the instructions from PostgreSQL refer to the `adduser` program to create a `postgres` user as the owner. adduser doesn’t exist on macOS. While there are equivalents, I wanted to use my OS user `andy` to keep things simple for now.

Since I did that, I needed to change the ownership of the data directory to make `andy` the owner. I did that by running:

```sh
chown andy /usr/local/pgsql/data
```

Now that PostgreSQL was compiled, it was ready to initialize and start. I ran the `initdb` program included in PostgreSQL to initialize the data directory which is where all the database content is stored. The `-D` option below is the flag for the data directory, and the value is the absolute path to it.

```sh
/usr/local/pgsql/bin/initdb -D /usr/local/pgsql/data
```

With that initialized, we can start PostgreSQL. Use the `pg_ctl` program to start it up, again supplying the path to the data directory as an argument.

```sh
/usr/local/pgsql/bin/pg_ctl \
  -D /usr/local/pgsql/data \
  -l logfile start
```

Review the rest of the [Short Version instructions here](https://www.postgresql.org/docs/current/install-make.html#INSTALL-SHORT-MAKE).

Now that we've got the latest source code version of PostgreSQL compiled, initialized, and running on the default port 5432, we’re ready to use it for testing, connecting to the built-in `postgres` database, or creating a new one on the instance.

## Testing Documentation Changes

I read the PostgreSQL documentation a lot, and I’ve learned how to make contributions to it if I see something to propose. Some of those suggestions have been reviewed and committed by others into the project. Cool! This makes me feel like I’m part of the community of PostgreSQL. My experience in interacting on the list has been positive. There is a lot of meticulous attention paid to the details of the documentation, which makes sense, given the widespread usage, longevity, technical nature, criticality of the usage, and international audience.

While building docs isn’t strictly necessary to submit a patch, reviewing built HTML versions inspires confidence to see what users will see. This way I’m more confident when sending a documentation patch to pgsql-hackers that it will look like I expect.

Blogger, presenter, and DBA extraordinaire Lætitia Avrot has a post [Patching Postgres' Documentation](https://mydbanotebook.org/post/patching-doc/) that taught me and inspired me to contribute my first documentation patch. Thank you Lætitia! I’ve now contributed a few more and some have been reviewed and committed directly or have inspired a related commit. I’ve linked those here: [#1](https://github.com/postgres/postgres/commit/16ace6f7452a968f2b5b058ccccd75db4c56ef34
), [#2](https://github.com/postgres/postgres/commit/dab5538f0bfc4cca76396f5d510e2df6f5350d4c
), [#3](https://github.com/postgres/postgres/commit/363eb059966d0be0a41c206cee40dfd21eb73251)

## Testing Patches

[Adam Hendel emailed the pgsql-hackers list](https://www.postgresql.org/message-id/flat/CABfuTggpE-A5pvif9Zv++c4Jn3iu_7ccJ23Pm+8r+CKRBUMg_Q@mail.gmail.com) about the addition of a `--log-header` flag for pgbench to add more information to the log file output.

Since I’d just compiled PostgreSQL before reading that email, and since I’ve gotten to know Adam Hendel a bit in the community, I was eager to help. I sprung into action, knowing I could add the patch to my local installation, re-compile, and test it out. I’m also familiar a bit with pgbench and have used it, and thought the gist of the change to the log file made sense. I think testing a patch and relaying one’s experience can help to move a patch forward.

To start, I made a `~/patches` directory to store this particular patch file and future ones. 

I copied the patch file into that directory. We'll call it `the-patch-file.patch` below since this is an example:

```sh
mv the-patch-file.patch ~/patches
```

Then I applied it:

```sh
git apply ~/patches/the-patch-file.patch
```

With the patch in place, I was ready to compile PostgreSQL so that the newly built one had the patch included.

Once PostgreSQL was compiled again, I was ready to run pgbench and test the new behavior.

First I needed to find where the pgbench executable was running from since I needed to run my local installation version I’d just compiled. I found that and ran `cd` to go to that directory. Here's where the program was for me since I keep my `postgres` source code in `/Users/andy/Projects/postgres`:

```sh
/Users/andy/Projects/postgres/src/bin/pgbench
```

I ran pgbench from that directory. The arguments are split onto their own new lines.

```sh
pgbench -i \
-d postgres src/bin/pgbench/pgbench postgres://andy:@localhost:5432/postgres \
--log --log-header
```

I removed the existing log file, since I wanted to test changes going into it:

```sh
rm pgbench_log.*
```

Now I could run the compiled version of pgbench like this, using the new `--log-header` flag:

```sh
src/bin/pgbench/pgbench postgres://andy:@localhost:5432/postgres --log --log-header
pgbench (17devel)
```

Finally, I could check the output of the log file to verify it had what I expected:

```sh
cat pgbench_log.*
client_id transaction_no time script_no time_epoch time_us
0 1 8435 0 1699902315 902700
0 2 1130 0 1699902315 903973
```

I was able to verify using the new flag and that the results were what Adam described. Nice!

## What’s Next?

We’re just scratching the surface of setting up a local testing environment here. It would be nice to also run the full set of tests that are included in PostgreSQL. Tests are an important part of verifying functionality and getting patches accepted.

There are also a lot of programs included in the distribution of PostgreSQL such as pgbench, which may have separate testing requirements. When building PostgreSQL, there are [loads of different flags](https://www.postgresql.org/docs/current/install-make.html#INSTALL-PROCEDURE-MAKE), developer options, and environment variables that can be provided at configuration time that are worth reviewing.

## Wrap Up

If you use macOS, you may find a little less support in general for compiling PostgreSQL, but fortunately the steps aren't too complicated, and PostgreSQL supports compilation for this platform.

In future posts, we'll look at more ways to run experimental versions of PostgreSQL on macOS.

Once you've compiled PostgreSQL or have an experimental version to test with, and now how to start it up and use the built in databases, create your own, or other included programs, you've got a great place to test unreleased documentation changes, functionality changes, and connect more significantly with the community and the project.

Thanks for reading!
