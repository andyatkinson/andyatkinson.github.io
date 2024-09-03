---
layout: post
title: "Upgrading to PostgreSQL 15 on Mac OS"
tags: [PostgreSQL, DevOps]
date: 2022-12-12
comments: true
---

PostgreSQL 15 shipped in late 2022 (See [PostgreSQL 15 Release Notes](https://www.postgresql.org/docs/current/release-15.html)), including interesting new features like SQL `MERGE`. I wanted to give them a try. 

On my Mac, I was running PostgreSQL 14.3 and had some significant databases I wanted to preserve but have them running on 15.

To perform the upgrade, I used `pg_upgrade` which ships with PostgreSQL. To initialize, install, and manage the cluster on Mac OS, I use [Postgres.app](https://postgresapp.com).

Postgres.app installs PostgreSQL in versioned directories. I had separate directories for versions 14 and 15.

Postgres.app has an "Initialize" button that creates a new cluster. I imagine this runs `initdb` behind the scenes.

During my upgrade, I ended up running `initdb` manually so that I could directly set specific flags. See: [`initdb` Documentation](https://www.postgresql.org/docs/current/app-initdb.html)

To get started, check which version of `pg_upgrade` is active.

```sh
$ which pg_upgrade
/Applications/Postgres.app/Contents/Versions/14/bin/pg_upgrade
```

If the old version is active, make sure to use `pg_upgrade` from the new PostgreSQL 15 version.

## Steps
1. Download and install Postgres.app. This is a regular Mac OS app with a `.dmg`.
1. Choose "Replace" during installation. You are replacing the Mac OS app, not modifying the current PostgreSQL cluster.
1. Open [Postgres.app](https://postgresapp.com). Choose the "+" icon. Version 15 is now available. Click the plus button to create a new cluster. In PostgreSQL the collection of databases is a "cluster."

To make the versions easier to keep track of, I renamed both clusters, `my_db_14`, and `my_db_15`. Both ran on the same port so I ran one at a time.

Stop any running copies of 14. I use the `pg_ctl` program, `-D` and a path to the data directory.

```sh
pg_ctl stop \
-D "/Users/andy/Library/Application\ Support/Postgres/var-14/"
```

While running "Initialize" from Postgres.app is possible, I had inconsistencies flagged by `pg_upgrade` between the cluster versions.

In the end, I did not initialize the cluster from the app, but ran `initdb` with various flags.

The data directory for version 15 is below.

```sh
/Users/andy/Library/Application\ Support/Postgres/var-15
```

Stop both versions before performing the upgrade. Stop the version 15 cluster if it's running.

```sh
pg_ctl stop \
-D /Users/andy/Library/Application\ Support/Postgres/var-15
```

## Running `pg_upgrade` with `--check`
Run `pg_upgrade` with the `--check` option to perform a dry run. Provide the data directory and the binaries directory for both clusters.

This means there are 4 arguments to `pg_upgrade` besides `--check`. 

The full command with the version 15 `pg_upgrade` and all 5 arguments is below.

```sh
/Applications/Postgres.app/Contents/Versions/15/bin/pg_upgrade \
--check \
--old-datadir "/Users/andy/Library/Application Support/Postgres/var-14" \
--old-bindir "/Applications/Postgres.app/Contents/Versions/14/bin" \
--new-datadir "/Users/andy/Library/Application Support/Postgres/var-15" \
--new-bindir "/Applications/Postgres.app/Contents/Versions/15/bin"
```


## Checksums
One issue I ran into was with checksums.

The error was `"the old cluster does not use data checksums but the new one does".`

What I did was to disable checksums for the new 15 cluster. I don't fully understand the implications of this, but since this is for my local installation, I'm not worried about it for now.

To disable checksums I ran the following command.

```sh
/Applications/Postgres.app/Contents/Versions/15/bin/pg_checksums \
--disable \
-D "/Users/andy/Library/Application Support/Postgres/var-15"
```


## Errors with extensions
The next error I had was with `pg_cron`, which is an extension I'd compiled for PostgreSQL 14.

```sh
FATAL:  could not access file "pg_cron": No such file or directory
```

I’d set up [citusdata/pg_cron](https://github.com/citusdata/pg_cron) in 14, so I’ll need to set that up in 15 as well.

I confirmed it wasn't listed in available extensions, from a `psql` prompt in 15. I disabled it initially to make the upgrade easier, but was able to recompile it for 15.

The other items in `shared_preload_libraries` for me are items that ship with PostgreSQL (`pg_stat_statements`, and `auto_explain`).

```sql
SELECT * FROM pg_extension;
```

I needed to modify my path to make sure the version 15 directory was active.

```sh
export PATH=$(which pg_config):$PATH
```

I followed the normal build from source instructions for [citusdata/pg_cron](https://github.com/citusdata/pg_cron).

Once that completed, I added it to the new `postgresql.conf` config file.

```sh
vim "/Users/andy/Library/Application\ Support/Postgres/var-15/postgresql.conf"
# edit shared_preload_libraries
shared_preload_libraries = 'pg_cron' # (requires restart)
```

Now I can start PostgreSQL 15 again.

```sh
/Applications/Postgres.app/Contents/Versions/15/bin/pg_ctl start \
-D "/Users/andy/Library/Application Support/Postgres/var-15"
```

## Having a cluster install user
I needed to create a `postgres` superuser for the upgrade.

```
"FATAL:  role "postgres" does not exist". 
```

I solved this by adding `--username postgres` to the `initdb` command.


## Locale provider mismatch
The next error was a mismatch in the locale providers between the versions.

```
"locale providers for database "template1" do not match:  old 'libc', new 'icu'".
```

I solved this by adding `no-locale` to `initdb`, and running it directly on the new data directory.


## Encodings mismatch
The next issue was a mismatch in the encodings between the clusters.

```
"encodings for database "template1" do not match: old 'UTF8', new 'SQL_ASCII'"
```

I solved this by adding `--encoding UTF8` to the `initdb` command below.

I added these flags `--lc-collate "en_US.UTF-8"` and `--lc-ctype "en_US.UTF-8"` based on the `pg_upgrade` documentation in an attempt to have them match between clusters.

[`pg_upgrade` Documentation](https://www.postgresql.org/docs/current/pgupgrade.html)

## Final `initdb` command with flags
The final `initdb` command invocation is as follows.

```sh
/Applications/Postgres.app/Contents/Versions/15/bin/initdb \
--no-locale \
--encoding UTF8 \
--username postgres \
--lc-collate "en_US.UTF-8" \
--lc-ctype "en_US.UTF-8" \
-D "/Users/andy/Library/Application Support/Postgres/var-15"
```

After getting the `initdb` configured with the flags listed above, `pg_upgrade` with `--check` passed 100% of the checks. 🎉

The very satisfying output is below.

```sh
Performing Consistency Checks
-----------------------------
Checking cluster versions                                   ok
Checking database user is the install user                  ok
Checking database connection settings                       ok
Checking for prepared transactions                          ok
Checking for system-defined composite types in user tables  ok
Checking for reg* data types in user tables                 ok
Checking for contrib/isn with bigint-passing mismatch       ok
Checking for presence of required libraries                 ok
Checking database user is the install user                  ok
Checking for prepared transactions                          ok
Checking for new cluster tablespace directories             ok

*Clusters are compatible*
```

Once the checks completed, I ran `pg_upgrade` without `--check`, so it ran for real, and it ran without errors.

Following the recommendations, I performed database maintenance operations on the new cluster. In general these are things like `VACUUM`, `ANALYZE`, etc.

`pg_upgrade` prints out a `vacuumdb` command to run which was helpful.

```sh
/Applications/Postgres.app/Contents/Versions/15/bin/vacuumdb \
-U postgres \
--all \
--analyze-in-stages
```

## Closing Thoughts
The `pg_upgrade` helped me upgrade the cluster. I had a new PostgreSQL 15 cluster, running with the data directory from the previous major version.

Being able to perform a non-destructive upgrade while leaving the old version intact is a nice design. Using `--check` to perform a dry run first and work out issues was great.

While I did run into minor issues, I solved each one with help from Google and the upgrade was successful. Performing this upgrade on a large database would be more daunting, but this experience in local development was a way to get some practice.

Hopefully my upgrade experience is useful to PostgreSQL developers, Postgres.app users, documentation authors, or anyone else using `pg_upgrade`.

If you have any feedback, suggestions, or corrections, please leave a comment or contact me here.

Thanks for reading!
