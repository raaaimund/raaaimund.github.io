---
layout:     post
title:      Search for sender in all mails on Exchange Server
date:       2020-03-08 04:20
author:     Raimund Rittnauer
description:    How to filter all your emails of your Exchange Server for a specific sender address
categories: tech
comments: true
tags:
 - exchange server
 - powershell
---

First of all you have to establish a PowerShell Session with your exchange server.

``` powershell
PS > $UserCredential = Get-Credential
PS > $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://mail.mymailserver.at/PowerShell/ -Authentication Kerberos -Credential $UserCredential
PS > Import-PSSession $Session -DisableNameChecking
```

Now you can access your Exchange Server with the [Exchange PowerShell Module][1]{:target="_blank"}.
_Get-Mailbox_ for example will give you a list of all available mailboxes.

``` powershell
PS > Get-Mailbox
```

If you want to search for all emails in all mailboxes which are from a specific sender address you can use the [pipe operator][2]{:target="_blank"} and the [_Search-Mailbox_][3]{:target="_blank"} command together with the [-SearchQuery][4]{:target="_blank"} parameter.

``` powershell
PS > Get-Mailbox | Search-Mailbox -SearchQuery "from: raimund@rittnauer.at" -TargetMailbox "raimund" -TargetFolder "searchresults"
```

A copy of all filtered emails is now inside a folder named _searchresults_ in the specified _raimund_ mailbox.

There is also another nice feature called [Compliance Search][5]{:target="_blank"} with the cmdlet [New-ComplianceSearch][6]{:target="_blank"}.

> The Compliance Search feature in Exchange Server allows you to search all mailboxes in your organization. Unlike In-Place eDiscovery where you can search up to 10,000 mailboxes, there are no limits for the number of target mailboxes in a single search.

This is a really nice feature especially if you want to predefine search queries and then just execute them and if you dont want to copy the search results to a folder each time.

``` powershell
PS > New-ComplianceSearch -Name "Search All-Financial Report" -ExchangeLocation all -ContentMatchQuery 'sent>=01/01/2015 AND sent<=06/30/2015 AND subject:"financial report"'
PS > Start-ComplianceSearch -Identity "Search All-Financial Report"
```

[1]: https://docs.microsoft.com/en-us/powershell/module/exchange/?view=exchange-ps
[2]: https://docs.microsoft.com/en-us/powershell/scripting/learn/understanding-the-powershell-pipeline?view=powershell-7
[3]: https://docs.microsoft.com/en-us/powershell/module/exchange/mailboxes/search-mailbox?view=exchange-ps
[4]: https://docs.microsoft.com/en-us/exchange/security-and-compliance/in-place-ediscovery/message-properties-and-search-operators
[5]: https://docs.microsoft.com/en-us/exchange/policy-and-compliance/ediscovery/compliance-search?view=exchserver-2019
[6]: https://docs.microsoft.com/en-us/powershell/module/exchange/policy-and-compliance-content-search/new-compliancesearch?view=exchange-ps