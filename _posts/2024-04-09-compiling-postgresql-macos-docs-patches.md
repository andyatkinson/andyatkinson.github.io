---
layout: post
title: "Compiling PostgreSQL on macOS, Testing Docs and Patches"
tags: []
date: 2024-04-09
comments: true
---

This post covers my experience compiling PostgreSQL from source code following the steps on [Setup PostgreSQL development environment on MacOS](https://www.highgo.ca/2023/06/23/setup-postgresql-development-environment-on-macos).

## Introduction

What are we trying to do? We're trying to compile the PostgreSQL source code on macOS, then run the locally compiled version of PostgreSQL hosting a database we can test with. With this setup, we’re able to test newly committed functionality, and make contributions back to PostgreSQL.

## Background

The PostgreSQL documentation has a chapter called [Chapter 17. Installation from Source Code](https://www.postgresql.org/docs/current/installation.html) that's worth reading through.

There's a section called "Building and Installation with Autoconf and Make" that I'll follow here. Using Autoconf and make are considered the old way to build from source, and the new way is using Meson. A future post may cover Meson, as well as additional ways to compile daily snapshots, or switch between versions easily, but for now we’ll just compile this on macOS.

## Mac macOS Machine

- macOS Sonoma 14.4
- Homebrew
- Fish shell

Homebrew is quite popular, but Fish shell is not super popular, as the default shell is Zsh, and Bash is popular. Adapt the instructions for your preferred shell.

## Short version

In the PostgreSQL documentation, they have a short and long version which I like, and I’ll follow that here. Here's the short version:

- I cloned from [postgres/postgres](origin  git@github.com:postgres/postgres.git) on GitHub which is a mirror of the source code.
- When I want to recompile, I run `git pull` to get the latest source code

First we’ll need to install build dependencies, preparing the machine. I’ll do that with Homebrew.

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

With that preparation in place, we’re ready to compile PostgreSQL:

```sh
cd postgres
./configure
make && make install
```

You may run into compilation issues. Unfortunately this post isn’t meant to try and solve compilation issues, however I will note some issues I ran into below.

## Issues

Having recently overhauled my macOS setup, making sure to install the ARM binaries and not use Rosetta, and having recently updated to 14.1, I had to reinstall a number of things almost as if the machine was brand new. I completely reinstalled the command line tools for macOS, Homebrew, and all the formulae I had before that.

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

Once I'd installed `icu4c`, and `pkgconfig`, I needed to refer back to their post-install instructions. I used `brew info` plus the formula name to get those instructions. For example running `brew info icu4c` prints them out.

This will provide shell-specific instructions to add icu4c to your `PATH`, for example:

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

Next, the instructions from PostgreSQL refer to the `adduser` program to create a `postgres` user as the owner, except that adduser doesn’t exist on macOS. While there are equivalents, I wanted to use my OS user to keep it simple.

In lieu of creating a `postgres` user, I used my OS user `andy`. Since I did that, I needed to change the ownership of the data directory to make `andy` the owner. I did that by running:

```sh
chown andy /usr/local/pgsql/data
```

Next we run the `initdb` program included in PostgreSQL to initialize the data directory. The `-D` option below is the flag and the value is the absolute path to the data directory.

```sh
/usr/local/pgsql/bin/initdb -D /usr/local/pgsql/data
```

We can now use `pg_ctl` to start up PostgreSQL, again supplying the path to the data directory.

```sh
/usr/local/pgsql/bin/pg_ctl \
  -D /usr/local/pgsql/data \
  -l logfile start
```

Review the rest of the [Short Version instructions here](https://www.postgresql.org/docs/current/install-make.html#INSTALL-SHORT-MAKE).

Now that we've got the latest built version of PostgreSQL running on port 5432, we’re ready to use it for testing.

## Testing Documentation Changes

I read the PostgreSQL documentation a lot, and I’ve made several small suggestions with some of them being incorporated into the project. Cool!

While building docs isn’t strictly necessary to submit a patch, it’s confidence-inspiring to review built docs as HTML or another format before sending an email to pgsql-hackers.

Blogger, presenter, and DBA extraordinaire Lætitia Avrot has a post [Patching Postgres' Documentation](https://mydbanotebook.org/post/patching-doc/) that inspired me to learn how to modify documentation and create a patch. Thank you Lætitia! [#1](https://github.com/postgres/postgres/commit/16ace6f7452a968f2b5b058ccccd75db4c56ef34
), [#2](https://github.com/postgres/postgres/commit/dab5538f0bfc4cca76396f5d510e2df6f5350d4c
), [#3](https://github.com/postgres/postgres/commit/363eb059966d0be0a41c206cee40dfd21eb73251)

## Testing Patches

[Adam Hendel emailed the pgsql-hackers list](https://www.postgresql.org/message-id/flat/CABfuTggpE-A5pvif9Zv++c4Jn3iu_7ccJ23Pm+8r+CKRBUMg_Q@mail.gmail.com) about the addition of a `--log-header` flag for pgbench to add more information to the log file output.

Since I’d just compiled PostgreSQL before reading that email, I sprung into action, knowing I could add the patch, re-compile, and test it out.

To start, I made a `~/patches` directory to store the patch in and future patch files. 

I copied the patch file into that directory. We'll call it `the-patch-file.patch` below:

```sh
mv the-patch-file.patch ~/patches
```

Then I applied it:

```sh
git apply ~/patches/the-patch-file.patch
```

Now I was ready to compile PostgreSQL again.

Once PostgreSQL was compiled again, I was ready to test the new behavior.

First I needed to find where the pgbench executable was running from, then I'd `cd` into that directory. Here's where the program was:

```sh
/Users/andy/Projects/postgres/src/bin/pgbench
```

I ran pgbench from that directory:

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

I was able to run through those steps provided by Adam, verifying the expected changes to the log file. Nice!

## Wrap Up

If you use macOS, you may find a little less support in general for compiling PostgreSQL, but fortunately the steps aren't too complicated, and PostgreSQL supports compilation for this platform.

In future posts, we'll look at more ways to run experimental versions of PostgreSQL on macOS.

Once you've compiled PostgreSQL or have an experimental version to test with, you've got a place to test unreleased changes or even contribute changes to the project.

Thanks for reading!
