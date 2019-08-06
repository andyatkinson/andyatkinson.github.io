---
layout: post
title: "Estimating Memory Use in Redis and Mass Insert"
tags: [Redis, Databases, Ruby, Scripts]
date: 2019-08-06
comments: true
---

A recent work project involved persisting user data in Redis. We wanted to estimate the amount of memory we expected to use to determine whether the infrastructure currently available would be appropriately sized.


#### Data Details

* We're using Redis inside the user's request, so it needs to be fast
* We're using `hset` [^1] to store a hash for each user (Time complexity: O(1)), with a unique key per user
* Each key is composed of a prefix and a UUID representing the user
* We are setting up to 3 field and value pairs, which represent user interaction events
* We're using `hgetall` [^2] (O(N) where N is the size of the hash) to read the field and value pairs back out

#### Determining Memory Use Per Key

In the article [Estimate the memory usage for repeated keys in Redis](https://medium.com/@lucasmagnum/redistip-estimate-the-memory-usage-for-repeated-keys-in-redis-2dc3f163fdab), the technique uses the `INFO` command to look at how much the memory increased by after adding a key.

Since Redis Version 4, there is a more direct method, using the `memory usage` command [^3]. I set a couple of keys and checked their size, and they were about 225 bytes per key.

For 1,000,000 users then, we'd expect to use about 250 MB (`225 bytes * 1_000_000`) of memory.


#### Redis Mass Insertion Script

I modified the script below, to insert 1,000,000 items in Redis that are equivalent to what the application will insert. The [Redis Mass Insert](https://redis.io/topics/mass-insert) example uses a simple `SET` operation with a key and value, so I changed it to perform an `HSET` with realistic values and an `EXPIRE` operation.

```rb
#
# Usage:
#
# $ ruby redis_insert_example.rb | redis-cli --pipe
#
def gen_redis_proto(*cmd)
    proto = ""
    proto << "*"+cmd.length.to_s+"\r\n"
    cmd.each{|arg|
        proto << "$"+arg.to_s.bytesize.to_s+"\r\n"
        proto << arg.to_s+"\r\n"
    }
    proto
end

(0...10).each{|n|
  STDOUT.write(gen_redis_proto("SET","Key#{n}","Value#{n}"))
}
```

In order to clean this up, the following bash script will delete the keys, however it operates one by one, so it will be slow for large data sets.

```
for key in `echo 'KEYS Key*' | redis-cli | awk '{print $1}'`
 do echo DEL $key
done | redis-cli
```

#### Memory Used

Below we've loaded equivalent data for `1_000_000` users, which involved 3 key/value pairs per user, as well as 1 `EXPIRE` operation at the hash key level, to set a TTL on the key. This is why the script output below shows 4,000,000 replies (4 operations per user).

```sh
~/Projects/redis-mass-insert $ ruby redis_insert_groupon.rb | redis-cli --pipe
All data transferred. Waiting for the last reply...
Last reply received from server.
errors: 0, replies: 4000000
```

Now we can check the used memory, which we see is about 290 MB, fairly close to our estimate above from checking a single key. The additional memory may be due to storing all the TTL values.

```sh
~/Projects/redis-mass-insert $ redis-cli -p 6379 -a  password info| egrep "used_memory_human|total_system_memory_human"
Warning: Using a password with '-a' or '-u' option on the command line interface may not be safe.
used_memory_human:294.24M
total_system_memory_human:16.00G
```

Here is the Redis `info keyspace` output, where we can confirm that we have over 1 million keys with expiration values.

```
127.0.0.1:6379> info keyspace
# Keyspace
db0:keys=1000006,expires=1000000,avg_ttl=7775864775
```


[^1]: [Redis `hset` docs](https://redis.io/commands/hset)
[^2]: [Redis `hgetall` docs](https://redis.io/commands/hgetall)
[^3]: [Redis `memory usage` docs](https://redis.io/commands/memory-usage)
