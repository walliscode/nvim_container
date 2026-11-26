# Air-Gapped Neovim Container

A Neovim environment packaged as a container image that runs with no internet access. It is built on a connected machine and loaded into an air-gapped host.

## Language

**Air gap**:
A network with no route to the internet. The container must work fully inside it.
_Avoid_: Offline, isolated network

**Build host**:
The connected machine where the image is built and the tarball is exported.
_Avoid_: CI, builder

**Target host**:
The air-gapped machine where the image tarball is loaded and the container runs.
_Avoid_: Production, server

**Image tarball**:
The exported container image file that moves from the build host to the target host.
_Avoid_: Artifact, bundle

**Vendored plugin**:
A plugin's source, pinned to a specific commit, copied into the image at build time. Nothing is fetched at runtime.
_Avoid_: Installed plugin, managed plugin

**Pinned version**:
A specific commit or release that a vendored plugin, language server, or parser is locked to.
_Avoid_: Latest, floating version

**Expansion candidate**:
A plugin on the reviewed list that is not in the image yet and would be added through a rebuild.
_Avoid_: Optional plugin, future plugin

**Language package**:
The language server and Treesitter parser set for one language, baked into the image.
_Avoid_: Language support, LSP bundle
