CREATE TABLE t (
  id INT GENERATED ALWAYS AS IDENTITY,
  account_id INT NOT NULL
) PARTITION BY LIST (account_id);

CREATE TABLE t_account_1 PARTITION OF t FOR VALUES IN (1);
CREATE TABLE t_account_2 PARTITION OF t FOR VALUES IN (2);

INSERT INTO t (account_id) SELECT 1 FROM GENERATE_SERIES(1,10);
INSERT INTO t (account_id) SELECT 2 FROM GENERATE_SERIES(1,100);

-- Imagine we want to merge these
ALTER TABLE t MERGE PARTITIONS (t_account_1, t_account_2) INTO t_account_1_2;

-- Imagine some rows are misattributed
-- Split partition for account ids 
-- Makes more sense for RANGE partitioning
-- ALTER TABLE t_account_1 SPLIT PARTITION t_account_2 INTO
-- (PARTITION t_account_2 FOR VALUES (1) TO (50)
--   PARTITION t_account_3 FOR VALUES (51) TO (100));

CREATE TABLE t_events (
  id INT GENERATED ALWAYS AS IDENTITY,
  event_at TIMESTAMP WITHOUT TIME ZONE NOT NULL
) PARTITION BY RANGE (event_at);

CREATE TABLE t_events_last_week PARTITION OF t_events
  FOR VALUES FROM ('2024-04-08 00:00:00') TO ('2024-04-15 00:00:00');

CREATE TABLE t_events_this_week PARTITION OF t_events
  FOR VALUES FROM ('2024-04-15 00:00:00') TO ('2024-04-22 00:00:00');

CREATE TABLE t_events_next_week PARTITION OF t_events
  FOR VALUES FROM ('2024-04-22 00:00:00') TO ('2024-04-29 00:00:00');

-- Split 1 week partition into 7 days
ALTER TABLE t_events SPLIT PARTITION t_events_next_week INTO (
  PARTITION t_events_day_1 FOR VALUES FROM ('2024-04-22 00:00:00') TO ('2024-04-23 00:00:00'),
  PARTITION t_events_day_2 FOR VALUES FROM ('2024-04-23 00:00:00') TO ('2024-04-24 00:00:00'),
  PARTITION t_events_day_3 FOR VALUES FROM ('2024-04-24 00:00:00') TO ('2024-04-25 00:00:00'),
  PARTITION t_events_day_4 FOR VALUES FROM ('2024-04-25 00:00:00') TO ('2024-04-26 00:00:00'),
  PARTITION t_events_day_5 FOR VALUES FROM ('2024-04-26 00:00:00') TO ('2024-04-27 00:00:00'),
  PARTITION t_events_day_6 FOR VALUES FROM ('2024-04-27 00:00:00') TO ('2024-04-28 00:00:00'),
  PARTITION t_events_day_7 FOR VALUES FROM ('2024-04-28 00:00:00') TO ('2024-04-29 00:00:00')
);


-- detach
ALTER TABLE t_events DETACH PARTITION t_events_next_week CONCURRENTLY;

andy@[local]:5432 postgres# \d t_events_next_week
                    Table "public.t_events_next_week"
  Column  |            Type             | Collation | Nullable | Default
----------+-----------------------------+-----------+----------+---------
 id       | integer                     |           | not null |
 event_at | timestamp without time zone |           | not null |
Check constraints:
    "t_events_next_week_event_at_check" CHECK (event_at IS NOT NULL AND event_at >= '2024-04-22 00:00:00'::timestamp without time zone AND event_at < '2024-04-29 00:00:00'::timestamp without time zone);


ERROR:  partition bound for relation "t_events_next_week" is null

-- Can we add a new fake parent?

CREATE TABLE t_events_fake_new (
  id INT GENERATED ALWAYS AS IDENTITY,
  event_at TIMESTAMP WITHOUT TIME ZONE NOT NULL
) PARTITION BY RANGE (event_at);

-- Now we can reattach them to a fake new parent
ALTER TABLE t_events_fake_new SPLIT PARTITION t_events_next_week INTO (
  PARTITION t_events_day_1 FOR VALUES FROM ('2024-04-22 00:00:00') TO ('2024-04-23 00:00:00'),
  PARTITION t_events_day_2 FOR VALUES FROM ('2024-04-23 00:00:00') TO ('2024-04-24 00:00:00'),
  PARTITION t_events_day_3 FOR VALUES FROM ('2024-04-24 00:00:00') TO ('2024-04-25 00:00:00'),
  PARTITION t_events_day_4 FOR VALUES FROM ('2024-04-25 00:00:00') TO ('2024-04-26 00:00:00'),
  PARTITION t_events_day_5 FOR VALUES FROM ('2024-04-26 00:00:00') TO ('2024-04-27 00:00:00'),
  PARTITION t_events_day_6 FOR VALUES FROM ('2024-04-27 00:00:00') TO ('2024-04-28 00:00:00'),
  PARTITION t_events_day_7 FOR VALUES FROM ('2024-04-28 00:00:00') TO ('2024-04-29 00:00:00')
);


-- Perhaps this split would be very time consuming to do across all partitions
