# LM Studio Docker Container

Containerized [LM Studio](https://lmstudio.ai/) local LLM platform with browser-based GUI access via KasmVNC and NVIDIA GPU acceleration.

## Architecture

| Component | Detail |
|---|---|
| Base Image | `ghcr.io/linuxserver/baseimage-kasmvnc:ubuntunoble` (Ubuntu 24.04) |
| Display | KasmVNC with Openbox window manager |
| GPU | NVIDIA CUDA via NVIDIA Container Toolkit |
| Application | LM Studio v0.4.6 (.deb, downloaded at build time) |

## Prerequisites

- Docker Engine 24.x+
- Docker Compose v2.x
- NVIDIA driver >= 525.x installed on the host
- [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html) installed and configured

## Quick Start

```bash
vi stack.env

docker compose --env-file stack.env up -d --build

docker compose --env-file stack.env logs -f lmstudio
```

Access the GUI via your reverse proxy pointed at port 3000 on the container (WebSocket support required).

The OpenAI-compatible API is available on port 1234.

## First Run

1. Open the web UI in your browser.
2. LM Studio will launch and present its main interface.
3. Search for and download a model (e.g., Qwen 3, Llama, DeepSeek).
4. Models are stored in the `/config/.lmstudio/models` volume and persist across restarts.
5. Load a model and start chatting, or enable the server for API access.

## Volume Mounts

| Container Path | Purpose |
|---|---|
| `/config` | LM Studio configuration, conversations, extensions, caches, and KasmVNC settings |
| `/config/.lmstudio/models` | Downloaded model files (mounted as a separate volume for large model storage) |

## Ports

| Port | Description |
|---|---|
| 3000 | KasmVNC web UI (HTTP) |
| 3001 | KasmVNC web UI (HTTPS) |
| 1234 | LM Studio OpenAI-compatible API |

## API Usage

The API server is pre-configured to bind on `0.0.0.0:1234`. Start the server from within the LM Studio UI or via the CLI, then:

```bash
curl http://<host-ip>:1234/v1/models

curl http://<host-ip>:1234/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "your-model-identifier",
    "messages": [{"role": "user", "content": "Hello!"}]
  }'
```

## MCP Server Support

LM Studio 0.4.x supports MCP (Model Context Protocol) servers for tool use. Configure MCP servers through the LM Studio UI under Settings. The built-in JS sandbox plugin requires `HOME` to be set correctly, which is handled by this container's configuration.

## GPU Verification

```bash
docker exec -it lmstudio nvidia-smi
```

## Notes

- The .deb is downloaded at build time from `installers.lmstudio.ai`. No local package file is needed in the build context.
- `HOME=/config` is set as a container-level environment variable so that all child processes (including the Deno JS sandbox) inherit it correctly.
- The HTTP server config is seeded at build time to bind on `0.0.0.0`. If LM Studio overwrites this on first run, toggle the server setting in Settings > Developer.
- Electron runs with `--no-sandbox` and `seccomp=unconfined`, standard for containerized Chromium apps.
- `shm_size: 2gb` prevents Chromium renderer crashes from Docker's default 64MB `/dev/shm`.
- `libgomp1` is included for the CUDA llama.cpp inference backend.
- Vulkan libraries are included for LM Studio's hardware survey at startup.

## Updating

```bash
# Edit the LMSTUDIO_VERSION build arg in docker-compose.yml
docker compose --env-file stack.env build --no-cache
docker compose --env-file stack.env up -d
```
