---
layout: post
title: "A Look at PostgreSQL Foreign Key Constraints"
date: 2018-08-22
comments: true
tags: [Databases, SQL, PostgreSQL]
---

This post will focus on Foreign Key constraints.

Foreign Key constraints describe a data relationship and can be used to prevent half of the relationship from being deleted.

Constraints can belong to a table or a column. Run `\dt <tablename>` from psql to browse `Foreign-key constraints` (look for `REFERENCES`) for the table. Take note of which fields they cover.

Constraints are not deferrable by default. A use case for deferring constraint enforcement seems to be when multiple statements are issued in a transaction, when a statement would violate a constraint when enforced immediately, it can be made to only be enforced instead at the end of a transaction.

In order for a constraint to be deferrable per transaction they must have been defined using `DEFERRABLE INITIALLY IMMEDIATE`.

Alternatively they can be made to be deferred by default with `INITIALLY DEFERRABLE`.

## Using `SET CONSTRAINTS`

> SET CONSTRAINTS sets the behavior of constraint checking within the current transaction.

Per [SET CONSTRAINTS](https://www.postgresql.org/docs/current/sql-set-constraints.html), IMMEDIATE constraints are checked after each statement while deferred constraints are not checked until the transaction commits.

This excellent [Hashrocket blog post on deferring constraints](https://hashrocket.com/blog/posts/deferring-database-constraints) covers an example list where each list item has a unique position.

When re-ordering list items, in each re-ordering, two list items would temporarily have the same position value as they are shuffled around.

This would not be allowed normally because it would violate the uniqueness constraint on the position.

How did they work around this?

## Deferring Constraint Enforcement

The solution was to defer the enforcement of the unique constraint until the end of the transaction. This way each list item will have a unique position value by that time.

If a constraint is deferrable, it can have 3 classes (attributes of the constraint). The class of deferred constraint in the project I'm working on used `DEFERRABLE INITIALLY DEFERRED` which prompted this investigation.

Specifying deferrable this way would be more surprising than `INITIALLY IMMEDIATE` which is the default constraint behavior. For that reason, INITIALLY IMMEDIATE makes more sense as a default.

This allows enabling deferral of constraint enforcement as needed but otherwise uses the default behavior.

This was the recommendation from the Hashrocket article as well.

## Considering ON DELETE and ON UPDATE

Another attribute to specify on Foreign Key constraints is how to handle deletes or updates on referenced data.

For example, `ON DELETE RESTRICT` restricts deleting a product that an order item references.

`NO ACTION` is the default behavior when nothing is specified. `NO ACTION` allows the check to be deferred until later in the transaction.

However, specifying `RESTRICT` as an initial setting makes sense to me as a safeguard from deleting rows unintentionally.

In the event, the cascade delete is desired, the constraint could be modified later.

## Summary

* Foreign Key constraints describe and enforce data relationships
* Enforcement of constraints can be configured, being applied per statement if needed
* Constraint enforcement can be deferred until the transaction commits
* Deletes or updates on referenced tables can be propagated or restricted

Thanks!
