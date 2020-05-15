---
layout: post
title: "Rails API Serialization with JSON API - Part 1"
tags: [Ruby, Rails, API, Performance]
date: 2020-05-15
comments: true
---

Rails API Serialization with JSON API - Part 1

For a Rails 6 API app I'm working on, the API controllers should respond to the clients with JSON.

The most simple approach is to call `render :json` on the collection, which transforms it to a Array of Hashes, then serializes that to JSON. ([Rendering JSON](https://apidock.com/rails/ActionController/Base/render)).

Let's take a look at some of the pros and cons of this approach.

#### Simple JSON responses with `render :json`

- No configuration or gems are required, the code is very simple. The default JSON serialization on the collection is returned.
- Some customization can be made on the server upfront, such as limiting the fields in the response.
- Some useful response headers are included by default, such as `ETag` and `Content-Type: application/json`.

On the other hand, customization is limited. Here are some things that are missing that would be nice to have:

- The client has no ability to customize the fields being returned
- The client has no ability to request related data
- Sorting and paginating the items is not available by default

#### Serializers and JSON API

We're going to introduce a new serialization approach that will address some of the downsides of the more simple approach above. I selected the [fast_jsonapi](https://github.com/Netflix/fast_jsonapi) gem/library for to build the API responses, because of the performance claims, and because it implementes the [JSON API specification](https://jsonapi.org/), which is a specification for building APIs. Using a specification-based implementation will help with consistency and predictability as teams and technologies grow and change.

#### Sparse Fieldsets

JSON API specifies an ability for the client to select specific fields for a resource. This feature is called sparse fieldsets.

In this application, for a given Trip resource, currently it returns a `rider_name` and a `driver_name`. In order to limit the Trip fields to just the `rider_name`, we'd specify a query parameter as below. The format is the `fields` with the resource name pluralized as part of the key portion, and then a comma-separated list of the fields as the value.

```
curl "localhost:3000/api/trips/my?fields[trips]=rider_name
```

Now we can confirm in the `attributes` that we're only getting the `rider_name` back.

```
{
  "data": [
    {
      "id": "109",
      "type": "trip",
      "attributes": {
        "rider_name": "Annice K."
      }
    }
  ]
}
```

### Wrap-up

That's all for this post. In a future post, we'll cover more functionality that JSON API specifies, such as the client requesting related data.
