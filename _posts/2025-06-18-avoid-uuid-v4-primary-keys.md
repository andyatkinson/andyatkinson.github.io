---
layout: post
permalink: /constraint-driven-optimized-responsive-efficient-core-db-design
title: Avoid UUID Version 4 Primary Keys
date: 2025-07-02
tags: [PostgreSQL, Databases, Ruby on Rails]
---

## Introduction
Over the last decade, when working on databases where UUID Version 4[^rfc] was picked as the primary key data type, these databases usually have bad performance and excessive IO.

UUID is a native data type that can be stored as binary data, with various versions outlined in the RFC. Version 4 is mostly random bits, obfuscating information like when the value was created, or where it was generated.

Version 4 UUIDs are easy to work with in Postgres as the `gen_random_uuid()`[^gen] function generates values natively since version 13 (2020).

I've learned there are misconceptions about UUID Version 4, and sometimes the reasons users pick this data type is based on them.

Because of the poor performance, misconceptions, and available alternatives, I’ve come around to a simple position: *Avoid UUID Version 4 for primary keys*.

My more controversial take is to avoid UUIDs in general, but I understand there are some legitimate scenarios where there aren't practical alternatives.

As a database enthusiast, I wanted to have an articulated position on this classic "Integer v. UUID" debate.

Among databases folks, debating these alternatives may be tired and clichéd. However, from my consulting work, I can say that I'm working on databases with UUID v4 as the primary key in 2024 and 2025, and seeing the issues discussed in this post.

Let's dig in.

## The scope of UUIDs in this post
- UUIDs (or GUID in Microsoft speak)[^ms]) are long strings of 36 characters, 32 digits, 4 hyphens, stored as 128 bits (16 byte) values, stored using the binary `uuid` data type in Postgres
- The RFC documents how the 128 bits are set
- The bits for UUID Version 4 are mostly random values
- UUID Version 7 includes a timestamp in the first 48 bits, which works much better with database indexes compared with random values

Although unreleased as of this writing, and pulled from Postgres 17 previously, UUID V7 is part of Postgres 18[^land] scheduled for release in the Fall of 2025.

What kind of app databases are in scope for this post?

## Scope of web app usage and and scale
The kinds of web applications I'm thinking of with this post are monolithic web apps, with Postgres as their primary OLTP database. The apps could be in categories like social media, e-commerce, click tracking, or business process automation apps.

The types of performance issues discussed here are related to inefficient storage and retrieval, meaning they happen for all of these types of apps.

What's the core issue with UUID v4?

## Randomness is the issue
The core issue with UUID Version 4, given 122 bits are "random or pseudo-randomly generated values"[^rfc] and primary keys are backed by indexes, is the impact to inserts and retrieval of individual items or ranges of values from the index.

Random values don't have natural sorting like integers or lexicographic (dictionary) sorting like character strings.

UUID v4s do have "byte ordering," but this has no useful meaning for how they're accessed.

What use cases for UUID are there?

## Why choose UUIDs at all? Generating values from one or more client applications
One use case for UUIDs is when there's a need to generate an identifier on a client or from multiple services, then passed to Postgres for persistence.

For web apps, generally they instantiate objects in memory and don't expect an identifier to be used for lookups until after an instance is persisted as a row (where the database generates the identifier).

In a microservices architecture where the apps have their own databases, the ability to generate identifiers from each database without collisions is a use case for UUIDs. The UUID could also identify the database a value came from later, vs. an integer.

For collision avoidance (see HN discussion[^hn]), we can't practically make the same guarantee with sequence-backed integers. There are hacks, like generating even and odd integers between two instances, or using different ranges in the int8 range.

There are also alternative identifiers like using composite primary keys (CPKs), however the same set of 2 values wouldn't uniquely identify a particular table.

The avoidance of collisions is described this way on Wikipedia:[^wiki]

> The number of random version-4 UUIDs which need to be generated in order to have a 50% probability of one collision: 2.71 quintillion

This number would be equivalent to:

> Generating 1 billion UUIDs per second for about 86 years.

Are UUIDs secure?

## Misconceptions: UUIDs are secure
One misconception about UUIDs is that they're secure. However, the RFC describes that they shouldn't be considered secure "capabilities."

From RFC 4122[^rfc] Section 6 Security Considerations:
> Do not assume that UUIDs are hard to guess; they should not be used
>   as security capabilities

How can we create obfuscated codes from integers?

