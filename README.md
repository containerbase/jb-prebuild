![build](https://github.com/containerbase/jb-prebuild/actions/workflows/build.yml/badge.svg)
![GitHub release](https://img.shields.io/github/v/release/containerbase/jb-prebuild)
![GitHub](https://img.shields.io/github/license/containerbase/jb-prebuild)

# jb

prebuild jsonnet-bundler[^1] (`jb`) binaries for containerbase[^2], built with a current Go toolchain.

## Versions

A release version is the upstream version plus a rebuild counter, eg. `0.6.0.1` is upstream `v0.6.0`, first build.
The versions are listed in `versions` in `builder.json`, newest last.

- Go update (Renovate PR on `Dockerfile`): add the next counter for the latest upstream version to that PR, eg. `0.6.0.2`.
- Upstream release (Renovate PR on `renovate.Dockerfile`): add `<version>.1`, eg. `0.7.0.1`.

Existing releases are never rebuilt, so CI fails a pull request that changes one of these triggers without adding a version ([`bin/check-versions.sh`](bin/check-versions.sh)).

Before each upload, `binary-builder` runs [`bin/test.sh`](bin/test.sh), which tests the archive in a plain container of each distro: a static binary, the upstream version, and the `jb install` and `jb update` runs of Renovate's jsonnet-bundler manager on [`test/jsonnetfile.json`](test/jsonnetfile.json).

## Development

`mise install` installs Node.js, pnpm, jactionlint, shellcheck and zizmor, then `pnpm install --frozen-lockfile` installs the dependencies.

```bash
pnpm lint            # pnpm oxfmt-fix to fix the formatting
jactionlint          # the GitHub workflows
zizmor .github/      # security audit of the GitHub workflows
```

CI runs jactionlint and zizmor through mise in the `lint` job, and the commit hook runs them on staged workflow files.

```bash
# build and pack a version into .cache/
docker build -t builder .
docker run --rm -v ${PWD}/.cache:/cache builder 0.6.0.1

# test the archive on all distros
bin/test.sh .cache/jb-0.6.0.1-x86_64.tar.xz 0.6.0.1
```

`DOCKER_RUN_ARGS` passes extra `docker run` arguments to `bin/test.sh` (e.g. `--network=host`).

[^1]: https://github.com/jsonnet-bundler/jsonnet-bundler

[^2]: https://github.com/containerbase/base
