---
layout: post
title: Fixing CPU Throttling on a ThinkPad P14s During Jitsi Streams
date: 2026-04-30 09:00
author: Raimund Rittnauer
description: How to permanently fix Intel RAPL power limits resetting to 35W on a ThinkPad P14s causing CPU throttling during video calls
categories: tech
comments: true
tags:
  - linux
  - thinkpad
  - rapl
  - systemd
  - jitsi
  - cpu
---

During Jitsi video streams the CPU on my ThinkPad P14s was throttling badly — frame drops, lag, the works. The root cause turned out to be the Intel RAPL power limits being reset to a very low value (35W burst) by the firmware, starving the CPU of the headroom it needs for sustained load.

## What is RAPL

Intel RAPL (Running Average Power Limit) lets the OS control CPU power envelopes via the powercap sysfs interface. There are two constraints:

| Constraint | Name | Purpose |
|------------|------|---------|
| `constraint_0` | PL1 | Sustained (long-term) power limit |
| `constraint_1` | PL2 | Burst (short-term) power limit |

The limits are exposed at `/sys/class/powercap/intel-rapl:0/` and mirrored at `intel-rapl-mmio:0`. The firmware resets them on boot and on resume from sleep.

## Diagnosing the problem

```bash
cat /sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw
# 35000000  → 35W — too low
```

With PL1 at 35W the CPU cannot sustain the load of encoding and transmitting video, and the kernel's power capping kicks in to enforce the limit via frequency scaling.

## The fix

Two pieces are needed: apply the limits at boot, and re-apply them after every resume (the firmware resets them on wake).

### Boot service

Create `/etc/systemd/system/rapl-fix.service`:

```ini
[Unit]
Description=Fix ThinkPad P14s MMIO RAPL PL1 power limit
DefaultDependencies=no
After=sysinit.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'echo 55000000 > /sys/class/powercap/intel-rapl-mmio:0/constraint_0_power_limit_uw'
ExecStart=/bin/bash -c 'echo 64000000 > /sys/class/powercap/intel-rapl-mmio:0/constraint_1_power_limit_uw'
ExecStart=/bin/bash -c 'echo 55000000 > /sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw'
ExecStart=/bin/bash -c 'echo 64000000 > /sys/class/powercap/intel-rapl:0/constraint_1_power_limit_uw'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
```

Enable it:

```bash
systemctl enable --now rapl-fix.service
```

### Sleep hook

The firmware resets RAPL limits on resume. Systemd runs scripts in `/usr/lib/systemd/system-sleep/` on suspend and resume — create `/usr/lib/systemd/system-sleep/rapl-fix.sh`:

```bash
#!/bin/bash
# Re-apply RAPL power limits after resume from sleep (firmware resets them)
if [ "$1" = "post" ]; then
    sleep 2
    echo 55000000 > /sys/class/powercap/intel-rapl-mmio:0/constraint_0_power_limit_uw
    echo 64000000 > /sys/class/powercap/intel-rapl-mmio:0/constraint_1_power_limit_uw
    echo 55000000 > /sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw
    echo 64000000 > /sys/class/powercap/intel-rapl:0/constraint_1_power_limit_uw
fi
```

Make it executable:

```bash
chmod +x /usr/lib/systemd/system-sleep/rapl-fix.sh
```

The `sleep 2` gives the hardware a moment to settle before the limits are written — writing them immediately after wake occasionally fails silently.

## Verifying

```bash
# Check service status
systemctl status rapl-fix.service

# Check current limits
cat /sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw
# 55000000
cat /sys/class/powercap/intel-rapl:0/constraint_1_power_limit_uw
# 64000000
```

After applying this, Jitsi streams run without throttling.
