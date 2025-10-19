FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive
ARG USERNAME=dev
ARG UID=1000
ARG GID=1000

# Base tools + build deps (covers Python-from-source builds, too)
RUN apt-get update && apt-get install -y --no-install-recommends \
    sudo git curl ca-certificates gnupg \
    build-essential make cmake ninja-build pkg-config \
    gcc g++ gdb lldb clang llvm \
    libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev \
    liblzma-dev tk-dev libffi-dev libncurses-dev xz-utils wget \
    openssh-client nano vim \
 && rm -rf /var/lib/apt/lists/*

# --- Non-root user (robust / idempotent) ---
ARG USERNAME=dev
ARG UID=1000
ARG GID=1000

RUN set -eux; \
    # Ensure group ${GID} exists and is named ${USERNAME}
    if getent group "${GID}" >/dev/null; then \
        existing_group="$(getent group "${GID}" | cut -d: -f1)"; \
        if [ "${existing_group}" != "${USERNAME}" ]; then \
            groupmod -n "${USERNAME}" "${existing_group}"; \
        fi; \
    else \
        groupadd -g "${GID}" "${USERNAME}"; \
    fi; \
    # Ensure user ${UID} exists and is named ${USERNAME}, in group ${GID}
    if id -u "${UID}" >/dev/null 2>&1; then \
        existing_user="$(getent passwd "${UID}" | cut -d: -f1)"; \
        if [ "${existing_user}" != "${USERNAME}" ]; then \
            usermod -l "${USERNAME}" "${existing_user}"; \
        fi; \
        usermod -g "${GID}" -d "/home/${USERNAME}" -m "${USERNAME}"; \
        chsh -s /bin/bash "${USERNAME}"; \
    else \
        useradd -m -s /bin/bash -u "${UID}" -g "${GID}" "${USERNAME}"; \
    fi; \
    echo "${USERNAME} ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME}; \
    chmod 0440 /etc/sudoers.d/${USERNAME}

USER ${USERNAME}
WORKDIR /workspace

# ---- Rust (stable) ----
ENV RUSTUP_HOME=/home/${USERNAME}/.rustup \
    CARGO_HOME=/home/${USERNAME}/.cargo
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable
ENV PATH=/home/${USERNAME}/.cargo/bin:$PATH
RUN rustup component add clippy rustfmt

# ---- Node (LTS) via nvm ----
USER root
ENV NVM_DIR=/usr/local/nvm
RUN mkdir -p "${NVM_DIR}" \
 && curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash \
 # Use single quotes for the whole bash -lc string; double quotes inside
 && /bin/bash -lc 'source "$NVM_DIR/nvm.sh" \
    && nvm install --lts \
    && nvm alias default "lts/*" \
    && nvm use default \
    && corepack enable \
    # Symlink Node/npm/npx to a fixed path so PATH is static (no $(...) in ENV)
    && ln -sf "$(nvm which current)" /usr/local/bin/node \
    && ln -sf "$(dirname "$(nvm which current)")/npm" /usr/local/bin/npm \
    && ln -sf "$(dirname "$(nvm which current)")/npx" /usr/local/bin/npx \
    && ln -sf "$(dirname "$(nvm which current)")/corepack" /usr/local/bin/corepack'
# (No ENV with command substitution needed)

# Make nvm available in interactive shells too (optional quality-of-life)
RUN printf '%s\n' \
  'export NVM_DIR="/usr/local/nvm"' \
  '[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"' \
  '[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"' \
  > /etc/profile.d/nvm.sh

# ---- Python (3.13.7) via pyenv ----
USER ${USERNAME}
ENV PYENV_ROOT=/home/${USERNAME}/.pyenv
ENV PATH=${PYENV_ROOT}/bin:${PYENV_ROOT}/shims:$PATH
RUN curl https://pyenv.run | bash \
 && echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bashrc \
 && echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bashrc \
 && echo 'eval "$(pyenv init -)"' >> ~/.bashrc \
 && pyenv install 3.12.5 \
 && pyenv global 3.12.5 \
 && python -V && pip -V

CMD ["/bin/bash"]
