---
layout: post
title: "PostgreSQL Savepoints"
tags: [PostgreSQL]
date: 2024-07-22
comments: true
---

This is a short post describing the basics of [savepoints](https://www.postgresql.org/docs/current/sql-savepoint.html) within a transaction. A transaction is used to form a non-separable unit of work to commit or not, as a unit. Transactions are opened using the `BEGIN` keyword, then either committed or may be rolled back using `ROLLBACK` without any arguments.

Within the concept of a transaction, there is a further concept that allows for incremental transaction-level persistence, called "savepoints," which create sub-transactions that have similar properties to a transaction.

Savepoints mark a particular state of the transaction as a recoverable position. In a similar way to how `ROLLBACK` rolls back an entire transaction, `ROLLBACK TO` can be used within a transaction, and with a savepoint name, to restore the state of the data to how it appeared when the savepoint was created.

## Commands
Savepoints have some verbs to know about:
- The keyword savepoint can be a noun or a verb. For example with a savepoint when a name is provided, `SAVEPOINT a` where a is the name, uses savepoint as a command verb to create a savepoint object (a noun).
- The savepoint name can be reused successively, creating a new savepoint with the same name, reflecting a new state of the data
- Savepoints can be rolled back to, using the `ROLLBACK TO` command with the savepoint name https://www.postgresql.org/docs/current/sql-rollback-to.html
- Savepoints can also be "released" which is a bit confusing, using the RELEASE command, as they don’t change the state of the data within the transaction like `ROLLBACK TO` does, but free up the savepoint name and release those resources.

<https://www.postgresql.org/docs/current/sql-release-savepoint.html>


```sql
BEGIN;

INSERT INTO vehicles (name) VALUES ('Toyota bZ4X');
SAVEPOINT a;

INSERT INTO vehicles (name) VALUES ('Honda Prologue');
SELECT COUNT(*) FROM vehicles; -- 2

ROLLBACK TO a; -- SELECT COUNT(*) FROM VEHICLES; -- is 1

COMMIT;
```

Savepoints can be created using an existing name. The docs point out how the SQL standard says savepoints with the same name must be deleted when they’re replaced.

This is a place where Postgres doesn’t fully confirm as they’re kept around.

However, the state of the data is not restored unless `ROLLBACK TO` is used. 

After rolling back to a savepoint, savepoints created after that one aren’t known to the current transaction.

A savepoint can be removed by using the `RELEASE` command.

When releasing savepoints, this isn’t walking backwards through the state of the data though, to do that use `ROLLBACK TO`.

## Errors
Multiple savepoints with the same name can be released successively, which removes them, but doesn’t restore the state of the data to when they were created. When releasing a savepoint and it does't exist, this produces an error.

When this kind of error happens, the outer transaction is in an error state, and can be rolled back, however calling `COMMIT` will also rollback the transaction.

## Rolling back data
To restore the state of the data, the `ROLLBACK TO` statement must be used.
