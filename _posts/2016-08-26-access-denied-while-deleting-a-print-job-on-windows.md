---
layout:     post
title:      Access denied while deleting a print job on windows
date:       2016-08-26 20:30:00
author:     Raimund Rittnauer
summary:    How to definitively delete a print job, also with access denied on windows
categories: tech
thumbnail:  print
tags:
 - spooler
 - windows 10
 - sysadmintroubles
---

The number one issue which distracts me from programming are calls from my co-workers that they cannot print anymore.
The printing problems are caused from little problems like the wrong printer is selected, no paper anymore, no connection
to the printer to some some more tricky problems like a corrupt print job which
is forcing the printer to restart, damaged printer components, ...

But the number one issue are print jobs from another co-worker who worked previously on this pc, could not print,
because the wrong printer was selected or whatev and just turned off the pc.

Now a different co-worker signed in and also cannot print anymore because the previous incomplete print job is blocking all new
print jobs.

This is the moment, when I am in the middle of programming and trying to solve a problem or in the middle of solving a problem when I get a call,
"Please help me, it's very serious, the printer isn't working anymore and I have to print NOW!". Okay, I have nothing serious to do, so

* Printer is online? Yes.
* Wrong printer selected? No.
* Print job is finished? No.
* Print job from different co-worker is blocking the current one? Yes.
* Delete print jobs from other co-worker. Access denied.
* Sign out, sign in as admin.
* Delete print jobs from other co-worker. Access denied.
* WINDOWS + R. cmd. Enter. net stop spooler.
* Delete print jobs from other co-worker. Access denied.
* WINDOWS + R. cmd. Enter. net start spooler.
* ...
* Google

I could not delete any print jobs although I was signed in as an admin. With google I found an [article from Microsoft][1]{:target="_blank"} which describes
in which directory the spooler stores the print jobs. Per default the print jobs are stored in 

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

Voila, the queue is empty and everyone can happily print tons and tons of important stuff again.
I am also happy, because next time I have another option on my check-why-the-printer-isn't-working-checklist.

[1]: https://support.microsoft.com/de-de/kb/137503