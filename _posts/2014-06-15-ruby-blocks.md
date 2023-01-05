---
layout: post
title: "Using Ruby Blocks"
date: 2014-05-21
comments: true
tags: [Ruby, Tips, Programming]
---

A nice usage of Ruby blocks in application code is to externalize some repeated code.

The examples below are doing some different operations on a couple of values, but we might want to benchmark each operation.

Instead of duplicating the benchmarking code, we can create a method that takes a block as an argument, then move the repeated code there.

Now we can call the new method with a block that contains the code to be benchmarked. `block.call` executes the block. Another way to execute the block would be to call `yield` after verifying the block is present with `block_given?`.

```ruby
x = 1
y = 2

def with_benchmark(&block)
  return unless block
  time = Benchmark.measure do
    puts block.call
  end
  puts time
end

with_benchmark { x + y }
with_benchmark { x * y }
with_benchmark { x / y }
```
