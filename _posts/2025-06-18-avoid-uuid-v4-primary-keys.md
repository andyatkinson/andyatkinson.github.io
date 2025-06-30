---
layout: post
permalink: /constraint-driven-optimized-responsive-efficient-core-db-design
title: Avoid UUID Version 4 Primary Keys
---

## Introduction
Over the last decade, I've worked on databases where UUID Version 4[^rfc] was picked as the primary key data type, and these databases usually have had performance problems and excessive IO.

UUID is a native data type that can be stored as binary data, with various versions outlined in the RFC. Version 4 is usually picked because it's mostly made up of random bits, obfuscating information like when the value was created, or where it was generated.

Version 4 UUIDs are easy to work with in Postgres as the `gen_random_uuid()`[^gen] function generates values natively since version 13 (2020).

I've learned there are misconceptions about UUID Version 4, and sometimes the reasons users pick this data type is based on them.

Because of the poor performance, misconception, and available alternatives we'll look at later, I’ve come around to this position: Avoid UUID Version 4 for primary keys.

Let's dig in.

## The scope of UUIDs in this post
UUID (Univerisally Unique Identifier) can mean a lot of different things, so we'll define the scope here.
- UUIDs (or GUID in Microsoft speak)[^ms]) and long strings of 36 characters, 32 digits, 4 hyphens, stored as 128 bits (16 byte) values
- The RFC documents how the bits are set
- The bits for UUID Version 4 are mostly random values
- UUID Version 7 is newer and we'll discuss that.

UUID V7 is essentially the replacement, unless there are very strong reasons against it. V7 includes a portion of the bits that represent a timestamp, which makes multiple UUID V7 values comparable and sortable, solving most of the performance problems discussed in this post.

There are other versions below 4 and above 7, but versions 4 and 7 are discussed here.

## Scope of web app usage and and scale
The kinds of web applications I’ve worked on are monolithic web apps, with Postgres as their primary OLTP database, in categories like social media, e-commerce, click tracking, or general business process apps.

The type of performance issues here are related to inefficient storage and retrieval, meaning they occur regardless of the type of app.

## Randomness is the issue
The core issue is that among the 128 bits for UUID Version 4, 122 are "random or pseudo-randomly generated values."[^rfc]

Random values don’t have natural sorting like integers do, or lexicographic (dictionary) sorting like character strings.

UUID v4s are ordered by "byte ordering," which has no semantic meaning for their use.

Why pick them?

## Why choose UUIDs at all? Generating values from one or more client applications
One use case is generating the UUID on a client or from multiple applications or services. The client generates a UUID value and passes it to the server, which passes it to Postgres to store. Postgres does not generate it.

For web apps though, they generally instantiate objects in memory and get a database-generated id when they're persisted. They don't need a DB id before that usually.

I also tend to work with monolithic apps that have a single application database.

However, in a microservices architectures where the apps have their own databases, the ability to generate UUIDs across all the databases and not have to worry about collisions is legitimate. It would also make it possible to identify which database a value came from.

We can’t easily or practically make the collision avoidance guarantee (see HN discussion[^hn]) with sequence-backed integers. There are hacks, like generating even and odd integers between two instances, or using different ranges in the int8 range.

The avoidance of collisions is described this way on Wikipedia:[^wiki]

> The number of random version-4 UUIDs which need to be generated in order to have a 50% probability of one collision: 2.71 quintillion

This number would be equivalent to:

> Generating 1 billion UUIDs per second for about 86 years.

Why else might a team choose UUID V4?

## Reason for UUID: Hiding positional generation information
One reason cited for random UUID v4 is that it reveals no information about when it was generated.

While it's true that integers generated from the same system can be compared, and their generation time can be deduced, I haven't seen how this has significantly negatively impacted an organization.

Please get in touch if you can explain that one!

Besides, integers could still be used internally, and either UUIDs could be used externally, or an obfuscated code from an integer could be generated and used.

I prefer the latter approach, so we'll look at one approach for that later on.

## Misconceptions: UUIDs are for security
One misconception about UUIDs is that they're meant to be secure. However, the RFC describes that they shouldn't be considered secure "capabilities."

From RFC 4122[^rfc] Section 6 Security Considerations:
> Do not assume that UUIDs are hard to guess; they should not be used
>   as security capabilities

How can we create obfuscated codes based on integers?

## Creating obfuscated values using integers
While UUID V4s obfuscate their creation time and can't be meaningfully sorted to deduce their relative creation time, we can achieve those same properties by starting from integers.

By using a traditional integer internally, but by generating a pseudo-random code from it, we can use the code externally.

I have written up a post separately that covers how to do this, along with SQL and functions.

We'll summarize it here.

We can use this algorithm:
- Convert a decimal integer like "2" into binary bits. E.g. a 4 byte, 32 bit integer: 00000000 00000000 00000000 00000010
- Perform an exclusive OR (XOR) operation on all the bits using a key
- Encode each bit using a base62 alphabet

