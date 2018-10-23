---
layout:     post
title:      Deploy helm on your Kubernetes cluster
date:       2018-10-23 22:55:00
author:     Raimund Rittnauer
summary:    How to deploy helm on your Kubernetes cluster
categories: tech
thumbnail:  university
tags:
 - k8s
 - kubernetes
 - helm
---

You can get a detailed description on the [helm documentation][1]{:target="_blank"}.

Install helm using _snap_.
````
sudo snap install helm --classic
````

Create a service account and a cluster role binding the user tiller.
````
kubectl create serviceaccount --namespace kube-system tiller

kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller

kubectl patch deploy --namespace kube-system tiller-deploy -p '{"spec":{"template":{"spec":{"serviceAccount":"tiller"}}}}' 
````

Initialize helm
````
helm init --upgrade --service-account tiller
````

[1]: https://docs.helm.sh/using_helm/