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

My old Thinkpad T410 is now running Fedora 23 (Server Edition) where I host all my web projects and other stuff in separate Docker container.
If you use Docker, Fedora is the best joice, you install Fedora on your machine and configure everything over a nice web interface.
There is a fancy dashboard with all stats about your running containers and you also have access to the terminal in your browser.

![Docker Dashboard][fedora-dashboard]{:class="image-responsive"}

![Terminal][fedora-terminal]{:class="image-responsive"}

Finished
* Teamspeak 3 Server server.rittnauer.at. ([devalx/docker-teamspeak3][1]{:target="_blank"})
* Musicbot for Teamspeak 3 running [sinusbot][2]{:target="_blank"}. ([raaaimund/docker-sinusbot-beta][3]{:target="_blank"})
* Another bot called 'Kevin' for Teamspeak 3 running JTS3 Servermod. This bot is just for welcome messages and administrative stuff. ([raaaimund/docker-jts3servermod][4]{:target="_blank"})

In progress
* DNS tunnel with a container where Iodine is running. ([raaaimund/docker-iodine][5]{:target="_blank"})
* Cooking blog based on WordPress called kochzombie.at. ([wordpress][6]{:target="_blank"})
* Nodejs server which is listening to incoming SMS over a USB GSM Modem. The content is parsed and pushed to all connected clients.

[1]: https://hub.docker.com/r/devalx/docker-teamspeak3/
[2]: https://www.sinusbot.com/
[3]: https://hub.docker.com/r/raaaimund/docker-sinusbot-beta/
[4]: https://hub.docker.com/r/raaaimund/docker-jts3servermod/
[5]: https://hub.docker.com/r/raaaimund/docker-iodine/
[6]: https://hub.docker.com/_/wordpress/

[fedora-dashboard]: https://raw.githubusercontent.com/raaaimund/raaaimund.github.io/master/img/fedora-dashboard.jpg "Docker Dashboard"
[fedora-terminal]: https://raw.githubusercontent.com/raaaimund/raaaimund.github.io/master/img/fedora-terminal.jpg "Fedora Terminal"