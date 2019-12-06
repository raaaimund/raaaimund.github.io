---
layout:     post
title:      Inspect execution time for a SSRS report
date:       2019-12-05 11:57
author:     Raimund Rittnauer
summary:    Inspect execution time for SSRS report to determine slow queries
categories: tech
comments: true
tags:
 - ssrs
 - report
 - sql
---

When you render a report with [SQL Server Reporting Services][1]{:target="_blank"} by default the logs are stored in a table called _[ExecutionLogStorage][2]{:target="_blank"}_  with some views called _[ExecutionLog#][2]{:target="_blank"}_  (# is a number for backwards compatibility - use the view with the highest number) within the database _ReportServer_. Each row contains the logs for a rendered report. However this row only displays the overall time used for generating this report. If you want to know the query time for each of your data set used in your report and your sub reports you have to inspect the column _AdditionalInfo_ which is stored as XML. This column contains the following information about all your data sets used in this report and sub reports.

``` xml
<?xml version="1.0" encoding="utf-8"?>
<xs:schema id="NewDataSet" xmlns="" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:msdata="urn:schemas-microsoft-com:xml-msdata">
  <xs:element name="AdditionalInfo">
    <xs:complexType>
      <xs:sequence>
        <xs:element name="ProcessingEngine" type="xs:string" minOccurs="0" />
        <xs:element name="ScalabilityTime" minOccurs="0" maxOccurs="unbounded">
          <xs:complexType>
            <xs:sequence>
              <xs:element name="Pagination" type="xs:string" minOccurs="0" />
              <xs:element name="Processing" type="xs:string" minOccurs="0" />
            </xs:sequence>
          </xs:complexType>
        </xs:element>
        <xs:element name="EstimatedMemoryUsageKB" minOccurs="0" maxOccurs="unbounded">
          <xs:complexType>
            <xs:sequence>
              <xs:element name="Pagination" type="xs:string" minOccurs="0" />
              <xs:element name="Processing" type="xs:string" minOccurs="0" />
            </xs:sequence>
          </xs:complexType>
        </xs:element>
        <xs:element name="DataExtension" minOccurs="0" maxOccurs="unbounded">
          <xs:complexType>
            <xs:sequence>
              <xs:element name="SQL" type="xs:string" minOccurs="0" />
            </xs:sequence>
          </xs:complexType>
        </xs:element>
        <xs:element name="Connections" minOccurs="0" maxOccurs="unbounded">
          <xs:complexType>
            <xs:sequence>
              <xs:element name="Connection" minOccurs="0" maxOccurs="unbounded">
                <xs:complexType>
                  <xs:sequence>
                    <xs:element name="ConnectionOpenTime" type="xs:string" minOccurs="0" />
                    <xs:element name="DataSets" minOccurs="0" maxOccurs="unbounded">
                      <xs:complexType>
                        <xs:sequence>
                          <xs:element name="DataSet" minOccurs="0" maxOccurs="unbounded">
                            <xs:complexType>
                              <xs:sequence>
                                <xs:element name="Name" type="xs:string" minOccurs="0" />
                                <xs:element name="RowsRead" type="xs:string" minOccurs="0" />
                                <xs:element name="TotalTimeDataRetrieval" type="xs:string" minOccurs="0" />
                                <xs:element name="ExecuteReaderTime" type="xs:string" minOccurs="0" />
                              </xs:sequence>
                            </xs:complexType>
                          </xs:element>
                        </xs:sequence>
                      </xs:complexType>
                    </xs:element>
                  </xs:sequence>
                </xs:complexType>
              </xs:element>
            </xs:sequence>
          </xs:complexType>
        </xs:element>
      </xs:sequence>
    </xs:complexType>
  </xs:element>
  <xs:element name="NewDataSet" msdata:IsDataSet="true" msdata:UseCurrentLocale="true">
    <xs:complexType>
      <xs:choice minOccurs="0" maxOccurs="unbounded">
        <xs:element ref="AdditionalInfo" />
      </xs:choice>
    </xs:complexType>
  </xs:element>
</xs:schema>
```

This column stores additional information (haha) in XML format about your report. For example information about each of your DataSets in your report and sub reports.

The important nodes are _DataSet/Name_, _DataSet/RowsRead_, _DataSet/TotalTimeDataRetrieval_ and _DataSet/ExecuteReaderTime_. This column can increase in size if you use many sub reports with data sets, but luckily you can use SQL to query the XML data in this column.

Here is an example SQL to get the data from the latest rendered report with the specified _@reportPath_. The _@reportPath_ variable is the path to your report on your SSRS Server. The path is also stored in the column _ItemPath_ of the _ExecutionLog3_ view.

``` sql
USE ReportServer;

DECLARE @reportPath AS VARCHAR(MAX) = '/path/to/report';
DECLARE @AdditionalInfoXmlData AS XML;

SET @AdditionalInfoXmlData = (SELECT TOP 1 AdditionalInfo FROM ExecutionLog3 WHERE ItemPath = @reportPath ORDER BY TimeStart DESC);

SELECT DataSetName, SUM(RowsRead) RowsRead, SUM(DataRetrievalTime) DataRetrievalTime, SUM(ExecuteReaderTime) ExecuteReaderTime
FROM
   (
       SELECT Info.value('(DataSets/DataSet/Name/text())[1]', 'varchar(50)')            AS DataSetName,
              Info.value('(DataSets/DataSet/RowsRead/text())[1]', 'int')                AS RowsRead,
              Info.value('(DataSets/DataSet/TotalTimeDataRetrieval/text())[1]', 'int')  AS DataRetrievalTime,
              Info.value('(DataSets/DataSet/ExecuteReaderTime/text())[1]', 'int')       AS ExecuteReaderTime
       FROM @AdditionalInfoXmlData.nodes('/AdditionalInfo/Connections/Connection') AS DataSetInfo(Info)
   ) AS ExecutionLog3Data
GROUP BY DataSetName
ORDER BY DataRetrievalTime DESC
```

[1]: https://docs.microsoft.com/en-us/sql/reporting-services/create-deploy-and-manage-mobile-and-paginated-reports?view=sql-server-ver15
[2]: https://docs.microsoft.com/en-us/sql/reporting-services/report-server/report-server-executionlog-and-the-executionlog3-view?view=sql-server-ver15