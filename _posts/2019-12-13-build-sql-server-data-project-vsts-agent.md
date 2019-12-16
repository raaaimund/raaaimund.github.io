---
layout:     post
title:      Build SQL Server Data Project with VSTS build agent
date:       2019-12-13 04:20
author:     Raimund Rittnauer
description:    How to install all required services to build a .sqlproj project
categories: tech
comments: true
tags:
 - sql
 - vsts
---

To build a SQL Server Data Project (.sqlrpoj) with your VSVS build agent, you first have to install the required services like the following error message during a build describes

> ##[error]MyDataProj.sqlproj(63,3): Error MSB4019: The imported project "C:\Program Files (x86)\MSBuild\Microsoft\VisualStudio\v11.0\SSDT\Microsoft.Data.Tools.Schema.SqlTasks.targets" was not found. Confirm that the path in the <Import> declaration is correct, and that the file exists on disk.

So we are missing _Microsoft.Data.Tools.Schema.SqlTasks.targets_ on the machine of our build agent. We use a self hosted vsts build agent running on a virtual machine with Windows 10 and Visual Studio 2019 Community installed.

To let Visual Studio 2019 (on the machine of our build agent) install all requirements you just have to add one workload.

## Workload Data storage and processing

You have to add the workload __Data storage and processing__ to Visual Studio 2019.

![workload][workload]

For a solution with other versions of Visual Studio check out the [Microsoft documentation about SSDT][1]{:target="_blank"}.

[1]: https://docs.microsoft.com/en-us/sql/ssdt/download-sql-server-data-tools-ssdt?view=sql-server-ver15
[workload]: {{ site.baseurl }}/assets/img/2019-12-13-build-report-server-project-vsts-agent/workload.png "workload"