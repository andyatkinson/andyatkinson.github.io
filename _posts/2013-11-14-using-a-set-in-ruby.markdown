---
layout: post
title: "Using a Set in Ruby"
date: 2013-11-14
comments: true
tags: [Ruby, Tips]
---

A Set [^rubydoc] is a useful collection and something I under-utilize in Ruby. A Set does not allow duplicates. Converting between a Set and an Array is easy. In the article *A Guide to Ruby Collections, II: Hashes, Sets, and Ranges* [^sitepoint] the author has listed some nice examples where Sets are useful.

```ruby
(Set.new([1,2]) + [2]).to_a
=> [1, 2]
```

Equality of Sets can be determined with `#eql?` (the "identity" value, same as triple equals) and by comparing the `#hash` value. The order of the items is not part of the equality check. The second example shows another style of constructing a Set.

```ruby
Set.new([1,2]).eql?(Set.new[2,1]) # => true
Set[1,2].hash == Set[2,1].hash # => true
```

Sets can be used to store different types of objects like Array. Set operations can be performed which might make cleaner code when finding a subset of values. More Set operations can be found in the article *When Is a Set Better Than an Array in Ruby?* [^setbetter]. 

#### Set Operations

Set operations can also be performed on Arrays which Avdi Grimm describes in his article *Array Set Operations in Ruby* [^setarray].

```ruby
s1 = Set.new([1,2])
s2 = Set.new([2,3])

s1 & s2 # => #<Set: {2}>
s1 | s2 # => #<Set: {1, 2, 3}> 
s1 ^ s2 # => #<Set: {3, 1}>
```

#### Conclusion

Next time try a Set!

[^rubydoc]: [ruby-doc Set](http://www.ruby-doc.org/stdlib-2.0.0/libdoc/set/rdoc/Set.html)
[^setbetter]: [When Is a Set Better Than an Array in Ruby?](http://spin.atomicobject.com/2012/09/04/when-is-a-set-better-than-an-array-in-ruby/)
[^setarray]: [Array Set Operations in Ruby](http://devblog.avdi.org/2012/08/27/array-set-operations-in-ruby/)
[^sitepoint]: [A Guide to Ruby Collections, II: Hashes, Sets, and Ranges](http://www.sitepoint.com/guide-ruby-collections-ii-hashes-sets-ranges/)
