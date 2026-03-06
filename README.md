# LM Studio Docker Container

Containerized [LM Studio](https://lmstudio.ai/) local LLM platform with browser-based GUI access via jlesage/docker-baseimage-gui and NVIDIA GPU acceleration.

## Architecture

| Component | Detail |
|---|---|
| Base Image | `jlesage/docker-baseimage-gui:debian-12-v4` |
| Display | TigerVNC + Openbox + noVNC (jlesage stack) |
| GPU | NVIDIA CUDA via NVIDIA Container Toolkit |
| Application | LM Studio v0.4.6 (.deb, downloaded at build time) |

## Prerequisites

- Docker Engine 24.x+
- Docker Compose v2.x
- NVIDIA driver >= 525.x installed on the host
- [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html) installed and configured

## Quick Start

```bash
# Edit stack.env as needed
vi stack.env

# Build and start
docker compose --env-file stack.env up -d --build

# View logs
docker compose --env-file stack.env logs -f lmstudio
```

Access the GUI at `http://<host-ip>:5800`.

The OpenAI-compatible API is available at `http://<host-ip>:1234`.

## First Run

1. Open the web UI in your browser at port 5800.
2. LM Studio will launch and present its main interface.
3. Search for and download a model (e.g., Qwen 3, Llama, DeepSeek).
4. Models are stored in the `/models` volume and persist across restarts.
5. Load a model and start chatting, or enable the server for API access.

## Volume Mounts

| Container Path | Purpose |
|---|---|
| `/config` | LM Studio configuration, conversations, extensions, caches, and jlesage settings. Maps to `~/.cache/lm-studio` internally. |
| `/models` | Downloaded model files. Symlinked from `/config/.cache/lm-studio/models`. Keep this on fast storage with plenty of space. |

## Ports

| Port | Description |
|---|---|
| 5800 | jlesage web UI (noVNC) |
| 5900 | VNC direct access |
| 1234 | LM Studio OpenAI-compatible API |

## API Usage

The API server binds to `0.0.0.0:1234` by default (configured at build time). You must start the server from within the LM Studio UI or via the CLI. Once running:

```bash
# List loaded models
curl http://<host-ip>:1234/v1/models

# Chat completion
curl http://<host-ip>:1234/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "your-model-identifier",
    "messages": [{"role": "user", "content": "Hello!"}]
  }'
```

## MCP Server Support

LM Studio 0.4.x supports MCP (Model Context Protocol) servers for tool use. Configure MCP servers through the LM Studio UI under Settings. This was one of the primary motivations for containerizing LM Studio rather than using Ollama + Open WebUI.

## GPU Verification

```bash
docker exec -it lmstudio nvidia-smi
```

## Environment Variables

All standard [jlesage](https://github.com/jlesage/docker-baseimage-gui) environment variables are supported.

| Variable | Default | Description |
|---|---|---|
| `USER_ID` | `1000` | User ID for file ownership |
| `GROUP_ID` | `1000` | Group ID for file ownership |
| `TZ` | `Europe/Madrid` | Container timezone |
| `DISPLAY_WIDTH` | `1920` | Display width |
| `DISPLAY_HEIGHT` | `1080` | Display height |
| `KEEP_APP_RUNNING` | `1` | Auto-restart on crash |

## Notes

- The .deb is downloaded at build time from `installers.lmstudio.ai`. No local package file is needed in the build context.
- The models symlink (`/config/.cache/lm-studio/models` -> `/models`) allows the large model files to live on a separate volume or disk.
- The HTTP server config is seeded at build time to bind on `0.0.0.0` instead of `127.0.0.1`. If this gets overwritten by LM Studio on first run, you may need to edit it via the UI (Settings > Developer > Server).
- Electron runs with `--no-sandbox` and `seccomp=unconfined`, which is standard for containerized Chromium apps.
- `shm_size: 2gb` prevents Chromium renderer crashes from Docker's default 64MB `/dev/shm`.

## Updating

To update LM Studio:

```bash
# Edit the LMSTUDIO_VERSION build arg in docker-compose.yml
docker compose --env-file stack.env build --no-cache
docker compose --env-file stack.env up -d
```

## Troubleshooting

**Black screen or crash on start:** Check logs for Electron errors. Ensure `seccomp=unconfined` and `shm_size` are set.

**GPU not detected:** Verify `nvidia-smi` works inside the container. Check that the NVIDIA Container Toolkit is properly installed.

**API not accessible from outside:** Ensure port 1234 is mapped and the server is started within LM Studio. Check that `/config/.cache/lm-studio/.internal/http-server-config.json` has `"host":"0.0.0.0"`.

**Models not appearing:** Verify the `/models` volume is mounted and the symlink at `/config/.cache/lm-studio/models` points to `/models`. Models must follow the `publisher/model-name/file.gguf` directory structure (two levels deep).
