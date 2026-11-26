# syntax=docker/dockerfile:1
# Build on the connected build host. Nothing is fetched at container runtime.

FROM debian:bookworm-slim AS fetch
ARG NVIM_VERSION=0.12.6
RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl \
 && rm -rf /var/lib/apt/lists/*
RUN curl -fsSL -o /tmp/nvim.tar.gz \
      "https://github.com/neovim/neovim/releases/download/v${NVIM_VERSION}/nvim-linux-x86_64.tar.gz" \
 && mkdir -p /opt \
 && tar -xzf /tmp/nvim.tar.gz -C /opt \
 && mv /opt/nvim-linux-x86_64 /opt/nvim

FROM debian:bookworm-slim
COPY --from=fetch /opt/nvim /opt/nvim
ENV PATH="/opt/nvim/bin:${PATH}"

RUN useradd --create-home --uid 1000 --shell /bin/bash dev
COPY config/ /home/dev/.config/nvim/
RUN chown -R dev:dev /home/dev/.config

USER dev
WORKDIR /work
ENV TERM=xterm-256color
ENTRYPOINT ["nvim"]
