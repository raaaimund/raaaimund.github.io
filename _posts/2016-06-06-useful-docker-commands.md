---
layout:     post
title:      Useful Docker Commands
date:       2016-06-06 18:34:57
author:     Raimund Rittnauer
summary:    Collection of some useful Docker commands
categories: tech
thumbnail:  code
tags:
 - docker
 - shell
 - bash
---

## Just a collection of some useful Docker commands

### Remove containers and images
[@crosbymichael][1]{:target="_blank"}
{% highlight ruby %}
#!/bin/bash
# Delete all containers
docker rm $(docker ps -a -q)
# Delete all images
docker rmi $(docker images -q)
{% endhighlight %}

### A command I needed a lot - bash into a container
{% highlight ruby %}
docker exec -i -t CONTAINERNAME bash
{% endhighlight %}

[1]: https://github.com/docker/docker/issues/928#issuecomment-23538307