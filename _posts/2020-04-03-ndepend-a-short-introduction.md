---
layout:     post
title:      NDepend - a short introduction
date:       2020-04-03 04:20
author:     Raimund Rittnauer
description:    A short introduction to NDepend. A tool which definitely helps you improve your code quality.
categories: tech
comments: true
tags:
 - software quality
 - ndepend
---

## NWhat?

I am sure you love coding. Especiall if in the end your code is well written and well designed. Not only you, but also your coworker and everyone else who needs to read your code will benefit. If you are working on a small project it is maybe manageable on your own without the assistance of some special tools or something similar - very roughly said. I mean regardless of the size of the project, tools which assist you to write readable, well designed code and also force consistency are always really helpful. But it could get more difficult if you work on a large software project with a high level of collaboration. I am sure that [NDepend][1]{:target="_blank"} will provide you with very useful insights also for smaller software projects and you can benefit a lot from these insights. Actually it is a really great tool to enforce a certain level of code quality.

You should definitely give NDepend a try (there is the possibility to try NDepend for fourteen days).

## So lets try NDepend

For this step I will use NDepend with the default settings and no quality gate, rules or anything else customized to analyze a small Asp.Net Blazor project called [NoeClub][2]{:target="_blank}. It is just a small website [nö-club.at][3]{:target="_blank"} for cancelling a membership.

The installation is really simple and the first thing I noticed is that NDepend is really fast and integrates very well with Visual Studio 2019. It does not block Visual Studio during start up and the first code analysis and generation of the report took only about 15 seconds on another project with about ~11k loc.

> Because we know developer time is invaluable, NDepend is fast, very fast
>> ndepend.com

NDepend summarizes the results of the analysis on an interactive dashboard which provides a really nice overview about possible issues and insights about the quality of your code. Of course you can explore all data without leaving Visual Studio and as an alternative NDepend is also able to generate this report as HTML.

![dashboard][dashboard]

There is plenty of information and a good explanation with a detailed description and also suggestions how to fix it about every issue found in your code.

![issues][issues]

And of course also which part of your code violates this rule.

![issue-details][issue-details]

I really love the whole documentation of NDepend. Their really good [online documentation][4]{:target="_blank"} with many examples and that the tooltips in Visual Studio provide a detailed description right where you need it and also their estimation of the [technical debt][5]{:target="_blank"} for each issue.

> In this metaphor, doing things the quick and dirty way sets us up with a technical debt, which is similar to a financial debt. Like a financial debt, the technical debt incurs interest payments, which come in the form of the extra effort that we have to do in future development because of the quick and dirty design choice. We can choose to continue paying the interest, or we can pay down the principal by refactoring the quick and dirty design into the better design. Although it costs to pay down the principal, we gain by reduced interest payments in the future.
>> Martin Fowler

With this post I only covered a little bit about rules to detect issues in your code. But also just with this feature you can achieve consistency across your team and definitely improve code quality. Together with the estimation of the technical debt for each issue NDepend provides you additional insights and a good foundation for future planning.

The next days I will set up NDepend for one of my projects and integrate it in Azure DevOps.

[1]: https://www.ndepend.com/
[2]: https://dev.azure.com/rittnauer/noe-club
[3]: https://nö-club.at
[4]: https://www.ndepend.com/docs/getting-started-with-ndepend
[5]: https://www.ndepend.com/docs/technical-debt#Debt

[dashboard]: {{ site.baseurl }}/assets/img/2020-04-03-ndepend-a-short-introduction/ndepend-dashboard.png "dashboard"
[issues]: {{ site.baseurl }}/assets/img/2020-04-03-ndepend-a-short-introduction/ndepend-issues.png "issues"
[issue-details]: {{ site.baseurl }}/assets/img/2020-04-03-ndepend-a-short-introduction/ndepend-issue-details.png "issue-details"