---
layout: page
permalink: /postgresql-tips
title: PostgreSQL Tuning and Tips
---

Here are tuning params, tips and misc. information collected from work experience with PostgreSQL that didn't quite fit into a single blog post. More of an evolving source of personal documentation, references, and examples.

### Query: Approximate count on any table

A `count(*)` query on a large table may be too slow. If an approximate count is acceptable use this:

```
SELECT relname, relpages, reltuples::numeric, relallvisible, relkind, relnatts, relhassubclass, reloptions, pg_table_size(oid) FROM pg_class WHERE relname='table';
```

### Autovacuum

PostgreSQL runs an autovacuum process in the background to remove dead tuples. Dead tuples are the result of a multiversion model ([MVCC](https://www.postgresql.org/docs/9.5/mvcc-intro.html)).

There are two parameters to tune, "scale factor" and "threshold".

In [routine vacumming](https://www.postgresql.org/docs/9.1/routine-vacuuming.html), the two options are listed:

- scale factor (a percentage of dead tuples) [`autovacuum_vacuum_scale_factor`](https://www.postgresql.org/docs/9.1/runtime-config-autovacuum.html#GUC-AUTOVACUUM-VACUUM-SCALE-FACTOR)
- threshold (a specific number of dead tuples) [`autovacuum_vacuum_threshold`](https://www.postgresql.org/docs/9.1/runtime-config-autovacuum.html#GUC-AUTOVACUUM-VACUUM-SCALE-FACTOR)

The scale factor defaults to 20% (`0.20`). To optimize for our largest tables it has been recommended to set the scale factor very low 1% (`0.01`) or opt out of it altogether.

To opt out of scale factor entirely, set the value to 0 and set the threshold to the number to trigger the condition, e.g. 1000.

```
ALTER TABLE bigtable SET (autovacuum_vacuum_scale_factor = 0);
ALTER TABLE bigtable SET (autovacuum_vacuum_threshold = 1000);
```

If after experimentation you'd like to reset, use the `RESET` option.

```
ALTER TABLE bigtable RESET (autovacuum_vacuum_threshold);
ALTER TABLE bigtable RESET (autovacuum_vacuum_scale_factor);
```
<https://www.postgresql.org/docs/current/sql-altertable.html>

### Additional AV parameters

`autovacuum_max_freeze_age`

TBD


### Remove unused indexes

Indexes may have been created that are not used as part of a query plan. These should be removed to reduce unnecessary IO associated with maintaining the index.

Ensure these are set to `on`

```
SHOW track_activities;
SHOW track_counts;
```

Now we can take advantage of tracking on whether indexes have been used or not. We can look for zero scans, and also very infrequent scans.

Cybertec blog post with SQL query to discover unused indexes: [Get Rid of Your Unused Indexes!](https://www.cybertec-postgresql.com/en/get-rid-of-your-unused-indexes/)

On our very large production database where this process had never been done, we had dozens of indexes that could be eliminated, taking of 100s of gigabytes of space.

```sql
SELECT s.schemaname,
       s.relname AS tablename,
       s.indexrelname AS indexname,
       pg_relation_size(s.indexrelid) AS index_size
FROM pg_catalog.pg_stat_user_indexes s
   JOIN pg_catalog.pg_index i ON s.indexrelid = i.indexrelid
WHERE s.idx_scan = 0      -- has never been scanned
  AND 0 <>ALL (i.indkey)  -- no index column is an expression
  AND NOT i.indisunique   -- is not a UNIQUE index
  AND NOT EXISTS          -- does not enforce a constraint
         (SELECT 1 FROM pg_catalog.pg_constraint c
          WHERE c.conindid = s.indexrelid)
ORDER BY pg_relation_size(s.indexrelid) DESC;
```

### Timeout Tuning

  - Statement timeout: TBD
  - Reaping frequency: TBD

### Checkpoint Tuning

TBD

### Connections Management

  - PgBouncer. [Running PgBouncer on ECS](https://www.revenuecat.com/blog/pgbouncer-on-aws-ecs)
  - RDS Proxy. [AWS RDS Proxy](https://aws.amazon.com/rds/proxy/)

### Foreign Data Wrappers

Native Foreign data wrapper functionality in PostgreSQL allows connecting to a remote table and treating it like a local table.

The table structure may be specified when establishing the foreign table or it may be imported as well.

A bit benefit of this for us at work is that for a recent backfill, we were able to avoid the need for any intermediary data dump files. This is a win in terms of reducing process steps, increasing the overall speed, and decreasing the security risk by eliminating intermediary customer data files.

We used a `temp` schema to isolate any temporary tables away from the main schema (`public`).

Essentially the process is:
  1. Create a server
  1. Create a user mapping
  1. Create a foreign table (optionally importing the schema)

Let's say we had 2 services, one for managing inventory items for sale, and one for managing authentication.

We wanted to connect to the authentication database from the inventory database.

In the case below, the inventory database is connected to with the `root` user so there is privileges to create temporary tables, foreign tables etc.

```
create EXTENSION postgres_fdw;

CREATE SCHEMA temp;

CREATE SERVER temp_authentication;
FOREIGN DATA WRAPPER postgres_fdw
OPTIONS (host 'authentication-db-host', dbname 'authentication-db-name', port '5432'); -- set the host, name and port

CREATE USER MAPPING FOR root
SERVER temp_authentication
OPTIONS (user 'authentication-db-user', password 'authentication-db-password'); -- map the local root user to a user on the remote DB

IMPORT FOREIGN SCHEMA public LIMIT TO (customers)
    FROM SERVER temp_authentication INTO temp; -- this will make a table called temp.customers
```

Once this is established, we can issue queries as if the foreign table was a local table:

```
select * from temp.customers limit 1;
```

### HOT updates

HOT ("heap only tuple") updates, are updates to tuples not referenced from outside the table block.

[HOT updates in PostgreSQL for better performance](https://www.cybertec-postgresql.com/en/hot-updates-in-postgresql-for-better-performance/)

2 requirements:

- there must be enough space in the block containing the updated row
- there is no index defined on any column whose value is modified (big one)

### The `fillfactor`

[What is fillfactor and how does it affect PostgreSQL performance?](https://www.cybertec-postgresql.com/en/what-is-fillfactor-and-how-does-it-affect-postgresql-performance/)

- A percentage between 10 and 100
- you can adjust it to leave room for HOT updates when they're possible
- For tables with heavy updates a smaller fillfactor is appropriate
- Per table or per index

### Locks

[Lock Monitoring](https://wiki.postgresql.org/wiki/Lock_Monitoring)

- `log_lock_waits`
- `deadlock_timeout`

"Then slow lock acquisition will appear in the database logs for later analysis."


### Query planning tools

##### [pgMustard](https://www.pgmustard.com/). [YouTube demonstration video](https://www.youtube.com/watch?v=v7ef4Fpn2WI).
Nice tool and I learned a couple of tips. Format `EXPLAIN` output with JSON, and specify some additional options. Handy SQL comment to have hanging around on top of the query to study:

`explain (analyze, buffers, verbose, format text)` or specify `format json`


### Query: 10 largest tables

```sql
select schemaname as table_schema,
    relname as table_name,
    pg_size_pretty(pg_total_relation_size(relid)) as total_size,
    pg_size_pretty(pg_relation_size(relid)) as data_size,
    pg_size_pretty(pg_total_relation_size(relid) - pg_relation_size(relid))
      as external_size
from pg_catalog.pg_statio_user_tables
order by pg_total_relation_size(relid) desc,
         pg_relation_size(relid) desc
limit 10;
```
<https://dataedo.com/kb/query/postgresql/list-10-largest-tables>
