---
layout: page
permalink: /infrastructure
title: Infrastructure
---

# Get the configmaps for the key in the given namespace

`brew install jq`


`kubectl get cm <key> -n <namespace>`

`kubectl get cm <key> -n <namespace> -o json | jq`