## Creating obfuscated values using integers
While UUID V4s obfuscate their creation time, the values can't be ordered to see when they were created relative to each other. We can  achieve those properties with integers with a little more work.

One option is to generate a pseudo-random code from an integer, then use that value externally, while still using integers internally.

To see the full details of this solution, please check out: *Short alphanumeric pseudo random identifiers in Postgres*[^alpha]

We'll summarize it here.

- Convert a decimal integer like "2" into binary bits. E.g. a 4 byte, 32 bit integer: 00000000 00000000 00000000 00000010
- Perform an exclusive OR (XOR) operation on all the bits using a key
- Encode each bit using a base62 alphabet

The obfuscated id is stored in a generated column. By reviewing the generated values, they are similar, but aren't ordered by their creation order.

The values in insertion order were `01Y9I`, `01Y9L`, then `01Y9K`.

With alphabetical order, the last two would be flipped: `01Y9I` first, then `01Y9K` second, then `01Y9L` third, sorting on the fifth character.

If I wanted to use this approach for all tables, I’d try a centralized table that was polymorphic, storing a record for each table that's using a code (and a foreign key constraint).

That way I'd know where the code was used.

Why else might we want to skip UUIDs?

## Reasons against UUIDs in general: they consume a lot of space
UUIDs are 16 bytes (128 bits) per value, which is double the space of bigint (8 bytes), or quadruple the space of 4-byte integers. This extra space adds up once many tables have millions of rows, and copies of a database are being moved around as backups and restores.

A more considerable impact to performance though is the poor characteristics of writing and reading random data into indexes.

## Reasons against: UUID v4s add insert latency due to index page splits, fragmentation
For random UUID v4s, Postgres incurs more latency for every insert operation.

For integer primary key rows, their values are maintained in index pages with "append-mostly" operations on "leaf nodes," since their values are orderable, and since B-Tree indexes store entries in sorted order.

For UUID v4s, primary key values in B-Tree indexes are problematic.

Inserts are not appended to the right most leaf page. They are placed into a random page, and that could be mid-page or an already-full page, causing a page split that would have been unnecessary with an integer.

Planet Scale has a nice visualization of index page splits and rebalancing.[^ps]

Unnecessary splits and rebalancing add space consumption and processing latency to write operations. This extra IO shows up in Write Ahead Log (WAL) generation as well.

