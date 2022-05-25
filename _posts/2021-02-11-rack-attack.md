---
layout: post
title: "Throttling and Temporary Bans with Rack Attack"
tags: [Ruby, API, Programming, DevOps, Tools, Open Source, Performance]
date: 2021-02-11
comments: true
---

[Rack Attack](https://github.com/rack/rack-attack) is a Rack middleware developed at Kickstarter that can be used to throttle endpoints and temporarily ban bad actors.

The reasons to do this are to ensure overall system stability by preventing bogus requests from impacting legitimate requests.

Rack Attack uses a configurable cache to store its state information and we use Redis as the cache store.

#### Throttling use case

Recently we had a couple of simultaneous technical issues that caused a higher error rate and degraded user experience for some users.

We use a primary and replica RDBMS configuration where the replica is used for read queries. Replication lag is low, typically around 1 second. Queries that can tolerate slightly stale data will be sent to the read replica when possible.

The problems started when our database replication lag crept up to the 20 second range. The second problem was a JavaScript web client that pre-fetched pages of data from our internal API had a bug and started making repeated requests for pages of data endlessly, creating a sort of [denial-of-service attack](https://en.wikipedia.org/wiki/Denial-of-service_attack).

While various timeouts and circuit breakers are in place for resiliency, these runaway requests were causing CPU and load problems that needed to be stopped ASAP.


#### Mitigation and recovery

Enter Rack Attack! While the longer term fix was to introduce a bug fix, we were able to use Rack Attack to deploy a config change and mitigate the issue quickly.

Adding a configuration block like this one, we were able to throttle `GET` requests for a specific IP address that exceeded 60 requests in a 30 second period to a particular endpoint.

```ruby
Rack::Attack.throttle('manage/ip', :limit => 60, :period => 30.seconds) do |req|
  req.ip if req.path.match(/\/api\/manage\/foos\/\d+\/bars\?/) && req.get?
end
```

#### Temporary Ban use case

Another use case for Rack Attack is to mitigate risk on potential endpoints that may be abused by bad actors.

Recently an engineer identified an endpoint that could be used maliciously to determine if a particular email address was in the system.

Armed with knowledge about the email address a brute force login attempt could be conducted.

To mitigate that risk we can configured a temporary ban based on identifying a pattern of bad behavior using the IP address, endpoint, request time, and some parameters.

In this case we configured 50 `POST` requests in 2 minutes to this endpoint to create a ban of the IP address for 15 minutes.

```ruby
Rack::Attack::Allow2Ban.filter(ip, :maxretry => 50, :findtime => 2.minute, :bantime => 15.minutes) do
  req.path.match(/\/api\/manage\/foos\/\d+\/bars/) && req.post?
end
```

Now that this endpoint has some protections on it we can help ensure the overall resiliency of the system.
