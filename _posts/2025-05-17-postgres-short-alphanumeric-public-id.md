---
layout: post
permalink: /generating-short-alphanumeric-public-id-postgres
title: 'Short alphanumeric pseudorandom identifiers in Postgres'
comments: true
hidden: true
---

## Introduction
In this post, we'll cover a way to generate short, alphanumeric, pseudorandom identifiers using native Postgres tactics.

Here are three example values:
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

This type of identifier could be used in a variety of ways. For example, identifying transactions or reservations in a system, where having short identifiers helps users read and share them.

In database design, we have natural keys and surrogate keys as options to identify our rows.

Here we're using a surrogate `integer` type key, we'll call it `id`. Our identifier called `public_id` is then generated based on the `id` primary key, for display in an app. For that reason we'll store it as `text`.

The `public_id` is meant to be short both to minimize space consumption and speed up data access, but more for ease of use in reading and sharing the value by users.

## Design Properties
Here are other properties that are part of the design:

- A fixed size, 5 characters in length, regardless of the size of the input integer (and within the range of the `integer` data type)
- An obfuscated value, pseudorandom, not easily guessable. While not easily guessable, this is not meant to be "secure."
- Reversability back into the original integer
- Only native Postgres capabilities, no extensions, client web app language can be anything as it's within Postgres.
- Non math-heavy implementation.

Additional details:
- `public_id` is stored using `text` not not `char(5)`, following recommendations for best practices
- PL/PgSQL functions, native Postgres data types and constraints are used, like UNIQUE, NOT NULL, and CHECK, and a stored generated column.
- Converts integers to bits, uses exclusive-or (XOR) bitwise operation and modulo operations.

## PL/PgSQL Functions
Here are the functions used:

This function obfuscates the integer value using exclusive or (XOR) obfuscation.
- Uses a Hexadecimal key `0x5A3C1`
- Sets a max value for the data type range `62^5`, just under 1 billion values
- Converts integer bytes into bits
- `obfuscate_id(id INTEGER)`

This converts the obfuscated value into the `public_id` alphanumeric value, used within `obfuscate_id()`.
- `to_base62_fixed(val BIGINT, width INT DEFAULT 5)`

Reverses the `public_id` code back into the original integer.
- `deobfuscate_id(public_id CHAR(5))`

Used within `deobfuscate_id()`:
- `from_base62_fixed(str TEXT)`

For a length of 5 with this system, we can create up to around ~1 billion unique values. This was sufficiently large for the original use case.

For use cases requiring more values, by storing 6 characters for `public_id` then up to ~56 billion values could be generated.



## Table Design
Let's create a sample `transactions` table with an `integer` primary key with a generated identity column.

Besides the identity column, we'll use the `GENERATED` keyword again for a `STORED` column called `public_id` that stores the value.

The `public_id` column takes the `id` column as input, and obfuscates it and converts it to a 5 character alphanumeric value.
```sql
DROP TABLE IF EXISTS transactions;
CREATE TABLE transactions (
  id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,  -- 4-byte integer ID
  public_id text GENERATED ALWAYS AS (obfuscate_id(id)) STORED UNIQUE NOT NULL, -- 5-character obfuscated Base62 value
  amount NUMERIC,
  description TEXT
);
```

How do we ensure that the input value is conforming?

- `public_id` gets a `UNIQUE` constraint and `NOT NULL`, so we know we have a unique value
- A `CHECK` constraint is added to validate the length

```sql
ALTER TABLE transactions
    ADD CONSTRAINT public_id_length CHECK (LENGTH(public_id) <= 5);
```

## Insert Data
Insert some data into `transactions`:
```sql
INSERT INTO transactions (amount, description) VALUES
  (100.00, 'First transaction'),
  (50.00, 'Second transaction'),
  (0.25, 'Third transaction');
```

Let's query the data, and also make sure it's reversed properly:

## Access the rows
```sql
SELECT id, public_id, deobfuscate_id(public_id) AS reversed_id, description
FROM transactions;

 id | public_id | reversed_id |    description
----+-----------+-------------+--------------------
  1 | 01Y9I     |           1 | First transaction
  2 | 01Y9L     |           2 | Second transaction
  3 | 01Y9K     |           3 | Third transaction
```

## Additional time spent on inserts
Let's compare the time spent inserting 1 million rows into an equivalent `transactions` table without the `public_id` column or value generation.

That took average of 2037.906 milliseconds, or around 2 seconds on my machine.

Inserting 1 million rows with the `public_id` took an average of 6954.070 or around 7 seconds, or about 3.41x slower. Note that these times were with the indexes and constraints in place on the `transactions` table.

## Performance
Compared with random values, the pseudorandom `public_id` remains orderable, which means that lookups for individual rows or ranges of rows can use the index and run fast and reliably even as the row count grows.


## Source Code
<https://github.com/andyatkinson/pg_scripts/pull/15>