[Buildkite reported a 50% reduction in write IO](https://buildkite.com/resources/blog/goodbye-integers-hello-uuids/) for the WAL by moving to time-ordered UUIDs.

Given fixed size pages, we want high density within the pages. Later on we'll use *pageinspect* to check the average leaf density between integer and UUID to help compare the two.

## Excessive IO for lookups even with orderable UUIDs
B-Tree page layout means you can fit fewer UUIDs per 8KB page. Since we have the limitation of fixed page sizes, we at least want them to be as densely packed as possible.

Since UUID indexes are ~40% larger in leaf pages than bigint (int8) for the same logical number of rows, they can’t be as densely packed with values. As Lukas says, "*All in all, the physical data structure matters as much as your server configuration to achieve the best I/O performance in Postgres*."[^pga5]

This means that for individual lookups, range scans, or UPDATES, we will incur ~40% more I/O on UUID indexes, as more pages are scanned. Remember that even to access one row, in Postgres the whole page is accessed where the row is, and copied into a shared memory buffer.

Let’s insert and query data and take a look at numbers between these data types.

## Working with integers, UUID v4, and UUID v7
Let’s create integer, UUID v4, and UUID v7 fields, index them, load them into the buffer cache with *pg_prewarm*.

I will use the schema examples from the Cybertec post [Unexpected downsides of UUID keys in PostgreSQL](https://www.cybertec-postgresql.com/en/unexpected-downsides-of-uuid-keys-in-postgresql/) by Ants Aasma.

View [andyatkinson/pg_scripts PR #20](https://github.com/andyatkinson/pg_scripts/pull/20).

On my Mac, I compiled the `pg_uuidv7` extension. Once compiled and enabled for Postgres, I could use the extension functions to generate UUID V7 values.

Another extension `pg_prewarm` is used. It's a module included with Postgres, so it just needs to be enabled per database where it's used.

The difference in latency and the enormous difference in buffers from the post was reproducible in my testing.

> "Holy behemoth buffer count batman"
<small>- Ants Aasma</small>

Cybertec post results:
- 27,332 buffer hits, index only scan on the `bigint` column
- 8,562,960 buffer hits, index only scan on the UUID V4 index scan

Since these are buffer *hits* we're accessing them from memory, which is faster than disk. We can focus then on only the difference in latency based on the data types.

How many more pages are accessed for the UUID index? 8,535,628 (8.5 million!) more 8KB pages were accessed, a 31229.4% increase. In terms of MB and MB/s that is:
- 68,285,024 MB or ~68.3 GB! more data that's accessed

Calculating a low and high estimate of access speeds for memory:
- Low estimate: 20 GB/s
- High estimate: 80 GB/s

Accessing 68.3 GB of data from memory (`shared_buffers` in PostgreSQL) would add:
- ~3.4 seconds of latency (low speed)
- ~0.86 seconds of latency (high speed)

That's between ~1 and ~3.4 seconds of additional latency solely based on the data type. Here we used 10 million rows and performed 1 million updates, but the latencies will get worse as data and query volumes increase.

## Inspecting density with the pageinspect extension
We can inspect the average fill percentage (density) of leaf pages using the *pageinspect* extension.

The `uuid_experiments/page_density.sql` ([andyatkinson/pg_scripts PR #20](https://github.com/andyatkinson/pg_scripts/pull/20)) query in the repo gets the indexes for the integer and v4 and v7 uuid columns, their total page counts, their page stats, and the number of leaf pages.

Using the leaf pages, the query calculates an average fill percentage.

After performing the 1 million updates on the 10 million rows mentioned in the example, I got these results from that query:
```sql
 idxname             | avg_leaf_fill_percent
---------------------+-----------------------
 records_id_idx      |                 97.64
 records_uuid_v4_idx |                 79.06
 records_uuid_v7_idx |                 90.09
(3 rows)
```

This shows the `integer` index had an average fill percentage of nearly 98%, while the UUID v4 index was around 79%.

## UUID Downsides: Worse cache hit ratio
The Postgres buffer cache is a critical part of good performance.

For good performance, we want our queries to produce cache "hits" as much as possible.

The buffer cache has limited space. Usually 25-40% of system memory is allocated to it, and the total database size including table and index data is usually much larger than that amount of memory. That means we'll have trade-offs, as all data will not fit into system memory. This is where the challenges come in!

When pages are accessed they're copied into the buffer cache as buffers. When write operations happen, buffers are dirtied before being flushed.[^string]

Since the UUIDs are randomly located, additional buffers will need to be copied to the cache compared to ordered integers. Buffers might be evicted to make space that are needed, decreasing hit rates.

## Mitigations: Rebuilding indexes with UUID values
Since the tables and indexes are more likely to be fragmented, it makes sense to rebuild the tables and indexes periodically.

Rebuilding tables can be done using pg_repack, pg_squeeze, or `VACUUM FULL` if you can afford to perform the operation offline.

Indexes can be rebuilt online using `REINDEX CONCURRENTLY`.

While the newly laid out data in pages, they will still not have correlation, and thus not be smaller. The space formerly occupied by deletes will be reclaimed for reuse though.

## Mitigation: Shared buffers and work_mem memory sizing
If possible, size your primary instance to have 4x the amount of memory of your size of database. In order words if your database is 25GB, try and run a 128GB memory instance.

This gives around 32GB to 50GB of memory for buffer cache (`shared_buffers`) which is hopefully enough to store all accessed pages and index entries.

Use *pg_buffercache*[^pgbc] to inspect the contents, and *pg_prewarm*[^pgpre] to populate tables into it.

One tactic I’ve used when working with UUID v4 random values where sorting is happening, is to provide more memory to sort operations.

To do that in Postgres, we can change the `work_mem` setting. This setting can be changed for the whole database, a session, or even for individual queries.

Check out [Configuring work_mem in Postgres](https://www.pgmustard.com/blog/work-mem) on PgMustard for an example of setting this in a session.

## Mitigation in Rails: UUID and implicit order column Active Record
Since Rails 6, we can control implicit_order_column.[^bb] The [database_consistency gem even has a checker](https://github.com/djezzzl/database_consistency/issues/197) for folks using UUID primary keys.

When ORDER BY is generated in queries implicitly, it may be worth ordering on a different high cardinality field that's indexed, like a `created_at` timestamp field.

## Mitigating poor performance by clustering on orderable field
Cluster on a column that's high cardinality and indexed could be a mitigation option.

For example, imagine your UUID primary table has a `created_at` timestamp column that's indexed with `idx_on_tbl_created_at`, and clustering on that.

```sql
CLUSTER table_with_uuid_ok USING idx_on_tbl_created_at;
```
I don't see CLUSTER used ever really though as it takes an [access exclusive](https://pglocks.org/?pgcommand=CLUSTER) lock. The CLUSTER is a one-time operation that would also need to be repeated regularly to maintain its benefits.

## Recommendation: Stick with sequences, integers, and big integers
For new databases that *may* be small, with unknown growth, I recommend plain old integers and an identity column (backed by a sequence)[^seq] for primary keys. These are signed 32 bit (4-byte) values. This provides about 2 billion positive unique values per table.

For many business apps, they will never reach 2 billion unique values per table, so this will be adequate for their entire life. I've also recommended always using bigint/int8 in other contexts.

I guess it comes down to what you know about your data size, how you can project growth. There are plenty of low growth business apps out there, in constrained industries, and constrained sets of business users.

For Internet-facing consumer apps with expected high growth, like social media, click tracking, sensor data, telemetry collection types of apps, or when migrating an existing medium or large database with 100s of millions or billions of rows, then it makes sense to start with `bigint` (int8), 64-bit, 8-byte integer primary keys.

## UUID v4 alternatives: Use time-ordered UUIDs like Version 7
Since Postgres 18 is not yet released, generating UUID V7s now in Postgres is possible using the `pg_uuidv7` extension.

If you have an existing UUID v4 filled database and can't afford a costly migration to another primary key data type, then starting to populate new values using UUID v7 will help somewhat.

Fortunately the binary `uuid` data type in Postgres can be used whether you're storing V4 or V7 UUID values.

Another alternative that relies on an extension is *sequential_uuids*.[^sequ]

## Summary
- UUID v4s increase latency for lookups, as they can't take advantage of fast ordered lookups in B-Tree indexes
- For new databases, don’t use `gen_random_uuid()` for primary key types, which generates random UUID v4 values
- UUIDs consume twice the space of `bigint`
- UUID v4 values are not meant to be secure per the UUID RFC
- UUID v4s are random. For good performance, the whole index must be in buffer cache for index scans, which is increasingly unlikely for bigger data.
- UUID v4s cause more page splits, which increase IO for writes with increased fragmentation, and increased size of WAL logs
- For non-guessable, obfuscated pseudo-random codes, we can generate those from integers, which could be an alternative to using UUIDs
- If you must use UUIDs, use time-orderable UUIDs like UUID v7

Do you see any errors or have any suggested improvements? Please [contact me](/contact). Thanks for reading!

## Learn More
- Franck Pachot for AWS Heroes has an interesting take on [UUID in PostgreSQL](https://dev.to/aws-heroes/uuid-in-postgresql-3n53)
- Brandur has a great post: [Identity Crisis: Sequence v. UUID as Primary Key](https://brandur.org/nanoglyphs/026-ids)
- 5mins of Postgres: [UUIDs vs Serial for Primary Keys - what's the right choice?](https://pganalyze.com/blog/5mins-postgres-uuid-vs-serial-primary-keys)
- [andyatkinson/pg_scripts PR #20](https://github.com/andyatkinson/pg_scripts/pull/20)

[^alpha]: <https://andyatkinson.com/generating-short-alphanumeric-public-id-postgres>
[^gen]: <https://www.postgresql.org/docs/current/functions-uuid.html>
[^rfc]: <https://datatracker.ietf.org/doc/html/rfc4122#section-4.4>
[^pgbc]: <https://www.postgresql.org/docs/current/pgbuffercache.html>
[^pgpre]: <https://www.postgresql.org/docs/current/pgprewarm.html>
[^ms]: <https://stackoverflow.com/a/6953207/126688>
[^hn]: <https://news.ycombinator.com/item?id=36429986>
[^wiki]: <https://en.wikipedia.org/wiki/Universally_unique_identifier>
[^ps]: <https://planetscale.com/blog/the-problem-with-using-a-uuid-primary-key-in-mysql>
[^string]: <https://stringintech.github.io/blog/p/postgresql-buffer-cache-a-practical-guide/>
[^seq]: <https://www.cybertec-postgresql.com/en/uuid-serial-or-identity-columns-for-postgresql-auto-generated-primary-keys/>
[^sequ]: <https://pgxn.org/dist/sequential_uuids>
[^bb]: <https://www.bigbinary.com/blog/rails-6-adds-implicit_order_column>
[^land]: <https://www.thenile.dev/blog/uuidv7>
[^pga5]: <https://pganalyze.com/blog/5mins-postgres-io-basics>
