---
layout: post
title: "Manually Fixing a Rails Migration"
tags: [PostgreSQL, Rails, Databases, Tips]
date: 2021-08-30
comments: true
---

This tip is a recipe for how to recover from a Rails migration that failed to apply in production. This process could work for any SQL migration. The example below is for an index added to a table.

This is also more of a symptom than an underlying problem.

## Manually Add the Schema Version
Figure out the schema version. The version is the numeric part of the filename, for example in `20211121190924_create_index.rb` it would be `20211121190924`. This version will exist in the schema migrations table where it was applied earlier in pre-production as well.

Since we're going to manually create the migration, we will insert the version manually so that on future deploys it does not attempt to run again and appears as if it had been applied normally.

```sql
INSERT INTO schema_migrations (version) VALUES (20211121190924);
```

## For Active Record migrations, translate them to SQL
Let's use an example of adding an index. We occasionally have issues where the index create even with `CONCURRENTLY` (in background) will be canceled due to a statement timeout. As an aside, make sure the statement timeout is raised a bit for migrations. [Strong Migrations](https://github.com/ankane/strong_migrations#migration-timeouts) raises it to 1 hour.

To avoid typos, I want to get the exact SQL statement used to create the index from an earlier environment. I can achieve that using this query and the name of the index:

```sql
SELECT indexdef FROM pg_indexes
WHERE indexname = 'index_name';
```

Let's say we want to index the blog post ID for comments where the post_id is not null. So we will use a partial index. Let's say comments can be stored without being associated to a post.

```sql
SELECT indexdef FROM pg_indexes
WHERE indexname = 'index_comments_on_post_id';
```

Running the query then might produce a statement like below. *Please note* I've manually added the `CONCURRENTLY` keyword below. The index build will be slower but will not block other operations on the table.

```sql
CREATE INDEX CONCURRENTLY index_comments_on_post_id
ON public.comments USING btree (post_id)
WHERE (post_id IS NOT NULL);
```

## Wrap-up and Summary
* The migration version is the numeric part of the filename, and is inserted into the `schema_migrations` table to track which migrations have run
* The original Rails migration file will still be useful for other developers and other environments.
* It may be worth raising the statement timeout if migrations fail to finish in time
* Run migrations concurrently to avoid blocking other table operations
* Consider using [Strong Migrations](https://github.com/ankane/strong_migrations) or a similar utility to increase the safety and reliability of migrations
* Once you have the SQL modification to apply, apply it manually and track it via schema migrations.
* Since we're usually in a failed deploy state, after performing this manual fix we typically deploy again to confirm everything is a known good state.
* Whenever applying production changes, it's a good idea to do a dry run on a non-production DB and share the plan in advance with a team member to help spot mistakes
