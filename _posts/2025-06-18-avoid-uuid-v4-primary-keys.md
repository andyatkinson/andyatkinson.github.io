---
layout: post
permalink: /constraint-driven-optimized-responsive-efficient-core-db-design
title: Avoid UUID Version 4 Primary Keys
---

## Introduction
In the last 5 years, I've helped clients or companies that picked UUID Version 4[^rfc] for their primary keys (and matching foreign keys), that invariably faced significant performance problems and had excessive amounts of IO.

This is easy to do as they can be natively generated in Postgres for example, using the `gen_random_uuid()`[^gen] function. There's a native binary data type `uuid` to store values.

I've learned that besides performance problems, there are misconceptions about UUID Version 4 that can lead to picking them.

After seeing this pattern on repeat, I’ve come around to a general recommendation: Avoid UUID Version 4 for primary keys outside of a few scenarios.

In this post, we will look at why performance for v4 UUIDs is a problem, consider storage, index maintenance, and cache behavior, downsides, and a few scenarios where UUIDs are probably required.

We’ll look at recommendations for alternatives and how to mitigate impacts if you're stuck with these.

## Defining UUID Scope
- UUID in general (similar to GUID), 128 bit value
- UUID Version (Mostly random)
- UUID Version 7, includes timestamp, making it orderable

There are other versions below 4 and above 7, but versions 4 and 7 are the main ones in this discussion.

## Scope and scale of apps
The kinds of web applications I’ve worked on are monolithic web apps, with Postgres as their primary OLTP database, in categories like social media, e-commerce, click tracking, or general business process apps.

The type of performance issues here are related to inefficient storage and retrieval, meaning they occur regardless of the type of app.

## Randomness means no correlation
The core issue is that among the 128 bits (16 bytes) of data for UUID Version 4, 122 of the 128 are “random or pseudo-randomly generated values”.[^rfc] Random values don’t have natural sorting like integers do, or lexicographic (dictionary) sorting like character strings do.

Their ordering is "byte ordering," and that has no significant (or "semantic") meaning to how the data is inserted. This means we’ve lost "correlation" between the semantic meaning of inserts, one, two, three and so on, and how they're stored.

When inserts are physically ordered by being appended onto the end, this is a key performance characteristic for efficiently scanning ranges of data, or for fast lookups of individual items. In B+-Tree indexes, items are stored in sorted order. Item lookups rely on the sorted nature for fast traversal, with successive binary search operations.

Given the loss of ordering, why pick UUID Version 4 for a primary key data type?

## Why choose UUIDs at all? Generating values from one or more client applications
Imagine an offline mobile or desktop application that wants to work with items using an identifier locally, that will be persisted in Postgres. The client generates a UUID value and passes it to the server, which passes it to Postgres to store.

I personally haven’t worked on apps with this requirement. For web apps, they generally instantiate objects in memory and then get a database-generated id when they’re persisted. I also tend to work with monolithic apps that have a single application database.

However, I have worked with microservices architectures where the apps have their own databases. The ability to generate unique UUID values across all databases without collisions could be useful, in scenarios where it was critical to uniquely identify the database where the value came from.

We can’t make the collision avoidance guarantee with sequence-backed integers.
<https://news.ycombinator.com/item?id=36429986>

For example, the number of UUIDs that need to be generated in order to have a 50% probability of at least one collision is 2.71 quintillion, computed as follows:[27]

This number would be equivalent to generating 1 billion UUIDs per second for about 86 years.
<https://en.wikipedia.org/wiki/Universally_unique_identifier>


## Reason for UUID: Hiding positional generation information
Not sure on this one


## Reasons for UUID: Non-guessable next values, with integers
We can achieve pseudo-random identifiers that are obfuscated. Algorithm:

Convert decimal integer into bits, e.g. 1 gets converted into 00000000000000000000000000000001
Perform an XOR operation on the bits using a key
Encode each bit using a base62 alphabet

We started from integer primary keys, and stored this obfuscated value in a Postgres generated column. The generated value does not appear sequential to a human reader. 
For example the values in insertion order are, `01Y9I`, `01Y9L`, then `01Y9K`.

If they followed alphabetical ordering we’d expect `01Y9I`, then `01Y9K`, then `01Y9L`.

This solution is detailed further in this post: *Short alphanumeric pseudo random identifiers in Postgres*[^alpha]

If we wanted to take that a step further, while admittedly being a complex and unconventional design, we could have a single global sequence that is shared by all tables.

As long as all the tables use that sequence, then the sequence would guarantee uniqueness and the uniqueness would be global across all tables. We could generate short random identifiers from that unique sequence value.

If I wanted to have globally unique obfuscated ids, I’d probably want to make that a core table that was polymorphic, referring outward to a table by name and the primary key id, so I’d know how to look up which table the record was in based on it’s obfuscated id.

Now that we covered some reasons why UUIDs might be selected, let’s look at the reasons to avoid UUID in general, and especially versoin 4 as primary keys.

## Misconceptions: UUIDs are for security
From RFC 4122[^rfc] Section 6 Security Considerations:
> Do not assume that UUIDs are hard to guess; they should not be used
>   as security capabilities

## UUIDs consume a lot of space
UUIDs are 16 bytes (128 bits) per value, which is double the space of bigint (8 bytes), or quadruple the space of 4-byte integers. This extra space adds up once many tables have millions of rows, and copies of a database are being moved around as backups and restores.

## UUID v4s add insert latency due to page splits, fragmentation
For UUID v4s, due to their randomness, Postgres incurs more latency for every insert operation.
For integers, inserts are “append-mostly” operations on “leaf nodes.” Inserts are maintained in the primary key index.
For UUID v4s, inserts are not appended to the right most leaf page. They are placed into a random page, and could be mid-page or into a full page, causing an otherwise unnecessary page split.
Page splits and rebalancing mean more fragmented data, which means it will have higher latency to access. 

