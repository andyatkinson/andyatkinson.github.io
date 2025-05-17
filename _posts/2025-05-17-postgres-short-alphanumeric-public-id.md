---
layout: post
permalink: /generating-short-alphanumeric-public-id-postgres
title: 'Short alphanumeric public ids in Postgres'
comments: true
---

In this post, we'll cover a way to generate row identifiers beyond the traditional methods like integers or UUIDs.

This type of identifier could be used in a variety of places. A couple of examples would be for financial transactions or reservation booking systems.

In database design, we have natural keys and surrogate keys. Here we're using a surrogate `integer` type key, we'll call it `id`.

The `public_id` is a alphanumeric "code" generated from the surrogate `id` primary key.

The `public_id` is meant to be short for technical reasons, and to make it easier for humans to read and share.

Here are some other properties that are part of the design:

- The `public_id` has a fixed size, it's always 5 characters in length here, regardless of the size of the integer it's based on (within the size range limits of the `integer` data type)
- `public_id` is stored using `text` not not `char(5)`, following recommendations for best practices
- The generated value is obfuscated, not an incremented value, meaning it's not "easily" guessable. While not easily guessable, this is not meant to be a "secure" value.
- The `public_id` value can be reversed into the original integer value
- The system is encapsulated in Postgres, and doesn't require extensions. PL/PgSQL functions, native Postgres data types and constraints are used, like UNIQUE, NOT NULL, and CHECK, and a stored generated column.
- The implementation is not math-heavy. It does use work with bits and exclusive-or (XOR) bit inversion.

Here are the functions used:

This converts the integer into the public_id alphanumeric value.
- `to_base62_fixed(val BIGINT, width INT DEFAULT 5)`

This reverses the `public_id` code back into the original integer.
- `from_base62_fixed(str TEXT)`

This is used internally within `to_base62_fixed()` to obfuscate the value.
- `obfuscate_id(id INTEGER)`

This is used within `from_base62_fixed` to reverse the obfuscation.
- `deobfuscate_id(public_id CHAR(5))`

For a length of 5 with this system, we can create up to around ~1 billion unique values. This was sufficiently large for the original use case.

For use cases that need more unique values, 6 characters of length can do up to ~56 billion values.

https://github.com/andyatkinson/pg_scripts/pull/15


## Table Design
Let's create a sample `transactions` table with an `integer` primary key with a generated identity column.

Besides the identity column, we'll use the `GENERATED` keyword again for a `STORED` column called `public_id` that stores the value.

The `public_id` column takes the `id` column as input, and obfuscates it and converts it to a 5 character alphanumeric value.
```sql
DROP TABLE IF EXISTS transactions;
CREATE TABLE transactions (
  id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,  -- 4-byte integer ID
  public_id text GENERATED ALWAYS AS (obfuscate_id(id)) STORED UNIQUE NOT NULL, -- 5-character Base62 public ID, obfuscated
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

Insert some data into `transactions`:
```sql
INSERT INTO transactions (amount, description) VALUES
  (100.00, 'First transaction'),
  (50.00, 'Second transaction'),
  (0.25, 'Third transaction');
```

Let's query the data, and also make sure it's reversed properly:

```sql
SELECT id, public_id, deobfuscate_id(public_id) AS reversed_id, description
FROM transactions;
--  id | public_id | reversed_id |    description
-- ----+-----------+-------------+--------------------
--   1 | 01Y9I     |           1 | First transaction
--   2 | 01Y9L     |           2 | Second transaction
--   3 | 01Y9K     |           3 | Third transaction
```



