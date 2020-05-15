---
layout: post
title: "Calendar Generation with Sparse Data"
date: 2017-05-18
comments: true
tags: [Ruby, Rails, API, Performance]
---

At work, our drivers interact with a calendar interface via the mobile app, that represents days of the week in 30 minute blocks. We generate 2 weeks of calendar days at once and personalize the data to the driver. The data is sparse, meaning not every block has data, but we need a block for every 30 minute increment.

A driver can interact with blocks to indicate they are available to work, they can see how many drivers are needed to work, whether they have been scheduled, the pay rate for that block, and more.

We don't want to loop over the blocks more than once, or be conducting queries while rendering the schedule. Also, in order to have a snappy app experience, we want to keep our API response time <=100ms, including building and serving the JSON. Sounds interesting!

### Overview of the solution

We can generate 30 minute increment blocks in plain Ruby, but how do we fill the blocks in with data efficiently?

The route we went was to take inspiration from the "<mark>constant time lookup</mark>" benefit of a hash table, and put together an intermediate data structure as a plain Ruby hash, that was responsible for collecting all the data needed for the calendar before rendering began, so that rendering was very straightforward, pulling from this hash, and incurring no performance penalty. Seems reasonable. Let's look at this in more detail.

By the way, if you need a primer or refresher on hash tables and hash functions, I recommend "Taking Hash Tables Off The Shelf" [^ht1] and "Hashing Out Hash Functions" [^ht2] by Vaidehi Joshi.

The second article here discusses hash functions to compute a key, and minimize collisions. In our case we didn't need to worry about that, we're using the database ID for the object we're working with, as the key, which is guaranteed to be unique, enforced by a database constraint. With that out of the way, the main challenge for us was coming up with efficient queries to get the driver and schedule data we needed.

### Solution steps

 * Do not conduct queries while rendering
 * Put together intermediate mapping of calendar data that will be needed while blocks are being rendered
 * (Optional) Use plain SQL with Active Record, while still sanitizing the query

### Diving into some code

One of the pieces of data we want to show is whether a particular block is already assigned.

We are able to do a single query for all of the assignments of drivers to a block of time. Then we make our hash as mentioned earlier, with each block's ID as the key, and the value as the count of assignments, doing the counting in Ruby instead of SQL.

Now we can look up the number of assignments for any block in constant time from the hash of data, and we aren't querying for the count of assignments every time we're rendering a block of time.

```ruby
all_assignments = [] # 1) chunk of SQL to find all the assignments

# 2) put together the intermediate data structure
all_blocks.each_with_object({}){ |block_id, hash|
  h[block_id] = all_assignments.select{|a| a['block_id'].to_i == block_id}.size.to_i
}

# 3) Look up the count for the block ID key while rendering
# => {block_id => count}
```

> We are using `Enumerable#each_with_object` here to produce a Hash that maps the block ID to the count of assignments. We don't need a hash function to compute a key, since we are already guaranteed to have a unique key by using the database ID as the key.

### Using Active Record

We are using Active Record but chose to express the query in SQL. This way we get benefits from Active Record like sanitization and being able to parameterize the queries.

For sanitization, we use a private method, which might make upgrades more difficult later (using private methods is generally a bad idea, but the downsides can be mitigated by wrapping uses of it, so it can be changed in one spot later). Since the method is private, we use `send` to work around this in Ruby. `Assignment` in this example is the Active Record model. This is a simplification of our real data model.

The private method `sanitize_sql` takes the SQL query as a string and then a hash of parameters. We're passing an array of block IDs as the value, to a parameter named `block_ids`.

```ruby

# Parameterized SQL query. Expects hash with `block_ids` key, and array of block ID values
sql = %{SELECT a.id, a.block_id FROM assignments a JOIN drivers d ...
          WHERE a.block_id IN (:block_ids)}


block_ids = [] # relevant block IDs
```

```ruby
Assignment.send(:sanitize_sql, ["sql", {block_ids: block_ids}])
```

### Summary

Generating 2 weeks of calendar data per driver, for our thousands of drivers using the app and expecting a fast user experience, was tricky! Using the approaches here <mark>allowed us to stay in the 50-100ms range</mark> for rendering this data, providing a fast experience with rich data to interact with.

The applicability of this approach will really depend on your specific application. However it seems like a handy tool to keep in mind for highly structured data, where the end result requires the data is denormalized and re-structured as JSON.


[^ht1]: [Taking Hash Tables Off The Shelf](https://dev.to/vaidehijoshi/taking-hash-tables-off-the-shelf) by Vaidehi Joshi

[^ht2]: [Hashing Out Hash Functions](https://dev.to/vaidehijoshi/hashing-out-hash-functions) by Vaidehi Joshi
