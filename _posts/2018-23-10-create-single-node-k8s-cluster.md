---
layout:     post
title:      Create a single node Kubernetes cluster on Ubuntu 18.04.1 (Bionic Beaver) with kubeadm
date:       2018-23-10 21:00:00
author:     Raimund Rittnauer
summary:    How to create a single node Kubernetes cluster on Ubuntu 18.04.1 (Bionic Beaver) with kubeadm
categories: tech
thumbnail:  university
tags:
 - ubuntu
 - k8s
 - kubernetes
 - kubeadm
---

At first we have to install docker

````
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

sudo apt update && sudo apt install docker-ce
````

With docker installed we have to disable swap on our system as mentioned in the [changelog][1]{:target="_blank"}.

````
sudo swapoff -a

sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
````

The aforementioned command comments out all swap entries in the /etc/fstab file.

Now we have everything prepared to create a single node Kubernetes cluster (version 1.12.1) with kubeadm.

````
sudo apt-get update && sudo apt-get install -y apt-transport-https && curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -

echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list && sudo apt-get update

sudo apt install -y kubeadm  kubelet kubernetes-cni
````

With kubeadm installed we have to initialize our master. A full description is available on the [Kubernetes documentation][3]{:target="_blank"}

You can specify the Kubernetes version using the  _--kubernetes-version=v1.12.1_ flag.

A list of available versions is on their [github][2]{:target="_blank"} repo.

With the _--apiserver-advertise-address=192.168.1.254_ flag you can specify the ip address on which the Kubernetes api server listens.

A list of available flags for _kubeadm init_ is available on the [Kubernetes documentation][4]{:target="_blank"}.

````
sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=192.168.1.254 --kubernetes-version=v1.12.1
````

The end of the output should contain the command for joining other workers. It looks something like the following command.

````
kubeadm join 192.168.1.254:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash>
````

To make kubectl work for your non-root user, run the following commands.

````
mkdir $HOME/.k8s

sudo cp /etc/kubernetes/admin.conf $HOME/.k8s/

sudo chown $(id -u):$(id -g) $HOME/.k8s/admin.conf

export KUBECONFIG=$HOME/.k8s/admin.conf

echo "export KUBECONFIG=$HOME/.k8s/admin.conf" | tee -a ~/.bashrc
````

We also need to install a networking model for Kubernetes. A detailed description is available on the [Kubernetes documentatoin][5]{:target="_blank"}.

````
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/k8s-manifests/kube-flannel-rbac.yml
````

To use the master also as a worker we have to run the _kubectl taint_ command, which allows pods to be scheduled to run on the Kubernetes master server. A detailed description is available on the [Kubernetes documentation][6]{:target="_blank"}.

````
kubectl taint nodes --all node-role.kubernetes.io/master-
````

Now we have a single node Kubernetes cluster running on Ubuntu 18.04.1 (Bionic Beaver).

To install the dashboard see my other post [][7].

[1]: https://github.com/kubernetes/kubernetes/blob/master/CHANGELOG-1.8.md#before-upgrading
[2]: https://github.com/kubernetes/kubernetes/releases
[3]: https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/
[4]: https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm-init/
[5]: https://kubernetes.io/docs/concepts/cluster-administration/networking/
[6]: https://kubernetes.io/docs/concepts/configuration/taint-and-toleration/