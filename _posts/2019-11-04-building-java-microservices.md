---
layout: post
title: "Building Java Microservices at Groupon"
tags: [Java, Programming, Open Source]
date: 2019-11-04
comments: true
---

The purpose of this article is to link some of the tools we use to build Java microservices at Groupon.

Groupon started as a Ruby on Rails shop and continues to use it, but not as the primary choice for a new microservice. Some of the tooling like Capistrano and the selection of Dropwizard as a building block framework can be linked to the usage of Ruby on Rails in the past.

### Language, Frameworks, Third-Party Libraries

* Java 8 (or Java 11) as the JVM language. I think [Kotlin](https://kotlinlang.org/) is cool but we don't use it.
* [Dropwizard](https://www.dropwizard.io/) as a framework to build API/REST microservices with Java
* [JDBI](http://jdbi.org/) for database object relational mapping. We use PostgreSQL.
* [Flyway DB Migrations](https://flywaydb.org/) for incremental database migrations
* [Quartz Job Scheduler](http://www.quartz-scheduler.org/) for background jobs
* [OkHttp](https://square.github.io/okhttp/) for http clients and a mock web server
* [Immutables](https://github.com/immutables/immutables/) for building immutable objects
* [Google Guava](https://github.com/google/guava) for immutable collections (`Map`, `Set`, `List` etc.)
* [JsonPath](https://github.com/json-path/JsonPath) for querying JSON files
* [Simple Java Mail](http://www.simplejavamail.org) for sending emails


### Editor

* [IntelliJ IDEA](https://www.jetbrains.com/idea/) as the IDE


### Build and Code Analysis

* Maven
  * Building the project
  * Other tasks like [PMD Static Code Analyzer](https://pmd.github.io/)
* [JaCoCo Java Code Coverage](https://www.jacoco.org/jacoco/trunk/index.html)


### Testing

* [JUnit](https://junit.org/) as the primary test assertions library
* [JSONassert](https://github.com/skyscreamer/JSONassert) assertions within JSON files
* [OkHttp](https://square.github.io/okhttp/) for a [MockWebServer](https://github.com/square/okhttp/tree/master/mockwebserver)
* Wiser for SMTP email verification testing
* [Mockito](https://site.mockito.org/) for unit test mocking

### Deployment

For deployment we use both [Capistrano](https://capistranorb.com/) and a custom internal promotion-based deployment method.

### Service Discovery

Services have generated API documentation with [Swagger](https://swagger.io/). A custom web application provides a directory of all services, where attributes of the services such as the owner or email list are driven from YAML configuration files.

