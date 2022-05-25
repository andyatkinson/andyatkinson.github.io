---
layout: post
title: "JWT, JWK, and JWKS Oh My"
tags: [API, Programming]
date: 2021-05-12
comments: true
---

Authentication and authorization with JSON technologies can be a confusing mess of of acronyms, so this post is an attempt to sort these out. This post including the title, is very similar to [Red Thunder: JWTs? JWKs? ‘kid’s? ‘x5t’s? Oh my!](https://redthunder.blog/2017/06/08/jwts-jwks-kids-x5ts-oh-my/). Check their post out as well which was helpful diagrams.

NOTE TO READER: This Post is in progress and being edited for technical accuracy. If you see errors please contact me.

Here are the technologies covered:

* JSON Web Token (JWT)
* JSON Web Key (JWK)
* JSON Web Key Set (JWKS)

The last two are sort of the same thing, a set of JWK structures is a JSON Web Key set.

The JWT (JSON Web Token) is passed around in an encoded form.

#### What is JWT?

JSON Web Token (RFC 7519) is an open standard, useful for Authorization and Information Exchange. JWTs represent "claims". JWTs are signed using a secret or a public/private key pair.

[Introduction to JWTs](https://jwt.io/introduction/)

JWT has the following structure.

* Header
* Payload
* Signature

These pieces are encoded and delimited by periods like in the example below.

Example:

`xxxxx.yyyyy.zzzzz`

How are they used in Authorization?

Typically the JWT encoded form is used in the `Authorization` HTTP request header. The value using the "`Bearer` schema" would look like this and have the JWT information as below.

`Authorization: Bearer <encoded JWT>` 


#### What is JWK?

A JSON Web Key (JWK), an IETF standard (RFC 7517), is a JSON data structure that represents a cryptographic key.

> JSON Web Key (JWK) provides a mechanism to distribute the public keys that can be used to verify JWTs. [^ruleoftech]

#### What is JWKS?

JSON Web Key Set (JWKS), an IETF standard, is a set of keys containing the public keys used to verify any JSON Web Token (JWT). A JSON Web Key Set is composed of 1 or more JSON Web Keys (JWK). Each JWK represents a cryptographic public key that can be used to validate the signature of a signed JSON Web Token (JWT).

#### JWKS example

In our app we generate a JWKS pair for each service, which includes a `.pem` file and a `.json` file.

The JSON file has the following keys:

- `kty` (RSA)
- `kid` (key identifier, "alias" for the key)
- `n`: the modulus for a pem file
- `e`: the exponone for a pem file


#### What are they used for?

To securely transmit information between services.


#### Why are they important?

JWT and JWKS are important because they are an open, IETF, industry standard.

The signature for a JWT is calculated using the header and the payload, which means the content can be verified as having originated from the sender, and not having been tampered with.

Is this better than a browser cookie? JWT doesn't have the Cross-Origin Resource Sharing (CORS) limitation cookies do when the token is sent in the `Authorization` header.

### Tooling

Depending on what you are doing, you may need to generate some cryptographic pair files or a SSH key. Here are some things I ran across in researching this.

#### PKCS12

Archive file format.

#### keytool

`keytool` is a Key and Certificate Management Tool.

Keytool can be used to generate a private and public key pair.

`ssh-keygen` is a tool that can be used to generate an SSH key.


### The JWT gem in ruby

In a Ruby on Rails application using JWTs for secure requests, the jwt gem may be useful. It is something we are using at work.

The flow around secure requests looks like this:

- End user logs in with their browser, gets a JWT in the response. The JWT is stored in a browser cookie. The JWT is sent for HTTP requests as a request header, with the value being read from the cookie.

For HTTP communication between back-end services without browser cookies:

Interservice HTTP requests: send public key information as part of the Authorization header, remote service knows how to verify the JWT.

Remote service needs the sending service's public key to verify the JWT.

References:

[^ruleoftech]: Rule of Tech <https://ruleoftech.com/2020/generating-jwt-and-jwk-for-information-exchange-between-services>

* [Auth0 Documentation](https://auth0.com/docs/tokens/json-web-tokens/json-web-key-sets)
* [JSON Web Key (JWK) RFC](https://tools.ietf.org/html/rfc7517)
* [Ruby JWT gem](https://github.com/jwt/ruby-jwt)
* [Akamai blog post on rotating JWTs utilizing JWKS](https://blogs.akamai.com/2019/10/verify-jwt-with-json-web-key-set-jwks-in-api-gateway.html)
* [JWTs? JWKs? ‘kid’s? ‘x5t’s? Oh my!](https://redthunder.blog/2017/06/08/jwts-jwks-kids-x5ts-oh-my/)


NOTE TO READER: This Post is in progress and being edited for technical accuracy. If you see errors please contact me.
