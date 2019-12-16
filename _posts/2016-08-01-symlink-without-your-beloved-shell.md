---
permalink:	/:categories/:year/:month/:day/:title/
layout:     post
title:      Symlink without your beloved shell
date:       2016-08-01 09:34:57
author:     Raimund Rittnauer
description:    PHP code to create symlinks
categories: tech
thumbnail:  code
comments: true
tags:
 - php
 - shell
 - symlink
---

Sometimes you dont have access to your shell, maybe because the services of your hoster only includes ftp or whatever the reason is.
But you want to set up a clean installation environment for your [typo3][1]{:target="_blank"} website. For this step you totally need symlinks!
Luckily my PHP loving co-worker got a great tip for this specific problem.
You can create symlinks with the PHP function [symlinks][2]{:target="_blank"}. Just declare your symlinks in php file, upload the file to
your ftp directory and with your browser you have to execute this php file and your symlinks are created.

_symlinks.php_
{% highlight ruby %}
<?php
    symlink ( "typo3_src/index.php", "index.php" );
?>
{% endhighlight %}

Now you can perform a clean typo3 installation, unless you dont get problems with other php settings during your typo3 installation check.

### Links

- [typo3][1]{:target="_blank"}
- [symlinks][2]{:target="_blank"}

[1]: https://docs.typo3.org/typo3cms/InstallationGuide/QuickInstall/GetAndUnpack/Index.html
[2]: http://php.net/manual/en/function.symlink.php
