---
layout: post
title: "A Quick Look at GraphQL"
date: 2017-07-20
comments: true
tags: [JavaScript, API, Programming]
---

[GraphQL](http://graphql.org/) is a technology from Facebook, in use since 2012, that is an alternative to REST APIs, providing the ability to both query data and transport it from a server to a client.

My quick summary would be that it claims to avoid the bloat of unused REST API actions, large request payloads with unnecessary data, the complexity of API versions, endpoints, and documentation, while still providing fast server responses.

Those claims could be leveraged to move faster in development on the client side, by not having to add new endpoints, change endpoints, or make client-specific changes, such as between a mobile web browser, and a native mobile client. If query performance on the back-end is fast, and payload sizes are small, then this architecture could result in faster experiences for clients compared with the alternative. However, my guess would be that a heavily optimized endpoint would still be useful in specific cases.

I started [typing out the code samples in the GraphQL tutorial](https://github.com/andyatkinson/graphql-demo) to get more of a sense of these claimed benefits.

## Evolve the API without versions
Traditionally when adding a client feature that expects data from the server, backwards-compatibility is a goal, although certain situations require a breaking change. A new API version may be appropriate.

Unfortunately in real world apps I've seen (and been part of) massive code duplication occurs, basically copying and pasting existing code into a new namespace, and then making the relevant and typically few changes needed. This feels like a win right away because nothing breaks for deployed clients, but this has created a new maintenance problem now, where bugs may exist in particular API versions among other issues.

An alternative to versioning might be creating a new REST resource, but it is difficult to avoid duplication with this approach as well, and now there are 2 places to look for something that might be conceptually very similar. Both of these approaches work and are used commonly, but being able to avoid versioning and duplication would be very nice.

Typically my experience with new API versions are that the meaningful code changes are small relative to the overhead (duplicated code). Less code means less bugs!

## Types and fields versus endpoints
Traditionally in a REST API, we think in terms of resources, and having a endpoint for each resource. In a system with a lot of endpoint bloat, which I would define as having implemented but unused resource actions, this could cut down a lot on lines of code. Typically what we do is to make it a goal to have minimal bloat, having endpoints only for the queries the client needs specifically.

This keeps the payload small, and reduces the documentation/support burden, and of course means that the data coming back is tightly coupled to the UI. If we're adding new features, or changing an existing feature, we need new endpoints, or to modify existing endpoints, ideally preserving backwards compatibility.

Being able to skip over all of this would certainly be beneficial. GraphQL claims that as fields age, they can be deprecated.

## GraphiQL
[GraphiQL](https://github.com/graphql/graphiql) is a very interesting looking tool that is easy to add to a project. Traditionally I'd explore data via a `curl` JSON request or maybe an HTTP Client, but this can be tedious, and doesn't give me an autocomplete listing of everything available, which seems very useful.

GraphQL's claimed benefits certainly are worth looking into for a production application. It may be a way to move quickly in the earlier stages of product development. I'd keep an eye on whether the back-end query performance is acceptable. It would also be interesting to see if over time, API versions, and resource duplication could be avoided.
