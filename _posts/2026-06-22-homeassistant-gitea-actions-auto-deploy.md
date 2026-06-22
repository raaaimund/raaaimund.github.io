---
layout: post
title: Auto-deploying Home Assistant config via Gitea Actions
date: 2026-06-22 18:00
author: Raimund Rittnauer
description: How to set up a Gitea (or GitHub) Actions workflow that SSHes into a Home Assistant OS instance, runs git pull on the config directory, and fires a persistent web UI notification with a restart link when changes land
categories: tech
comments: true
tags:
  - homeassistant
  - gitea
  - homelab
  - self-hosted
  - automation
  - ci-cd
---

I keep my Home Assistant configuration in a self-hosted Gitea repository. Every time I push a change, I want HA to automatically pull it and notify me in the web UI that a restart is needed. This post documents the full setup — including several non-obvious problems with the HA SSH addon's network topology.

## Architecture

```
  git push
     │
     ▼
  Gitea repo
     │  triggers
     ▼
  Gitea Actions runner
     │  SSH into
     ▼
  root@ha.home.rittnauer.at  (HA SSH addon container)
     │  git pull /root/config
     │  curl webhook → HA core
     ▼
  Persistent notification in HA web UI
  "Config updated – [View changes] · [Restart now]"
```

## Prerequisites

- Home Assistant OS with the **Terminal & SSH** addon installed and running
- The HA config directory already tracked in a git repo with a remote pointing to your Gitea instance
- A Gitea Actions runner registered for the repository

## Step 1 — Clone the config repo on the HA host

SSH into your HA instance and clone the repo into `/root/config` (which is where HA OS mounts the config directory inside the SSH addon container):

```bash
ssh root@ha.home.rittnauer.at
cd /root
git clone ssh://repo.example.com:2222/youruser/homeassistant-config.git config
```

## Step 2 — Generate a deploy SSH key

On your workstation, generate a dedicated key pair for the Gitea runner:

```bash
ssh-keygen -t ed25519 -C "gitea-deploy" -f ~/.ssh/gitea_ha_deploy -N ""
```

Add the **public key** to the HA host's `authorized_keys`:

```bash
ssh-copy-id -i ~/.ssh/gitea_ha_deploy.pub root@ha.home.rittnauer.at
```

Add the **public key** to Gitea as a deploy key for the repository (repo → **Settings → Deploy Keys**) so the HA host can `git pull` from Gitea.

Add the **private key** as a Gitea Actions secret named `HA_SSH_PRIVATE_KEY` (repo → **Settings → Secrets → Actions**).

## Step 3 — Create the workflow

Create `.gitea/workflows/deploy.yaml` in the repository:

```yaml
name: Deploy to Home Assistant

on:
  push:
    branches:
      - main

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Pull config on Home Assistant
        run: |
          mkdir -p ~/.ssh
          echo "${{ secrets.HA_SSH_PRIVATE_KEY }}" > ~/.ssh/id_ed25519
          chmod 600 ~/.ssh/id_ed25519
          ssh -o StrictHostKeyChecking=no -i ~/.ssh/id_ed25519 root@ha.home.rittnauer.at << ENDSSH
            cd /root/config
            RESULT=\$(git pull)
            echo "\$RESULT"
            if ! echo "\$RESULT" | grep -q 'Already up to date'; then
              HA_IP=\$(curl -s http://supervisor/core/info \
                -H "Authorization: Bearer \${SUPERVISOR_TOKEN}" \
                | grep -o '"ip_address":"[^"]*"' | cut -d'"' -f4)
              curl -sf -X POST "http://\${HA_IP}:8123/api/webhook/config_git_pull_deployed" \
                -H "Content-Type: application/json" \
                -d '{"commit_url":"${{ gitea.server_url }}/${{ gitea.repository }}/commit/${{ gitea.sha }}"}' \
                -w " HTTP %{http_code}\n"
            fi
          ENDSSH
```

### Why an unquoted heredoc?

The SSH command uses `<< ENDSSH` (unquoted delimiter). This lets Gitea Actions expand `${{ gitea.sha }}` etc. before sending the script to the remote shell. Remote shell variables (`$RESULT`, `$SUPERVISOR_TOKEN`) are escaped with `\$` so they survive the local expansion and get evaluated on the HA host.

