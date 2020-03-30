---
layout: post
title: "A Look at PostgreSQL Foreign Key Constraints"
date: 2018-08-22
comments: true
tags: [Databases, SQL, PostgreSQL]
---

Foreign key constraints enforce that a referenced "thing" exists.

Constraints can be browsed for a table (e.g. with `\dt table`) under `Foreign-key constraints` with a `REFERENCES`, indicating the table and referenced table. They can also show up at the column-level when the referenced table has a primary key.

Constraints are not deferrable by default. From my investigation, the main use case for deferring constraint enforcement seems to be when using transactions. Constraints can be set as deferrable per transaction as long as the deferrable attribute was originally specified, i.e. `deferrable initially immediate`, or they can always be deferred with `INITIALLY DEFERRABLE`.

A foreign key constraint may be altered later with [ALTER CONSTRAINT](https://www.postgresql.org/docs/9.4/static/sql-altertable.html) although to change this behavior with other constraints, I believe the constraint would need to be removed and then added again with the deferrable attribute set.

#### SET CONSTRAINTS

> SET CONSTRAINTS sets the behavior of constraint checking within the current transaction.

According to the [SET CONSTRAINTS docs](https://www.postgresql.org/docs/9.1/static/sql-set-constraints.html), IMMEDIATE constraints are checked after each statement while deferred constraints are not checked until the transaction commits.

For example, within one transaction, there may be be multiple `INSERT` statements. Constraints like uniqueness may be enforced after every statement or deferred until the end of the statements when the transaction will be committed.

*Why would the difference be significant?*

This excellent [Hashrocket blog post on deferring constraints](https://hashrocket.com/blog/posts/deferring-database-constraints) goes in depth into an example with a list where each list item has a unique position.

To briefly summarize the article, when re-ordering a list of items where each re-order generates an update statement per list item within a transaction, two list items would have the same position value. This would break because it would violate the uniqueness constraint. The solution was to defer enforcement of the unique constraint until the end of the transaction where each list item has a new position value.

If a constraint is deferrable, it can have 3 classes (attributes of the constraint). The class of deferred constraint in the project I'm working on used `DEFERRABLE INITIALLY DEFERRED` which prompted this investigation. I found this is not the default behavior.

Specifying deferrable this way would be more surprising than `INITIALLY IMMEDIATE` which is the default constraint behavior. For that reason, INITIALLY IMMEDIATE makes more sense as a default. This allows opting in to the deferrable constraint enforcement on a per transaction basis, but otherwise preserves the default behavior. This was the recommendation from the Hashrocket article as well.

#### ON DELETE and ON UPDATE

Another attribute to specify on foreign key constraints is how to handle when deletes or updates happen on referenced data. The [PostgreSQL constraints documentation](https://www.postgresql.org/docs/9.5/static/ddl-constraints.html) has an example with products, orders, and order items that is helpful.

For example, `ON DELETE RESTRICT` restricts deleting a product that an order item references.

`NO ACTION` is the default behavior when no nothing is specified. `NO ACTION` allows the check to be deferred until later in the transaction. However, specifying `RESTRICT` as an initial setting makes sense to me, as a safeguard from deleting rows unintentionally.

In the event, the cascade delete is desired, the constraint could be modified later.


#### Summary

 * Foreign key constraints ensure data in a referenced table exists
 * Enforcement of constraints can be applied per statement in a batch of statements within a transaction, or deferred until the transaction commits
 * Deletes or updates on referenced tables can be propagated or restricted

