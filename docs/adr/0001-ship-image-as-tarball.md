# Build on a connected machine and ship the image as a tarball

The image is built on a connected build host and exported as a tarball to the air-gapped target host, rather than built inside the air gap or pulled from an internal registry. This keeps the target host free of build tooling and any network dependency. The cost is that every update requires a new tarball transfer.
