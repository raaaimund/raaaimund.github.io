---
layout:     post
title:      Import a SQL Dump file which exceeds the maximum file size
date:       2016-08-01 21:30:00
author:     Raimund Rittnauer
summary:    Split a SQL Dump file which exceeds the maximul file size in smaller parts, to import this file in phpMyAdmin
categories: tech
thumbnail:  code
tags:
 - phpMyAdmin
 - MySQL
 - SQL-Dump
---

I had to transfer a [typo3][1]{:target="_blank"} website to a new hoster and we had some issues. One of our issue was that the maximum file size for the SQL Dump was limited to
2048 KiB. Our compressed SQL Dump file had about 9 MiB. We also had no access to the MySQL command line.

![phpMyAdmin Maximum Upload Size][phpmyadmin-maxuploadsize]{:class="image-responsive"}

At first we tried to create a dump file for each single table. The problem was that also the dump file of some tables were larger than 2048 KiB. So we tried to manually
split these large dump files into smaller files and finally we managed to import all our data.

The typo3 frontend worked, but the backend was a mess. We could not create new content, got exceptions and error messages. Something went wrong in splitting the large dump
files into smaller one.

Luckily my co-worker found a tool called [SQLDumpFileSplitter 2][2]{:target="_blank"} and with this masterpiece we could import all data and everything worked like a charm - frontend and backend! You just
have to follow these two steps

1. import DataStructure.sql first
2. import every other SQL file in the correct order


Happy splitting!

[1]: https://docs.typo3.org/typo3cms/InstallationGuide/QuickInstall/GetAndUnpack/Index.html
[2]: http://www.rusiczki.net/2007/01/24/sql-dump-file-splitter/

[phpmyadmin-maxuploadsize]: https://raw.githubusercontent.com/raaaimund/raaaimund.github.io/master/img/phpmyadmin-maxuploadsize.png "phpMyAdmin Maximum Upload Size"