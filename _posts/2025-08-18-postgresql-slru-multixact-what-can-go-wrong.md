---
layout: post
permalink: /postgresql-slru-multixact-what-can-go-wrong
title: What are SLRUs and MultiXacts in Postgres? What can go wrong?
date: 2025-09-25 11:15:00
tags: [PostgreSQL, Databases]
---

In this post we’ll cover two types of Postgres internals.

The first internal item is an “SLRU.” The acronym stands for “simple least recently used.” The LRU portion refers to caches and how they work, and SLRUs in Postgres are a collection of these caches.

SLRUs are small in-memory item stores. Since they need to persist across restarts, they're also saved into files on disk. Alvaro[^alvaro] calls SLRUs “poorly named” for a user-facing feature. If they're internal, why are they worth knowing about as Postgres users?

They’re worth knowing about because there can be a couple of possible failure points with them, due their fixed size. We'll look at those later in this post.

Before getting into that, let's cover some basics about what they are and look at a specific type.

## Main purpose of SLRUs
The main purpose of SLRUs is to track metadata about Postgres transactions.

SLRUs are a general mechanism used by multiple types. Like a lot of things in Postgres, the SLRU system is extensible which means extensions can create new types.

The “least recently used” aspect might be recognizable from cache systems. LRU refers to how the oldest items are evicted from the cache when it’s full, and newer items take their place.
This is because the cache has a fixed amount of space (measured in 8KB pages) and thus can only store a fixed amount of items.

Old SLRU cache items are periodically cleaned up by the Vacuum process.

