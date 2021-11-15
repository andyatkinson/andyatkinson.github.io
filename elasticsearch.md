---
layout: page
permalink: /elasticsearch
title: Elasticsearch Tuning and Tips
---

## Tuning

| Parameter | Default | |
| --- | ----------- | --- |
| index.refresh_interval | Every 1s | [Tune for indexing speed](https://www.elastic.co/guide/en/elasticsearch/reference/current/tune-for-indexing-speed.html) |


## Use Cases

### As a primary database

Elasticsearch can be used as a primary database in a way similar to a RDBMS like PostgreSQL.

The operational concerns here are more about indexing rate, search speed etc. as opposed to search results relevancy.


* [Elasticsearch as a primary database?](https://dev.to/er_dward/elasticsearch-as-a-primary-database-15a5)
* [ElasticSearch and Denormalization in Rails](https://multithreaded.stitchfix.com/blog/2015/02/25/elasticsearch-and-denormalization/)


### Resources

* [How to Improve your Elasticsearch Indexing Rate](https://opster.com/blogs/improve-elasticsearch-indexing-rate/)




### As a search engine

Elasticsearch has powerful capabilities built in for searching.

### Tools

#### Tracking searches

* [Searchjoy](https://github.com/ankane/searchjoy)
