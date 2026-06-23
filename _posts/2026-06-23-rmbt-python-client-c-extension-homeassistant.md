---
layout: post
title: Unlocking multi-threaded RMBT throughput in Python with a GIL-free C extension
date: 2026-06-23
author: Raimund Rittnauer
description: How we went from ~8 Gbit/s to ~94 Gbit/s on a loopback RMBT speed test by writing a small C extension that releases the GIL during the recv/send hot loop — and how it ships to every Home Assistant architecture as a pre-built manylinux wheel.
categories: tech
comments: true
tags:
  - python
  - homeassistant
  - rmbt
  - c-extension
  - performance
  - pypi
  - homelab
---

The [RMBT protocol](https://www.netztest.at) is what powers the Austrian [RTR Nettest](https://www.netztest.at) — the official national broadband measurement tool. I maintain a Python implementation of the RMBT client ([open-rmbt-client-cli](https://github.com/raaaimund/open-rmbt-client-cli)) and a [Home Assistant custom integration](https://github.com/raaaimund/ha-rmbt-nettest) that runs speed tests from your HA instance.

The pure-Python client works well up to ~1 Gbit/s, but the GIL becomes the bottleneck as thread count and link speed increase. This post documents how a ~180-line C extension removes that ceiling, how it ships as a pre-built wheel for every Home Assistant platform, and how the HA integration gracefully handles environments where the extension is not available.

## The Python client

The client performs the full RMBT measurement sequence:

1. `POST /RMBTControlServer/settings` — register, receive client UUID
2. `POST /RMBTControlServer/testRequest` — receive token, test server address, thread count
3. **Pre-test** — 2-second single-thread GETCHUNKS download to calibrate chunk size and thread count
4. **Ping** — 1 s / 10–100 pings
5. **Download** — multi-threaded GETTIME; all threads start simultaneously via `threading.Barrier`
6. **Upload** — multi-threaded PUTNORESULT
7. `POST /RMBTControlServer/result`

Each measurement thread opens its own TCP connection to the test server and streams data for the configured duration (typically 7–10 seconds). The server signals the end of a chunk with a terminal byte of `0xFF`; the client echoes `OK` and reads back `TIME <ns>` for the server-side elapsed time.

The download hot loop in pure Python looks like this:

```python
while True:
    want     = min(in_chunk, READ_BLOCK)   # 16 KiB at a time
    data     = conn.read_exact(want)
    total   += want
    in_chunk -= want

    now_ns = time.monotonic_ns()
    if now_ns - last_sample_ns >= SAMPLE_NS:   # 40 ms
        samples.append((total, now_ns - t0_ns))
        last_sample_ns = now_ns

    if in_chunk == 0:
        if data[-1] == 0xFF:
            break
        in_chunk = chunk_size
```

On a loopback test with 4 threads the pure-Python implementation achieved around **8 Gbit/s downstream and 6 Gbit/s upstream**. The Rust client on the same machine does ~32 Gbit/s in both directions. The gap is the GIL.

## Why the GIL hurts here

CPython's Global Interpreter Lock ensures that only one thread executes Python bytecode at a time. The `socket.recv()` call itself releases the GIL — the OS-level I/O runs in parallel — but all the Python overhead *between* recv calls (bytecode dispatch, attribute lookups, the `time.monotonic_ns()` call, list append, loop counter arithmetic) holds it.

With 4 measurement threads, only one can be in the Python bytecode interpreter at a time. The others are waiting for the GIL even though their sockets have data ready. The bottleneck is not the network; it is thread serialisation inside the interpreter.

## The C extension: releasing the GIL for the whole loop

The fix is a small C extension (`rmbt_loop`) that wraps the entire tight loop in `Py_BEGIN_ALLOW_THREADS` / `Py_END_ALLOW_THREADS`. Inside that region no Python API calls are allowed, but all four threads can call `recv()` / `send()` concurrently without any coordination.

```c
Py_BEGIN_ALLOW_THREADS

t0 = last_sample = monotonic_ns();

while (!err_flag) {
    Py_ssize_t want = (in_chunk < read_block) ? in_chunk : read_block;
    Py_ssize_t got  = 0;

    /* drain any bytes already buffered by Python */
    if (init_off < init_len) {
        Py_ssize_t take = init_len - init_off;
        if (take > want) take = want;
        memcpy(buf, init_ptr + init_off, (size_t)take);
        init_off += take;
        got       = take;
    }

    /* fill remainder from socket */
    while (got < want) {
        ssize_t n = recv(fd, buf + got, (size_t)(want - got), 0);
        if (n > 0) {
            got += (Py_ssize_t)n;
        } else if (errno == EAGAIN && wait_readable(fd)) {
            continue;   /* non-blocking fd — poll and retry */
        } else {
            err_flag = 1; break;
        }
    }
    /* ... sample collection in C arrays, chunk boundary check ... */
}

Py_END_ALLOW_THREADS
```

Speed samples are collected into a plain C array during the loop and converted to a Python list only after `Py_END_ALLOW_THREADS` re-acquires the GIL. The function returns `(total_bytes, samples, leftover_bytes)` to Python, which then handles the protocol tail (`OK` / `TIME <ns>`) as before.

### The EAGAIN surprise

Python's `socket.create_connection(..., timeout=30)` puts the underlying file descriptor into **non-blocking mode** (`O_NONBLOCK`) at the OS level and uses `select` internally to implement the timeout. A direct `recv()` call from C on such an fd returns `EAGAIN` immediately if the kernel buffer is momentarily empty — no data lost, but our C loop would treat it as an error.

The fix is a small `poll()` helper:

```c
static int wait_readable(int fd) {
    struct pollfd pfd = { fd, POLLIN, 0 };
    return (poll(&pfd, 1, 30000) > 0);   /* 30 s timeout */
}
```

When `recv()` returns `EAGAIN`, we poll until data arrives (or 30 seconds pass) and retry. This is identical to what Python's own socket wrapper does internally.

The upload path has the equivalent for `send()`:

```c
static int wait_writable(int fd) {
    struct pollfd pfd = { fd, POLLOUT, 0 };
    return (poll(&pfd, 1, 30000) > 0);
}
```

### Transparent fallback

The extension is imported at module level with a silent fallback:

```python
try:
    from rmbt_client import rmbt_loop as _rmbt_loop
except ImportError:
    _rmbt_loop = None
```

The C path is only taken for plain HTTP connections on non-TLS, non-WebSocket sockets — the cases where we have a raw file descriptor we can hand to C. TLS and WebSocket connections always use the pure-Python path. An environment variable `RMBT_PURE_PYTHON=1` forces the Python path unconditionally, which is useful for benchmarking.

## Building the extension

Because the extension is optional, `setup.py` wraps the build in a custom command class that swallows compilation errors:

```python
class OptionalBuildExt(build_ext):
    def run(self):
        try:
            super().run()
        except Exception as exc:
            print(f"WARNING: C extension build failed ({exc}); "
                  "falling back to pure-Python implementation.")

    def build_extension(self, ext):
        try:
            super().build_extension(ext)
        except Exception as exc:
            print(f"WARNING: Skipping {ext.name}: {exc}")
```

If `gcc` or `python3-dev` are missing, `pip install rmbt-client` still succeeds and installs a working pure-Python package. Only a pre-built wheel or a system with build tools gets the C extension.

The `pyproject.toml` was migrated from hatchling to the setuptools backend to support C extensions:

```toml
[build-system]
requires = ["setuptools>=68", "wheel"]
build-backend = "setuptools.build_meta"
```

### Docker build

A multi-stage Dockerfile keeps the final image small by compiling in a builder stage and only copying the resulting wheel into the slim runtime image:

```dockerfile
FROM python:3.13-slim AS builder
RUN apt-get update -qq \
 && apt-get install -y --no-install-recommends gcc python3-dev \
 && rm -rf /var/lib/apt/lists/*
WORKDIR /build
COPY pyproject.toml setup.py ./
COPY rmbt_client/ rmbt_client/
RUN pip install --no-cache-dir setuptools wheel build \
 && python -m build --wheel --outdir /dist .

FROM python:3.13-slim
COPY --from=builder /dist/*.whl /tmp/
RUN pip install --no-cache-dir /tmp/*.whl && rm /tmp/*.whl
ENTRYPOINT ["rmbt-client"]
```

The result is a **189 MB** image. A single-stage image with build tools left in place was 580 MB.

Run a test against a local server:

```sh
docker run --rm --network=host rmbt-client -h http://127.0.0.1:8080
```

`--network=host` is needed on Linux so the container can reach loopback addresses on the host.

## Measured throughput

All numbers from a loopback test (`127.0.0.1`, 4 threads, 7 s).

**Test system:** Intel Core i7-1165G7 @ 2.80 GHz (4 cores / 8 threads, 11th Gen), 24 GB RAM, x86_64 Linux

| Client | Download | Upload |
|---|---|---|
| Python 1.1.x — C extension | ~94 Gbit/s | ~68 Gbit/s |
| Python 1.0.0 — pure Python | ~8 Gbit/s | ~6 Gbit/s |
| Rust | ~32 Gbit/s | ~32 Gbit/s |

> **No test on a real 100 Gbit/s network has been performed.** These numbers measure how fast the CPU can push bytes through the loopback stack, not a real-world link. On an actual high-speed link, NIC driver overhead, interrupt coalescing, and kernel socket buffer tuning dominate long before the Python vs. C difference matters. For typical home and office connections (up to ~10 Gbit/s) either implementation is more than fast enough.

The C extension beats the Rust client on loopback because the Rust implementation processes one thread at a time in its current form, while the Python extension runs all four threads in parallel with no GIL overhead. On a real network link where I/O wait dominates, the difference would be negligible.

## Shipping to every Home Assistant platform

`gcc` and `python3-dev` are not available on the most common HA installation types:

| Installation | Build tools available? |
|---|---|
| Home Assistant OS (HAOS) | ✗ — custom Buildroot distro, read-only rootfs |
| HA Container (Docker) | ✗ — minimal image, no package manager |
| HA Supervised | ✗ — same container as above |
| HA Core (bare metal) | Maybe — depends on the host OS |

This means telling users to "compile the extension yourself" is not actionable for the vast majority of HA users. The solution is to publish **pre-built manylinux wheels** to PyPI that `pip` can install without any compiler.

The three architectures HA actually runs on:

| Architecture | Covers |
|---|---|
| `x86_64` | NUC, generic x86 VM, Docker on x86 |
| `aarch64` | Raspberry Pi 4 / 5, modern ARM boards (64-bit HAOS) |
| `armv7l` | Raspberry Pi 3 and older (32-bit HAOS) |

The CI workflow uses [cibuildwheel](https://cibuildwheel.pypa.io) with QEMU emulation for cross-architecture builds:

```yaml
wheels:
  runs-on: ubuntu-latest
  strategy:
    matrix:
      arch: [x86_64, aarch64, armv7l]
  steps:
    - uses: actions/checkout@v4

    - name: Set up QEMU (cross-arch emulation)
      if: matrix.arch != 'x86_64'
      uses: docker/setup-qemu-action@v3

    - name: Build wheels (${{ matrix.arch }})
      uses: pypa/cibuildwheel@v4.1.0
      with:
        package-dir: clientPython/
        output-dir: dist/
      env:
        CIBW_BUILD: "cp313-manylinux*"
        CIBW_ARCHS: ${{ matrix.arch }}
```

`manylinux` wheels target glibc ≥ 2.17, which covers all current HAOS versions. The wheel filenames encode the full compatibility range, for example:

```
rmbt_client-1.1.1-cp313-cp313-manylinux2014_aarch64.manylinux_2_17_aarch64.manylinux_2_28_aarch64.whl
```

When a user installs `rmbt-client==1.1.1` on a Raspberry Pi 4 running 64-bit HAOS, `pip` automatically selects the `aarch64` wheel and no compiler is needed.

The PyPI publish step uses `skip_existing: true` so re-running a workflow for an already-published version does not fail the entire CI job:

```yaml
- name: Publish to PyPI
  uses: pypa/gh-action-pypi-publish@release/v1
  with:
    skip_existing: true
```

## Home Assistant integration

The [ha-rmbt-nettest](https://github.com/raaaimund/ha-rmbt-nettest) custom integration lists `rmbt-client` as a requirement in `manifest.json`. HA's frontend installs it automatically via pip when the integration is added.

Since the C extension is now compiled into the wheel, users on x86_64, aarch64, and armv7l get it automatically. Users on unsupported platforms silently fall back to pure Python.

To make the situation visible in the HA log, `async_setup_entry` runs a one-time check:

```python
def _check_c_extension() -> None:
    try:
        from rmbt_client import rmbt_loop  # noqa: F401
    except ImportError:
        LOGGER.warning(
            "[Warn] rmbt_loop C extension not available — using pure-Python fallback. "
            "Throughput on multi-threaded tests may be limited by the GIL. "
            "A pre-built wheel for your platform may not yet be published to PyPI; "
            "see https://github.com/raaaimund/open-rmbt-client-cli for details."
        )
```

This appears in **Settings → System → Logs** if the extension is missing, pointing the user to the right place without breaking the integration.

## Lessons learned

**Non-blocking sockets are the default in Python's timeout mode.** `socket.create_connection(..., timeout=N)` sets `O_NONBLOCK` on the fd. Calling `recv()` directly from C without knowing this returns `EAGAIN` on the first miss and looks like a connection error. Always handle `EAGAIN` / `EWOULDBLOCK` with a `poll()` retry.

**PyPI filenames are permanent.** Once a wheel is uploaded for a given version and filename, it can never be replaced. Re-tagging a commit and re-running the publish workflow will fail with `400 File already exists`. Increment the patch version for any re-publish, even if only documentation changed.

**`skip_existing: true` is not a version management strategy** — it is a safety net for idempotent retries within a single release. The correct response to a "file already exists" error is still to bump the version.

**Multi-stage Docker builds are worth the extra `FROM` line.** Dropping build tools from the final image in this case reduced the image size from 580 MB to 189 MB.
