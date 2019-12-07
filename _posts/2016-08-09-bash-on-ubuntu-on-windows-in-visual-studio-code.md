---
layout:     post
title:      Bash on Ubuntu on Windows in Visual Studio Code
date:       2016-08-09 22:30:00
author:     Raimund Rittnauer
description:    How to use Bash on Ubuntu on Windows in Visual Studio Code
categories: tech
thumbnail:  code
comments: true
tags:
 - windows 10
 - bash
 - ubuntu
 - visual studio code
---

It's very simple to change the default command line of [Visual Studio Code][1]{:target="_blank"} to the new [Bash on Ubuntu on Windows][2]{:target="_blank"}.
You just have to modify one line in your vscode user settings file.
You can open your settings file with _File -> Preferences -> User Settings_.

![Open User Settings Animated][open-user-settings-animated]{:class="image-responsive"}

All your settings are in a [JSON][3]{:target="_blank"} file and vscode will open your settings in a split screen. On the left side are the default settings
and on the right side you can overwrite specific variables of your settings file.

![User Settings Bash][user-settings-bash]{:class="image-responsive"}

On the right side you have to overwrite the _"terminal.integrated.shell.windows"_ variable with the new value _"C:\\\\Windows\\\\sysnative\\\\bash.exe"_.

{% highlight ruby %}
// Place your settings in this file to overwrite the default settings
{
    "terminal.integrated.shell.windows": "C:\\Windows\\sysnative\\bash.exe"
}
{% endhighlight %}

Now you can toggle your new bash with the following shortcut 
``
Strg + ö (German)
``
or with
``
Strg + . (English)
``

![Bash in Visual Studio Code][bash-in-vscode]{:class="image-responsive"}

Happy bashing!

### Links

- [Visual Studio Code][1]{:target="_blank"}
- [Bash on Ubuntu on Windows][2]{:target="_blank"}
- [JSON][3]{:target="_blank"}

[1]: https://code.visualstudio.com
[2]: https://msdn.microsoft.com/en-us/commandline/wsl/about
[3]: http://www.json.org/

[open-user-settings-animated]: {{ site.baseurl }}/assets/img/open-user-settings.gif "Open User Settings Animated"
[user-settings-bash]: {{ site.baseurl }}/assets/img/user-settings-bash.png "User Settings Bash"
[bash-in-vscode]: {{ site.baseurl }}/assets/img/bash-in-vscode.png "Bash in Visual Studio Code"