A quoted heredoc (`<< 'ENDSSH'`) would block all local expansion — fine for most variables, but then you cannot inject Gitea context values like the commit SHA into the script.

### Why not `localhost:8123`?

The **Terminal & SSH addon** runs in its own Docker container on HA OS's internal `hassio` network. When you SSH in, you are inside that container — not on the HA OS host. `localhost:8123` does not resolve to the HA core from inside the addon container.

### Why not `http://supervisor/core/api/webhook/...`?

The supervisor proxy at `http://supervisor/core/api/...` requires the `SUPERVISOR_TOKEN` for authentication. While `SUPERVISOR_TOKEN` *is* available as an environment variable in the SSH session, the supervisor returns `401` for webhook endpoints proxied this way.

The reliable solution: use the supervisor API to resolve the HA core's actual IP address, then call the core directly. HA core webhooks require no authentication.

```bash
HA_IP=$(curl -s http://supervisor/core/info \
  -H "Authorization: Bearer ${SUPERVISOR_TOKEN}" \
  | grep -o '"ip_address":"[^"]*"' | cut -d'"' -f4)
curl -X POST "http://${HA_IP}:8123/api/webhook/config_git_pull_deployed"
```

The IP (`172.30.32.1` on a typical HA OS install) is resolved dynamically each time so it stays correct across HA OS updates.

## Step 4 — Create the HA webhook automation

Add this automation to `automations.yaml`:

```yaml
- id: 'your-unique-id'
  alias: Notify config git pull deployed
  description: Creates a persistent notification when new config is pulled from git
  triggers:
    - trigger: webhook
      webhook_id: config_git_pull_deployed
      allowed_methods:
        - POST
      local_only: true
  conditions: []
  actions:
    - action: persistent_notification.create
      data:
        notification_id: config_restart_required
        title: "Config updated – restart required"
        message: >
          New configuration was pulled from git.
          [View changes]({{ trigger.json.commit_url }}) · [Restart now](/config/developer-tools/yaml)
  mode: single
```

`local_only: true` ensures the webhook only accepts calls from the local network. The `trigger.json.commit_url` variable comes from the JSON body sent by the curl call in the workflow.

The notification appears in the HA sidebar bell (🔔). Clicking "View changes" opens the commit on your Gitea instance. Clicking "Restart now" opens the HA Developer Tools YAML tab, which has the **Check configuration** and **Restart** buttons.

## Step 5 — Reload automations

After the first deploy, reload automations once so HA picks up the new webhook trigger:

**Settings → Automations & Scenes → ⋮ → Reload automations**

Subsequent deploys trigger the webhook and update the notification automatically.

## Gotchas summary

| Problem | Root cause | Fix |
|---|---|---|
| `exit code 7` (curl) | `localhost:8123` unreachable from SSH addon container | Resolve HA core IP dynamically via `supervisor/core/info` |
| `exit code 6` (curl) | Quoted heredoc + inner quotes caused curl to run on the runner, not the HA host | Use unquoted heredoc `<< ENDSSH` with `\$` escaping for remote variables |
| `HTTP 401` from supervisor proxy | Supervisor proxy requires its own auth for webhook endpoints | Call HA core directly on its IP instead of going through `http://supervisor/core/api/...` |
| Notification shows no commit link | `${{ gitea.sha }}` inside a quoted heredoc is not expanded | Use unquoted heredoc so Gitea context variables are substituted before the script is sent to SSH |

## No restart button in the web UI

HA's `persistent_notification` API only supports `title`, `message`, and `notification_id` — there is no `actions` field for custom buttons. The "Dismiss" button on every notification is hardcoded into the HA frontend.

The **Repairs** panel (Settings → System → Repairs) does support fix buttons, but its issue registry is only writable by Python integrations, not from automations or external scripts.

For web UI notifications, markdown deep links in the `message` field are the only option. Mobile companion app notifications do support full actionable buttons via `data.actions` and the `mobile_app_notification_action` event.
