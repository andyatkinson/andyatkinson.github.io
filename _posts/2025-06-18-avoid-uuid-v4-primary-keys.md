---
layout: post
permalink: /constraint-driven-optimized-responsive-efficient-core-db-design
title: Avoid UUID Version 4 Primary Keys
---

## Introduction
In the last handful of years, I've worked on databases where UUID Version 4[^rfc] was picked for the primary key data type and the database typically had performance problems and excessive IO.

UUID v4 is easy to pick as they can be natively generated in Postgres with the `gen_random_uuid()`[^gen] function added in 13 (2020). There's a native binary data type `uuid` to store values.

I've learned that there are misconceptions about UUID Version 4 that can lead to them being chosen.

After seeing this pattern on repeat, I’ve come around to a general recommendation: Avoid UUID Version 4 for primary keys when possible.

In this post, we will look at why performance for v4 UUIDs is a problem, consider their storage, maintenance, and cache behavior. We'll cover the limited set of scenarios where UUIDs are likely required.

## Defining UUID Scope
- UUID in general (similar to GUID), 128 bit (16 byte) values
- UUID Version 4, mostly random bits
- UUID Version 7, includes a timestamp which makes it orderable, solving most of the problems

There are other versions below 4 and above 7, but versions 4 and 7 are the main ones discussed here.

## Scope and scale of apps
The kinds of web applications I’ve worked on are monolithic web apps, with Postgres as their primary OLTP database, in categories like social media, e-commerce, click tracking, or general business process apps.

The type of performance issues here are related to inefficient storage and retrieval, meaning they occur regardless of the type of app.

## Randomness means loss of correlation and locality
The core issue is that among the 128 bits for UUID Version 4, 122 are "random or pseudo-randomly generated values."[^rfc]

Random values don’t have natural sorting like integers do, or lexicographic (dictionary) sorting like character strings.

UUID v4s are ordered by "byte ordering," which has no semantic meaning for their use.

Because they're inserted randomly, we lose "correlation" between their insert-based logical ordering, and their physical storage.

When inserts are physically stored with high correlation to their logical order, this is a key characteristic for efficiently scanning ranges of ordered data, fast binary search lookups of items in B+-Tree indexes, and part of the temporal and spatial locality for caching, which we'll look at later.

Given the loss of orderability, why pick UUIDs?

## Why choose UUIDs at all? Generating values from one or more client applications
Imagine an offline mobile or desktop application that wants to work with items using an identifier locally, that will be persisted in Postgres. The client generates a UUID value and passes it to the server, which passes it to Postgres to store.

I personally haven’t worked on apps with this requirement. For web apps, they generally instantiate objects in memory and then get a database-generated id when they’re persisted. I also tend to work with monolithic apps that have a single application database.

However, I have worked with microservices architectures where the apps have their own databases. The ability to generate unique UUID values across all databases without collisions could be useful, in scenarios where it was critical to uniquely identify the database where the value came from.

We can’t make the collision avoidance guarantee with sequence-backed integers.
<https://news.ycombinator.com/item?id=36429986>

For example, the number of UUIDs that need to be generated in order to have a 50% probability of at least one collision is 2.71 quintillion.

This number would be equivalent to "generating 1 billion UUIDs per second for about 86 years."
<https://en.wikipedia.org/wiki/Universally_unique_identifier>

## Reason for UUID: Hiding positional generation information
One reason folks cite is that a random UUID v4 reveals no information about when it was generated. While it's true that integers can reveal their generation time, can be compared and sorted, I haven't seen a practical negative imapct of this.

Integers could be used internally, and external obfuscated identifiers can be generated for use. We'll look at that later next.

## Misconceptions: UUIDs are for security
From RFC 4122[^rfc] Section 6 Security Considerations:
> Do not assume that UUIDs are hard to guess; they should not be used
>   as security capabilities


## Reasons against UUID: We can create obfuscated values using integers
We can achieve pseudo-random obfuscated identifiers using integers. Algorithm:

- Convert decimal integer into binary bits
- Perform an XOR operation on the bits using a key
- Encode each bit using a base62 alphabet

We started from integer primary keys, and stored this obfuscated value in a Postgres generated column. The generated value does not appear sequential to a human reader. 

For example the values in insertion order are, `01Y9I`, `01Y9L`, then `01Y9K`.

If they followed alphabetical ordering we'd expect the last two to be flipped: `01Y9I`, then `01Y9K`, then `01Y9L`.

This solution is detailed further in this post: *Short alphanumeric pseudo random identifiers in Postgres*[^alpha]

If I wanted to have globally unique obfuscated ids, I’d probably want to make that a core table that was polymorphic, referring outward to a table by name and the primary key id, so I’d know how to look up which table the record was in based on it’s obfuscated id.

