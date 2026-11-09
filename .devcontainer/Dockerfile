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
# The gh and git directories are created here, owned by dev, so an empty named volume mounted over either takes dev's
# ownership. dev gets passwordless sudo because the start script uses it to take ownership of a
# repository clone that a named volume holds as root.
RUN userdel -r ubuntu \
    && useradd --uid "${USER_UID}" --create-home --shell /bin/bash "${USERNAME}" \
    && install -d -o "${USERNAME}" -g "${USERNAME}" /home/${USERNAME}/.config /home/${USERNAME}/.config/gh /home/${USERNAME}/.config/git /home/${USERNAME}/.claude \
    && echo "${USERNAME} ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME} \
    && chmod 0440 /etc/sudoers.d/${USERNAME}

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
