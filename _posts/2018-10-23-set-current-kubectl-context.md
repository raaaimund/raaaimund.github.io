---
permalink:	/:categories/:year/:month/:day/:title/
layout:     post
title:      Set the current kubectl context
date:       2018-10-23 23:00:00
author:     Raimund Rittnauer
description:    How to set the current kuectl context
categories: tech
thumbnail:  university
comments: true
tags:
 - k8s
 - kubernetes
 - kubectl
---

You can get a detailed description on the [kubectl Cheat Sheet][1]{:target="_blank"}.

````
kubectl config view

kubectl config set-context development --namespace=development --cluster=kubernetes --user=kubernetes-admin

kubectl config use-context development

kubectl config current-context
````

Now all requests we make to the Kubernetes cluster using kubectl are scoped to the development namespace.

[1]: https://kubernetes.io/docs/reference/kubectl/cheatsheet/#kubectl-context-and-configuration
