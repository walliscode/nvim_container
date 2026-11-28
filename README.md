# nvim_container

A Neovim container image for an air-gapped network. It is built on a connected
build host and runs with no network access.

## Build and run (ticket 01)

### On the build host (connected)

Requires Docker.

```sh
# Build the image, run every check in tests/checks/, and keep the image only if they all pass
./tests/build-and-test.sh
```

It refuses to run with uncommitted changes, so every tagged image matches a commit.

On pass the script tags the tested image as `nvim-container:latest` and
`nvim-container:<nvim-version>-<git-sha>`, and prints the image and layer sizes.
On fail it removes the image and exits non-zero, so an untested image is never
left behind.

To run only the checks against an image that already exists, use
`NVIM_TEST_IMAGE=<tag> ./tests/run.sh`.

The Dockerfile downloads the pinned Neovim v0.12.6 release at build time.
Nothing is fetched when the container runs.

### Creating the internal network

The container runs on an internal-only Docker network. It has no route to the
internet, but other hosts on the internal network are reachable from it.

```sh
docker network create --internal nvim-internal
```

### Starting Neovim in the container

Run this with your personal drive mounted. Your drive lives at
`user/${COMPANY_USER_NAME}` on the host:

```sh
docker run -it --rm --network nvim-internal \
  --user "$(id -u):$(id -g)" \
  -v "$HOME/user/${COMPANY_USER_NAME}":/work \
  nvim-container:latest
```

- `-it` gives Neovim a terminal. Without it, Neovim will not start.
- `--network nvim-internal` keeps the container on the internal network.
- `-v ...:/work` mounts your personal drive at `/work`. It is the only place the
  container can write. Your personal config lives in `/work/.nvim/`.
- `--user "$(id -u):$(id -g)"` makes files you create owned by your host user.
  Without it, they are owned by uid 1000.

To open a specific file, add it after the image name:

```sh
docker run -it --rm --network nvim-internal --user "$(id -u):$(id -g)" \
  -v "$HOME/user/${COMPANY_USER_NAME}":/work nvim-container:latest src/main.c
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
