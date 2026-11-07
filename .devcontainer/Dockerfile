# Development image for codeo itself: Ubuntu 24.04 with the tools codeo's shell suites and its own
# workflow need (bash, git, jq, shellcheck, gh) plus Claude Code, running as the non-root user dev.
#
# Left out on purpose: language runtimes and SDKs, cloud CLIs, database clients, Kubernetes tooling and
# a container engine. codeo is plain bash; nothing here builds or deploys anything beyond it.
FROM ubuntu:24.04

ARG USERNAME=dev
ARG USER_UID=1000

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates curl git gnupg jq less locales shellcheck sudo \
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

# Ubuntu 24.04 ships a user named ubuntu that holds UID 1000; remove it so dev can have that UID.
# The gh directory is created here, owned by dev, so an empty named volume mounted over it takes dev's
# ownership. /workspaces is where VS Code's clone-in-volume puts the repository (cloned as root), so dev
# gets passwordless sudo to take ownership of it.
RUN userdel -r ubuntu \
    && useradd --uid "${USER_UID}" --create-home --shell /bin/bash "${USERNAME}" \
    && install -d -o "${USERNAME}" -g "${USERNAME}" /home/${USERNAME}/.config /home/${USERNAME}/.config/gh /home/${USERNAME}/.claude \
    && install -d -o "${USERNAME}" -g "${USERNAME}" /workspaces \
    && echo "${USERNAME} ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME} \
    && chmod 0440 /etc/sudoers.d/${USERNAME}

USER ${USERNAME}
WORKDIR /home/${USERNAME}

ENV CLAUDE_CONFIG_DIR=/home/dev/.claude \
    PATH=/home/dev/.local/bin:${PATH} \
    LANG=en_US.UTF-8

# Claude Code is left to update itself in a running container. The installer's first run writes state
# (including a machine id) into the config directory; keep only settings.json so none of it is baked in.
RUN curl -fsSL https://claude.ai/install.sh | bash -s latest \
    && find "${CLAUDE_CONFIG_DIR}" -mindepth 1 -maxdepth 1 ! -name settings.json -exec rm -rf {} +
