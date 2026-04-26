---
layout: post
title: Running a Local LLM on an Intel iGPU with llama.cpp SYCL and Hermes
date: 2026-04-26 09:00
author: Raimund Rittnauer
description: How to run Qwen3.5 on an Intel Iris Xe GPU with llama.cpp, deploy it via Ansible, and wire it up to Hermes as a homelab AI agent
categories: tech
comments: true
tags:
  - homelab
  - llm
  - ansible
  - llama.cpp
  - intel
  - sycl
  - hermes
  - self-hosted
---

This post documents how I set up a fully local LLM stack on a homelab server with an Intel Iris Xe integrated GPU: llama.cpp compiled with Intel SYCL for GPU inference, Hermes as an agentic AI assistant, and Open WebUI as the chat frontend — all deployed via Ansible.

I cover two deployment approaches: a **Docker-based** setup using LocalAI (easier to get started, more flexible multi-model), and a **host-native** setup running llama.cpp directly as a systemd service (simpler, better GPU access, easier to upgrade).

## Hardware and OS

The server (`ai.home.rittnauer.at`) runs **Ubuntu 25.10** with an Intel processor that exposes an **Iris Xe iGPU** at `/dev/dri/renderD128`. It is a Proxmox VM with PCI passthrough for the GPU. There is no discrete GPU — all inference runs on the integrated graphics.

Key constraints that shaped every decision:
- Iris Xe is a UMA (unified memory) GPU — it shares RAM with the CPU
- Intel oneAPI SYCL is the only vendor-supported GPU compute path for llama.cpp on Intel
- Memory bandwidth is the primary bottleneck for token generation

## Architecture

Both approaches expose an OpenAI-compatible HTTP API that Hermes and Open WebUI connect to.

```
                    ┌─────────────────────────────────────────┐
                    │        ai.home.rittnauer.at              │
                    │                                          │
  Browser / API     │  ┌────────────┐   ┌───────────────────┐ │
  ──────────────►   │  │ Open WebUI │   │ Traefik (proxy)   │ │
                    │  │ (Docker)   │   │ (Docker)          │ │
                    │  └─────┬──────┘   └───────────────────┘ │
                    │        │                                  │
                    │  ┌─────▼────────────────────────────┐   │
                    │  │  llama-server  (systemd, host)   │   │
                    │  │  llama.cpp + SYCL                │   │
                    │  │  model: Qwen3.5-4B.Q4_K_M.gguf  │   │
                    │  └──────────────────────────────────┘   │
                    │                                          │
  agent.home        │  ┌──────────────────────────────────┐   │
  ──────────────►   │  │  Hermes gateway (systemd, host)  │   │
                    │  │  → https://ai.home.rittnauer.at  │   │
                    │  └──────────────────────────────────┘   │
                    └─────────────────────────────────────────┘
```

## Approach 1: Docker with LocalAI

