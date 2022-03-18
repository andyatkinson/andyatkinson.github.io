---
layout: page
permalink: /infrastructure
title: Infrastructure
---

## Guidance

* [Twelve-Factor App](https://12factor.net/)


## Kubernetes, Terraform, Helm

This page will list Kubernetes, Terraform, and Helm tips and tricks.

This is the stack that I have used at a couple of companies and it has some great features:

* Rolling updates of new code to pods. Guide: [Performing a Rolling Update](https://kubernetes.io/docs/tutorials/kubernetes-basics/update/update-intro/)
* Fast release rollbacks with Helm. Guide: [Helm Rollback](https://helm.sh/docs/helm/helm_rollback/)
* Environment variables management with [Kubernetes ConfigMap](https://kubernetes.io/docs/concepts/configuration/configmap/)


### View the config map

Environment variables may be stored in the config map

`kubectl get cm <key> -n <namespace>`

To format the content for easier viewing:

`kubectl get cm <key> -n <namespace> -o json | jq`


### Restart deployment

Rolling restart of the pods

`kubectl rollout restart deploy -n <namespace> <name>`


### Quick Rollbacks

With Helm, we can roll back a release quickly.

`helm rollback <release> -n <namespace>`

To list releases:

`helm list`


### Get Pods

`kubectl get pods -n <namepsace>`

### Rails console on pod

`kubectl -it exec -n <namespace> <podname> -- bundle exec rails c`

