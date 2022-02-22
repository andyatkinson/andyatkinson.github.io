---
layout: page
permalink: /infrastructure
title: Infrastructure
---


## Kubernetes and Terraform

This page will list Kubernetes and Terraform tips and tricks.



### View the config map

Environment variables may be stored in the config map

`kubectl get cm <key> -n <namespace>`

To format the content for easier viewing:

`kubectl get cm <key> -n <namespace> -o json | jq`


### Restart deployment

Rolling restart of the pods

`kubectl rollout restart deploy -n <namespace> <name>`
