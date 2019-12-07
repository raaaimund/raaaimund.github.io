---
layout:     post
title:      Access denied while deleting a print job on windows
date:       2016-08-26 20:30:00
author:     Raimund Rittnauer
description:    How to definitively delete a print job, also with access denied on windows
categories: tech
thumbnail:  print
comments: true
tags:
 - spooler
 - windows 10
 - sysadmintroubles
---

I could not delete any print jobs although I was signed in as an admin. Luckily I found an [article from Microsoft][1]{:target="_blank"} which describes in which directory the spooler stores the print jobs. Per default the print jobs are stored in 

```
%SystemRoot%\SYSTEM32\SPOOL\PRINTERS
```

Now I just had to 

```
net stop spooler
```

Go to the default directory and delete all files, then 

```
net start spooler
```

Voila, the queue is empty.

### Links

- [article from Microsoft][1]{:target="_blank"}

[1]: https://support.microsoft.com/de-de/kb/137503