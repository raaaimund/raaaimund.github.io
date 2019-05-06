---
layout:     post
title:      Useful Docker Commands
date:       2016-06-06 14:34:57
author:     Raimund Rittnauer
summary:    Collection of some useful Docker commands
categories: tech
thumbnail:  code
comments: true
tags:
 - docker
 - shell
 - bash
---

### Remove containers and images
[snippet by crosbymichael][1]{:target="_blank"}
{% highlight ruby %}
#!/bin/bash
# Delete all containers
docker rm $(docker ps -a -q)
# Delete all images
docker rmi $(docker images -q)
{% endhighlight %}

### Bash into a container
{% highlight ruby %}
docker exec -i -t CONTAINERNAME bash
{% endhighlight %}

### Alias to get IP
{% highlight ruby %}
alias dip="docker inspect --format '{% raw %}{{ .NetworkSettings.IPAddress }}{% endraw %}'"
{% endhighlight %}

[1]: https://github.com/docker/docker/issues/928#issuecomment-23538307