#!/bin/sh
# =============================================================================
# LM Studio launcher for jlesage/docker-baseimage-gui
#
# Electron requires --no-sandbox inside containers.
# --disable-gpu-sandbox allows CUDA compute without Chromium GPU sandboxing.
# --disable-dev-shm-usage avoids /dev/shm size issues in Docker.
# =============================================================================

export HOME=/config

# Resolve the LM Studio binary (.deb typically installs to /opt/)
LMSTUDIO_BIN=""
for candidate in \
    /opt/LM\ Studio/lm-studio \
    /opt/lm-studio/lm-studio \
    /opt/LM-Studio/lm-studio \
    /usr/bin/lm-studio \
    /usr/lib/lm-studio/lm-studio; do
    if [ -x "$candidate" ] && [ -f "$candidate" ]; then
        LMSTUDIO_BIN="$candidate"
        break
    fi
done

# Fallback: search common install locations
if [ -z "$LMSTUDIO_BIN" ]; then
    LMSTUDIO_BIN=$(find /opt /usr/lib /usr/bin -maxdepth 3 -name "lm-studio" -type f -executable 2>/dev/null | head -1)
fi

if [ -z "$LMSTUDIO_BIN" ]; then
    echo "ERROR: Could not locate LM Studio binary." >&2
    echo "Searching for candidates..." >&2
    find /opt /usr/lib /usr/bin -maxdepth 3 -iname "*lm*studio*" -type f 2>/dev/null >&2
    sleep 30
    exit 1
fi

exec "$LMSTUDIO_BIN" \
    --no-sandbox \
    --disable-gpu-sandbox \
    --disable-dev-shm-usage \
    --disable-software-rasterizer \
    "$@"
