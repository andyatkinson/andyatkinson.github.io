---
layout: post
title: "JWT, JWK, and JWKS Oh My"
tags: [API, Programming]
date: 2021-05-12
comments: true
featured_image_thumbnail:
featured_image: /assets/images/pages/andy-atkinson-California-SF-Yosemite-June-2012.jpg
featured_image_caption: Yosemite National Park. &copy; 2012 <a href="/">Andy Atkinson</a>
featured: true
---

Authentication and authorization with JSON technologies can be a confusing mess of of acronyms, so this post is an attempt to sort these out.

Here are the technologies covered:

* JSON Web Token (JWT)
* JSON Web Key (JWK)
* JSON Web Key Set (JWKS)

### What is JWT?

JSON Web Token (RFC 7519) is an open standard, useful for Authorization and Information Exchange. JWTs represent "claims". JWTs are signed using a secret or a public/private key pair.

[Introduction to JWTs](https://jwt.io/introduction/)

Structure

* Header
* Payload
* Signature

Example:

`xxxxx.yyyyy.zzzzz`

How are they used in Authorization?

Typically using the `Authorization` HTTP request header using the `Bearer` schema, as follows:

`Authorization: Bearer <token>` 


### What is JWK?

A JSON Web Key (JWK), an IETF standard (RFC 7517), is a JSON data structure that represents a cryptographic key.

> JSON Web Key (JWK) provides a mechanism to distribute the public keys that can be used to verify JWTs. [^ruleoftech]

### What is JWKS?

JSON Web Key Set (JWKS), an IETF standard, is a set of keys containing the public keys used to verify any JSON Web Token (JWT). A JSON Web Key Set is composed of 1 or more JSON Web Keys (JWK). Each JWK represents a cryptographic public key that can be used to validate the signature of a signed JSON Web Token (JWT).

#### JWKS example

In our app we generate a JWKS pair for each service, which includes a `.pem` file and a `.json` file.

The JSON file has the following keys:

- `kty` (RSA)
- `kid` (key identifier, "alias" for the key)
- `n`
- `e`
- `kid`


#### What are they used for?

To securely transmit information between services.


#### Why are they important?

JWT and JWKS are important because they are an open, IETF, industry standard.

The signature for a JWT is calculated using the header and the payload, which means the content can be verified as having originated from the sender, and not having been tampered with.

Is this better than a browser cookie? JWT doesn't have the Cross-Origin Resource Sharing (CORS) limitation cookies do when the token is sent in the `Authorization` header.

#### PKCS12

Archive file format.

#### keytool

`keytool` is a Key and Certificate Management Tool.

`ssh-keygen`


References:

* [^ruleoftech]: <https://ruleoftech.com/2020/generating-jwt-and-jwk-for-information-exchange-between-services>
* [Auth0 Documentation](https://auth0.com/docs/tokens/json-web-tokens/json-web-key-sets)
* [JSON Web Key (JWK) RFC](https://tools.ietf.org/html/rfc7517)
* [Ruby JWT gem](https://github.com/jwt/ruby-jwt)
* [Akamai blog post on rotating JWTs utilizing JWKS](https://blogs.akamai.com/2019/10/verify-jwt-with-json-web-key-set-jwks-in-api-gateway.html)
* [JWTs? JWKs? ‘kid’s? ‘x5t’s? Oh my!](https://redthunder.blog/2017/06/08/jwts-jwks-kids-x5ts-oh-my/)


### JWT gem in ruby

Flow:

- End user logs in, gets a JWT back, JWT is sent around in header
- Interservice HTTP requests: sends public key information as part of the Authorization header, remote service knows how to verify the JWT. Remote service needs a public key associated with the sending service.
