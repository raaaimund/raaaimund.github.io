---
layout:     post
title:      Merge on-premise with existing Azure AD user
date:       2019-06-13 12:00:00
author:     Raimund Rittnauer
description:    How to merge an on-premise AD user with an already existing Azure AD user using hard-match (sourceAnchor/immutableID).
categories: tech
comments: true
tags:
 - azure ad
 - active directory
---

In this post i will briefly explain how to merge an on-premise AD user with an already existing Azure AD user using hard-match with the **sourceAnchor/immutableID** property.

There are [two methods][1]{:target="_blank"} how Azure AD Connect will match existing users.

> When you install Azure AD Connect and you start synchronizing, the Azure AD sync service (in Azure AD) does a check on every new object and try to find an existing object to match. There are three attributes used for this process: **userPrincipalName**, **proxyAddresses**, and **sourceAnchor/immutableID**.

### Soft-Match

Soft-Match will use the properties **userPrincipalName** and **proxyAddresses** to match existing users. For the **proxyAddresses** attribute only the value with SMTP:, that is the primary email address, is used for the evaluation.

### Hard-Match

Hard-Match will use the property **sourceAnchor/immutableID**. You can only select which property is used as **sourceAnchor** during the installation of Azure AD Connect as described in their [documentation][2]{:target="_blank"}. If the selected sourceAnchor is not of type string, then Azure AD Connect Base64Encode the attribute value to ensure no special characters appear.

> By default, Azure AD Connect (version 1.1.486.0 and older) uses objectGUID as the sourceAnchor attribute. ObjectGUID is system-generated.

So we only have to set the **immutableID** property of the existing user in our Azure AD to the Base64 encoded string of the **ObjectId** of the user in our on-premise AD. If you already synchronized your Active Directory then you probably have two users with the same name in your Azure AD. Just follow the following steps to finally merge these users:

You have to execute the following *OnPrem* PowerShell commands on the machine with your on-premise AD and the *Azure* PowerShell commands via the Azure Cloud Shell. For available PowerShell commands on the Azure Active Directory PowerShell see their [documentation][3]{:target="_blank"}.

#### 1. *OnPrem*: Get ObjectId from AD User

```
$user = Get-ADUser -Filter 'Name -like "*NAME*"'
```

#### 2. *OnPrem*: immutableId = ToBase64(ObjectId)

```
$immutableid = [System.Convert]::ToBase64String($nicole.ObjectGUID.tobytearray())
$immutableid
```

#### 3. *Azure*: Remove duplicated Azure AD User

```
Remove-AzureADUser -ObjectId <objectid>
```

The following PowerShell command prints a list of all users and their *ObjectId*.

```
Get-AzureADUser
```

#### 4. *Azure*: Remove duplicated Azure AD User permanently

On the sidemenu there is a menu item called *Deleted users*. There you can select the user and permanently delete it.

#### 5. *Azure*: Set immutableId for Azure AD User

```
Set-AzureADUser -ObjectId <objectid> -ImmutableId <immutableid>
```

#### 6. *OnPrem*: Start AD Sync

```
Start-ADSyncSyncCycle -PolicyType Delta
```

Just wait some seconds and your user should get synchronized correctly.

Useful links:

* <https://support.microsoft.com/en-us/help/2641663/use-smtp-matching-to-match-on-premises-user-accounts-to-office-365>
* <https://chinnychukwudozie.com/2015/04/10/matching-an-office-365-azure-cloud-user-identity-with-an-on-premise-active-directory-user-object/>
* <https://www.codetwo.com/admins-blog/how-to-merge-an-office-365-account-with-an-on-premises-ad-account-after-hybrid-configuration/>
* <https://support.microsoft.com/en-us/help/2641663/use-smtp-matching-to-match-on-premises-user-accounts-to-office-365>
* <https://support.microsoft.com/en-nz/help/2643629/one-or-more-objects-don-t-sync-when-the-azure-active-directory-sync-to>


[1]: https://docs.microsoft.com/en-us/azure/active-directory/hybrid/how-to-connect-install-existing-tenant#sync-with-existing-users-in-azure-ad
[2]: https://docs.microsoft.com/en-us/azure/active-directory/hybrid/plan-connect-design-concepts
[3]: https://docs.microsoft.com/en-us/powershell/module/azuread/?view=azureadps-2.0#users