---
layout: post
title: Connect to a Kubernetes cluster using kubectl and a service account token
date: 2018-10-24 21:00:00
author: Raimund Rittnauer
summary: How to connecto to a Kubernetes cluster using kubectl and a service account token
categories: tech
thumbnail: university
comments: true
tags:
  - k8s
  - kubernetes
  - kubectl
---

A detailed description of kubectl is on the [Kubernetes documentation][1]{:target="_blank"}.

This post is the summary of an [IBM post][2]{:target="_blank"}.

At first we have to configure kubectl to connect to the api server of our cluster.

```
kubectl config set-cluster kubernetes --server=https://192.168.1.254:6443 --insecure-skip-tls-verify=true
```

Then we set the configuration for our context and the credentials.

```
kubectl config set-context context-name --cluster=cluster-name

kubectl config set-credentials kubernetes-admin --token=<token>

kubectl config set-context context-name --user=kubernetes-admin

kubectl config set-context context-name --namespace=development

kubectl config use-context context-name
```

In my post about [deploying the Kubernetes dashboard][3]{:target="_blank"} you can see an example of how to create a service account and get the token for this user.

[1]: https://kubernetes.io/docs/reference/kubectl/overview/
[2]: https://www.ibm.com/developerworks/community/blogs/fe25b4ef-ea6a-4d86-a629-6f87ccf4649e/entry/Configuring_the_Kubernetes_CLI_by_using_service_account_tokens1?lang=en

[3]: {% post_url 2018-10-23-deploy-kubernetes-dashboard %}
