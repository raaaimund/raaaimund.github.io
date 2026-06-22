---
layout: post
title: Connecting Claude and Hermes to Penpot via MCP
date: 2026-05-07 09:00
author: Raimund Rittnauer
description: How to run the Penpot MCP server behind Traefik, fix the Vite allowedHosts reverse-proxy issue, and wire up Claude Code and Hermes as MCP clients
categories: tech
comments: true
tags:
  - homelab
  - penpot
  - mcp
  - ansible
  - traefik
  - claude
  - hermes
  - self-hosted
---

[Penpot](https://penpot.app/) ships an official MCP server (`@penpot/mcp`) that exposes your designs as tools for AI agents. This post documents how I deployed it as a Docker sidecar behind Traefik, what broke when accessed through a reverse proxy (Vite's `allowedHosts` check), and how I wired it up to both Claude Code and Hermes.

## Architecture

Penpot itself runs on `design.home.rittnauer.at`. The MCP server runs as a sidecar container on the same host and shares the internal Docker network with Penpot. Traefik routes the public subdomain `mcp.design.home.rittnauer.at` to the right backend port.

```
                    ┌──────────────────────────────────────────┐
                    │       design.home.rittnauer.at            │
                    │                                           │
  Browser           │  ┌───────────────────────────────────┐   │
  ──────────────►   │  │ penpot-frontend (port 8080)       │   │
                    │  └───────────────────────────────────┘   │
                    │                                           │
                    │  ┌───────────────────────────────────┐   │
                    │  │ penpot-mcp                        │   │
                    │  │  :4400  plugin frontend (Vite)    │   │
                    │  │  :4401  MCP HTTP / SSE server     │   │
                    │  │  :4402  WebSocket (plugin ↔ MCP)  │   │
                    │  └───────────────────────────────────┘   │
                    │                                           │
                    │  ┌───────────────────────────────────┐   │
  Claude / Hermes   │  │ Traefik                           │   │
  ──────────────►   │  │  mcp.design.home.rittnauer.at/mcp → :4401  │   │
                    │  │  mcp.design.home.rittnauer.at/ws  → :4402  │   │
                    │  │  mcp.design.home.rittnauer.at     → :4400  │   │
                    │  └───────────────────────────────────┘   │
                    └──────────────────────────────────────────┘
```

The three ports serve distinct purposes:

| Port | Purpose |
|------|---------|
| 4400 | Penpot plugin frontend — a Vite dev server that serves the in-browser plugin |
| 4401 | MCP HTTP server — SSE and message endpoints used by Claude and Hermes |
| 4402 | WebSocket — real-time channel between the in-browser Penpot plugin and the MCP server |

## Penpot Flag

The MCP server relies on Penpot's plugin system. You must enable it in `PENPOT_FLAGS`:

```yaml
penpot_flags: "enable-smtp enable-prepl-server disable-registration disable-login-with-password enable-feature-plugins"
```

Without `enable-feature-plugins`, the Penpot UI does not expose the plugin panel and the WebSocket connection from the browser plugin cannot be established.

## Docker Image

The `@penpot/mcp` package is published to npm and runs as a Node.js process. There is no official Docker image, so you build a local one.

**Dockerfile.mcp:**

```dockerfile
FROM node:22-alpine

RUN npm install -g pnpm@latest-10

WORKDIR /opt/penpot-mcp
RUN npm init -y && npm install @penpot/mcp@2.14.1

# Patch Vite plugin server: allowedHosts: [] rejects any non-localhost Host header,
# breaking reverse-proxy deployments. true disables the DNS-rebinding check.
RUN sed -i 's/allowedHosts: \[\]/allowedHosts: true/' \
      node_modules/@penpot/mcp/packages/plugin/vite.config.ts

EXPOSE 4400 4401 4402
CMD ["/opt/penpot-mcp/node_modules/.bin/penpot-mcp", "--multi-user"]
```

The `--multi-user` flag is important: it makes the server accept a `?userToken=<token>` query parameter on each request instead of requiring a single global token baked into the image. This means each user connects with their own Penpot API token.

### The allowedHosts Fix

This is the non-obvious part. When `penpot-mcp` starts, the plugin frontend (port 4400) is served by a Vite dev server. Vite has a security feature that blocks requests with a `Host` header that does not match an allowlist — this prevents DNS rebinding attacks.

The default config in `@penpot/mcp` sets `allowedHosts: []`, which rejects **all** non-localhost `Host` headers. As soon as Traefik proxies a request to port 4400 with `Host: mcp.design.home.rittnauer.at`, Vite refuses it:

```
[vite] Invalid Host header
```

The fix is to set `allowedHosts: true`, which disables the check entirely. Since the Vite server is only reachable through Traefik (not exposed directly to the internet), the DNS rebinding risk is already mitigated by the reverse proxy.

The `sed` command in the Dockerfile patches the compiled config file in place after `npm install`:

```bash
sed -i 's/allowedHosts: \[\]/allowedHosts: true/' \
  node_modules/@penpot/mcp/packages/plugin/vite.config.ts
```

## docker-compose.yml

```yaml
services:
  penpot-mcp:
    build:
      context: .
      dockerfile: Dockerfile.mcp
    image: penpot-mcp:local
    container_name: penpot-mcp
    restart: unless-stopped
    networks:
      - penpot
      - dmznet
    environment:
      PENPOT_REMOTE_MODE: "true"
      PENPOT_MCP_SERVER_HOST: "0.0.0.0"
      PENPOT_MCP_SERVER_ADDRESS: "mcp.design.home.rittnauer.at"
      PENPOT_MCP_PLUGIN_SERVER_HOST: "0.0.0.0"
      WS_URI: "wss://mcp.design.home.rittnauer.at/ws"
```

Key environment variables:

| Variable | Purpose |
|----------|---------|
| `PENPOT_REMOTE_MODE` | Enables the remote MCP mode — without this the server only accepts local connections |
| `PENPOT_MCP_SERVER_HOST` | Bind address for the MCP HTTP server (port 4401) |
| `PENPOT_MCP_SERVER_ADDRESS` | Public hostname — embedded in the plugin's connection info shown in the Penpot UI |
| `PENPOT_MCP_PLUGIN_SERVER_HOST` | Bind address for the Vite plugin frontend (port 4400) |
| `WS_URI` | WebSocket URL the browser plugin connects to — must be reachable from the user's browser |

The container needs to be on both the internal `penpot` network (to talk to `penpot-backend`) and the `dmznet` network (to be reachable by Traefik).

## Traefik Configuration

The three ports require three separate Traefik routers. The WebSocket on port 4402 gets two routes: an HTTP upgrade route for the `/ws` path (handles the initial HTTP→WebSocket handshake), and a TCP passthrough on a dedicated entrypoint (carries the upgraded WebSocket traffic).

**traefik.dynamic.yml:**

```yaml
http:
  routers:
    penpot-mcp-server:
      rule: "Host(`mcp.design.home.rittnauer.at`) && (PathPrefix(`/mcp`) || PathPrefix(`/sse`) || PathPrefix(`/messages`))"
      entrypoints:
        - websecure
      service: penpot-mcp-server
      tls:
        certResolver: letsencryptresolver
    penpot-mcp-ws:
      rule: "Host(`mcp.design.home.rittnauer.at`) && PathPrefix(`/ws`)"
      entrypoints:
        - websecure
      service: penpot-mcp-ws-http
      tls:
        certResolver: letsencryptresolver
    penpot-mcp-plugin:
      rule: "Host(`mcp.design.home.rittnauer.at`)"
      entrypoints:
        - websecure
      service: penpot-mcp-plugin
      tls:
        certResolver: letsencryptresolver

  services:
    penpot-mcp-server:
      loadBalancer:
        servers:
          - url: http://penpot-mcp:4401
    penpot-mcp-ws-http:
      loadBalancer:
        servers:
          - url: http://penpot-mcp:4402
    penpot-mcp-plugin:
      loadBalancer:
        servers:
          - url: http://penpot-mcp:4400

tcp:
  routers:
    penpot-mcp-ws:
      rule: "HostSNI(`mcp.design.home.rittnauer.at`)"
      entrypoints:
        - penpot-mcp-ws
      service: penpot-mcp-ws
      tls:
        certResolver: letsencryptresolver
  services:
    penpot-mcp-ws:
      loadBalancer:
        servers:
          - address: penpot-mcp:4402
```

The TCP router uses a dedicated Traefik entrypoint `penpot-mcp-ws` bound to port 4402. Register it in your Traefik static config (or Ansible `traefik_commands`):

```yaml
traefik_commands:
  - --entrypoints.penpot-mcp-ws.address=:4402
```

And open port 4402 on the host:

```yaml
traefik_additional_ports:
  - "4402:4402/tcp"
```

## Generating a User Token

In Penpot, go to **Profile → Access tokens → Add new token**, give it a name, and copy the generated value. This token is passed as a query parameter on every MCP request.

## Connecting Claude Code

Register the MCP server in Claude Code's settings. The MCP URL follows the pattern `https://mcp.design.home.rittnauer.at/mcp?userToken=<token>`:

```json
{
  "mcpServers": {
    "penpot": {
      "type": "sse",
      "url": "https://mcp.design.home.rittnauer.at/mcp?userToken=<your-token>"
    }
  }
}
```

Add this to `~/.claude/settings.json` (global) or `.claude/settings.json` in your project directory. After restarting Claude Code, the Penpot tools (`high_level_overview`, `execute_code`, `import_image`, `export_shape`, `penpot_api_info`) appear in the MCP tools list.

## Connecting Hermes

Hermes reads MCP server configuration from its `config.yaml`. Add a `mcp_servers` block:

```yaml
mcp_servers:
  penpot:
    url: "https://mcp.design.home.rittnauer.at/mcp?userToken=<your-token>"
    enabled: true
```

If you manage Hermes with Ansible, store the token in `host_vars` and template it in:

{% raw %}
```yaml
# host_vars/agent.home.rittnauer.at/hermes.yml
hermes_penpot_mcp_token: "<your-token>"

hermes_mcp_servers:
  penpot:
    url: "https://mcp.design.home.rittnauer.at/mcp?userToken={{ hermes_penpot_mcp_token }}"
```
{% endraw %}

{% raw %}
```jinja
# config.yaml.j2
{% if hermes_mcp_servers %}
mcp_servers:
{% for name, server in hermes_mcp_servers.items() %}
  {{ name }}:
    url: "{{ server.url }}"
    enabled: {{ server.get('enabled', true) | lower }}
{% endfor %}
{% endif %}
```
{% endraw %}

## Ansible Role Summary

The full Ansible role for Penpot has this structure:

```
roles/penpot/
├── defaults/main.yml
├── handlers/main.yml
├── tasks/main.yml
└── templates/
    ├── docker-compose.yml.j2
    └── Dockerfile.mcp.j2
```

Relevant `defaults/main.yml` variables:

{% raw %}
```yaml
penpot_mcp_enabled: false
penpot_mcp_version: "2.14.1"
penpot_mcp_public_host: "mcp.{{ public_fqdn }}"
```
{% endraw %}

The task that builds the MCP image only runs when `penpot_mcp_enabled: true`:

{% raw %}
```yaml
- name: Template Dockerfile.mcp
  ansible.builtin.template:
    src: Dockerfile.mcp.j2
    dest: "{{ penpot_base_dir }}/Dockerfile.mcp"
  when: penpot_mcp_enabled
  notify: Restart penpot
```
{% endraw %}

## Gotchas Summary

- **`enable-feature-plugins` flag is required** — without it the Penpot plugin panel is hidden and the WebSocket handshake never happens.
- **Vite `allowedHosts: []` breaks reverse proxies** — any `Host` header that is not localhost is rejected. Patch to `allowedHosts: true` in the Dockerfile after `npm install`. This is a post-install sed on the installed package's config file; it needs to be re-applied whenever the package version changes.
- **Three separate ports, three separate routers** — the MCP HTTP endpoint, the plugin frontend, and the WebSocket are each on their own port and need their own Traefik router and service entry.
- **TCP entrypoint for port 4402** — the WebSocket needs both an HTTP router (for the upgrade handshake under `/ws`) and a TCP passthrough on a dedicated Traefik entrypoint. Without the TCP router, the WebSocket connection drops after the handshake.
- **`PENPOT_REMOTE_MODE: "true"` is required** — without it the server only binds to localhost and rejects remote connections.
- **`--multi-user` flag** — without it, `penpot-mcp` expects a single hardcoded token. With `--multi-user`, each client passes `?userToken=<token>` in the URL.
- **Token scope** — the token has the same permissions as the Penpot user who created it. Use a dedicated service account if you want to limit access to specific projects.
