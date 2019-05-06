---
layout:     post
title:      Deploy cert-manager with http validation on your Kubernetes cluster
date:       2018-10-24 20:00:00
author:     Raimund Rittnauer
summary:    How to deploy cert-manager with http validation on your Kubernetes cluster and issue certificates from letsencrypt.org
categories: tech
thumbnail:  university
comments: true
tags:
 - k8s
 - kubernetes
 - cert-manager
 - letsencrypt
---

A guide on how to get started is available on the [cert-manager documentation][1]{:target="_blank"}. In this post we deploy cert-manager on our Kubernetes cluster using helm. Afterwards we create a cluster issuer using http validation and a certificate for our domains. We will configure our cluster issuer to obtain certificates from [letsencrypt][4]{:target="_blank"}.

The recommended way is to deploy cert-manager using helm. In my [other post][2]{:target="_blank"} you can find a description how to install helm.

````
helm install --name cert-manager --namespace kube-system stable/cert-manager
````

A detailed description how to create a cluster issuer with http validation and a certificate is available on the [cert-manager documentation][3]{:target="_blank"}.

After cert-manager is deployed, we can create a cluster issuer and a certificate. For testing purposes and until everything works as expected it is recommended to use the staging environment because the production environment imposes much stricter rate limits.

Note that wildcard certificates are only supported using dns validation instead of http validation.

__cluster-issuer-stating.yaml__
````
apiVersion: certmanager.k8s.io/v1alpha1
kind: ClusterIssuer
metadata:
  name: cluster-issuer
spec:
  acme:
    email: john@doe.com
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      name: letsencrypt-staging
    http01: {}
````

````
kubectl create -f cert-manager/cluster-issuer-staging.yaml
````

The _privateKeySecretRef_ field specifies the name of the secret which is created by this cluster issuer. The specified email address and the secret is needed for authentication for the staging api.

The presence of the _http01_ field simply enables the HTTP-01 challenge for this Issuer. No further configuration is necessary or currently possible.

When it comes time to prove ownership of a domain Certbot tells the server it wants to be authorized for the domain. The server sends back a pending authorization that has a HTTP-01 challenge as one option for completing the authorization. That HTTP-01 challenge comes with a random token and Certbot takes the token and uses your ACME account private key and the token to creates a key authorization string as described in Section 8.1. The key authorization string is then put in a file identified by the random token and then placed in .well-known/acme-challenge/ for the ACME server to check.

When the ACME server sends a HTTP request to yourdomain/.well-known/acme-challenge/TOKEN it can look at the key authorization string from inside that file and validate it with the token and the public key known for your account. If it checks out then your ACME account is considered authorized to issue certificates for that domain.

Source: https://community.letsencrypt.org/t/whats-the-file-that-http-01-challenge-requires-at-challenge/42342/2

In this [document][5]{:target="_blank"} you can find a description of the HTTP Challenge.

Next step is to create a certificate for our domains.

__certificate.yaml__
````
apiVersion: certmanager.k8s.io/v1alpha1
kind: Certificate
metadata:
  name: gitlab-my-domain-com
  namespace: my-domain
spec:
  secretName: gitlab-my-domain-com-tls
  issuerRef:
    kind: ClusterIssuer
    name: cluster-issuer
  commonName: gitlab.my-domain.com
  dnsNames:
  - gitlab.my-domain.com
  - registry.my-domain.com
  acme:
    config:
    - http01: {}
      domains:
      - gitlab.my-domain.com
      - registry.my-domain.com
````

````
kubectl create -f cert-manager/certificate.yaml
````

The value of the _issuerRef.name_ field has to be the name of our cluster issuer. If you use a issuer you have to adapt the value of the _issuerRef.kind_ field.

When the certificate is issued from [letsencrypt][4]{:target="_blank"} a secret with the name specified in the _secretName_ field is created. You can use this secret in your _tls_ section of your ingress ressource.

The presence of the _http01_ has the following meaning (from the [documentation][3]{:target="_blank"}):

The fields ingress and ingressClass in the http01 stanza can be used to control how cert-manager interacts with Ingress resources:

* If the ingress field is specified, then an Ingress resource with the same name in the same namespace as the Certificate must already exist and it will be modified only to add the appropriate rules to solve the challenge. This field is useful for the GCLB ingress controller, as well as a number of others, that assign a single public IP address for each ingress resource. Without manual intervention, creating a new ingress resource would cause any challenges to fail.
* If the ingressClass field is specified, a new ingress resource with a randomly generated name will be created in order to solve the challenge. This new resource will have an annotation with key kubernetes.io/ingress.class and value set to the value of the ingressClass field. This works for the likes of the NGINX ingress controller.
* If neither are specified, new ingress resources will be created with a randomly generated name, but they will not have the ingress class annotation set.
* If both are specified, then the ingress field will take precedence.

An example for the ingress ressource.

__gitlab-ingress.yaml__
````
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: gitlab
  labels:
    app: gitlab
  annotations:
    kubernetes.io/ingress.class: "nginx"
spec:
  tls:
    - hosts:
      - gitlab.my-domain.com
      - registry.my-domain.com
      - mattermost.my-domain.com
      - prometheus.my-domain.com
      secretName: gitlab-my-domain-com-tls
  rules:
  - host: gitlab.my-domain.com
    http:
      paths:
      - path: /
        backend:
          serviceName: gitlab
          servicePort: 8005
  - host: registry.my-domain.com
    http:
      paths:
      - path: /
        backend:
          serviceName: gitlab
          servicePort: 8105
````

After creating the above Certificate, we can check whether it has been obtained successfully using the _kubectl describe_ command.

````
kubectl describe cert gitlab-my-domain-com
````

For information about ACME see this [Wikipedia post][6]{:target="_blank"}.

For information about how to use dns validation see this [GitHub repo][7]{:target="_blank"}.

[1]: https://cert-manager.readthedocs.io/en/latest/getting-started/index.html
[2]: {% post_url 2018-10-23-deploy-helm %}
[3]: https://cert-manager.readthedocs.io/en/latest/tutorials/acme/http-validation.html
[4]: https://letsencrypt.org/
[5]: https://tools.ietf.org/html/draft-ietf-acme-acme-07#section-8.3
[6]: https://en.wikipedia.org/wiki/Automated_Certificate_Management_Environment
[7]: https://github.com/joohoi/acme-dns