---
permalink:	/:categories/:year/:month/:day/:title/
layout:     post
title:      Backup and restore GitLab on Docker
date:       2018-10-04 21:00:00
author:     Raimund Rittnauer
description:    How to backup and restore GitLab on Docker
categories: tech
thumbnail:  university
comments: true
tags:
 - gitlab
 - docker
---

## backup

Default location of backups is /var/opt/gitlab/backups.

```
docker exec -t <name of container> gitlab-rake gitlab:backup:create
```

Get your backup.

````
docker cp <name of container>:/var/opt/gitlab/backups/<name of backup> .
````

Also backup your secrets.

```
docker cp <name of container>:/etc/gitlab/gitlab-secrets.json .
```

## restore

The backup tarball has to be available in the backup location (default location is /var/opt/gitlab/backups).

```
docker cp <name of backup> <name of container>:/var/opt/gitlab/backups
```

The git user has to be owner of the tarball.

```
 docker exec -it <name of container> chown git:git /var/opt/gitlab/backups/<name of backup>
```

Run the restore task.

```
docker exec -it <name of container> gitlab-rake gitlab:backup:restore
```

Next, restore /etc/gitlab/gitlab-secrets.json.

```
docker cp gitlab-secrets.json <name of pod>:/etc/gitlab/gitlab-secrets.json
```

Source: [gitlab docs][1]{:target="_blank"}

[1]: https://docs.gitlab.com/ee/raketasks/backup_restore.html
