# syntax=docker/dockerfile:1
# Build on the connected build host. Nothing is fetched at container runtime.

FROM debian:bookworm-slim AS fetch
ARG NVIM_VERSION=0.12.6
ARG NVIM_SHA256=474430d53e6264f6d6dd18db42d6dc9df3a1b56ca9e88a325bbf860e1a811d87
RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl \
 && rm -rf /var/lib/apt/lists/*
RUN curl -fsSL -o /tmp/nvim.tar.gz \
      "https://github.com/neovim/neovim/releases/download/v${NVIM_VERSION}/nvim-linux-x86_64.tar.gz" \
 && echo "${NVIM_SHA256}  /tmp/nvim.tar.gz" | sha256sum -c - \
 && mkdir -p /opt \
 && tar -xzf /tmp/nvim.tar.gz -C /opt \
 && mv /opt/nvim-linux-x86_64 /opt/nvim

FROM debian:bookworm-slim
COPY --from=fetch /opt/nvim /opt/nvim
ENV PATH="/opt/nvim/bin:${PATH}"

RUN useradd --create-home --uid 1000 --shell /bin/bash dev \
 && mkdir /work && chown dev:dev /work
COPY --chown=dev:dev config/ /home/dev/.config/nvim/

USER dev
WORKDIR /work
ENV TERM=xterm-256color
ENTRYPOINT ["nvim"]
