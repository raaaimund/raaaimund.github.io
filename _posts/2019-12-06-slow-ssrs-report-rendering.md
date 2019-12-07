---
layout:     post
title:      Slow SSRS Report Rendering
date:       2019-12-06 11:57
author:     Raimund Rittnauer
description:    Some tips to determine why a SSRS report is rendering so slow
categories: tech
comments: true
tags:
 - ssrs
 - report
 - sql
---

This post should provide you some tips to determine why a [SQL Server Reporting Services][1]{:target="_blank"} report is rendering so slow.

## Inspect your log files

> The report [execution log][2]{:target="_blank"} is stored in the report server database that by default is named ReportServer. The SQL views provide the execution log information. The "2" and "3" views were added in more recent releases and contain new fields or they contain fields with friendlier names than the previous releases.

``` sql
-- https://docs.microsoft.com/en-us/sql/t-sql/functions/cast-and-convert-transact-sql?redirectedfrom=MSDN&view=sql-server-ver15
select
     ItemPath
     , TimeStart
     , TimeEnd
     , convert(varchar, TimeEnd - TimeStart, 114) as Duration
     , convert(varchar, dateadd(ms, TimeDataRetrieval, 0), 114) as TimeDataRetrieval
     , convert(varchar, dateadd(ms, TimeProcessing, 0), 114) as TimeProcessing
     , convert(varchar, dateadd(ms, TimeRendering, 0), 114) as TimeRendering
from ExecutionLog3
order by TimeStart desc;
```

The result of this select statement are three very informative columns of the _ExecutionLog3_ view 

### TimeDataRetrieval

> Number of milliseconds spent retrieving the data.

Thats the time the SSRS sends the queries to the SQL server, the SQL server executes the queries and sends back the results to the SSRS.

### TimeProcessing

> Number of milliseconds spent processing the report.

Thats the time the SSRS gets the results and processes the data based on code and settings (sorting, filtering, ..) in this report and report elements.

### TimeRendering

> Number of milliseconds spent rendering the report.

Thats the time SSRS renders the processed data with the report elements for the specified output format (PDF, DOCX, HTML, ...).

### AdditionalInfo

I skipped this column in the select statement above, because the content is in XML format and if you have a more complex report with maybe many sub reports this could end up in a large amount of XML data.

This column stores additional information (haha) in XML format about your report. For example information about each of your DataSets in your report and sub reports. I have another [blog post][4]{:target="_blank"} about the content of this column.

But these were only four columns of the _ExecutionLog3_ view. The [Microsoft documentation][3]{:target="_blank"} covers really nearly everything what you need to know about that view and other parts of the execution log.

## Avoid select *

The projection of your select statement should only contain columns you need in your report.

## Use SQL server

Use SQL server for filtering or sorting your data to reduce _TimeProcessing_ of your report.

## Disable rendering of sub report

Just setting the visibility based on an expression does not disable rendering of a sub report. Instead pass _Nothing_ as a value for the report parameter.

For more tips there is a nice [YouTube video][5]{:target="_blank"} about performance of SSRS.

[1]: https://docs.microsoft.com/en-us/sql/reporting-services/create-deploy-and-manage-mobile-and-paginated-reports?view=sql-server-ver15
[2]: https://docs.microsoft.com/en-us/sql/reporting-services/report-server/report-server-executionlog-and-the-executionlog3-view?view=sql-server-ver15
[3]: https://docs.microsoft.com/en-us/sql/reporting-services/report-server/report-server-executionlog-and-the-executionlog3-view?view=sql-server-ver15#bkmk_executionlog3
[4]: {% post_url 2019-12-05-dataset-execution-time-for-ssrs-report %}
[5]: https://www.youtube.com/watch?time_continue=977&v=9WecPsBnBec&feature=emb_logo