## Inspecting density with the pageinspect extension
We can inspect this using the pageinspect extension. It has a function called average leaf density. We want a high amount of leaf density to indicate low amounts of splits.
We can inspect this using the pageinspect.avg_leaf_density.
Show usages of this
```sql
create extension pageinspect;
```

```sql
pageinspect.avg_leaf_density
```

We will perform that later on using an example.

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
- 27332 buffers index only scan bigint column
- 8562960 buffers count index only scan on UUID V4 index scan

8,562,960 pages is 8,535,628 pages more than 27,332 pages, which equals:
- 66,676 MB, or
- 65.1 GB (approx) of additional data

Memory Bandwidth (GB/s)
DDR4-3200 (2–4 channels)
20–50 GB/s

Two rough estimates:
Low-end (conservative): 20 GB/s
High-end (aggressive): 80 GB/s

Accessing 65.1 GB of data from memory (shared_buffers in PostgreSQL) would take:
- ~3.3 seconds on a modest server (20 GB/s)
- ~0.8 seconds on a high-bandwidth server (80 GB/s)

My conclusion: That's between 1 and 3 additional seconds of latency. This will add up when this query is running in high volume, and on larger data sets. This was on 10 million rows, but what about 100 million, or 1 billion?

## Loss of locality for cache purposes
When Postgres accesses pages, they’re stored in the buffer cache or OS page cache. When data is written it’s written into buffers that are considered dirtied, then they’re flushed to disk later.
For good performance, we want our queries to access as many pages that are in the buffer cache as possible.
The Postgres buffer cache has a couple of types of locality, that refers to how data is stored relative to other data. One type is Spatial locality.
Another type is temporal locality. This means recently accessed data is likely to be accessed again. 

"Non-locality of reference - scattered data rather than clustered"
Poor cache performance

It takes away the ability for the query tuner programmer that relies on indexes, to have predictability in index usage (even within the declarative nature of planning).  Non-clusterable.


## Franck
https://dev.to/aws-heroes/uuid-in-postgresql-3n53


## UUID fragmentation mitigation
Since the tables and indexes can be fragmented, it makes sense to rebuild the tables or indexes periodically.

Rebuilding tables can be done with pg_repack or VACUUM FULL if you can afford to perform the rebuild offline.

Indexes can be rebuilt online using REINDEX CONCURRENTLY. 

While the newly laid out distribution of data into pages will still not have the correlation of integers, and thus not be smaller, the space occupied formerly by deletes will be reclaimed for reuse. 

## UUID and implicit order column Active Record
Implicit order column
<https://github.com/djezzzl/database_consistency/issues/197>



## OS page cache
Temporal and spatial locality
Yes, temporal locality is utilized via the buffer replacement policy:
Buffer eviction
LRU algorithm

Sequential scan prefetching
PostgreSQL tries to prefetch blocks during sequential scans, using a ring buffer that prevents overwhelming the buffer cache.

This prefetching captures spatial locality during full table scans but is isolated from the main buffer replacement strategy.


## Mitigating poor performance by clustering on orderedable field
Cluster on an indexed orderable column, For example in Active Record with UUID v4 primary keys, index the created_at column, and cluster on that. That will reorder pages for better spatial locality for scans.

```sql
CLUSTER your_table USING your_index;
```

## Sticking with sequences, integers, and big integers
For new databases, with unknown growth, I recommend plain old integers and sequences for primary keys. These are signed 32 bit (4-byte) values. This provides about 2 billion positive unique values per table. For many business apps, they will never reach 2 billion unique values per table, so this will be adequate for their entire life.
For Internet-facing consumer apps with high growth, like social media, click tracking, sensor data, telemetry collection types of apps, or when migrating an existing database with 100s of millions or billions of rows, then it makes sense to start with “bigint” (int8), 64 bit, 8 byte integer primary keys.

## Misconception about UUID: Hides generation information
UUID version 7 encodes generation time.

## UUID v4 Mitigations for sorting
One tactic I’ve used when working with UUID v4 random values where sorting is happening, is to provide more memory to sort operations.
To do that in Postgres, we can change the work_mem setting. This setting can be change database wide, at the session level, or even for individual queries.

## UUID v4 alternatives - Use V7
`pg_uuidv7`
In Postgres 17, the pg_uuidv7 extension can be used to generate UUID v7 values. Fortunately in Postgres 18 scheduled for released in Fall 2025, UUID v7 values can be generated natively without extensions.
If you have an existing UUID v4 filled database and can’t afford a costly migration to another data type, then at least beginning to populate new values using UUID v7 will help somewhat.
Fortunately the binary “uuid” data type in Postgres can be used regardless of whether you’re storing V4 or V7 UUIDs.

## Closing Thoughts
- For new databases don’t choose UUID v4 (gen_random_uuid() function) for primary key types if you can choose. This data type has significantly worse performance when inserting new data, accessing individual values, or accessing ranges of values.
- Random UUID v4s don’t have correlation between logical and physical order, and lose cache locality, which is a critical aspect of performance and cost efficiency. 
- UUIDs were not meant to be used for security, per the original UUID RFC authors.
- For non-guessable pseudo random values, generate those from integers. Use integers internally for primary keys and foreign keys for maximum performance, then generate obfuscated ids for use outside of the database.

Do you see any errors or have any suggested improvements? Please [contact me](/contact). Thanks for reading!

[^alpha]: <https://andyatkinson.com/generating-short-alphanumeric-public-id-postgres>
[^gen]: <https://www.postgresql.org/docs/current/functions-uuid.html>
[^rfc]: <https://datatracker.ietf.org/doc/html/rfc4122#section-4.4>
