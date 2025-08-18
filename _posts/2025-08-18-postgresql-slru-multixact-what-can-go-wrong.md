---
layout: post
permalink: /postgresql-slru-multixact-what-can-go-wrong
title: What are SLRUs and Multixacts in Postgres? What can go wrong?
hidden: true
---

What are SLRUs and Multixacts in Postgres? What can go wrong?
In this post we’ll cover two types of Postgres internals. These came up in recent work so I took the opportunity to learn a little more about them, but this is not meant to be an exhaustive resource. I’ll link some more resources that go further towards the end.

The first internal item is an “SLRU.” While the acronym stands for “simple least recently used” and it does indeed refer to a type of cache, SLRUs are also a generalized internal storage mechanism for different types of data, and are kind of a collective category of internal stuctures to observe and be aware of for higher scale Postgres operations.

SLRUs store small items in memory and the content is also persisted to disk. Alvaro[^alvaro] calls SLRUs “poorly named” for a user-facing feature. If they're internal, why are they worth knowing about as a user? They’re worth knowing about as because they're related to a couple of possible failure scenarios given their fixed size, that we'll look at later on in the post.

Before getting into that, let's cover some basic info about what they are and look at one of the types in more detail.

## Main purpose of SLRUs
The main purpose of SLRUs is to track metadata about Postgres transactions.

SLRUs are a generic mechanism where multiple types of items can be stored, although there are SLRUs for different "types." Like a lot of things in Postgres, the SLRU system is extensible which means extensions can (and do) create new types of SLRUs.

The “least recently used” aspect might be recognizable from cache systems. LRU refers to how the oldest items are evicted from the cache when it’s full, and newer items take their place.
This is because the cache has a fixed amount of space (measured in 8KB pages) and thus can store a fixed amount of items. Old SLRU cache items are periodically cleaned up by the Vacuum process.

