---
layout: post
title: Surge Conference 2010
date: 2010-10-10
comments: true
tags: [Conferences, Events]
---

[Surge Conference](http://omniti.com/surge/2010) was held in Baltimore, MD in September 2010, put on by [OmniTI](http://omniti.com/). Some attendees compared it to the Velocity conference which also covers web performance, scalability, and operations.

Most attendees seemed to be system administrators or work in operations, though plenty of the attendees were developers and managers. I have some rough notes from the sessions I attended.

Most of the content was new to me.

## Scalable Design Patterns
- interesting idea: add latency and see how it affects business variables in order to fund an improvement
- correlate business stats: ad-buy, convergence rates, page view time
- concept of "the cloud is a crutch" plan and report on what you really need, shouldn't ever need to spin up 1000 instances
- book recommendation "art of scalability"
- narrow write (extremely fast and few nodes), narrow-read()
- look at the financial services industry and academic paper
- messaging
producers and consumers
- CEP (complex event processing) system: esper (epl language, to provide grep like functionality on real time data stream, coming off a message queue, live feed of data (http logs, SQL slow query log))
caching
- every type of data needs its own caching policy
- don't have to pull all this data before you deliver the content

## Most Common MySQL Mistakes (Ronald Bradford)
This presenter was a database consultant with many years of experience.

- why is my site freezing? myisam storage engine uses exclusive table locks for DML (table level locks when data is manipulated), under-predictable nature due to locks in heavy reads environment

Solution: identify blocking queries, use a transactional engine....usually long reads, end user reporting tool, tool that has arbitrary queries: show processlist; (examine which query has a lock), solution is to optimize those blocking statements (indexes, limit query, summary table, change storage engine)...heavy select statements are usually aggregate queries, probably good candidates to move them to a queue or background processing

- why is my database so large? Don't put large assets in the database, or large chunks of uncompressed data that could be compressed (maximize memory usage for important data, reduce database recovery time). Compress text data, particularly with no indexes on it and when it is not searchable.
- I can't access my website: monitoring, alerting, dashboard, status site. monitoring/alerting are good but are reactive, useless for realtime analysis. Recommendation: dashboard page, sampling at 1s/3s/5s, e.g. 1% of throughput, uptime of server, latency time, number of db connections, locked, not locked, how big pages are, how many apache connections there are.
- my replication slave can't keep up: most mysql environments have a couple servers at least, writes happen on the master and are replayed on the slave, understand what the threshold is with how fast the slave can replay the writes on the master (identify the weakest link), on the slave everything is replayed in a single thread (compared with writes on the master). Have you ever performed a database recovery?, have a DR plan in place (documented, tested, timed, verified end to end). Do you pass the mysql backup quiz?
- why executing 1200 qps for 50 users? (too many queries for small number of users): duplicate, redundant, cachable, row at a time (RAT/CAT (chunk at a time)) queries, reduce the number of queries for greater scalability, (determine ahead of time what to query and ask for multiple rows instead of RAT), first goal is eliminate SQL statement if possible, otherwise optimize it. mysql binary log, writes every transaction, mysqlbinlog, tcpdump tool.
- my database is slow: evaluate the time taken in database and between application tiers. tools: httpwatch, stevesouders.com, Yahoo performance rules
- I want to add new hardware, how do I change my application to support this? Requires no code changes, to add add more hardware. API in place: one code path for business functionality, enables testability. Store results of query in cache, hates ORMs in use in Rails/hibernate because returning the whole row is unnecessary

Sharding products: akeban (automatic sharding), mysql monitoring, monyog (not free, easy to install) and cacti.

## Scaling LinkedIn
- 0-90 million techcrunch disrupt, 1,000,000 content shares per day on facebook, throw hardware at the picture
- first bottleneck, database, distributed database
- SOA: new at the time, each service can scale independently, 275 services and growing every day. Increase complexity, diminished integrity.  "eventual consistency", higher cost, unintended side effects
- read "8 fallacies of distributed computing" on wikipedia
- "pillars of infrastructure"
- data layer, most important piece (read to write ratio, range queries, consistency, derived data and caches (search index), replication, etl)
- the log, the queueing, the search, batch and etl (general business analytics), the RPC, deployment, monitoring
- pillars of a social network platform: profile, graph (associations), stream, communications, search, intelligence
- research [voldemort](http://project-voldemort.com/) and [zookeeper](http://hadoop.apache.org/zookeeper/docs/r3.1.2/zookeeperProgrammers.html)
- "read after write" consistency, you would see your own changes, but others may not see them right away
- load datasets for developers. they use lucene (search, people search) and hadoop (used for background processing, batch environment, data is transferred in, business analytics, run queries against different logs etc.).
- support public APIs, zookeeper: primarily manages clusters of servers, x86 solaris boxes, linux boxes more and more

## Facebook Operations
Tom Cook: systems engineer, tools, what does it look like, pain points. 500+ active million users (visited in less than 30 days), 80% return weekly.

- facebook data center in oregon, prineville, oregon, servers in bay area and virginia
- HipHop for PHP, memcached, over 300 terabytes of data in RAM being served
- facebook mysql patches, google has a patch set, FlashCache (performance benefits of SSD, on regular disks)
- Internal services to facebook (news feed, search, chat, ads, media)
- service implementation languages: how to talk between these systems? facebook uses thrift, glue between backends at facebook
- OS: linux, centos with a modified 2.6 kernel, facebook has a kernel team, systems management: configuration management (use the same policy for next 10-20k servers), puppet, chef, Facebook uses CFEngine (full update every 15-20 minutes) (about 1000 different rules, spread across about 100 policy files), peer reviews, internal diffs
- On-demand tools (gather some data about all the tools in my network, undo a terrible mistake), used "dsh" for this
- web push: pushed at least once per day
- code distributed via internal BitTorrent swarm (really fast)
- "engineering + operations" write test and deploy their own code
- "dark launches": had users hit endpoints for the usernames feature before it went live, get exposed to real traffic, "it is really best to expose features to real traffic at our size", "ops people embedded into the dev team", help with automation, cfengine integration, tough to prove the value to the engineers, ops people write documentation for the tools as well
- "change logging": everything that occurs in network gets logged in some way, new feature enabled, version of code on certain servers, everything is logged in to the system to correlate the performance to those events
- Ganglia: grid report, looking at aggregate server data on a dashboard page, fast (host data collected every minute, more data every 5 minutes), straightforward, nested grids and pools, store RRDs in RAM, over 5 million metrics in ganglia, ganglia for very fast viewing, what has happened in the last two minutes. internal system for historical data, usage for last minute, hour, day etc. Facebook uses Nagios configs, nagios feeds all of its alarms into aggregate internal tools
- "Scribe" (open source) high-performance logging infrastructure, built entirely on top of thrift, built as a thrift service, originally used syslog, 50TB/day through Scribe, where does this data come from? Data is loaded into Hadoop. open source map/reduce data mining, reporting, data warehouse. Want financial people to use data, "Hive" is a SQL-like syntax for Hadoop cluster
- "constant failure": data center goes offline, can't fix it, happens a lot at facebook, levels of failure impact user interaction, constant communication at facebook, IRC, lot of automated bots, internal news updates, "headers" on internal tools, change log/feeds
- heavy users of configuration management
- plan ahead, facebook.com/engineering, facebook.com/opensource

## Wikia talk
- Via twitter: Short version: GA, Varnish CDN, Riak/FS, Memcache, SSDs

## Big Data (Mike Malone)
- HD, fault tolerant, choose non-relational database
- cap theorem, PODC 2000 consistency, availability, partition tolerance, 2-phase commit pattern, acknowledgment comes after replica responds to write server
- atomicity, consistency, isolation, durability
- apache cassandra codebase, 30k lines of code
- cassandra's partitioning strategy is pluggabble, responsible for mapping a key to the node
- "space filling curve", "z-curve", can measure the distance, "sorts lexicographically in a single dimension", DHT: distributed hash table
- distributed hash-table overlay

## Get Rails to Scale
Synopsis: interesting talk by Geir Magnusson about how Gilt Groupe moved away from Rails, they needed to get away from the database due to their traffic patterns. [Gilt Groupe](http://www.gilt.com): limited availability sales from high end fashion.

- stress test/load test, http://www.soasta.com/
- zeus traffic manager: http://www.zeus.com/products/traffic-manager/
- Java in memory solution handles about 50,000 transactions per second
- Amazon DynamoDB, project voldemort is the implementation of the project, distributed key-value store designed for availability, uses consistent hashing
- vector clocks
- voldemort, get, put operations, simple operations
- "we have 400 thins" just hopeless
- "falcon fastest in a dive, swift is fastest in level flight"

## How Etsy launches features
- 96% of etsy's users are women
- continuous deployment model, small and frequent changes, deploy 10-15 times per day, architecture review, development/ops feedback loop, go or no go, launch
- built nagios talks, while it is being written
- "go or no/go meeting", operability review, contingency checklist
- "why should you be the only one to celebrate or be unhappy about feature launch"
- dark launch, cookies or whatever for staff, some subset of users
- Questions to ask in go/no go meeting: 
- is it possible to dark launch this feature? yes? do it.
- is it possible to turn on this feature for a subset of users?
- "an unmonitored box is a broken box"
- are all the lead devs, ops, etc. present for the launch meeting?
- is there a single easy place for users to provide feedback? more of a direct line into the company.
- "have all leads agreed on a post-launch time to declare if this is successful."
- "have we done a contingency checklist?"
- leaving on/off switches, they usually leave the "switches" for dark launched features in the code even after they are no longer used
- subset or dark launch initially, some period of time, a month or something, then go back and clean up and remove code that could be removed as a toggle, or maybe it is kept in there.
- "at flickr monday was the highest upload day by 40%"
- "we do the work upfront to make it safe to launch at peak", "biggest bang for the buck for the company"
- contingency checklist: what could possibly go wrong, if it does, what are we going to do about it?
- 55 developers at etsy, split up into various teams
- "the feature launched. we're on techcrunch...sorry, AOL." LOL.
- metrics, are we there yet? omg who to call if it breaks later?
- "ramping down"
- graphite metrics collection, ganglia for infrastructure, ganglia log tailer, keeps cursor on the log, can get any metric out of those log lines, as long as you're logging, there are some built-in graphs
- we use browser cookies for a/b testing for certain users to test things, if they have the cookie, they get a feature, otherwise they don't, they use A/B test framework for some of the ramp-up.  

## Chris Brown from Opscode
- Google, Amazon, Microsoft built their tools
- "most folks are unprepared for success"
- controltier, nanite, capistrano
- origin myth of ec2, "first 2 years of ec2 development happened in south africa"
- "execution service" original name, bad choice ("not that EC2 is much better")
- "design by fight club", design to lose instances
- "primitives in design" does one simple thing, does it well, "you can't outthink the customer" you are going to winnow the customer decisions, UI vs. API
- "make simple composable tools" "you can't outthink your customer, allow them to make composable tools"
- guiding principle, "simplfy"
- simple and open wins, examples: API, REST, OpenID, OAuth
- book recommendation: "the art of capacity planning"
- "admission control" "web service design vs. website design", web design wants more users to admission control is not necessarily done
- MVCC multi-version concurrency control, vector clocks, and reconciliation. don't resurrect objects.
- splunk: data porn, it is beautiful, save everything, forever 

## Ops in the Cloud
- distributed databases, CouchDB
- "what is availability?" more than uptime, who can operate on your system at a given point in time?
- probabilistic risk assessment, event tree analysis, fault tree analysis
- if a node goes bad, you attach it to a new EBS and you are good to go http://www.pingdom.com/

## Conclusion
Lots of interesting things to learn about Ops and devops, scaling, fault tolerance etc. A good conference overall.
