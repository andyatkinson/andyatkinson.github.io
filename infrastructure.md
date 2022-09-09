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


### More Helm

- `helm list`
- `helm history monolith -n <namespace>`
- `helm lint` <https://helm.sh/docs/helm/helm_lint/>


### Get Pods

`kubectl get pods -n <namepsace>`

`kubectl exec -it deployment/<deployment-name> -n <namespace-name> -- bundle exec rails console`

### Rails console on pod

`kubectl -it exec -n <namespace> <podname> -- bundle exec rails c`

### Kubernetes Jobs

Check the history of deployments:

`kubectl rollout history deployment/frontend`

Restart specific services:

`kubectl rollout restart deploy -n <namespace> sidekiq`
`kubectl rollout restart deploy -n <namespace> <deployment-name>`

Scale a deployment:

`kubectl scale deployment <deployment-name> --replicas=2 -n service`


[Jobs](https://kubernetes.io/docs/concepts/workloads/controllers/job/)

- Jobs may be expressed in a yaml file
- Jobs may be invoked like: `kubectl apply -f /Users/anatki/Projects/project/some_cool_job.yaml -n <namespace>`

### Terraform

`terraform login` (get set up with terraform cloud)
`terraform init`
`terraform plan` (create the plan)