[LocalAI](https://localai.io/) is a drop-in OpenAI-compatible API server that runs in Docker and manages multiple models via a model gallery. This is the easiest starting point.

### Intel SYCL Image

LocalAI publishes pre-built Docker images with Intel oneAPI bundled. **Pin to a specific image tag** — the `master-gpu-intel` tag tracks oneAPI 2025.3 which has a GPF regression in Level Zero GPU context teardown that crashes the backend after inference:

```yaml
# Use master-sycl-f16-ffmpeg-core (oneAPI 2025.1) — stable on Iris Xe.
# master-gpu-intel uses oneAPI 2025.3 which crashes after inference
# (Level Zero GPU context teardown: libc.so.6+0x18afeb).
local_ai_image: localai/localai:master-sycl-f16-ffmpeg-core
```

### docker-compose.yml.j2

```yaml
services:
  local-ai:
    image: {{ local_ai_image }}
    container_name: local-ai
    restart: unless-stopped
    devices:
      - /dev/dri:/dev/dri
    group_add:
      - render
      - video
    environment:
      - MODELS_PATH=/build/models
      - THREADS={{ local_ai_threads }}
      - CONTEXT_SIZE={{ local_ai_context_size }}
      - GPU_LAYERS={{ local_ai_gpu_layers }}
      - GALLERIES={{ local_ai_galleries }}
{% if local_ai_api_key %}
      - API_KEY={{ local_ai_api_key }}
{% endif %}
    volumes:
      - {{ local_ai_models_dir }}:/build/models
    networks:
      - dmznet
      - default

networks:
  dmznet:
    external: true
  default:
    driver: bridge
```

### defaults/main.yml

```yaml
local_ai_base_dir: /srv/local-ai
local_ai_models_dir: /mnt/data/local-ai/models

local_ai_image: localai/localai:master-sycl-f16-ffmpeg-core

local_ai_port: 8080
local_ai_threads: 4
local_ai_context_size: 4096

# Use a large positive number, not -1. llama.cpp SYCL does not treat -1
# as "all layers" and silently falls back to CPU.
local_ai_gpu_layers: 99

local_ai_galleries: '[{"name":"localai","url":"github:mudler/LocalAI/gallery/index.yaml@master"}]'
local_ai_api_key: ""
```

### Qwen3.5 Sidecar

The bundled llama.cpp in older LocalAI images predates Qwen3.5 architecture support. The workaround is a sidecar container running a custom-built binary mounted from the host:

```yaml
  llama-server-qwen35:
    image: {{ local_ai_image }}
    container_name: llama-server-qwen35
    restart: unless-stopped
    devices:
      - /dev/dri:/dev/dri
    group_add:
      - render
      - video
    command:
      - /bin/bash
      - -c
      - |
        source /opt/intel/oneapi/setvars.sh --force 2>/dev/null
        /build/models/llama-server \
          --model /build/models/llama-cpp/models/Qwen3.5-4B.Q4_K_M.gguf \
          --port {{ local_ai_qwen35_port }} \
          --host 0.0.0.0 \
          -ngl 99 \
          --ctx-size {{ local_ai_qwen35_ctx_size }}
    volumes:
      - {{ local_ai_models_dir }}:/build/models
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:{{ local_ai_qwen35_port }}/health"]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 180s
    networks:
      - default
```

The `start_period: 180s` in the healthcheck matters: the LocalAI image has a built-in healthcheck on port 8080, and the sidecar's model warmup takes up to 2 minutes on first start. Without a long start_period, Docker marks the container unhealthy before the model finishes loading.

### Traefik Dynamic Config (LocalAI)

```yaml
http:
  routers:
    local-ai:
      rule: Host(`api.{{ fqdn }}`)
      service: local-ai
      tls:
        certResolver: letsencryptresolver
  services:
    local-ai:
      loadBalancer:
        servers:
          - url: http://local-ai:8080
```

### Open WebUI with Two Backends

When running the main LocalAI plus the Qwen3.5 sidecar, wire both into Open WebUI via semicolon-separated URLs:

```yaml
environment:
  - OPENAI_API_BASE_URLS=http://local-ai:8080/v1;http://llama-server-qwen35:8081/v1
  - OPENAI_API_KEYS=;
  - ENABLE_OLLAMA_API=false
  - ENABLE_API_KEYS=true
```

Both containers need to be on the same Docker network as Open WebUI.

---

## Approach 2: llama.cpp Directly on the Host

Running llama.cpp natively as a systemd service removes the Docker layer entirely. This simplifies the GPU device access path and makes the oneAPI version fully explicit and upgradeable.

### oneAPI Version Selection

This is the most critical decision. The Intel oneAPI toolchain has version-specific issues:

| Version | Status |
|---------|--------|
| 2025.1 | Stable, but llama.cpp commits after mid-2025 reference `intel_gpu_bmg_g31` and `intel_gpu_wcl` GPU arch symbols that were added to compiler headers in 2025.2 |
| 2025.2 | **Recommended** — stable on Iris Xe, compatible with current llama.cpp |
| 2025.3 | **Broken** — GPF crash in Level Zero GPU context teardown after inference |

Always pin the version explicitly. Never use the unversioned `intel-oneapi-compiler-dpcpp-cpp` metapackage.

### APT Repository Setup

Intel distributes its GPG keys as ASCII-armored PEM, but apt requires binary `.gpg` format. Using `get_url` or `wget` to save the key directly will result in `The key(s) in the keyring are ignored as the file has an unsupported filetype` — always pipe through `gpg --dearmor`:

```bash
curl -fsSL https://repositories.intel.com/gpu/intel-graphics.key \
  | gpg --dearmor -o /etc/apt/keyrings/intel-graphics.gpg

curl -fsSL https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB \
  | gpg --dearmor -o /etc/apt/keyrings/intel-oneapi.gpg
```

### Required Packages

```bash
apt-get install -y \
  intel-level-zero-gpu libze1 libze-dev \
  intel-oneapi-compiler-dpcpp-cpp-2025.2 \
  intel-oneapi-mkl-devel-2025.2 \
  intel-oneapi-dnnl-2025.2 \
  cmake ninja-build git
```

Note the package naming: Level Zero is split across `intel-level-zero-gpu`, `libze1`, and `libze-dev` — there is no single `level-zero` package. DNN is `intel-oneapi-dnnl-*` (with an `l`), not `intel-oneapi-dnn-*`.

### Build

```bash
source /opt/intel/oneapi/setvars.sh --force

cmake \
  -DGGML_SYCL=ON \
  -DCMAKE_C_COMPILER=icx \
  -DCMAKE_CXX_COMPILER=icpx \
  -DGGML_SYCL_F16=ON \
  -DCMAKE_BUILD_TYPE=Release \
  -GNinja \
  /opt/llama.cpp/src

ninja llama-server
```

`GGML_SYCL_F16=ON` uses FP16 SYCL kernels which are generally faster than FP32 on Iris Xe.

### Runtime Wrapper Script

systemd services cannot `source` shell scripts directly, so oneAPI environment setup needs a wrapper:

```bash
#!/usr/bin/env bash
set -euo pipefail

source /opt/intel/oneapi/setvars.sh --force >/dev/null 2>&1

export ONEAPI_DEVICE_SELECTOR=level_zero:0
export GGML_SYCL_DEVICE=0
export SYCL_CACHE_PERSISTENT=1
export ZES_ENABLE_SYSMAN=1
export UR_L0_ENABLE_RELAXED_ALLOCATION_LIMITS=1

exec /opt/llama.cpp/bin/llama-server \
  --model /mnt/data/llama-cpp/models/Qwen3.5-4B.Q4_K_M.gguf \
  --host 0.0.0.0 \
  --port 8080 \
  --ctx-size 32768 \
  --n-gpu-layers 99 \
  --threads 4 \
  --batch-size 512 \
  --ubatch-size 512 \
  --flash-attn on
```

Key environment variables:

| Variable | Purpose |
|----------|---------|
| `ONEAPI_DEVICE_SELECTOR=level_zero:0` | Force Level Zero backend, avoid OpenCL fallback |
| `GGML_SYCL_DEVICE=0` | Select the first SYCL device (the iGPU) |
| `SYCL_CACHE_PERSISTENT=1` | Cache JIT-compiled kernels to disk — avoids ~30–60s warmup on every restart |
| `ZES_ENABLE_SYSMAN=1` | Enable GPU system management (power/thermal monitoring) |
| `UR_L0_ENABLE_RELAXED_ALLOCATION_LIMITS=1` | Allow large model allocations on UMA hardware |

### systemd Service

```ini
[Unit]
Description=llama-server (llama.cpp SYCL)
After=network.target

[Service]
Type=simple
ExecStart=/opt/llama.cpp/bin/llama-server.sh
Restart=on-failure
RestartSec=10
SupplementaryGroups=render video
LimitMEMLOCK=infinity
LimitNOFILE=65536
StandardOutput=journal
StandardError=journal
SyslogIdentifier=llama-server

[Install]
WantedBy=multi-user.target
```

`SupplementaryGroups=render video` gives the service access to `/dev/dri/renderD128`. `LimitMEMLOCK=infinity` is needed for large UMA allocations.

### Ansible Role

The full role structure:

```
roles/llama-cpp/
├── defaults/main.yml
├── handlers/main.yml
├── tasks/
│   ├── main.yml
│   ├── intel-repos.yml   # APT repos + packages
│   ├── build.yml         # clone + cmake + ninja
│   ├── models.yml        # download models, verify active model
│   └── service.yml       # wrapper script + systemd unit
└── templates/
    ├── llama-server.sh.j2
    └── llama-server.service.j2
```

#### defaults/main.yml

```yaml
llama_cpp_install_dir: /opt/llama.cpp
llama_cpp_model_dir: /mnt/data/llama-cpp/models

# Active model — must match a name in llama_cpp_models
llama_cpp_model: Qwen3.5-4B.Q4_K_M.gguf

# Model list — url is optional (skip download if absent)
llama_cpp_models: []

llama_cpp_port: 8080
llama_cpp_host: "0.0.0.0"
llama_cpp_ctx_size: 32768
llama_cpp_gpu_layers: 99
llama_cpp_threads: 4
llama_cpp_batch_size: 512
llama_cpp_ubatch_size: 512
llama_cpp_flash_attn: true

# Pin the git ref — never use HEAD in production
llama_cpp_git_ref: "dcad77cc3"
llama_cpp_repo: "https://github.com/ggml-org/llama.cpp.git"

# 2025.2 required for dcad77cc3+ (intel_gpu_bmg_g31/wcl arch symbols)
# 2025.3 has a Level Zero GPF regression — avoid it
llama_cpp_oneapi_version: "2025.2"
llama_cpp_sycl_f16: true
```

#### tasks/intel-repos.yml

```yaml
- name: Download and dearmor Intel GPU drivers signing key
  ansible.builtin.shell:
    cmd: >
      curl -fsSL https://repositories.intel.com/gpu/intel-graphics.key
      | gpg --dearmor -o /etc/apt/keyrings/intel-graphics.gpg
    creates: /etc/apt/keyrings/intel-graphics.gpg

- name: Add Intel GPU drivers repository
  ansible.builtin.apt_repository:
    repo: >
      deb [arch=amd64 signed-by=/etc/apt/keyrings/intel-graphics.gpg]
      https://repositories.intel.com/gpu/ubuntu noble unified
    filename: intel-gpu
    state: present
    update_cache: false

- name: Download and dearmor Intel oneAPI signing key
  ansible.builtin.shell:
    cmd: >
      curl -fsSL
      https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB
      | gpg --dearmor -o /etc/apt/keyrings/intel-oneapi.gpg
    creates: /etc/apt/keyrings/intel-oneapi.gpg

- name: Add Intel oneAPI repository
  ansible.builtin.apt_repository:
    repo: "deb [signed-by=/etc/apt/keyrings/intel-oneapi.gpg] https://apt.repos.intel.com/oneapi all main"
    filename: intel-oneapi
    state: present
    update_cache: false

- name: Update apt cache
  ansible.builtin.apt:
    update_cache: true

- name: Install Intel GPU Level Zero runtime
  ansible.builtin.apt:
    name:
      - intel-level-zero-gpu
      - libze1
      - libze-dev
    state: present

- name: Install Intel oneAPI DPC++ compiler and math libraries
  ansible.builtin.apt:
    name:
      - intel-oneapi-compiler-dpcpp-cpp-{{ llama_cpp_oneapi_version }}
      - intel-oneapi-mkl-devel-{{ llama_cpp_oneapi_version }}
      - intel-oneapi-dnnl-{{ llama_cpp_oneapi_version }}
    state: present
```

#### tasks/build.yml

```yaml
- name: Clone llama.cpp repository
  ansible.builtin.git:
    repo: "{{ llama_cpp_repo }}"
    dest: "{{ llama_cpp_install_dir }}/src"
    version: "{{ llama_cpp_git_ref }}"
  register: llama_cpp_git

- name: Check if llama-server binary exists
  ansible.builtin.stat:
    path: "{{ llama_cpp_install_dir }}/bin/llama-server"
  register: llama_server_bin

- name: Create build directory
  ansible.builtin.file:
    path: "{{ llama_cpp_install_dir }}/build"
    state: directory
    mode: "0755"
  when: llama_cpp_git.changed or not llama_server_bin.stat.exists

- name: Configure llama.cpp with SYCL
  ansible.builtin.shell:
    cmd: >
      bash -c 'source /opt/intel/oneapi/setvars.sh --force &&
      cmake
      -DGGML_SYCL=ON
      -DCMAKE_C_COMPILER=icx
      -DCMAKE_CXX_COMPILER=icpx
      {% if llama_cpp_sycl_f16 %}-DGGML_SYCL_F16=ON{% endif %}
      -DCMAKE_BUILD_TYPE=Release
      -GNinja
      {{ llama_cpp_install_dir }}/src'
    chdir: "{{ llama_cpp_install_dir }}/build"
  environment:
    PATH: /opt/intel/oneapi/compiler/{{ llama_cpp_oneapi_version }}/bin:{{ ansible_env.PATH }}
  when: llama_cpp_git.changed or not llama_server_bin.stat.exists
  register: llama_cmake

- name: Build llama-server
  ansible.builtin.shell:
    cmd: "bash -c 'source /opt/intel/oneapi/setvars.sh --force && ninja llama-server'"
    chdir: "{{ llama_cpp_install_dir }}/build"
  environment:
    PATH: /opt/intel/oneapi/compiler/{{ llama_cpp_oneapi_version }}/bin:{{ ansible_env.PATH }}
  when: llama_cmake is changed
  register: llama_build

- name: Install llama-server binary
  ansible.builtin.copy:
    src: "{{ llama_cpp_install_dir }}/build/bin/llama-server"
    dest: "{{ llama_cpp_install_dir }}/bin/llama-server"
    remote_src: true
    mode: "0755"
  when: llama_build is changed
  notify: restart llama-server
```

#### tasks/models.yml

```yaml
- name: Create model directory
  ansible.builtin.file:
    path: "{{ llama_cpp_model_dir }}"
    state: directory
    mode: "0755"

- name: Download models
  ansible.builtin.get_url:
    url: "{{ item.url }}"
    dest: "{{ llama_cpp_model_dir }}/{{ item.name }}"
    mode: "0644"
    tmp_dest: "{{ llama_cpp_model_dir }}"
  loop: "{{ llama_cpp_models | selectattr('url', 'defined') | list }}"
  loop_control:
    label: "{{ item.name }}"

- name: Verify active model exists
  ansible.builtin.stat:
    path: "{{ llama_cpp_model_dir }}/{{ llama_cpp_model }}"
  register: active_model_stat

- name: Fail if active model file is missing
  ansible.builtin.fail:
    msg: >
      Active model '{{ llama_cpp_model }}' not found at
      {{ llama_cpp_model_dir }}/{{ llama_cpp_model }}.
      Add it to llama_cpp_models with a url, or place it manually.
  when: not active_model_stat.stat.exists
```

#### host_vars for the AI host

```yaml
# host_vars/ai.home.rittnauer.at/llama-cpp.yml
llama_cpp_model: Qwen3.5-4B.Q4_K_M.gguf

llama_cpp_models:
  - name: Qwen3.5-4B.Q4_K_M.gguf
    url: "https://huggingface.co/Qwen/Qwen3.5-4B-GGUF/resolve/main/Qwen3.5-4B-Q4_K_M.gguf"
```

To switch models: update `llama_cpp_model`, add an entry to `llama_cpp_models`, and re-run the playbook. The download is idempotent — already-present files are skipped. The service restarts automatically via the handler.

### Traefik (host-native)

Since llama-server runs on the host and Traefik runs in Docker, `host-gateway` bridges the two:

```yaml
# host_vars/ai.home.rittnauer.at/traefik.yml
traefik_extra_hosts:
  - "host-gateway:host-gateway"
```

```yaml
# traefik.dynamic.yml.j2
http:
  routers:
    llama-server:
      rule: Host(`api.{{ fqdn }}`)
      service: llama-server
      tls:
        certResolver: letsencryptresolver
  services:
    llama-server:
      loadBalancer:
        servers:
          - url: http://host-gateway:8080
```

### Open WebUI (host-native)

Same `host-gateway` trick for Open WebUI:

```yaml
# docker-compose.yml.j2
services:
  open-webui:
    image: ghcr.io/open-webui/open-webui:main
    extra_hosts:
      - "host-gateway:host-gateway"
    environment:
      - WEBUI_SECRET_KEY={{ open_webui_secret_key }}
      - OPENAI_API_BASE_URLS=http://host-gateway:8080/v1
      - ENABLE_OLLAMA_API=false
      - ENABLE_API_KEYS=true
    volumes:
      - {{ open_webui_data_dir }}:/app/backend/data
    networks:
      - dmznet
```

`ENABLE_API_KEYS=true` activates Bearer token auth on the `/api/v1/` endpoints, required for programmatic access from Hermes or other clients.

---

## Traefik Timeout — Both Approaches

LLM inference can take minutes. Traefik's default idle timeout of 180s will silently drop the connection mid-response. Add this regardless of which inference backend you use:

```yaml
traefik_commands:
  - --entrypoints.websecure.transport.respondingTimeouts.readTimeout=0
  - --entrypoints.websecure.transport.respondingTimeouts.writeTimeout=0
  - --entrypoints.websecure.transport.respondingTimeouts.idleTimeout=600s
```

---

## Hermes Agent

[Hermes](https://github.com/kagi-search/hermes) is a local AI agent that can browse the web, run shell commands, and interact with system services. It runs as a systemd service on a separate host (`agent.home.rittnauer.at`) and talks to the LLM over HTTPS.

### config.yaml.j2

```yaml
model:
  provider: custom
  base_url: "{{ hermes_llm_base_url }}"
  model: "{{ hermes_llm_model }}"

providers:
  custom:
    request_timeout_seconds: {{ hermes_request_timeout }}
    stale_timeout_seconds: {{ hermes_stale_timeout }}

terminal:
  backend: local
```

### hermes-gateway.service.j2

```ini
[Unit]
Description=Hermes Gateway
After=network.target

[Service]
Type=simple
ExecStart={{ hermes_bin }} gateway run
Restart=on-failure
RestartSec=5
User=root
WorkingDirectory={{ hermes_data_dir }}
Environment=HOME=/root
```

`User=root` is **not optional**. Hermes reads its own systemd unit file at startup via `_read_systemd_user_from_unit()` and raises `ValueError: Refusing to install the gateway system service as root` if the unit does not explicitly declare `User=root`. The `--run-as-user root` flag only exists on `gateway install`, not on `gateway run`.

### defaults/main.yml

```yaml
hermes_install_dir: /usr/local/lib/hermes-agent
hermes_bin: /usr/local/bin/hermes
hermes_data_dir: /root/.hermes

hermes_llm_base_url: "https://ai.home.rittnauer.at/api/v1"
hermes_llm_api_key: ""
hermes_llm_model: "Qwen3.5-4B.Q4_K_M.gguf"

# Local LLM is slow — raise timeouts well beyond the 180s default.
# Hermes sends 10K+ token prompts for agentic tasks.
hermes_request_timeout: 600
hermes_stale_timeout: 600

hermes_dashboard_host: "0.0.0.0"
hermes_dashboard_port: 9119
```

Hermes sends prompts that can reach 13,000+ tokens for agentic tasks. At ~82 tok/s prompt eval on the Iris Xe, a 13K prompt takes ~2.5 minutes to first token. Setting both timeouts to 600s covers normal conversational turns without hitting the default 180s stale timeout.

---

## Performance

Qwen3.5-4B Q4_K_M on Intel Iris Xe (UMA, Ubuntu 25.10):

| Metric | Value |
|--------|-------|
| Generation speed | ~7.4 tok/s |
| Prompt eval (150 tokens) | ~82 tok/s |
| Time to first token (150-token prompt) | ~1.8s |
| Context size | 32768 tokens |

Benchmarked with the native `/completion` endpoint:

```bash
curl -s http://localhost:8080/completion \
  -H 'Content-Type: application/json' \
  -d '{
    "prompt": "<|im_start|>user\nExplain neural networks<|im_end|>\n<|im_start|>assistant\n",
    "n_predict": 200
  }' | python3 -c "
import json, sys
d = json.load(sys.stdin)
t = d['timings']
print('prompt eval:', t['prompt_n'], 'tokens @', round(t['prompt_per_second'], 1), 'tok/s')
print('generation:', t['predicted_n'], 'tokens @', round(t['predicted_per_second'], 1), 'tok/s')
"
```

Flash attention (`--flash-attn on`) and batch tuning (`--batch-size 512`) showed no meaningful improvement over defaults on this hardware (~1% delta across multiple runs). The GPU is compute-bound at this scale; tuning helps more on larger models or discrete GPUs.

---

## Gotchas Summary

- **Intel repo keys must be dearmored** — keys are distributed as ASCII PEM, apt needs binary GPG. Always use `curl | gpg --dearmor`, not `get_url`.
- **oneAPI 2025.3 crashes** — use 2025.2. Pin the version. Never use the unversioned metapackage.
- **llama.cpp commits after mid-2025 need oneAPI 2025.2+** — for `intel_gpu_bmg_g31`/`intel_gpu_wcl` GPU arch symbols in `sycl_hw.cpp`.
- **`SYCL_CACHE_PERSISTENT=1` is essential** — without it, every restart recompiles SYCL kernels (~30–60s warmup).
- **`UR_L0_ENABLE_RELAXED_ALLOCATION_LIMITS=1`** — required for large model allocations on UMA hardware.
- **Level Zero package names** — it is `libze1` + `libze-dev`, not `level-zero`. DNN is `intel-oneapi-dnnl-*` (with an `l`).
- **LocalAI `gpu_layers: -1` silently falls back to CPU** — llama.cpp SYCL does not treat -1 as "all layers". Use `99` to safely cover any model up to ~100 transformer layers.
- **LocalAI healthcheck port** — the base image checks port 8080. A sidecar on a different port needs a custom `healthcheck:` block with a long `start_period` (180s+).
- **Traefik idle timeout** — default 180s kills long inference. Set `idleTimeout=600s` or `0` for unlimited.
- **Hermes `User=root` in service file** — read programmatically by Hermes at startup. Without it, `gateway run` raises `ValueError`.
- **Open WebUI `ENABLE_API_KEYS=true`** — required env var even if the API key is inserted directly into SQLite.