To store the obfuscated id, I used a generated column. By reviewing the generated values, they are similar, but aren't alphabetically (lexicographically) orderable consistent with their creation order.

For example the values in insertion order were `01Y9I`, `01Y9L`, then `01Y9K`.

If they followed alphabetical ordering we'd expect the last two to be flipped: `01Y9I` first, then `01Y9K` second, then `01Y9L` third, sorting on the fifth character.

To see the full details of this solution, please check out: *Short alphanumeric pseudo random identifiers in Postgres*[^alpha]

If I wanted to use this approach for all tables, I’d consider a centralized table that was polymorphic, storing a record for each external type generated that's using a code.

That way I'd know which type the code belongs to.

Why else might we want to skip UUIDs?

## Reasons against UUIDs in general: they consume a lot of space
UUIDs are 16 bytes (128 bits) per value, which is double the space of bigint (8 bytes), or quadruple the space of 4-byte integers. This extra space adds up once many tables have millions of rows, and copies of a database are being moved around as backups and restores.

A more considerable downside than space consumption, is poor index performance. How does that work?

## Reasons against: UUID v4s add insert latency due to index page splits, fragmentation
For UUID v4s, due to their randomness, Postgres incurs more latency for every insert operation.

For integer primary key rows, their values are maintained in index pages with "append-mostly" operations on "leaf nodes," since their values are orderable, and since B-Tree indexes store entries in sorted order.

For UUID v4s, primary key values in B-Tree indexes are problematic.

Inserts are not appended to the right most leaf page. They are placed into a random page, and that could be mid-page or a already-full page, causing a page split that would have been unnecessary with an integer.

Planet Scale has a nice visualization of index page splits and rebalancing.[^ps]

Unnecessary splits and rebalancing add space consumption and processing latency to write operations.

Later on we will use the *pageinspect* extension to check the average leaf density between integer and UUID.

## Excessive IO for lookups even with orderable UUIDs
B-Tree page layout means you can fit fewer UUIDs per 8KB page. Since we have the limitation of fixed page sizes, we at least want them to be densely packed as possible.

Since UUID indexes are ~40% larger in leaf pages than bigint (int8) for the same logical number of rows, they can’t be as densely packed with values.

This means that for individual lookups, range scans, or UPDATES, we will incur ~40% more I/O on UUID indexes, as more pages are scanned. Remember that even to access one row, in Postgres the whole page is accessed where the row is, and copied into a shared memory buffer.

Let’s insert and query data and take a look at numbers between these data types.

## Working with integers, UUID v4, and UUID v7
Let’s create integer, UUID v4, and UUID v7 fields, index them, load them into the buffer cache with *pg_prewarm*.

