---
layout: post
title: "You make a good point! — PostgreSQL Savepoints"
tags: [PostgreSQL]
date: 2024-07-22
comments: true
---

This post will look at the basics of PostgreSQL [Savepoints](https://www.postgresql.org/docs/current/sql-savepoint.html) within a Transaction.

A transaction is used to form a non-separable unit of work to commit or not, as a unit. Transactions are opened using the `BEGIN` keyword, then either committed or may be rolled back. Use `ROLLBACK` without any arguments to do that.

## Dividing Up a Transaction
Within the concept of a transaction, there is a smaller unit that allows for incremental persistence, scoped to the transaction, called "savepoints." Savepoints create sub-transactions with some similar properties to a transaction.

## Savepoints
Savepoints mark a particular state of the transaction as a recoverable position. In a similar way to how `ROLLBACK` rolls back an entire transaction, `ROLLBACK TO <savepoint-name>` captures a position within the transaction that the state of the data can be restored to.

After restoring to a savepoint, querying the data will show its state at the time the savepoint was created.

## Commands
Savepoints have verbs to know about:
- "Savepoint" may be used as a noun or verb depending on the context. Running the command `SAVEPOINT a` where a is the name of the savepoint, uses "savepoint" as a command verb that creates savepoint "a". The savepoint "a" (a noun) was created.
- The savepoint name can be reused, creating a new savepoint with the same name, reflecting a new state of the data.
- Savepoints can be rolled back to, using the `ROLLBACK TO <savepoint-name>` command, specifying a named savepoint <https://www.postgresql.org/docs/current/sql-rollback-to.html>
- Savepoints can be "released" by using the `RELEASE` command. Releasing a savepoint does not change the state of the data though, which is what `ROLLBACK TO` may do. Releasing a savepoint frees up the savepoint name and releases the resources used to create the samepoint. Read more: <https://www.postgresql.org/docs/current/sql-release-savepoint.html>


Let's look at SQL commands for creating and rolling back to a savepoint:
```sql
BEGIN;

INSERT INTO vehicles (name) VALUES ('Toyota bZ4X');
SAVEPOINT a;

INSERT INTO vehicles (name) VALUES ('Honda Prologue');
SELECT COUNT(*) FROM vehicles; -- 2

ROLLBACK TO a; -- SELECT COUNT(*) FROM VEHICLES; -- is 1

COMMIT; -- Only one vehicle was saved
```

A savepoint can be removed by using the `RELEASE` command.

Here's an example of creating and releasing a savepoint:
```sql
BEGIN;

INSERT INTO vehicles (name) VALUES ('Toyota bZ4X');

SAVEPOINT a;

RELEASE a;

COMMIT; -- Only one vehicle was saved
```

In the example above, a savepoint was created and then released, not impacting the state of the data.

## Reusing Savepoints
Savepoints names can be reused. The docs describe how the SQL standard says savepoints with the same name must be deleted when they’re replaced.

This is a place where Postgres doesn’t fully conform to the SQL standard, since it says in PostgreSQL savepoints are kept around.

When savepoints are created, the state of data within the transaction is saved "just before" at the moment of creation. This can be recovered by restored to the savepoint using the `ROLLBACK TO` command.

When rolling back to a savepoint, savepoints created later in the transaction are no longer "known."

## Errors
When multiple savepoints are created using the same name, for example three times, they can also each be released as many times as there are savepoints.

Imagine three were created with the name "a". In that case, release can be called three times for "a", but on the fourth time it will produce an error.

When this kind of error happens, the outer transaction is now also in an error state. From there the outer transaction may be rolled back. In that error state, calling `COMMIT` also rolls back the transaction.

```sql
BEGIN;

SAVEPOINT a;
SAVEPOINT a;
SAVEPOINT a;

RELEASE a;
RELEASE a;
RELEASE a;
RELEASE a; -- ERROR:  savepoint "a" does not exist
```

## Wrap Up
That was a brief intro to savepoints inside transactions. Remember that savepoints are a mechanism to create "recoverable positions" for a state of transaction-level data, within a transaction.
