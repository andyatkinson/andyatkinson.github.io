---
layout: post
title: "Encrypting and Decrypting with Ruby"
date: 2018-01-22
comments: true
tags: [Programming, Ruby, Tips]
---

For a recent project I had the opportunity to research how we might encrypt a few pieces of data, with a shared key and initial value, and I put together the following notes. This is mostly re-hashing the [OpenSSL:Cipher documentation](https://ruby-doc.org/stdlib-1.9.3/libdoc/openssl/rdoc/OpenSSL/Cipher.html) if you'd rather jump straight there.

In this example we'll represent some fields of data about a person as a Ruby Hash that maps the name of the data to the value. Let's say we are storing their name, email, and the date they were created.

#### Encrypt

Before storing encrypted data, we'll do some transformations to make it easier to work with. We'll convert the data to JSON for easier serialization and deserialization, URL encode it to handle tricky characters in the strings like name, and base64 encode it to shrink it down.

In the example below, a random key and initial value are generated and assigned, and the same variables are assumed to be accessible in the decryption process. This would be the case in a Ruby IRB session for example, but in a real world scenario the values would be stored elsewhere.

<pre><code class="language-ruby">data = {:name=>"Andy A.", :email=>"andy+hello@example.com", :created_on=>"2018-01-20"}

require 'openssl'
require 'uri'
require 'base64'
require 'json'

cipher = OpenSSL::Cipher::AES.new(256, :CBC)
cipher.encrypt

key = cipher.random_key
iv = cipher.random_iv

encrypted = cipher.update(data.to_json) + cipher.final

encoded = URI::encode(Base64.encode64(encrypted))</code></pre>

Now we have an encoded and encrypted representation to store.


#### Decrypt

This part sets up the decryption, passing in the key and initial value we used above to encrypt thed data.

```ruby
decipher = OpenSSL::Cipher::AES.new(256, :CBC)
decipher.decrypt
decipher.key = key
decipher.iv = iv
```

Now that we can decrypt the data back into plain text.

```ruby
plain = decipher.update(encrypted) + decipher.final
```

At this point, we have our plain text version, although it is represented as a JSON string. The last step is to parse the string as JSON to arrive back at the original Ruby Hash.

```ruby
data == JSON.parse(plain)
```
