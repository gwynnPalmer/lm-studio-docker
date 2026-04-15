# =============================================================================
# LM Studio - Containerized Local LLM Platform
# Base: LinuxServer KasmVNC (Ubuntu Noble 24.04)
# GPU:  NVIDIA CUDA via NVIDIA Container Toolkit
# =============================================================================

FROM ghcr.io/linuxserver/baseimage-kasmvnc:ubuntunoble

#ARG LMSTUDIO_VERSION=0.4.6-1

LABEL maintainer="lmstudio-docker"
LABEL description="LM Studio local LLM platform with browser-based GUI and NVIDIA GPU support"

# --------------------------------------------------------------------------
# Environment
# --------------------------------------------------------------------------
ENV TITLE="LM Studio"
ENV START_DOCKER=false
ENV HOME=/config
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=all

# --------------------------------------------------------------------------
# Install system dependencies
#   - Electron/Chromium runtime requirements
#   - CUDA inference runtime dependencies
#   - Vulkan support (LM Studio hardware survey)
#   - Locale support
# --------------------------------------------------------------------------
RUN \
  echo "***** install electron and system dependencies *****" && \
  apt-get update && \
  apt-get install -y --no-install-recommends \
    # Electron / Chromium shared libraries
    libgtk-3-0 \
    libnotify4 \
    libnss3 \
    libxss1 \
    libxtst6 \
    libatk-bridge2.0-0 \
    libdrm2 \
    libgbm1 \
    libasound2t64 \
    libx11-xcb1 \
    libxcomposite1 \
    libxcursor1 \
    libxdamage1 \
    libxfixes3 \
    libxi6 \
    libxrandr2 \
    libxrender1 \
    libpango-1.0-0 \
    libcairo2 \
    libcups2 \
    libdbus-1-3 \
    libexpat1 \
    libfontconfig1 \
    libgcc-s1 \
    libnspr4 \
    libpangocairo-1.0-0 \
    # CUDA inference runtime dependency
    libgomp1 \
    # Vulkan support (LM Studio uses it for hardware survey)
    libvulkan1 \
    mesa-vulkan-drivers \
    # General utilities
    wget \
    curl \
    ca-certificates \
    locales \
    xdg-utils \
  && \
  # Generate locale
  sed -i 's/# en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen && \
  locale-gen en_US.UTF-8 && \
  # Clean up
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# --------------------------------------------------------------------------
# Download and install LM Studio .deb
# --------------------------------------------------------------------------
RUN \
  echo "***** download LM Studio latest *****" && \
  wget -q -O /tmp/lmstudio.deb \
    "https://lmstudio.ai/download/latest/linux/x64?format=deb" && \
  echo "***** install LM Studio *****" && \
  apt-get update && \
  apt-get install -y --no-install-recommends /tmp/lmstudio.deb && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# --------------------------------------------------------------------------
# Create directory structure
# --------------------------------------------------------------------------
RUN \
  mkdir -p \
    /config/.lmstudio \
    /config/.lmstudio/models

# --------------------------------------------------------------------------
# Seed the HTTP server config to bind on 0.0.0.0 instead of 127.0.0.1
#   Without this, the API is only accessible from inside the container.
# --------------------------------------------------------------------------
RUN \
  mkdir -p /config/.lmstudio/.internal && \
  echo '{"port":1234,"host":"0.0.0.0"}' > /config/.lmstudio/.internal/http-server-config.json

# --------------------------------------------------------------------------
# Autostart script for KasmVNC
# --------------------------------------------------------------------------
COPY root/ /

# --------------------------------------------------------------------------
# Ports
#   3000     - KasmVNC web interface (HTTP)
#   3001     - KasmVNC web interface (HTTPS)
#   1234     - LM Studio OpenAI-compatible API
# --------------------------------------------------------------------------
EXPOSE 3000 3001 1234
