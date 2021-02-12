---
layout: post
title: "Rails API Authentication with JWT"
tags: [Ruby, Rails, API]
date: 2020-06-04
comments: true
---

Authentication is a bit tricky with HTTP as it is a stateless protocol. This means that the client plays a role in identifying the user, working with the server.

Typically in a Rails web application a session cookie is set in the response after the user authenticates. Now the user can be identified via a session ID the server has created, and the browser takes care of persisting the information in the browser's cookie store, and passing it in future requests.

How do we identify a user then when there is no browser or cookie store? One solution is to use a token the server has generated that identifies the user, and pass with each request as a header.

This article is going to look at implementing this approach using the JSON Web Tokens (JWT) standard.

## JSON Web Tokens

[JSON Web Tokens](https://jwt.io/) are a standards based approach, to encode information that the client can use securely. JWTs can be signed. A signed token means that the token can be verified again on the server once the client passes it back. This might be done by hashing information that includes a unique secret the server has.

## bcrypt gem

Since the scope of JWT does not include usernamd and password authentication, we're going to bring in the [bcrypt gem](https://github.com/codahale/bcrypt-ruby) and use Rails' `has_secure_password` functionality, to store a hashed password for our users. In the example [rideshare application](https://github.com/andyatkinson/rideshare/pull/18), we set up an authentication endpoint where a username and password can be submitted.

Once the user supplies their usernamd and password, they receive a JWT formatted JSON response to use in future requests.


## jwt gem

The [jwt gem](https://github.com/jwt/ruby-jwt) is an implementation of the RFC 7519 OAuth JSON Web Token (JWT) standard. In the example application we're using it for the Ruby methods to encode and decode the tokens.

In this application, the JSON response might look like this:

```
{
  "token": "eyJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjoxMTYsImV4cCI6MTU5MTI4NTUyM30.Qo-1bBnZYN4sayW6zQ7MfcigU_8JN_X2_iMthqHIm6Q",
  "exp": "06-04-2020 10:45",
  "username": "Test U."
}
```

We have the token itself, an expiration, and the username of the user.

Once the client has the token, subsequent requests can use the `token` attribute as the value for the `Authorization` header.

Sending this via `curl` would look like this:

```
curl --location --request GET 'http://localhost:3000/api/trips/my?rider_id=110' \
--header 'Authorization: eyJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjoxMTYsImV4cCI6MTU5MTM4NjE5NH0.cpkdkJY_KaNqEe0FEI8aN9jefAbrLONVSw0uckJg3Iw'
```

Sending no `Authentication` header or sending an a token that has expired will raise an error and return a `401 Unauthorized`.