Now that we covered some reasons why UUIDs might be selected, let’s look at the reasons to avoid UUID in general, and especially versoin 4 as primary keys.

## Reasons against UUIDs in general: they consume a lot of space
UUIDs are 16 bytes (128 bits) per value, which is double the space of bigint (8 bytes), or quadruple the space of 4-byte integers. This extra space adds up once many tables have millions of rows, and copies of a database are being moved around as backups and restores.

## Reasons against: UUID v4s add insert latency due to page splits, fragmentation
For UUID v4s, due to their randomness, Postgres incurs more latency for every insert operation.

For integers, inserts are "append-mostly" operations on "leaf nodes." Inserts are maintained in the primary key index.

For UUID v4s, inserts are not appended to the right most leaf page. They are placed into a random page, and could be mid-page or into a full page, causing an otherwise unnecessary page split.

Page splits and rebalancing mean more fragmented data, which means it will have higher latency to access.

Later on we will use the pageinspect extension to check the average leaf density between integer and UUID.

## Excessive IO for lookups even with orderable UUIDs
While there is a replacement UUID type that has orderable properties, V7, and is starting to take the place of UUID v4 for performance reasons, UUID itself still is large occupying more space, and adding more latency for lookups.

B-Tree page layout means you can fit fewer UUIDs per 8KB page. Since we have the limitation of fixed page sizes, we at least want them to be densely packed to be efficient.

Since UUID indexes are ~40% larger in leaf pages than bigint (int8) for the same logical number of rows, they can’t be as densely packed with values.

This means that for individual lookups, range scans, or UPDATES, we will incur  ~40% more I/O on UUID indexes, as more pages are scanned.

Let’s insert and query some data and take a look at numbers and some claims made in this post.

## Working with integers, UUID v4, and UUID v7
Let’s create integer, UUID v4, and UUID v7 fields, index them, load them into the buffer cache with pg_prewarm, and access them.

Instead of inventing that from scratch, I will use this Cybertec post called “surprising things about UUIDs” which set up this kind of schema design and inserted data.

To do that I did need to compile the pg_uuidv7 extension for macOS but that was straightforward. Once compiled and enabled for Postgres, I could use the extension functions to generate UUID V7 values. Pg_prewarm is a module included with postgres, so that just requires being enabled.
Even though my local SSD storage seemed faster on my M1 Macbook Pro compared with the original example, the difference in latency and the huge difference in buffers (pages) between integer and UUID was reproducible.

<https://www.cybertec-postgresql.com/en/unexpected-downsides-of-uuid-keys-in-postgresql/ >

Cybertec post results:
- 27,332 buffer hits, index only scan on the `bigint` column
- 8,562,960 buffer hits, index only scan on the UUID V4 index scan

8,562,960 is 8,535,628 more than 27,332 8KB pages. If we multiple, that equals:
- 66,676 MB more IO, or
- ~65.1 GB

Since these are buffer hits, we're accessing them in fast memory, but that's still a big differences.

Let's understand the data access related latency. AI helped me come up with some example Memory Bandwidth (GB/s):
- DDR4-3200 (2–4 channels)
- Speed of 20–50 GB/s

We calculated a low and high estimate of the hardware speed:
- Low-end (conservative): 20 GB/s
- High-end (aggressive): 80 GB/s

Accessing 65.1 GB of data from memory (`shared_buffers` in PostgreSQL) would add:
- ~3.3 seconds of latency on a modest server (20 GB/s)
- ~0.8 seconds of latency on a high-bandwidth server (80 GB/s)

My conclusion: That's between 1 and 3 seconds of additional latency, and that will get worse as data sizes and fragmentation increases.

This was on 10 million rows, but what if we performed the same experiments on 100 million or 1 billion rows?

## Inspecting density with the pageinspect extension
We can inspect this using the pageinspect extension. It has a function called average leaf density. We want a high amount of leaf density to indicate low amounts of splits.
We can inspect this using the `pageinspect.avg_leaf_density`.

Show usages of this:
```sql
create extension pageinspect;
```

```sql
pageinspect.avg_leaf_density
```

We will perform that later on using an example.

## Loss of locality for caching
When Postgres accesses pages, they’re stored in the buffer cache or OS page cache, which are memory and have high access speeds compared with disks. That gap has been reduced with fast NVMe disk drives.

When data is written it’s written into buffers, they're considered "dirtied," and dirty buffers are later flushed to disk. When data is accessed outside the buffer cache or OS cache, it's copied into those caches.

This is the idea of temporal locality, that pages that are recently accessed are likely to be accessed again. For good performance, we want our queries to result in cache "hits" as much as possible. The buffer cache is limited, usually 25-40% of system memory, while the total database size including table data and index data is usually larger than the available buffer cache memory. That means we'll have trade-offs, and not everything will fit.

