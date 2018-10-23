---
layout:     post
title:      Install Kubernetes dashboard
date:       2018-23-10 22:00:00
author:     Raimund Rittnauer
summary:    How to install the Kubernetes dashboard
categories: tech
thumbnail:  university
tags:
 - k8s
 - kubernetes
 - dashboard
---

This post summarizes the steps from the official [Kubernetes dashboard git repo][1]{:target="_blank"}.

At first we have to deploy the dashboard on our cluster.

````
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard.yaml
````

To run the proxy for accessing the dasboard run the following command. You can use the _--address_ and _--port_ flag for changing ip and port bindings. _127.0.0.1_ and _8001_ are anyway the default values.

````
kubectl proxy --address 127.0.0.1 --port 8001
````

Now you can access the dasboard at _http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/_.

Note that the dashboard is only availabe via localhost because it will not be possible to sign in. See the [documentation on github][2]{:target="_blank"}.

<blockquote>
NOTE: Dashboard should not be exposed publicly using kubectl proxy command as it only allows HTTP connection. For domains other than localhost and 127.0.0.1 it will not be possible to sign in. Nothing will happen after clicking Sign in button on login page.
</blockquote>

You can access the dashboard using a secure tunnel.

````
sh -L 8001:127.0.0.1:8001 -N username@192.168.1.254
````

To sign in we need to create a service accout and a role binding.

__admin-user.yaml__
````
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kube-system
````

````
kubectl create -f admin-user.yaml
````

__cluster-role-binding.yaml__
````
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kube-system
````

````
kubectl create -f cluster-role-binding.yaml
````

You can get the token with the following command.

````
kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep admin-user | awk '{print $1}')
````

For more details about creating a service accound and a cluster role binding see the [documentation on github][3]{:target="_blank"}.

[1]: https://github.com/kubernetes/dashboard
[2]: https://github.com/kubernetes/dashboard/wiki/Accessing-Dashboard---1.7.X-and-above#kubectl-proxy
[3]: https://github.com/kubernetes/dashboard/wiki/Creating-sample-user