## What about the buffer cache?
The buffer cache (sized by configuring [shared_buffers](https://www.postgresql.org/docs/current/runtime-config-resource.html)) is another form of cache in Postgres. Thomas Munro proposed unifying the SLRUs by using the existing buffer cache mechanism to serve their purpose, as opposed to them being a distinct form of memory cache. <https://www.youtube.com/watch?v=AEP60783Mas>

However, as of the current and next Postgres releases, 17 and 18, SLRUs are still their own distinct type of cache.

What types of data is stored in SLRUs?

## What types of data is tracked in SLRUs?
Transactions are a core concept for relational databases like Postgres. Transactions are abbreviated “Xact” in Postgres which is useful information when analyzing the names of SLRUs we'll do in a moment. Transactions get a 32 bit integer identifier when they’re created, and besides regular transactions, there are variations of transactions. For example, transactions can be created inside other transactions which are called “nested transactions.”

Whether parent or nested transactions, they each get their own 32-bit integer identifier once they begin modifying something. The [SAVEPOINT] keyword can be used (blog post: [You make a good point! — PostgreSQL Savepoints](https://andyatkinson.com/blog/2024/07/22/postgresql-savepoints) to save incremental status of a transaction.

Another variation of a transaction is a “multi-transaction,” (multiple transactions in a group) or “multiXact” in Postgres speak.

## What are MultiXacts?
Another type of transaction is a “Multixact” or multi-transaction. A MultiXact gets a separate number from the transaction identifier. I think of it like a “group” number. The group is working with the same logical table row for example, but each transaction in the group has a distinct purpose. Think of multiple transactions all doing a foreign key referential integrity lookup on the same referenced primary key.

When MultiXacts are created, their identifier is stored in tuple header info, replacing the transaction id that would normally be stored in the tuple header.

As this buttondown blog post ("Notes on some PostgreSQL implementation details")[^buttondown] describes, the tuple (row version) header has a small fixed size. The MultiXact id replaces the transaction id using the same size identifier (but a different one), to keep the tuple header size small (as opposed to adding another identifier).

Here’s a definition of MultiXact IDs:
> A MultiXact ID is a secondary data structure that tracks multiple transactions holding locks on the same row.

Transaction IDs and Multixact IDs are both represented as a 32-bit integer. This means there’s a max number of values of around 4 billion.

What do we mean by transaction metadata? One example is with nested transactions, the parent transaction, the “creator”.

If you’d like to read how AWS introduces Multixacts, check out this post. This post describes them: What are Multixacts?
<https://aws.amazon.com/blogs/database/multixacts-in-postgresql-usage-side-effects-and-monitoring/>

We will continue to explore Multixacts and then come back to SLRUs.

When do Multixacts get created?

## When do Multixacts get created?
Multixacts get created only for certain types of DML operations and for certain schema definitions. In other words, it’s possible that your particular Postgres database workload does not create Multixacts at all, or it’s possible they’re heavily used.
Let’s look at what creates MultiXacts:
- Foreign key constraint enforcement
- `SELECT FOR SHARE`
If you use no foreign key constraints and your application (or ORM) never creates a SELECT FOR SHARE, then your Postgres database may have no Multixacts.

Let’s go back to SLRUs.

## More about SLRUs
SLRUs have a fixed size (prior to Postgres 17) measured in pages. When items are evicted from the SLRU cache, a “page replacement” occurs. <https://www.interdb.jp/pg/pgsql08/01.html>

The page being replaced is called the “victim” page and Postgres must do a little work to find a victim page.
Since SLRUs survive Postgres restarts, they’re saved in files in the PGDATA directory <https://www.postgresql.org/docs/17/storage-file-layout.html#PGDATA-CONTENTS-TABLE> as opposed to existing in memory only.

The directory name will depend on the SLRU type. For example for MultiXacts, the directory name is `pg_multixact`.
Despite being saved to disk, SLRUs are logged in the write ahead log (WAL). This means they exist only on the primary instance and survive restarts, but aren’t replicated, so they wouldn’t survive a loss of the primary instance in the event of a primary instance replacement.
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

To determine if our system is creating Multixact SLRUs, we can query the pg_stat_slru view. We'd see non-zero numbers for the data points (rows) below, when the system is creating SLRU data.

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

“Hit” and “read” refer to reads from the SLRU that where the desired pages were already in the SLRU or they were not.
When new pages are allocated, we see this reflected in “blks_zeroed” as they’re written out with zeroes.
When new pages are written (blks_written) into the SLRU this creates “dirtied” pages that eventually will be written out (flushes).
SLRUs can also be truncated (“Truncates” count).

Some of the source code for SLRUs in Postgres is in the file `backend/access/transam/slru.c`.
<https://github.com/postgres/postgres/blob/master/src/backend/access/transam/slru.c>

Now that we know some basics about SLRUs and a specific type, the MultiXact SLRU, what are some operational concerns or things that can go wrong?

## What can go wrong with SLRUs and Xacts?
Operational problems can stem from the fact that SLRUs use a 32-bit integer identifier, which is 4 bytes of space, and can “wrap around” when the available space is exhausted, given a high enough volume of creation.

Two examples with public write-ups related to SLRU operational problems are:
Subtransactions overflow: Using subtransactions, each use of a subtransaction creates an id to track. Up to 2 billion positive values can be tracked. At a high enough creation rate It’s possible to run out of values.
This was written up in the GitLab post [Why we spent the last month eliminating PostgreSQL subtransactions](https://about.gitlab.com/blog/why-we-spent-the-last-month-eliminating-postgresql-subtransactions/).

Multixact member space exhaustion: Multi-xact or multiple transactions can occur in a few scenarios.
An explicit row lock: `SELECT … FOR SHARE` or `SELECT … FOR UPDATE`. Written up in the Metronome blog post: [Root Cause Analysis: PostgreSQL MultiXact member exhaustion incidents (May 2025)](https://metronome.com/blog/root-cause-analysis-postgresql-multixact-member-exhaustion-incidents-may-2025).

A foreign key constraint lookup on a high insert table referencing a low cardinality table as the referenced table.

Another type of problem in the buttondown [^buttondown] post is the quadratic growth of MultiXacts.

Dilip Kumar talked about: “Long running transaction, system can go fully to cache replacement, TPS drops, with subtransactions ids (need to get parent ids)” (see presentation).

## What do we do with all of this info as Postgres operators?
Let's wrap up this post with some takeaways. If operating a high scale Postgres instance when it comes to SLRUs, what's worth knowing about?

- Know about the SLRU system in general, how to monitor it, and don't forget extensions
- Learn about SLRUs limitations and possible failure points, for the various types
- Determine whether your workload is using the SLRU system, monitor their use, and learn about the relevant possible failure points for your use

## What’s changing with SLRUs in new Postgres versions?
In Postgres 17, the Multixact member space and offset is now configurable beyond the initial default size. The unit is the number of 8KB pages. The default size is X and Y and this is configurable.
Multixact_member_buffers, default is 32 8kb pages

Multixact_offset_buffers, default is 16 8kb pages

> In the recent episode of postgres.fm *MultiXact member space exhaustion*,[^pgfm] the Metronome engineers discussed working on a patch related to Multixact member exhaustion.

Lukas covers changes in Postgres 17 to adjust SLRU cache sizes. Each of the SLRU types can now be configured to be larger in size.
<https://pganalyze.com/blog/5mins-postgres-17-configurable-slru-cache>

## Resources
Dilip Kumar presentation 2024 - PostgreSQL Development Conference <https://www.youtube.com/watch?v=74xAqgS2thY>

MultiXacts Dan Slimmon
<https://blog.danslimmon.com/2023/12/11/concurrent-locks-and-multixacts-in-postgres/>

5 minutes of Postgres LWLock Lock Manager
<https://pganalyze.com/blog/5mins-postgres-LWLock-lock-manager-contention>

[^pgfm]: <https://postgres.fm/episodes/multixact-member-space-exhaustion>
[^buttondown]: <https://buttondown.com/nelhage/archive/notes-on-some-postgresql-implementation-details/>
[^alvaro]: <https://p2d2.cz/files/p2d2-2025-herrera-slru.pdf>
[^alvaro2]: <https://www.postgresql.eu/events/pgconfde2025/sessions/session/6457/slides/664/pgconfde25-herrera-slru.pdf>
