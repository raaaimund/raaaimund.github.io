---
permalink:	/:categories/:year/:month/:day/:title/
layout:     post
title:      Unzip without your beloved shell
date:       2016-08-01 21:00:00
author:     Raimund Rittnauer
description:    PHP code to unzip a file
categories: tech
thumbnail:  code
comments: true
tags:
 - php
 - shell
 - unzip
 - zip
---

Sometimes you dont have access to your shell, maybe because the services of your hoster only includes ftp or whatever the reason is.
But you want to set up a clean installation environment for your brand new [typo3][1]{:target="_blank"} website and you dont want to upload
every single file from your compressed typo3 zip file.
You can unzip files with the PHP function [system][2]{:target="_blank"}. Just upload your compressed typo3 zip file to your ftp directory, 
create a php file which calls unzip, also upload this file to your ftp directory and with your browser you can execute this php file and your
zip file should be uncompressed in seconds.

_unzip.php_
{% highlight ruby %}
<?php
    system("unzip typo3.zip");
?>
{% endhighlight %}

Now you can perform a clean typo3 installation, unless you dont get problems with other php settings during your typo3 installation check.

### Links

- [typo3][1]{:target="_blank"}
- [system][2]{:target="_blank"}

[1]: https://typo3.org/download/
[2]: http://php.net/manual/en/function.system.php
