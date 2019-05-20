---
layout:     post
title:      EU Election 2019 in Austria
date:       2019-05-19 18:00:00
author:     Raimund Rittnauer
summary:    Just some bar plots using the data of the applicants from parties in Austria
categories: tech
comments: true
tags:
 - eu election 2019
 - plot
 - R
---

Some bar plots with the data from the applicants for the EU election from parties in Austria. You can find the data on the [BMI][1]{:target="_blank"} website.
All the files I found were PDFs ... so I had to somehow convert the PDFs into a format that I could use for the following bar plots.

Here are the converted files of the parties (tab-separated text file)

* [EUROPA][2]{:target="_blank"}
* [FPÖ][3]{:target="_blank"}
* [Grüne][4]{:target="_blank"}
* [KPÖ][5]{:target="_blank"}
* [NEOS][6]{:target="_blank"}
* [ÖVP][7]{:target="_blank"}
* [SPÖ][8]{:target="_blank"}

and the [.Rmd file][9]{:target="_blank"} containing the code for the plots.

## average age

![avgage][avgage]

## all those titles

![titles][titles]

## students

![students][students]

## IT girls & guys

![itgng][itgng]

## KiwaraRinnen

![kiwararinnen][kiwararinnen]

## teachers

![teachers][teachers]

## retired girls & guys

![retired][retired]

## farmer

![farmer][farmer]

## consultant

![consultant][consultant]

## from vienna

![fromvienna][fromvienna]

## from burgenland

![frombgld][frombgld]

[1]: https://www.bmi.gv.at/412/Europawahlen/Europawahl_2019/start.aspx#pk_04
[2]: {{ site.baseurl }}/assets/blog-files/eu2019/EUROPA.txt
[3]: {{ site.baseurl }}/assets/blog-files/eu2019/FPOE.txt
[4]: {{ site.baseurl }}/assets/blog-files/eu2019/GRUENE.txt
[5]: {{ site.baseurl }}/assets/blog-files/eu2019/KPOE.txt
[6]: {{ site.baseurl }}/assets/blog-files/eu2019/NEOS.txt
[7]: {{ site.baseurl }}/assets/blog-files/eu2019/OEVP.txt
[8]: {{ site.baseurl }}/assets/blog-files/eu2019/SPOE.txt
[9]: {{ site.baseurl }}/assets/blog-files/eu2019/eu2019.Rmd

[avgage]: {{ site.baseurl }}/assets/img/eu2019/avgage.png "average age"
[consultant]: {{ site.baseurl }}/assets/img/eu2019/consultant.png "consultant"
[farmer]: {{ site.baseurl }}/assets/img/eu2019/farmer.png "farmer"
[frombgld]: {{ site.baseurl }}/assets/img/eu2019/frombgld.png "from burgenland"
[fromvienna]: {{ site.baseurl }}/assets/img/eu2019/fromvienna.png "from vienna"
[itgng]: {{ site.baseurl }}/assets/img/eu2019/itgng.png "it girls & guys"
[kiwararinnen]: {{ site.baseurl }}/assets/img/eu2019/kiwararinnen.png "kiwararinnen"
[retired]: {{ site.baseurl }}/assets/img/eu2019/retired.png "retired"
[students]: {{ site.baseurl }}/assets/img/eu2019/students.png "students"
[teachers]: {{ site.baseurl }}/assets/img/eu2019/teachers.png "teachers"
[titles]: {{ site.baseurl }}/assets/img/eu2019/titles.png "academic titles"