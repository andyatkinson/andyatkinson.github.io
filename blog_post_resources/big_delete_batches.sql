-- Original clicks table
CREATE TABLE clicks (
  id BIGINT GENERATED ALWAYS AS IDENTITY,
  company_id INTEGER NOT NULL,
  session_id TEXT,
  link_id BIGINT,
  created_at TIMESTAMP WITHOUT TIME ZONE
);

INSERT INTO clicks (company_id, session_id, link_id)
SELECT
  floor(random()*100),
  SUBSTR(MD5(RANDOM()::TEXT), 0, 6)
  floor(random()*100),
FROM GENERATE_SERIES(1,1000000) s;


-- Slice of records from day of incident
-- Add an index to the original big table, to speed up the selection
-- for the same query conditions
CREATE INDEX idx1_single_day ON clicks (created_at ASC)
WHERE (created_at >= '2024-03-19 00:00:00'::TIMESTAMP WITHOUT TIME ZONE
AND created_at < '2024-03-20 00:00:00'::TIMESTAMP WITHOUT TIME ZONE);


-- With the index in place, copy the row data into a new table
-- Capture all row data, theoretically using the index ^^^^ just created, to make this fast
CREATE TABLE clicks_20240319 AS
SELECT *
FROM clicks
WHERE (created_at >= '2024-03-19 00:00:00'::TIMESTAMP WITHOUT TIME ZONE)
AND (created_at < '2024-03-20 00:00:00'::TIMESTAMP WITHOUT TIME ZONE);


SELECT link_id, created_at, session_id, count(*)
FROM clicks_20240319
GROUP BY 1, 2,3
HAVING COUNT(*) > 1
ORDER BY count(*) DESC
LIMIT 10;


-- Now we're ready to find duplicates
-- This index helps support that query
CREATE INDEX idx_clicks_dupe_detection
ON clicks_20240319 (created_at, session_id, link_id, id);


-- Write a query to find the dupes from the daily slice table
-- This uses the ROW_NUMBER() window function,
-- and selects rows higher than row #1 which are considered
-- duplicates. The primary key id is placed into another
-- new "dupe ids" table. From there we can validate some
-- data and then perform deletes by primary key.
CREATE TABLE clicks_20240319_dupe_ids AS
WITH duplicates AS (
    SELECT
    id, ROW_NUMBER() OVER(
        PARTITION BY hit_at, session_id, link_id
        ORDER BY hit_at DESC
    ) AS rownum
    FROM hits_20240319
)
SELECT
    d.id
FROM duplicates d
JOIN hits h ON d.id = h.id
WHERE d.rownum > 1;



-- Anonymouse DO block to create batched DELETE
-- statements in batches. The batch size below is set on the
-- LIMIT clause and is 10000
--
DO
$do$
DECLARE
   _max_id integer := -1;  -- assuming positive, unique IDs!
BEGIN
LOOP
   WITH cte AS (
      SELECT id  -- don't use *, we only need id
      FROM   clicks_20240319_dupe_ids t1
      WHERE  t1.id > _max_id
      ORDER  BY id
      LIMIT  10000
      )
   , del AS (
      DELETE FROM clicks t
      USING  cte c
      WHERE  t.id = c.id
      )
   SELECT max(id) FROM cte
   INTO _max_id;

   EXIT WHEN _max_id IS NULL;
   COMMIT;
END LOOP;
END
$do$;
