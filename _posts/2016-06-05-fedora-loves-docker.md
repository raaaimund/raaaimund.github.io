---
layout:     post
title:      Fedora loves Docker
date:       2016-06-05 16:37:57
author:     Raimund Rittnauer
summary:    Fedora loves Docker
categories: tech
thumbnail:  heart
tags:
 - fedora
 - docker
---

Fedora definetly <i class="fa fa-heart"></i> Docker

On a sunny sunday afternoon me and my roommate were sitting in the living room, we chilled and he streamed a great video about docker.

<div class="embed-responsive embed-responsive-16by9">
  <iframe class="embed-responsive-item" width="560" height="315" src="https://www.youtube.com/embed/Q5POuMHxW-0" frameborder="0" allowfullscreen>
  </iframe>
</div>

It was fascinating, it was so less overhead and so simple to use, I wanted to give Docker a try. My roommate also recommended to use Fedora
in combination with Docker and in fact this was a really great advice. They fit so great, after i set up Fedora on my old Thinkpad I did not
spent a single minute on trying another distribution because Fedora totally rocks.

There is a fancy dashboard with all stats about your running containers
![Docker Dashboard][fedora-dashboard]{:class="image-responsive"}

and you also have access to the terminal in your browser.
![Terminal][fedora-terminal]{:class="image-responsive"}

My old Thinkpad T410 is now running Fedora 23 (Server Edition) where I host all my web projects and other stuff in separate Docker container.
If you use Docker, Fedora is the best joice, you simply install Fedora on your machine and configure everything over a nice web interface.

### Finished
* Teamspeak 3 Server server.rittnauer.at. ([devalx/docker-teamspeak3][1]{:target="_blank"})
* Musicbot for Teamspeak 3 running [sinusbot][2]{:target="_blank"}. ([raaaimund/docker-sinusbot-beta][3]{:target="_blank"})
* Another bot called 'Kevin' for Teamspeak 3 running JTS3 Servermod. This bot is just for welcome messages and administrative stuff. ([raaaimund/docker-jts3servermod][4]{:target="_blank"})
* Automated nginx reverse proxy for docker containers to address my containers with hostnames. ([jwilder/nginx-proxy][5]{:target="_blank"})

### In progress
* DNS tunnel with a container where Iodine is running. ([raaaimund/docker-iodine][6]{:target="_blank"})
* Cooking blog based on WordPress called kochzombie.at. ([wordpress][7]{:target="_blank"})
* Nodejs server which is listening to incoming SMS over a USB GSM Modem. The content is parsed and pushed to all connected clients.

### A command I needed a lot - bash into a container
{% highlight ruby %}
docker exec -i -t CONTAINERNAME bash
{% endhighlight %}

[1]: https://hub.docker.com/r/devalx/docker-teamspeak3/
[2]: https://www.sinusbot.com/
[3]: https://hub.docker.com/r/raaaimund/docker-sinusbot-beta/
[4]: https://hub.docker.com/r/raaaimund/docker-jts3servermod/
[5]: https://hub.docker.com/r/jwilder/nginx-proxy/
[6]: https://hub.docker.com/r/raaaimund/docker-iodine/
[7]: https://hub.docker.com/_/wordpress/

[fedora-dashboard]: https://raw.githubusercontent.com/raaaimund/raaaimund.github.io/master/img/fedora-dashboard.png "Docker Dashboard"
[fedora-terminal]: https://raw.githubusercontent.com/raaaimund/raaaimund.github.io/master/img/fedora-terminal.PNG "Fedora Terminal"