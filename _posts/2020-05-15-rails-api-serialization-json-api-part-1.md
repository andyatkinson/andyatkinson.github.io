---
layout: post
title: "Rails API Serialization with JSON:API - Part 1"
tags: [Ruby, Rails, API, Performance]
date: 2020-05-15
comments: true
---

For a Rails 6 API app I'm working on, there is an API endpoint that provides data to clients, formatted as JSON.

After querying relevant Trip records, the simplest approach to turn this into JSON is to call `render :json` on the collection, which transforms the data to an Array of Hashes and then serializes that object to a JSON formatted string. ([Rendering JSON](https://apidock.com/rails/ActionController/Base/render))

This is a simple approach and a good starting point, but let's take a look at some of the pros and cons of this approach.

#### Simple JSON responses with `render :json`

- No configuration or gems are required, the code is very simple. The default JSON serialization on the collection is returned.
- Some customization can be made on the server upfront, such as limiting the fields in the response, but this is static configuration.

On the other hand, customization is limited. Here are some things that are missing that would be nice to have:

- The client has no ability to customize the fields being returned
- The client has no ability to request data that is related to the resource
- Sorting and pagination are not available by default

#### Serializers and JSON:API

We're going to introduce a new serialization approach that will address some of the downsides above. I selected the [fast_jsonapi](https://github.com/Netflix/fast_jsonapi) gem/library to build the API response in part because it implements the [JSON:API specification](https://jsonapi.org/). The serialization option built in to Rails is Active Model Serialization.

Using a specification-based implementation will help with consistency and predictability as teams and technologies grow and change.

#### Sparse Fieldsets

JSON:API specifies an ability for the client to specify a reduced set of fields for a resource, reducing time on the server and the weight of the payload. JSON:API calls this sparse fieldsets, and we can use it to generate part of the API response dynamically.

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

#### Wrap-up

That's all for Part 1 of selecting a JSON:API compatible API serialization option for a Rails API app.

In a future post, we'll cover more functionality that JSON:API specifies, such as the client requesting data that is related to the resource.

UPDATE: [Rails API Serialization with JSON:API - Part 2](rails-api-serialization-json-api-part-2) is now available.
