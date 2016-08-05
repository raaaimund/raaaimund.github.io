---
layout:     post
title:      Hollywood on Bash on Ubuntu on Windows
date:       2016-08-05 23:30:00
author:     Raimund Rittnauer
summary:    How to install Hollywood on Bash on Ubuntu on Windows
categories: tech
thumbnail:  code
tags:
 - windows 10
 - bash
 - ubuntu
 - hollywood
---

Finally I got my [Bash on Ubuntu on Windows][1]{:target="_blank"} and the first thing I tried was [Hollywood][2]{:target="_blank"}. Thats an awesome
script which turns your lame bash into a fancy hollywood-like bash which consumes all of your CPU power.

![Bash with Hollywood][bash-hollywood]{:class="image-responsive"}

You just have to add a repository which contains the package for hollywood.

``
$ sudo apt-add-repository ppa:hollywood/ppa
``
<br>
``
$ sudo apt-get update  
``

To run hollywood you need the package [byobu][3]{:target="_blank"} (a text based window manager and terminal multiplexer) and the package hollywood.

``
$ sudo apt-get install byobu hollywood
``

To start the magic you just have to run byobu and hollywood in your bash.
![Bash with Hollywood Animated][bash-hollywood-animated]{:class="image-responsive"}

To remove byobu and hollywood from your system just use apt-get remove.

``
$ sudo apt-get remove byobu hollywood  
``

I simply <3 my new bash!

[1]: https://msdn.microsoft.com/en-us/commandline/wsl/about?f=255&MSPPError=-2147217396
[2]: https://github.com/dustinkirkland/hollywood
[3]: http://byobu.co/

[bash-hollywood]: {{ site.url }}/img/bash-hollywood.png "Bash with Hollywood"
[bash-hollywood-animated]: {{ site.url }}/img/bash-hollywood.gif "Bash with Hollywood Animated"