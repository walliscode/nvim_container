# nvim_container

A Neovim container image for an air-gapped network. It is built on a connected
build host and runs with no network access.

## Build and run (ticket 01)

### On the build host (connected)

Requires Docker.

```sh
# Build the image and run the offline check
./tests/offline_start.sh

# Or build it yourself
docker build -t nvim-container:latest .
```

The Dockerfile downloads the pinned Neovim v0.12.6 release at build time.
Nothing is fetched when the container runs.

### Starting Neovim in the container

Run this from the project you want to edit:

```sh
docker run -it --rm --network none \
  -v "$PWD":/work \
  nvim-container:latest
```

- `-it` gives Neovim a terminal. Without it, Neovim will not start.
- `--network none` confirms the container works with no network.
- `-v "$PWD":/work` mounts your current directory at `/work`. Edits are written
  to the host.
- The container runs as user `dev` (uid 1000). If your host user has a different
  uid, files you create may have different ownership.

To open a specific file:

```sh
docker run -it --rm --network none -v "$PWD":/work nvim-container:latest src/main.c
```

### Moving the image into the air gap

On the build host:

```sh
docker save nvim-container:latest -o nvim-container.tar
```

Copy `nvim-container.tar` to the target host, then load it:

```sh
docker load -i nvim-container.tar
```

After loading, follow the "Starting Neovim in the container" steps above on the
target host.