## What about the buffer cache?
The buffer cache (sized by configuring [shared_buffers](https://www.postgresql.org/docs/current/runtime-config-resource.html)) is another form of cache in Postgres. Thomas Munro proposed unifying the SLRUs and buffer cache mechanisms.

However, as of Postgres 17 and the upcoming 18 release (released September 9, 2025), SLRUs are still their own distinct type of cache.

What types of data is stored in SLRUs?

## What type of data is tracked in SLRUs?
Transactions are a core concept for relational databases like Postgres. Transactions are abbreviated “Xact,” and Xacts are one of the types of data stored in SLRUs.

Besides regular transactions, there are variations of transactions. Transactions can be created inside other transactions, which are called “nested transactions.”

Whether parent or nested transactions, they each get their own 32-bit integer identifier once they begin modifying something, and these are all tracked while they're in use. The [SAVEPOINT](https://www.postgresql.org/docs/current/sql-savepoint.html) keyword (blog post: [You make a good point! — PostgreSQL Savepoints](https://andyatkinson.com/blog/2024/07/22/postgresql-savepoints) saves the incremental status for a transaction.

Another variation of a transaction is a “multi-transaction,” (multiple transactions in a group) or “MultiXact” in Postgres speak.

## What are MultiXacts?
A MultiXact gets a separate number from the transaction identifier. I think of it like a “group” number. The group might be related to a table row, but each transaction in the group is doing something different. Think of multiple transactions all doing a foreign key referential integrity check on the same referenced primary key.

Here’s a definition of MultiXact IDs:
> A MultiXact ID is a secondary data structure that tracks multiple transactions holding locks on the same row.

When MultiXacts are created, their identifier is stored in tuple header info, replacing the transaction id that would normally be stored in the tuple header.

As this buttondown blog post ("Notes on some PostgreSQL implementation details")[^buttondown] describes, the tuple (row version) header has a small fixed size. The MultiXact id replaces the transaction id using the same size identifier (but a different one), to keep the tuple header size small (as opposed to adding another identifier).

Transaction IDs and MultiXact IDs are both represented as a unsigned 32-bit integer, meaning it's possible to store a max of around ~4 billion values (See: [Transactions and Identifiers](https://www.postgresql.org/docs/current/transaction-id.html). We can get the current transaction id value by running `select pg_current_xact_id();`.

What do we mean by transaction metadata? One example is with nested transactions, the parent transaction, the “creator”.

If you’d like to read how AWS introduces MultiXacts, check out this post. This post describes them: What are MultiXacts?
<https://aws.amazon.com/blogs/database/multixacts-in-postgresql-usage-side-effects-and-monitoring/>

When do MultiXacts get created?

## When do MultiXacts get created?
MultiXacts get created only for certain types of DML operations and for certain schema definitions. In other words, it’s possible that your particular Postgres database workload does not create MultiXacts at all, or it’s possible they’re heavily used.
Let’s look at what creates MultiXacts:
- Foreign key constraint enforcement
- `SELECT FOR SHARE`

If you use no foreign key constraints or your application (or ORM) never creates `SELECT FOR SHARE`, then your Postgres database may have no MultiXacts.

Let’s go back to SLRUs.

## More about SLRUs
SLRUs have a fixed size (prior to Postgres 17) measured in pages. When items are evicted from the SLRU cache, a [page replacement](https://www.interdb.jp/pg/pgsql08/01.html) occurs.

The page being replaced is called the “victim” page and Postgres must do a little work to find a victim page.
Since SLRUs survive Postgres restarts, they’re [saved in files in the PGDATA directory](https://www.interdb.jp/pg/pgsql08/01.html://www.postgresql.org/docs/17/storage-file-layout.html#PGDATA-CONTENTS-TABLE).

The directory name will depend on the SLRU type. For example for MultiXacts, the directory name is `pg_multixact`. SLRU buffer pages are written to the WAL and to disk, meaning that if the primary instance fails, the state can be recovered.

See the `slru.c` `SlruPhysicalWritePage` function comments which describes writing WAL and writing out data:
<pre>
Honor the write-WAL-before-data rule, if appropriate, so that we do not
write out data before associated WAL records.
</pre>

Each SLRU instance implements a circular buffer of pages in shared memory, evicting the least recently used pages. A circular buffer is another interesting Postgres internal concept but is beyond the scope of this post.
How can we observe what’s happening with SLRUs?

## Using pg_stat_slru
Since Postgres 13, we have the system view "pg_stat_slru" to query to inspect cumulative statistics about the SLRUs.
<https://www.postgresql.org/docs/current/monitoring-stats.html#PG-STAT-SLRU-VIEW>
To list only the names of the built-in SLRU types:

```sql
select name from pg_stat_slru;
      name
-----------------
 CommitTs
 MultiXactMember
 MultiXactOffset
 Notify
 Serial
 Subtrans
 Xact
 Other
```

To determine if our system is creating MultiXact SLRUs, we can query the pg_stat_slru view. We'd see non-zero numbers in rows below when the system is creating SLRU data.

```sql
select name from pg_stat_slru;
                     View "pg_catalog.pg_stat_slru"
    Column    |           Type           | Collation | Nullable | Default 
--------------+--------------------------+-----------+----------+---------
 name         | text                     |           |          | 
 blks_zeroed  | bigint                   |           |          | 
 blks_hit     | bigint                   |           |          | 
 blks_read    | bigint                   |           |          | 
 blks_written | bigint                   |           |          | 
 blks_exists  | bigint                   |           |          | 
 flushes      | bigint                   |           |          | 
 truncates    | bigint                   |           |          | 
 stats_reset  | timestamp with time zone |           |          |
```

To look at the `pg_xact` SLRU:
```sql
select * from pg_stat_slru where name = 'Xact';
 name | blks_zeroed | blks_hit | blks_read | blks_written | blks_exists | flushes | truncates |          stats_reset
------+-------------+----------+-----------+--------------+-------------+---------+-----------+-------------------------------
 Xact |         460 | 30686596 |        44 |         2030 |           0 |    1684 |         0 | 2024-11-19 09:52:33.506794-06
```

“Hit” and “read” refer to reads from the SLRU that where the desired pages were already in the SLRU or they were not.

When new pages are allocated, we see this reflected in “blks_zeroed” as they’re written out with zeroes.

When new pages are written (blks_written) into the SLRU this creates “dirtied” pages that eventually will be written out (flushes).

SLRUs can also be truncated (“Truncates” count).

Some of the source code for SLRUs in Postgres is in the file `backend/access/transam/slru.c`.
<https://github.com/postgres/postgres/blob/master/src/backend/access/transam/slru.c>

Now that we know some basics about SLRUs and a specific type, the MultiXact SLRU, what are some operational concerns or things that can go wrong?

## What can go wrong with SLRUs and Xacts?
Operational problems can stem from the fact that SLRUs use a 32-bit number and for high scale Postgres, it's possible to consume these fast enough that the number can “wrap around.”

Two examples with public write-ups related to SLRU operational problems are:

- Subtransactions overflow: Using subtransactions, each use of a subtransaction creates an id to track. At a high enough creation rate it's possible to run out of values.
This was written up in the GitLab post: [Why we spent the last month eliminating PostgreSQL subtransactions](https://about.gitlab.com/blog/why-we-spent-the-last-month-eliminating-postgresql-subtransactions/).

MultiXact member space exhaustion: MultiXact or multiple transactions can occur in a few scenarios.
- An explicit row lock: `SELECT … FOR SHARE`
- `SELECT … FOR UPDATE`

Written up in the Metronome blog post: [Root Cause Analysis: PostgreSQL MultiXact member exhaustion incidents (May 2025)](https://metronome.com/blog/root-cause-analysis-postgresql-multixact-member-exhaustion-incidents-may-2025).

A scenario for that could be a foreign key constraint lookup on a high insert table referencing a low cardinality table.

Another type of problem in the buttondown post[^buttondown] is the quadratic growth of MultiXacts.

Dilip Kumar talked about: “Long running transaction, system can go fully to cache replacement, TPS drops, with subtransactions ids (need to get parent ids).” See Dilip's presentation for more info.[^dilip]

## What do we do with info as Postgres operators?
This is a huge topic and this post just scratches the surface.

However, let's wrap this up here a bit with some takeaways.

If operating a high scale Postgres instance when it comes to SLRUs, what's worth knowing about?

- Know about the SLRU system in general, how to monitor it, and don't forget about extensions
- Learn about SLRUs limitations and possible failure points, for the various types
- Determine whether your workload is using SLRUs, monitor their growth, and learn about the possible failure points based on your use

## What’s changing with SLRUs in new Postgres versions?
In Postgres 17, the MultiXact member space and offset is now configurable beyond the initial default size. The unit is the number of 8KB pages. The default size is X and Y and this is configurable.

- multixact_member_buffers, default is 32 8kb pages
- multixact_offset_buffers, default is 16 8kb pages

> In the recent episode of postgres.fm *MultiXact member space exhaustion*,[^pgfm] the Metronome engineers discussed working on a patch related to MultiXact member exhaustion.

Lukas covers changes in Postgres 17 to adjust SLRU cache sizes. Each of the SLRU types can now be configured to be larger in size.
<https://pganalyze.com/blog/5mins-postgres-17-configurable-slru-cache>

## Conclusion
I'm still learning about MultiXacts, SLRUs, and failure modes as a result of these. If you have feedback on this post or additional useful resources, I'd love to hear about them. Please contact me here or on social media.

Thanks for reading!

## Resources
Dilip Kumar presentation 2024 - PostgreSQL Development Conference <https://www.youtube.com/watch?v=74xAqgS2thY>

MultiXacts Dan Slimmon
<https://blog.danslimmon.com/2023/12/11/concurrent-locks-and-multixacts-in-postgres/>

5 minutes of Postgres LWLock Lock Manager
<https://pganalyze.com/blog/5mins-postgres-LWLock-lock-manager-contention>

SLRU Improvements Proposals Wiki
<https://wiki.postgresql.org/wiki/SLRU_improvements>

## Corrections

September 27, 2025: An earlier version of this post inaccurately described SLRU buffers as not being WAL logged. Thank you to Laurenz Albe for writing in to correct this and providing a pointer into the source code to learn more.

[^pgfm]: <https://postgres.fm/episodes/multixact-member-space-exhaustion>
[^buttondown]: <https://buttondown.com/nelhage/archive/notes-on-some-postgresql-implementation-details/>
[^alvaro]: <https://p2d2.cz/files/p2d2-2025-herrera-slru.pdf>
[^alvaro2]: <https://www.postgresql.eu/events/pgconfde2025/sessions/session/6457/slides/664/pgconfde25-herrera-slru.pdf>
[^dilip]: <https://www.youtube.com/watch?v=74xAqgS2thY>
