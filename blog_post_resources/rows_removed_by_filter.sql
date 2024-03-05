-- Raw SQL and Active Record
-- Refer to blog post for final information
--

-- Disable Autovacuum so we have control over it
ALTER TABLE rideshare.users SET (autovacuum_enabled = false);

-- Add name_code column
ALTER TABLE rideshare.users
ADD COLUMN name_code VARCHAR (25)
DEFAULT NULL;

-- Populate name_code values
WITH u1 AS (
    SELECT id,
    CONCAT(SUBSTRING(first_name, 1, 1),
           SUBSTRING(last_name, 1, 1),
           FLOOR(RANDOM() * 10000 + 1)::INTEGER
    ) AS code
    FROM users
)
UPDATE users u
SET name_code = u1.code
FROM u1
WHERE u.id = u1.id;


-- Active Record code below:
-- name_code = User.all.sample.name_code # => "AG6805"
--
-- Make sure rows exist:
-- User.where(name_code: "AG6805").count # => 1

-- Don't use "first" use "limit(1)"
-- We need "ANALYZE" to get Rows Removed by Filter
--
-- User.where(name_code: 'AG6805').limit(1).explain(:analyze)
--
-- tuple ID: (block_number,tuple_index)
--    ctid
-- ----------
--  (657,20)

CREATE EXTENSION IF NOT EXISTS pageinspect;

-- This was before running a VACUUM FULL
-- We can see the raw data for the table, and reference the t_ctid
SELECT * FROM rideshare.heap_page_items(rideshare.get_raw_page('rideshare.users', 657));

-- What we see is the number of pages/blocks filtered out in order to satisfy the condition
-- We inserted 20K rows
-- We can check the overall table:

SELECT COUNT(DISTINCT(sub.block)) FROM (
  SELECT (ctid::text::point)[0]::int AS block
  FROM rideshare.users
) sub;

-- We see it's about 352 blocks


--
-- Buffer cache inspection
--
CREATE EXTENSION IF NOT EXISTS pg_buffercache SCHEMA rideshare;

SELECT * FROM rideshare.pg_buffercache where bufferid BETWEEN 0 AND 3;

-- Looking at the buffer cache content by bufferid ORDER ASC
--
SELECT b.bufferid, n.nspname, c.relname, b.relblocknumber
FROM rideshare.pg_buffercache b
JOIN pg_class c ON b.relfilenode = pg_relation_filenode(c.oid) AND
b.reldatabase IN (0, (SELECT oid FROM pg_database WHERE datname = current_database()))
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'rideshare'
ORDER BY b.relblocknumber ASC;
