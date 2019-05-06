---
layout:     post
title:      Backup and restore GitLab on k8s
date:       2018-10-21 21:00:00
author:     Raimund Rittnauer
summary:    How to backup and restore GitLab on k8s
categories: tech
thumbnail:  university
comments: true
tags:
 - gitlab
 - k8s
---

## backup

Default location of backups is /var/opt/gitlab/backups.

```
kubectl exec -t <name of pod> gitlab-rake gitlab:backup:create
```

Get your backup.

````
kubectl cp <name of pod>:/var/opt/gitlab/backups/<name of backup> .
````

Also backup your secrets.

```
kubectl cp <name of pod>:/etc/gitlab/gitlab-secrets.json .
```

## restore

The backup tarball has to be available in the backup location (default location is /var/opt/gitlab/backups).

```
kubectl cp <name of backup> <name of pod>:/var/opt/gitlab/backups
```

The git user has to be owner of the tarball.

```
kubectl exec -it <name of pod> chown git:git /var/opt/gitlab/backups/<name of backup>
```

Run the restore task.

```
kubectl exec -it <name of pod> gitlab-rake gitlab:backup:restore
```

Next, restore /etc/gitlab/gitlab-secrets.json.

```
kubectl cp gitlab-secrets.json <name of pod>:/etc/gitlab/gitlab-secrets.json
```

Source: [gitlab docs][1]{:target="_blank"}

[1]: https://docs.gitlab.com/ee/raketasks/backup_restore.html