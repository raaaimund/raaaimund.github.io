---
layout:     post
title:      Monitor your internet speed with Docker
date:       2020-04-29 08:23
author:     Raimund Rittnauer
description:    Monitor your internet speed with speedtest.net cli, InfluxDB, Telegraf and visualise it with Grafana
categories: tech
comments: true
tags:
 - docker
 - grafana
 - influxdb
 - telegraf
---

Monitor your internet speed with [speedtest.net][1]{:target="_blank"}, [Grafana][2]{:target="_blank"}, [Telegraf][3]{:target="_blank"}, [InfluxDB][4]{:target="_blank"} and [Docker][5]{:target="_blank"}.

All source code is available on [GitHub][7]{:target="_blank"}

After running 

```
docker-compose up
```

Docker starts the following services

* influxdb
    * store for our speed test results
* speedtester
    * schedules a cron job for running a speed test using the [speedtest.net cli][6]{:target="_blank"} every five minutes and appends the results to a csv file
    * you can change the specified server and interval in the corresponding Dockerfile.
* telegraf
    * reads the tail of the csv file with the results and sends them to influxdb
* grafana
    * visualises our results on a simple preconfigured dashboard
    * default credentials are admin:admin

[1]: https://www.speedtest.net/
[2]: https://grafana.com/
[3]: https://www.influxdata.com/time-series-platform/telegraf/
[4]: https://www.influxdata.com/
[5]: https://www.docker.com/
[6]: https://www.speedtest.net/apps/cli
[7]: https://github.com/raaaimund/internet-speed-monitor