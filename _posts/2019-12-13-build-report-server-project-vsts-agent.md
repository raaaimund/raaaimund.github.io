---
layout:     post
title:      Build Report Server Project with VSTS build agent
date:       2019-12-13 04:20
author:     Raimund Rittnauer
description:    How to install all required services to build a .rptproj project
categories: tech
comments: true
tags:
 - ssrs
 - report
 - vsts
---

To build a Report Server Project (.rptproj) with your VSVS build agent, you first have to install the required services like the following error message during a build describes

> ##[error]MyReport.rptproj(60,3): Error MSB4019: The imported project "C:\Program Files (x86)\MSBuild\Reporting Services\Microsoft.ReportingServices.MSBuilder.targets" was not found. Confirm that the path in the <Import> declaration is correct, and that the file exists on disk.

So we are missing _Microsoft.ReportingServices.MSBuilder.targets_ on the machine of our build agent. We use a self hosted vsts build agent running on a virtual machine with Windows 10 and Visual Studio 2019 Community installed.

To let Visual Studio 2019 (on the machine of our build agent) install all requirements you have to add one workload and install one extension.

## Workload Data storage and processing

You have to add the workload __Data storage and processing__ to Visual Studio 2019.

![workload][workload]

## Extension Microsoft Reporting Services Project

And install the extension [__Microsoft Reporting Services Project__][1]{:target="_blank"} from the Visual Studio Marketplace.

[1]: https://marketplace.visualstudio.com/items?itemName=ProBITools.MicrosoftReportProjectsforVisualStudio
[workload]: {{ site.baseurl }}/assets/img/2019-12-13-build-report-server-project-vsts-agent/workload.png "workload"