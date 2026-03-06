# =============================================================================
# LM Studio - Containerized Local LLM Platform
# Base: jlesage/docker-baseimage-gui (Debian 12)
# GPU:  NVIDIA CUDA via NVIDIA Container Toolkit
# =============================================================================

FROM jlesage/baseimage-gui:debian-12-v4

ARG LMSTUDIO_VERSION=0.4.6-1

LABEL maintainer="lmstudio-docker"
LABEL description="LM Studio local LLM platform with browser-based GUI and NVIDIA GPU support"

# --------------------------------------------------------------------------
# Environment
# --------------------------------------------------------------------------
ENV APP_NAME="LM Studio"
ENV KEEP_APP_RUNNING=1
ENV HOME=/config
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=all

# --------------------------------------------------------------------------
# Install system dependencies
#   - Electron/Chromium runtime requirements
#   - CUDA toolkit compatibility libraries
#   - Locale support
# --------------------------------------------------------------------------
RUN \
  echo "***** install electron and system dependencies *****" && \
  apt-get update && \
  apt-get install -y --no-install-recommends \
    # Electron / Chromium shared libraries \
    libgtk-3-0 \
    # CUDA inference runtime dependency \
    libgomp1 \
    libnotify4 \
    libnss3 \
    libxss1 \
    libxtst6 \
    libatk-bridge2.0-0 \
    libdrm2 \
    libgbm1 \
    libasound2 \
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
    # Vulkan support (LM Studio uses it for hardware survey) \
    libvulkan1 \
    mesa-vulkan-drivers \
    # General utilities \
    wget \
    curl \
    ca-certificates \
    locales \
    xdg-utils \
  && \
  # Generate locale \
  sed -i 's/# en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen && \
  locale-gen en_US.UTF-8 && \
  # Clean up \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# --------------------------------------------------------------------------
# Download and install LM Studio .deb
# --------------------------------------------------------------------------
RUN \
  echo "***** download LM Studio v${LMSTUDIO_VERSION} *****" && \
  wget -q -O /tmp/lmstudio.deb \
    "https://installers.lmstudio.ai/linux/x64/${LMSTUDIO_VERSION}/LM-Studio-${LMSTUDIO_VERSION}-x64.deb" && \
  echo "***** install LM Studio *****" && \
  apt-get update && \
  apt-get install -y --no-install-recommends /tmp/lmstudio.deb && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# --------------------------------------------------------------------------
# Create directory structure
#   /config                          - jlesage persistent home
#   /config/.cache/lm-studio         - LM Studio app data, conversations, etc.
#   /models                          - Separate volume for large model files
# --------------------------------------------------------------------------
RUN \
  mkdir -p \
    /config/.cache/lm-studio \
    /models

# --------------------------------------------------------------------------
# Symlink models directory
#   LM Studio expects models at ~/.cache/lm-studio/models
#   We symlink this to /models so it can be a separate volume mount
# --------------------------------------------------------------------------
RUN \
  ln -sf /models /config/.cache/lm-studio/models

# --------------------------------------------------------------------------
# Seed the HTTP server config to bind on 0.0.0.0 instead of 127.0.0.1
#   Without this, the API is only accessible from inside the container.
# --------------------------------------------------------------------------
RUN \
  mkdir -p /config/.cache/lm-studio/.internal && \
  echo '{"port":1234,"host":"0.0.0.0"}' > /config/.cache/lm-studio/.internal/http-server-config.json

# --------------------------------------------------------------------------
# Openbox window matching
#   Ensure the main LM Studio window is matched correctly.
# --------------------------------------------------------------------------
RUN \
  mkdir -p /etc/openbox && \
  echo '<Root>' > /etc/openbox/main-window-selection.xml && \
  echo '  <Window>' >> /etc/openbox/main-window-selection.xml && \
  echo '    <Type>normal</Type>' >> /etc/openbox/main-window-selection.xml && \
  echo '  </Window>' >> /etc/openbox/main-window-selection.xml && \
  echo '</Root>' >> /etc/openbox/main-window-selection.xml

# --------------------------------------------------------------------------
# Application launch script
# --------------------------------------------------------------------------
COPY startapp.sh /startapp.sh
RUN chmod +x /startapp.sh

# --------------------------------------------------------------------------
# Ports
#   5800     - jlesage web UI (noVNC)
#   5900     - VNC direct access
#   1234     - LM Studio OpenAI-compatible API
# --------------------------------------------------------------------------
EXPOSE 5800 5900 1234