For UUIDs, when pages are accessed to try and find the target rows or row, pages are copied to the buffer cache regardless of whether they contain the row.

This uses the limited buffer cache space up unnecessarily, which reduces the scalability of our instance, which increases latency.

This is referred to as "non-locality of reference, scattered data rather than clustered".

## UUID fragmentation mitigation
Since the tables and indexes are more likely to be fragmented, it makes sense to rebuild the tables and indexes periodically.

Rebuilding tables can be done using pg_repack, pg_squeeze, or `VACUUM FULL` if you can afford to perform the operation offline.

Indexes can be rebuilt online using `REINDEX CONCURRENTLY`.

While the newly laid out data in pages, they will still not have correlation, and thus not be smaller. The space formerly occupied by deletes will be reclaimed for reuse though.

## Mitigation
If possible, size your primary instance to have 4x the amount of memory of your size of database. In order words if your database is 25GB, try and run a 128GB memory instance.

This gives you something liek 32GB to 50GB of memory for buffer cache (`shared_buffers`) which is hopefully enough to store all accessed pages and index entries.

Use pg_buffercache[^pgbc] to inspect the contents, and pg_prewarm[^pgpre] to populate key relations into the buffer cache.


## UUID and implicit order column Active Record
Implicit order column
<https://github.com/djezzzl/database_consistency/issues/197>

## OS page cache
Temporal and spatial locality
Yes, temporal locality is utilized via the buffer replacement policy:
- Buffer eviction
- LRU algorithm

Sequential scan prefetching

PostgreSQL tries to prefetch blocks during sequential scans, using a ring buffer that prevents overwhelming the buffer cache.

This prefetching captures spatial locality during full table scans but is isolated from the main buffer replacement strategy.

## Mitigating poor performance by clustering on orderable field
Cluster on an indexed orderable column. For example in Active Record with UUID v4 primary keys, index the `created_at` column, and cluster on that.

That will reorder pages for better spatial locality for scans.
```sql
CLUSTER your_table USING your_index;
```

## Sticking with sequences, integers, and big integers
For new databases, with unknown growth, I recommend plain old integers and sequences for primary keys. These are signed 32 bit (4-byte) values. This provides about 2 billion positive unique values per table. For many business apps, they will never reach 2 billion unique values per table, so this will be adequate for their entire life.

For Internet-facing consumer apps with high growth, like social media, click tracking, sensor data, telemetry collection types of apps, or when migrating an existing database with 100s of millions or billions of rows, then it makes sense to start with `bigint` (int8), 64-bit, 8-byte integer primary keys.

## Mitigations: Adding memory for UUID v4 sorting
One tactic I’ve used when working with UUID v4 random values where sorting is happening, is to provide more memory to sort operations.

To do that in Postgres, we can change the `work_mem` setting. This setting can be change database wide, at the session level, or even for individual queries.

## UUID v4 alternatives: Use V7
As of this writing, one option to generate UUID V7s in Postgres is to use the `pg_uuidv7` extension. In Postgres 18 scheduled for released in Fall 2025, UUID v7 values can be generated natively without extensions.

If you have an existing UUID v4 filled database and can't afford a costly migration to another primary key data type, then starting to populate new values using UUID v7 will help somewhat.

Fortunately the binary `uuid` data type in Postgres can be used whether you're storing V4 or V7 UUID values.

## Closing Thoughts
- For new databases, don’t use the `gen_random_uuid()` for primary key types, which generates UUID v4 values that are unfriendly for performance.
- Random UUID v4s don’t have correlation between logical and physical order, and lose temporal and spatial locality, a key aspect of caching and efficient reads and writes
- UUID v4 values are not meant to be secure despite their randomness, per the UUID RFC spec.
- For non-guessable pseudo-random values, generate those from integers. Use integers for primary keys and foreign keys, and obfuscated external ids for use outside the database.

Do you see any errors or have any suggested improvements? Please [contact me](/contact). Thanks for reading!

## More
- As usual, Franck Pachot for AWS Heroes has an interesting take on [UUID in PostgreSQL](https://dev.to/aws-heroes/uuid-in-postgresql-3n53)!

[^alpha]: <https://andyatkinson.com/generating-short-alphanumeric-public-id-postgres>
[^gen]: <https://www.postgresql.org/docs/current/functions-uuid.html>
[^rfc]: <https://datatracker.ietf.org/doc/html/rfc4122#section-4.4>
[^pgbc]: <https://www.postgresql.org/docs/current/pgbuffercache.html>
[^pgpre]: <https://www.postgresql.org/docs/current/pgprewarm.html>
