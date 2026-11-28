# syntax=docker/dockerfile:1
# Build on the connected build host. Nothing is fetched at container runtime.

FROM debian:bookworm-slim AS fetch
ARG NVIM_VERSION=0.12.6
ARG NVIM_SHA256=474430d53e6264f6d6dd18db42d6dc9df3a1b56ca9e88a325bbf860e1a811d87
RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl git \
 && rm -rf /var/lib/apt/lists/*
RUN curl -fsSL -o /tmp/nvim.tar.gz \
      "https://github.com/neovim/neovim/releases/download/v${NVIM_VERSION}/nvim-linux-x86_64.tar.gz" \
 && echo "${NVIM_SHA256}  /tmp/nvim.tar.gz" | sha256sum -c - \
 && mkdir -p /opt \
 && tar -xzf /tmp/nvim.tar.gz -C /opt \
 && mv /opt/nvim-linux-x86_64 /opt/nvim

ARG PLENARY_REV=74b06c6c75e4eeb3108ec01852001636d85a932b
ARG LSPCONFIG_REV=76f4cafc49677a34dc8ad8142b773d78ab4a041e
ARG CMP_REV=fe29aba4117227a6df637bc41e4b4fb4e98864a0
ARG TREESITTER_REV=52773f0d13a0c11d0c3ef33c14ab6ecc1c17148b
ARG TELESCOPE_REV=1e1bab730218eaf97fce743be3f56e51075928ac
ARG GITSIGNS_REV=166c03131e6a3528f692dd89f37668d991f17baa
RUN git init -q /opt/plugins/plenary.nvim \
 && git -C /opt/plugins/plenary.nvim fetch -q --depth 1 https://github.com/nvim-lua/plenary.nvim.git "${PLENARY_REV}" \
 && git -C /opt/plugins/plenary.nvim checkout -q FETCH_HEAD \
 && rm -rf /opt/plugins/plenary.nvim/.git
RUN git init -q /opt/plugins/nvim-lspconfig \
 && git -C /opt/plugins/nvim-lspconfig fetch -q --depth 1 https://github.com/neovim/nvim-lspconfig.git "${LSPCONFIG_REV}" \
 && git -C /opt/plugins/nvim-lspconfig checkout -q FETCH_HEAD \
 && rm -rf /opt/plugins/nvim-lspconfig/.git
RUN git init -q /opt/plugins/nvim-cmp \
 && git -C /opt/plugins/nvim-cmp fetch -q --depth 1 https://github.com/hrsh7th/nvim-cmp.git "${CMP_REV}" \
 && git -C /opt/plugins/nvim-cmp checkout -q FETCH_HEAD \
 && rm -rf /opt/plugins/nvim-cmp/.git
RUN git init -q /opt/plugins/nvim-treesitter \
 && git -C /opt/plugins/nvim-treesitter fetch -q --depth 1 https://github.com/nvim-treesitter/nvim-treesitter.git "${TREESITTER_REV}" \
 && git -C /opt/plugins/nvim-treesitter checkout -q FETCH_HEAD \
 && rm -rf /opt/plugins/nvim-treesitter/.git
RUN git init -q /opt/plugins/telescope.nvim \
 && git -C /opt/plugins/telescope.nvim fetch -q --depth 1 https://github.com/nvim-telescope/telescope.nvim.git "${TELESCOPE_REV}" \
 && git -C /opt/plugins/telescope.nvim checkout -q FETCH_HEAD \
 && rm -rf /opt/plugins/telescope.nvim/.git
RUN git init -q /opt/plugins/gitsigns.nvim \
 && git -C /opt/plugins/gitsigns.nvim fetch -q --depth 1 https://github.com/lewis6991/gitsigns.nvim.git "${GITSIGNS_REV}" \
 && git -C /opt/plugins/gitsigns.nvim checkout -q FETCH_HEAD \
 && rm -rf /opt/plugins/gitsigns.nvim/.git

FROM debian:bookworm-slim
COPY --from=fetch /opt/nvim /opt/nvim
ENV PATH="/opt/nvim/bin:${PATH}"

RUN useradd --create-home --uid 1000 --shell /bin/bash dev \
 && mkdir /work && chown dev:dev /work
COPY --chown=dev:dev config/ /home/dev/.config/nvim/
COPY --from=fetch /opt/plugins/ /home/dev/.config/nvim/pack/vendor/start/

USER dev
WORKDIR /work
ENV TERM=xterm-256color
ENTRYPOINT ["nvim"]
