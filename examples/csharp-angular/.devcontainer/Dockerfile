# Development image: Ubuntu with git, jq, gh and Claude Code, running as the non-root user dev. It is
# stack-neutral on purpose: no language runtimes, SDKs or cloud CLIs. Add yours in the "Project toolchain"
# section below, and nowhere else, so an update of this template stays a small diff.
FROM ubuntu:26.04

ARG USERNAME=dev
ARG USER_UID=1000

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates curl git gnupg jq less locales sudo \
    && locale-gen en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

# gh comes from GitHub's own apt repository; Ubuntu's package lags behind.
RUN install -d -m 0755 /etc/apt/keyrings \
    && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        -o /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends gh \
    && rm -rf /var/lib/apt/lists/*

# Ubuntu 26.04 ships a user named ubuntu that holds UID 1000; remove it so dev can have that UID.
# The gh and git directories are created here, owned by dev, so an empty named volume mounted over either takes dev's
# ownership. dev gets passwordless sudo because the start script uses it to take ownership of a
# repository clone that a named volume holds as root.
RUN userdel -r ubuntu \
    && useradd --uid "${USER_UID}" --create-home --shell /bin/bash "${USERNAME}" \
    && install -d -o "${USERNAME}" -g "${USERNAME}" /home/${USERNAME}/.config /home/${USERNAME}/.config/gh /home/${USERNAME}/.config/git /home/${USERNAME}/.claude \
    && echo "${USERNAME} ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME} \
    && chmod 0440 /etc/sudoers.d/${USERNAME}

# ---- Project toolchain (yours) -------------------------------------------------------------------
# Runs as root, before the dev user takes over. A C# backend, an Angular frontend and Kubernetes manifests:
# .NET 10 SDK, Node 22, Playwright's Chromium (for ng test; it has amd64 and arm64 builds), the Docker CLI
# (no engine, no socket) and kubectl.

# .NET SDK from Microsoft's dotnet-install script, system-wide, with the native libraries it needs.
ENV DOTNET_ROOT=/usr/share/dotnet \
    DOTNET_CLI_TELEMETRY_OPTOUT=1 \
    DOTNET_NOLOGO=1
RUN apt-get update \
    && apt-get install -y --no-install-recommends libicu-dev zlib1g libssl-dev \
    && rm -rf /var/lib/apt/lists/* \
    && curl -fsSL https://dot.net/v1/dotnet-install.sh -o /tmp/dotnet-install.sh \
    && bash /tmp/dotnet-install.sh --channel 10.0 --install-dir "${DOTNET_ROOT}" \
    && rm /tmp/dotnet-install.sh \
    && ln -s "${DOTNET_ROOT}/dotnet" /usr/local/bin/dotnet \
    && dotnet --version

# Node 22 LTS from NodeSource.
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/* \
    && node --version

# Headless Chromium for the Angular tests: Ubuntu's chromium package is a snap and Google Chrome has no
# arm64 build, so use Playwright's, installed with its system libraries into a shared path.
ENV PLAYWRIGHT_BROWSERS_PATH=/opt/playwright
RUN npx --yes playwright install --with-deps chromium \
    && chmod -R a+rX "${PLAYWRIGHT_BROWSERS_PATH}" \
    && ln -s "$(find "${PLAYWRIGHT_BROWSERS_PATH}" -type f -path '*chromium-*' \( -name chrome -o -name headless_shell \) | head -n 1)" /usr/local/bin/chromium \
    && printf '#!/bin/sh\nexec /usr/local/bin/chromium --no-sandbox "$@"\n' >/usr/local/bin/chromium-nosandbox \
    && chmod 0755 /usr/local/bin/chromium-nosandbox \
    && rm -rf /var/lib/apt/lists/* /root/.npm
# The wrapper adds --no-sandbox, which Chromium needs in a container; Karma's stock ChromeHeadless uses it.
ENV CHROME_BIN=/usr/local/bin/chromium-nosandbox

# The Docker CLI only, from Docker's apt repository: no engine, and no socket is mounted.
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc \
    && chmod a+r /etc/apt/keyrings/docker.asc \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" \
        > /etc/apt/sources.list.d/docker.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends docker-ce-cli docker-buildx-plugin docker-compose-plugin \
    && rm -rf /var/lib/apt/lists/*

# kubectl from the official release, for this machine's architecture.
RUN KUBECTL_VERSION="$(curl -fsSL https://dl.k8s.io/release/stable.txt)" \
    && curl -fsSL "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/$(dpkg --print-architecture)/kubectl" -o /usr/local/bin/kubectl \
    && chmod +x /usr/local/bin/kubectl \
    && kubectl version --client
# ---- End project toolchain -----------------------------------------------------------------------

USER ${USERNAME}
WORKDIR /home/${USERNAME}

ENV CLAUDE_CONFIG_DIR=/home/${USERNAME}/.claude \
    PATH=/home/${USERNAME}/.local/bin:${PATH} \
    LANG=en_US.UTF-8

# Claude Code is left to update itself in a running container. The installer's first run writes state
# (including a machine id) into the config directory; keep only settings.json so none of it is baked in.
# The final claude --version fails the build if the download did not install anything (a failed curl
# piped into bash exits 0 under /bin/sh).
RUN curl -fsSL https://claude.ai/install.sh | bash -s latest \
    && find "${CLAUDE_CONFIG_DIR}" -mindepth 1 -maxdepth 1 ! -name settings.json -exec rm -rf {} + \
    && claude --version