I will riff use the schema examples from the Cybertec post [Unexpected downsides of UUID keys in PostgreSQL](https://www.cybertec-postgresql.com/en/unexpected-downsides-of-uuid-keys-in-postgresql/) by Ants Aasma.

To get this working on my Mac, I compiled the `pg_uuidv7` extension. Once compiled and enabled for Postgres, I could use the extension functions to generate UUID V7 values.

Another extension `pg_prewarm` is used, but this is a module included with Postgres. It only needs to be enabled per database where it's used.

After running this, my local SSD storage seemed faster on my M1 Macbook Pro compared with the original example. However, the difference in latency and the enormous difference in buffers the post outlines between the integer and UUID fields was reproduced in my testing!

> "Holy behemoth buffer count batman"
<small>- Ants Aasma</small>

Cybertec post results:
- 27,332 buffer hits, index only scan on the `bigint` column
- 8,562,960 buffer hits, index only scan on the UUID V4 index scan

That's 8,535,628 (8 million!) more 8KB pages for the UUID version compared with the bigint version. In terms of MB and MB/s that is:
- 68,285,024 MB or ~68.3 GB! more data being accessed

Since these are buffer *hits*, we're accessing them from memory, meaning that access is much faster than disk. Still, how much latency is that adding?

AI helped me come up with some example Memory Bandwidth (GB/s) figures:
- DDR4-3200 (2–4 channels)
- Speed of 20–50 GB/s

Calculating a low and high estimate based on those speeds:
- Low (conservative): 20 GB/s
- High (aggressive): 80 GB/s

Accessing 68.3 GB of data from memory (`shared_buffers` in PostgreSQL) would add:
- ~3.4 seconds of latency on the low end
- ~0.86 seconds of latency on the high end

That's between nearly 1 and ~3.4 seconds of additional latency, solely because of the data type, and something that will get worse as data size and fragmentation increases.

Also, this was for 10 million rows and 1 million updates, but what if we were working with 100 million or 1 billion rows?

## Inspecting density with the pageinspect extension
We can inspect density of leaf pages using the pageinspect extension.

The query gets the indexes for the integer and v4 and v7 uuid columns, their total page counts, their page stats, and the number of leaf pages.

Using the leaf pages, the query calculates an average fill percentage.

After performing the 1 million updates, I got these results:
```sql
--  idxname       | avg_leaf_fill_percent
-- ---------------------+-----------------------
--  records_id_idx      |                 97.64
--  records_uuid_v4_idx |                 79.06
--  records_uuid_v7_idx |                 90.09
-- (3 rows)
```

This shows the integer index had a average fill percentage of nearly 98%, while the UUID v4 as around 79%.

## Loss of locality for caching
The Postgres buffer cache supports "temporal locality," the idea that pages that are recently accessed are likely to be accessed again.

For good performance, we want our queries to result in cache "hits" as much as possible. The buffer cache is limited, usually 25-40% of system memory, while the total database size including table data and index data is usually larger than the available buffer cache memory. That means we'll have trade-offs, and not everything will fit.

When pages are accessed they're copied into buffer cache as buffers. When write operations happen, buffers are dirtied before being flushed.[^string]

For UUIDs, when pages are accessed to try and find the target rows or row, pages are copied to the buffer cache regardless of whether they contain the row.

Since the UUIDs are randomly located, additional buffers will need to be copied to the cache, and needed buffers could be evicted. This uses up limited shared buffer cache, and additional cache misses increase latency.

## UUID fragmentation mitigation
Since the tables and indexes are more likely to be fragmented, it makes sense to rebuild the tables and indexes periodically.

Rebuilding tables can be done using pg_repack, pg_squeeze, or `VACUUM FULL` if you can afford to perform the operation offline.

Indexes can be rebuilt online using `REINDEX CONCURRENTLY`.

While the newly laid out data in pages, they will still not have correlation, and thus not be smaller. The space formerly occupied by deletes will be reclaimed for reuse though.

## Mitigation
If possible, size your primary instance to have 4x the amount of memory of your size of database. In order words if your database is 25GB, try and run a 128GB memory instance.

This gives you something liek 32GB to 50GB of memory for buffer cache (`shared_buffers`) which is hopefully enough to store all accessed pages and index entries.

Use pg_buffercache[^pgbc] to inspect the contents, and pg_prewarm[^pgpre] to populate key relations into the buffer cache.

## Mitigation in Rails: UUID and implicit order column Active Record
Since Rails 6, we can control implicit_order_column.[^bb] The [database_consistency gem even has a checker](https://github.com/djezzzl/database_consistency/issues/197) for folks using UUID primary keys that might want to check their models are setting this.

## Mitigating poor performance by clustering on orderable field
Cluster on an indexed orderable column. For example in Active Record with UUID v4 primary keys, index the `created_at` column, and cluster on that.

That will reorder pages for better spatial locality for scans.
```sql
CLUSTER your_table USING your_index;
```
## Sticking with sequences, integers, and big integers
For new databases that *may* be small, with unknown growth, I recommend plain old integers and an identity column (backed by a sequence)[^seq] for primary keys. These are signed 32 bit (4-byte) values. This provides about 2 billion positive unique values per table. For many business apps, they will never reach 2 billion unique values per table, so this will be adequate for their entire life.

For Internet-facing consumer apps with expected high growth, like social media, click tracking, sensor data, telemetry collection types of apps, or when migrating an existing medium or large database with 100s of millions or billions of rows, then it makes sense to start with `bigint` (int8), 64-bit, 8-byte integer primary keys.

## Mitigations: Adding memory for UUID v4 sorting
One tactic I’ve used when working with UUID v4 random values where sorting is happening, is to provide more memory to sort operations.

To do that in Postgres, we can change the `work_mem` setting. This setting can be change database wide, at the session level, or even for individual queries.

## UUID v4 alternatives: Use V7
As of this writing, one option to generate UUID V7s in Postgres is to use the `pg_uuidv7` extension. In Postgres 18 scheduled for released in Fall 2025, UUID v7 values can be generated natively without extensions.

If you have an existing UUID v4 filled database and can't afford a costly migration to another primary key data type, then starting to populate new values using UUID v7 will help somewhat.

Fortunately the binary `uuid` data type in Postgres can be used whether you're storing V4 or V7 UUID values.

Another alternative that relies on an extension is *sequential_uuids*.[^sequ]

## Closing Thoughts
- For new databases, don’t use `gen_random_uuid()` for primary key types, which generates UUID v4 that are unfriendly for performance due to being random
- UUIDs take twice the space of bigints
- UUID v4 values are not meant to be secure despite their randomness, per the UUID RFC spec.
- UUID v4s are random, which means the whole index must be in buffer cache to get index scans
- For non-guessable, obfuscated pseudo-random codes, we can generate those from integers, which could be an alternative to using UUIDs.

Do you see any errors or have any suggested improvements? Please [contact me](/contact). Thanks for reading!

## More
- Franck Pachot for AWS Heroes has an interesting take on [UUID in PostgreSQL](https://dev.to/aws-heroes/uuid-in-postgresql-3n53)
- Brandur has a great post: [Identity Crisis: Sequence v. UUID as Primary Key](https://brandur.org/nanoglyphs/026-ids)

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
