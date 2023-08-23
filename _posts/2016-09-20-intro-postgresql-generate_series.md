---
layout: post
title: "Intro to PostgreSQL 'generate_series'"
date: 2016-09-20
comments: true
tags: [PostgreSQL, SQL, Tips, Databases]
---

For a recent project, we wanted to efficiently present a week's worth of data grouped by day, where each row represented the summary of an hour of activity.

While researching potential solutions, I came across the PostgreSQL `GENERATE_SERIES` function and was able to use it to populate data to test with.

## Basic Examples

A series can be made up of numbers, spans of time, dates or other types. A start and stop value is provided and an optional step value.

This is a series from 1 to 4 with a step value of 2. The step value can also be negative which would make it count down instead of up.

Run the following statements from psql.

```sql
SELECT * FROM GENERATE_SERIES(1,4,2);
 generate_series
-----------------
               1
               3
```

A series can be made up of days. Here is an example from today to 2 days from now, with a step value of 1 day.

```sql
SELECT * FROM GENERATE_SERIES(
  NOW()::date,
  NOW()::date + interval '2 days',
  '1 day'
);
   generate_series
---------------------
 2016-09-20 00:00:00
 2016-09-21 00:00:00
 2016-09-22 00:00:00
```

## Real-world Problem Background Info

The real world example here was that we wanted a few days worth of activity and to have rows for each day whether there were earnings on that day or not.

In the example below, 2016-09-22 still has a results row but no sum.

``` bash
    date    |  sum
------------+-------
 2016-09-20 | 148.3
 2016-09-21 | 112.6
 2016-09-22 |
```

To set this up, you'll create some tables from psql.

Insert rows that summarize earnings for an employee by hour, and put this into a test database called `test_db`.

Change into that database with `\c test_db`, then create the table.

```sql
CREATE DATABASE test_db;

\c test_db

CREATE TABLE earnings (
employee_id INTEGER NOT NULL,
hour TIMESTAMPTZ NOT NULL,
total NUMERIC NOT NULL
);
```

Employee "1" worked on September 20 and 21 but not on the 22nd.

```sql
INSERT INTO earnings (employee_id, hour, total)
VALUES (1, '2016-09-20 08:00:00', 25.0);

INSERT INTO earnings (employee_id, hour, total)
VALUES (1, '2016-09-20 09:00:00', 70.3);

INSERT INTO earnings (employee_id, hour, total)
VALUES (1, '2016-09-20 10:00:00', 53.0);

INSERT INTO earnings (employee_id, hour, total)
VALUES (1, '2016-09-21 08:00:00', 11.5);

INSERT INTO earnings (employee_id, hour, total)
VALUES (1, '2016-09-21 09:00:00', 39.7);

INSERT INTO earnings (employee_id, hour, total)
VALUES (1, '2016-09-21 10:00:00', 61.4);
```

The earnings table now has 6 rows.

Extract the date from each hour column timestamp value and group on that, to create a daily sum.

```sql
SELECT to_char(hour, 'YYYY-MM-DD') as day, sum(total)
FROM earnings
GROUP BY day
ORDER BY day ASC;
    day     |  sum
------------+-------
 2016-09-20 | 148.3
 2016-09-21 | 112.6
```

## Real-world Problem, Final Solution

Using this technique you can summarize earnings for days where we have database records, but remember earlier that we wanted to have result rows even on days without earnings records.

How can we do that? That's where `GENERATE_SERIES` comes in!

Generate a series with a step value of 1 day covering the start and end dates.

Then do a LEFT OUTER JOIN on the earnings table by date. The final query is as follows.


```sql
SELECT
  series.date,
  sum(e.total)
FROM (
    SELECT to_char(day, 'YYYY-MM-DD') AS date FROM
    GENERATE_SERIES('2016-09-20'::date, '2016-09-22'::date, '1 day') AS day
) series
LEFT OUTER JOIN (
  SELECT * FROM earnings
  WHERE hour >= '2016-09-20' AND hour <= '2016-09-22') AS e
  ON (series.date = to_char(e.hour, 'YYYY-MM-DD')
)
GROUP BY series.date
ORDER BY series.date;
```

The final result now has a result row for 2016-09-22 even without an earnings row.

```sql
    date    |  sum
------------+-------
 2016-09-20 | 148.3
 2016-09-21 | 112.6
 2016-09-22 |
```

Thanks!
