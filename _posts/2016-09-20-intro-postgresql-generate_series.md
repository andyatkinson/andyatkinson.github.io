---
layout: post
title: "Intro to PostgreSQL 'generate_series'"
date: 2016-09-20
comments: true
tags: [PostgreSQL, SQL, Tips, Databases]
---


For a recent project, we wanted to efficiently present a week's worth of data, grouped by day, where each row represented the summary of an hour of activity.

While researching potential solutions, I came across the PostgreSQL [generate_series](https://www.postgresql.org/docs/8.0/static/functions-srf.html) function. I found it to be easy to use and could see it being useful again in the future. Let's take a look at some basic examples, then dive into a real-world usage example.

#### Basic examples

A series can be made up of numbers, spans of time, dates or more. A start and stop value is provided, and an optional step value.

This is a series from 1 to 4, with a step value of 2. The step value can also be negative which would make it count down (when the start value is greater than the stop value).

``` sql
select * from generate_series(1,4,2);
 generate_series
-----------------
               1
               3
```

A series can also be made up of days. Here is an example from today, to 2 days from now, with a step value of 1 day.

``` sql
select * from generate_series(now()::date, now()::date + interval '2 days', '1 day');
   generate_series
---------------------
 2016-09-20 00:00:00
 2016-09-21 00:00:00
 2016-09-22 00:00:00
```

#### Real-world problem, background info

For our real world example, things will get a little more complicated by combining a couple of queries. The real world example is the reporting example mentioned above, where we want a few days worth of activity, and output rows for each day, whether there were earnings or not.

The final result should look like this:

``` bash
    date    |  sum
------------+-------
 2016-09-20 | 148.3
 2016-09-21 | 112.6
 2016-09-22 |
```

To better understand the data and the query, let's set up a table and some rows.

We'll insert some rows that summarize earnings for an employee, by hour, and we can put this in to a test database called `test_db`.

``` sql
CREATE DATABASE test_db;

CREATE TABLE earnings (employee_id integer NOT NULL, hour timestamp NOT NULL, total numeric NOT NULL);
```

Employee "1" worked on September 20 and 21, but not on the 22nd.

``` sql
insert into earnings (employee_id, hour, total) VALUES (1, '2016-09-20 08:00:00', 25.0);
insert into earnings (employee_id, hour, total) VALUES (1, '2016-09-20 09:00:00', 70.3);
insert into earnings (employee_id, hour, total) VALUES (1, '2016-09-20 10:00:00', 53.0);

insert into earnings (employee_id, hour, total) VALUES (1, '2016-09-21 08:00:00', 11.5);
insert into earnings (employee_id, hour, total) VALUES (1, '2016-09-21 09:00:00', 39.7);
insert into earnings (employee_id, hour, total) VALUES (1, '2016-09-21 10:00:00', 61.4);
```

You should have 6 rows in the earnings table now. Now that the data is in place, let's do some analysis. We can extract the date from each hour column timestamp, and group on that, so that we can create a daily sum of the total column.

``` sql
SELECT to_char(hour, 'YYYY-MM-DD') as day, sum(total)
FROM earnings
GROUP BY day
ORDER BY day ASC;
    day     |  sum
------------+-------
 2016-09-20 | 148.3
 2016-09-21 | 112.6
```

#### Real-world problem, final solution

We know how to summarize earnings for days where we have database records, but what about days where there aren't any? That's where `generate_series` comes in!

Let's imagine a user wanted to see earnings for 3 days, from September 20 to 22. We generate a series with a step value of 1 day, for those start and end dates. We then do a left outer join on the earnings table by date. The final query looks like this:


``` sql
SELECT
    series.date,
    sum(e.total)

FROM (
    select to_char(day, 'YYYY-MM-DD') as date FROM
    generate_series('2016-09-20'::date, '2016-09-22'::date, '1 day') as day
) series

LEFT OUTER JOIN (
    SELECT * from earnings
    WHERE hour >= '2016-09-20' AND hour <= '2016-09-22') AS e
    ON (series.date = to_char(e.hour, 'YYYY-MM-DD')
)

GROUP BY series.date
ORDER BY series.date;
```


The final result should look like this. Now the data is organized in a way that makes it easy to work with as a CSV file, or in a programming language. Nice!


``` bash
    date    |  sum
------------+-------
 2016-09-20 | 148.3
 2016-09-21 | 112.6
 2016-09-22 |
```

That's all for now. Thanks for stopping by.
