---
layout: page
permalink: /elasticsearch
title: Elasticsearch Tuning and Tips
---

Elasticsearch is a distributed database with an HTTP API. Here are some things I've learned. I've installed Elasticsearch version 7.x on [Mac OS via Homebrew](https://www.elastic.co/guide/en/elasticsearch/reference/current/brew.html)

## Concepts

Mapping concepts from an RDMBS can be helpful.

* Index - this is like a RDBMS table
* Document - this is like a RDBMS row
* Mapping - this is like an RDBMS DDL structure, although it can be applied upfront or later on.

### More Concepts

These concepts are specific to the architecture of [Elasticsearch and scalability](https://www.elastic.co/guide/en/elasticsearch/reference/current/scalability.html).

* Shard - A self-contained index
  * Primary shard - for indexing requests. Each document is in a primary shard. Fixed at index creation.
  * Replica shard - a copy of a primary shard. Replica shards can be added to scale search requests.
* Node - (servers) nodes serve primary or replica shards
* Cluster - a collection of nodes
* Deployment - this is [Elastic.co](https://www.elastic.co/) terminology that seems to be synonymous with cluster

## API Concepts

Elasticsearch has an HTTP API. That means HTTP verbs like `POST`, `PUT`, `GET` and `DELETE` are mapped to concepts like creating, updating, searching and deleting things.

Elasticsearch also supports a bulk API that can be used to create and delete multiple documents.


### Create Index

```
curl -XPUT 'http://localhost:9200/foo'
```

### Add Documents To Index

Create a document with id `1` in the index `foo` with a title of "My title".

```
curl -H 'Content-Type: application/json' -X POST 'localhost:9200/foo/_doc/1?pretty' -d '
                                                  {
                                                  "title": "My title"
                                                  }'
```


### Search an Index

There are various ways of querying, this is using the [Query String format](https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-query-string-query.html). We can search for the document we just put into the index.

Adding `pretty` onto the end will format the JSON output on multiple lines and with indentation.

```
curl -X GET 'localhost:9200/foo/_search?q=title:title&pretty'
```

### More Queries

* `GET /_cat/indices`
* `GET /_cat/indices/*pattern*`
* `GET /index/_search` # list top 10 documents
* `GET /index/_search -d '{"foo":"bar"}'` # some JSON search payload

Example search request with a payload via `curl`:

```
curl -H "Content-Type: application/json" "http://localhost:9200/some_index_name/_search?pretty" -d '
{
    "from": 0,
    "size": 50,
    "sort": [
    ],
    "query": {
        "bool": {
            "filter": [
            ]
        }
    }
}
'
```


## Tuning

| Parameter | Default | |
| --- | ----------- | --- |
| index.refresh_interval | Every 1s | [Tune for indexing speed](https://www.elastic.co/guide/en/elasticsearch/reference/current/tune-for-indexing-speed.html) |


## Logs

On Mac OS ES 7 via Homebrew. Tailing the log file:

`tail -f /usr/local/var/log/elasticsearch/elasticsearch_brew.log`

Running via Docker (Recommended method):

`docker run -p 9200:9200 -p 9300:9300 -e "discovery.type=single-node" docker.elastic.co/elasticsearch/elasticsearch:7.17.0`

Some activity will be logged like index creation.


## Use Cases

### As a primary database

Elasticsearch can be used as a primary database in a way similar to a RDBMS like PostgreSQL.

The operational concerns here are more about indexing rate, search speed etc. as opposed to search results relevancy.


* [Elasticsearch as a primary database?](https://dev.to/er_dward/elasticsearch-as-a-primary-database-15a5)
* [ElasticSearch and Denormalization in Rails](https://multithreaded.stitchfix.com/blog/2015/02/25/elasticsearch-and-denormalization/)


### Resources

* [How to Improve your Elasticsearch Indexing Rate](https://opster.com/blogs/improve-elasticsearch-indexing-rate/)




### As a search engine

Elasticsearch has powerful capabilities for searching.

### Tools

Some tooling in Ruby

* Tracking searches - [Searchjoy](https://github.com/ankane/searchjoy)
* Elasticsearch ORM for Ruby - [Chewy](https://github.com/toptal/chewy)
