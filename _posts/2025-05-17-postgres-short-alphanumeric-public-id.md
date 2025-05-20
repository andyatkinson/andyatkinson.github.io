---
layout: post
permalink: /generating-short-alphanumeric-public-id-postgres
title: 'Short alphanumeric pseudo random identifiers in Postgres'
tags: [PostgreSQL]
date: 2025-05-20 16:00:00
---

## Introduction
In this post, we'll cover a way to generate short, alphanumeric, pseudo random identifiers using native Postgres tactics.

These identifiers can be used for things like transactions or reservations, where users need to read and share them easily. This approach is an alternative to using long, random generated values like [UUID](https://en.wikipedia.org/wiki/Universally_unique_identifier) values, which have downsides for usability and performance.

We'll call the identifier a `public_id` and store it in a column with that name. Here are some example values:
```sql
SELECT public_id
FROM transactions
ORDER BY random()
LIMIT 3;

 public_id
-----------
 0359Y
 08nAS
 096WV
```

## Natural and Surrogate Keys
In database design, we can use natural or surrogate keys to identify rows. We won't cover the differences here as that's out of scope.

For our `public_id` identifier, we're going to generate it from a conventional surrogate `integer` primary key called `id`. We aren't using natural keys here.

The `public_id` is intended for use outside the database, while the `id` `integer` primary key is used inside the database to be referenced by foreign key columns on other tables.

Whle `public_id` is short which minimizes space and speeds up access, the main reason for it is for usability.

With that said, the target for total space consumption was to be fewer bytes than a 16-byte UUID. This was achieved with an `integer` primary key and this additional 5 character generated value, targeting a smaller database where this provides plenty of unique values now and into the future.

Let's get into the design details.

## Design Properties
Here were the desired design properties:

- A fixed size, 5 characters in length, regardless of the size of the input integer (and within the range of the `integer` data type)
- Fewer bytes of space than a `uuid` data type
- An obfuscated value, pseudo random, not easily guessable. While not easily guessable, this is not meant to be "secure"
- Reversibility back into the original integer
- Only native Postgres capabilities, no extensions, client web app language can be anything as it's within Postgres
- Non math-heavy implementation

Additional details:
- `public_id` is stored using `text` not not `char(5)`, following recommendations for best practices
- PL/PgSQL functions, native Postgres data types and constraints are used, like UNIQUE, NOT NULL, and CHECK, and a stored generated column.
- Converts integers to bits, uses exclusive-or (XOR) bitwise operation and modulo operations.

## Limitations
- Did not set out to support case insensitivity now, possible future enhancement
- Did not try to exclude similar-looking characters (see: [Base32 Crockford](https://www.crockford.com/base32.html) below), possible future enhancement

## PL/PgSQL Functions
Here are the functions used:

This function obfuscates the integer value using exclusive or (XOR) obfuscation.
- Uses a Hexadecimal key `0x5A3C1` (make this any key you want)
- Sets a max value for the data type range `62^5`, which is just under 1 billion possible values. This was enough for this system and into the future, but a bigger system would want to use `bigint`
- Converts integer bytes into bits

Main entrypoint function:
- `obfuscate_id(id INTEGER)`

This converts the obfuscated value into the `public_id` alphanumeric value, used within `obfuscate_id()`.

This is "base 62" with the 26 upper and lower case characters, and 10 numbers (0-9).
- `to_base62_fixed(val BIGINT, width INT DEFAULT 5)`

Reverses the `public_id` back into the original integer.
- `deobfuscate_id(public_id TEXT)`

Used within `deobfuscate_id()`:
- `from_base62_fixed(str TEXT)`

For a length of 5 with this system, we can create up to around ~1 billion unique values. This was sufficiently large for the original use case.

For use cases requiring more values, by storing 6 characters for `public_id` then up to ~56 billion values could be generated, based on a `bigint` primary key.

## Table Design
Let's create a sample `transactions` table with an `integer` primary key with a generated identity column.

Besides the use in the identity column, we'll again use the `GENERATED` keyword to create a `STORED` column for the `public_id`.

The `public_id` column uses the `id` column as input, obfuscates it, encodes it to base 62, producing a 5 character value.
```sql
DROP TABLE IF EXISTS transactions;
CREATE TABLE transactions (
  id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,  -- 4-byte integer ID
  public_id text GENERATED ALWAYS AS (obfuscate_id(id)) STORED UNIQUE NOT NULL, -- 5-character obfuscated Base62 value
  amount NUMERIC,
  description TEXT
);
```

How do we guarantee `public_id` conforms to our expected data properties? Constraints!
- `public_id` gets a `UNIQUE` constraint and `NOT NULL`, so we know we have a unique value
- A `CHECK` constraint is added to validate the length

For an existing system, we could add a unique index `CONCURRENTLY` first as follows:
```sql
CREATE UNIQUE INDEX CONCURRENTLY IF NOT EXISTS idx_uniq_pub_id ON transactions (public_id);
```

Then we can add the unique constraint using the unique index, along with the `CHECK` constraint:
```sql
ALTER TABLE transactions
    ADD CONSTRAINT uniq_pub_id UNIQUE USING INDEX idx_uniq_pub_id, -- depends on index above
    ADD CONSTRAINT public_id_length CHECK (LENGTH(public_id) <= 5);
```

## Insert Data
Let's insert data into the `transactions` table:
```sql
INSERT INTO transactions (amount, description) VALUES
  (100.00, 'First transaction'),
  (50.00, 'Second transaction'),
  (0.25, 'Third transaction');
```

Let's query the data, and also make sure it's reversed (using the `deobfuscate_id(public_id TEXT)` function) properly:

## Access the rows
```sql
SELECT
    id,
    public_id,
    deobfuscate_id(public_id) AS reversed_id,
    description
FROM
    transactions;


 id | public_id | reversed_id |    description
----+-----------+-------------+--------------------
  1 | 01Y9I     |           1 | First transaction
  2 | 01Y9L     |           2 | Second transaction
  3 | 01Y9K     |           3 | Third transaction
```

## Additional time spent on inserts
Let's compare the time spent inserting 1 million rows into an equivalent `transactions` table without the `public_id` column or value generation.

That took an average of 2037.906 milliseconds, or around 2 seconds on my machine.

Inserting 1 million rows with the `public_id` took an average of 6954.070 or around 7 seconds, or about 3.41x slower. Note that these times were with the indexes and constraints in place on the `transactions` table in the second example, but not the first, meaning their presence contributed to the total time.

Summary: Creating this identifier made the write operations 3.4x slower for me locally, which was an acceptable amount of overhead for the intended use case.

## Performance
Compared with random values, the pseudo random `public_id` remains orderable, which means that lookups for individual rows or ranges of rows can use indexes, running fast and reliably even as row counts grow.

We can add a unique index on the `public_id` column like this:
```sql
CREATE UNIQUE INDEX CONCURRENTLY
IF NOT EXISTS
idx_uniq_pub_id ON transactions (public_id);
```

We can very that individual lookups or range scans use this index, by inspecting query execution plans for this table.

## PL/pgSQL Source Code
<https://github.com/andyatkinson/pg_scripts/pull/15>

## Feedback
Feedback on this approach is welcomed! Please use my contact form to provide feedback or leave comments on the PR.

Future enhancements to this could include unit tests using [pgTAP](https://pgtap.org) for the functions, packaging them into an extension, or supporting more features like case insensitivity or a modified input alphabet.

Thanks for reading!

## Alternatives
- [Base32 Crockford](https://www.crockford.com/base32.html) - An emphasis ease of use for humans: removing similar looking characters, case insensitivity.
- [ULID](https://blog.lawrencejones.dev/ulid/) - Also 128 bits/8 bytes like UUIDs, so I had ruled these out for space consumption, and they're slightly less "usable"
- [NanoIDs at PlanetScale](https://planetscale.com/blog/why-we-chose-nanoids-for-planetscales-api) - I like aspects of NanoID. This is random generation though like UUID vs. encoding a unique integer.
