# Elderland Flutter Codespace
FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04

# 避免交互式提示
ENV DEBIAN_FRONTEND=noninteractive

# 安装 Flutter 所需的基本依赖
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 安装 Flutter SDK（stable 分支）
ENV FLUTTER_HOME=/opt/flutter
ENV PATH="${FLUTTER_HOME}/bin:${PATH}"

RUN git clone --branch stable --depth 1 \
    https://github.com/flutter/flutter.git \
    "${FLUTTER_HOME}" \
    && flutter config --enable-web \
    && flutter doctor -v || true

# 确保 vscode 用户可以访问 flutter
RUN chown -R vscode:vscode "${FLUTTER_HOME}" \
    && chmod -R o+w "${FLUTTER_HOME}"

# 以 vscode 用户运行
USER vscode
