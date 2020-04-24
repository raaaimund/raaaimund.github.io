---
permalink:	/:categories/:year/:month/:day/:title/
layout:     post
title:      Useful Docker Commands
date:       2016-06-06 14:34:57
author:     Raimund Rittnauer
description:    Collection of some useful Docker commands
categories: tech
thumbnail:  code
comments: true
tags:
 - docker
 - shell
 - bash
---

## Remove containers and images
[snippet by crosbymichael][1]{:target="_blank"}
{% highlight ruby %}
#!/bin/bash
### Delete all containers
docker rm $(docker ps -a -q)
### Delete all images
docker rmi $(docker images -q)
{% endhighlight %}

## Bash into a container
{% highlight ruby %}
docker exec -i -t CONTAINERNAME bash
{% endhighlight %}

## Copy file from container to host

``` bash
docker cp <containerId>:/file/path/within/container /host/path/target
```

## Copy file from host to container

``` bash
docker cp /host/path/target <containerId>:/file/path/within/container
```

## Alias to get IP
{% highlight ruby %}
alias dip="docker inspect --format '{% raw %}{{ .NetworkSettings.IPAddress }}{% endraw %}'"
{% endhighlight %}

[1]: https://github.com/docker/docker/issues/928#issuecomment-23538307
