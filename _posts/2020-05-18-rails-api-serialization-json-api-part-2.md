---
layout: post
title: "Rails API Serialization with JSON API - Part 2"
tags: [Ruby, Rails, API, Performance]
date: 2020-05-15
comments: true
featured_image_thumbnail:
featured_image: /assets/images/pages/andy-atkinson-California-SF-Yosemite-June-2012.jpg
featured_image_caption: Yosemite National Park. &copy; 2012 <a href="/">Andy Atkinson</a>
featured: true
---

In [Rails API Serialization with JSON API - Part 1](rails-api-serialization-json-api-part-1) we looked at using the Sparse Fieldsets functionality of the JSON API specification.

In this post, we're going to pick up with the same Rails 6 API app. We're going to discuss the Compound Document feature and show how these two features can be combined.

Combining these two features can reduce the number of HTTP requests a client needs to make and reduce the size of the response payload.

#### Compound Documents

Using the [JSON API Compound Documents](https://jsonapi.org/format/#document-compound-documents), we're able to reduce the number of API calls a client would need to make, by adding related resources to the response.

This app serves Trip data, where a Trip is defined as something that a rider has taken, and was provided by a driver. When fetching trip details, the client may have the need to include some Driver details when presenting the Trip, so that is what we're going to add.

The following curl request would include the default serialization for the Driver in the response. Currently the serialized Driver response includes two fields, `display_name` and `average_rating`.

```
curl "localhost:3000/api/trips/199/details?include=driver"
```

We can see below that the response includes linkage information between the resources.

```
{
  "data": {
    "id": "199",
    "type": "trip",
    "attributes": {
      "rider_name": "Barney O.",
      "driver_name": "Loralee M."
    },
    "relationships": {
      "driver": {
        "data": {
          "id": "97",
          "type": "driver"
        }
      }
    }
  },
  "included": [
    {
      "id": "97",
      "type": "driver",
      "attributes": {
        "display_name": "Loralee M.",
        "average_rating": "2.33"
      }
    }
  ]
}
```

#### Combining Compound Documents and Sparse Fieldsets

Sparse Fieldsets can be used with the related resource, to limit the fields on the related resource.

For example, if we wanted to return *only* the `average_rating` for the Driver, that curl request would look like this:

```
curl "localhost:3000/api/trips/199/details?include=driver&fields[driver]=average_rating"
```

Looking at the `included` portion of the response here, we can see that the driver fields are limited to the `average_rating`, and `display_name` has been excluded.

```
...
"included": [
    {
      "id": "97",
      "type": "driver",
      "attributes": {
        "average_rating": "2.33"
      }
    }
  ]
...
```


#### Wrap-up

Using Compound Documents and Sparse Fieldsets, the client is able to specify the data it needs, reducing the number of HTTP requests and the size and time involved in generating the response.

Because this functionality is specified by the JSON API, we're able to build this into our server application in a consistent way for clients, improving the API experience through consistency and performance.
