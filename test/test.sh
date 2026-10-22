#!/bin/bash

# Tests a jb archive inside a plain ubuntu container.
# Usage: test.sh <archive> <version>

set -e

ARCHIVE=${1}
VERSION=${2}

CODENAME=$(awk -F= '$1 == "VERSION_CODENAME" { gsub(/"/, "", $2); print $2 }' /etc/os-release)

NAME=jb
ARCH=$(uname -m)
# our version is the upstream version plus a rebuild counter, eg. 0.6.0.1
UPSTREAM_VERSION=${VERSION%.*}
JB="/usr/local/${NAME}/${VERSION}/bin/${NAME}"

# xz-utils is only needed to extract the archive, git and ca-certificates for `jb install`
export DEBIAN_FRONTEND=noninteractive
apt-get update -q
apt-get install -q -y --no-install-recommends ca-certificates git xz-utils

echo "Testing ${NAME} ${VERSION} on ${CODENAME}-${ARCH}"
mkdir -p "/usr/local/${NAME}"
tar -xf "${ARCHIVE}" -C "/usr/local/${NAME}"

# a static binary, so it runs on every distro
if ldd "${JB}"; then
  echo "Not a static binary: ${JB}" >&2
  exit 1
fi

actual=$("${JB}" --version 2>&1)
echo "${actual}"
if [[ "${actual}" != "v${UPSTREAM_VERSION}" ]]; then
  echo "Unexpected version: ${actual}" >&2
  exit 1
fi

# what `git ls-remote` returns for the docsonnet tags, which jb pins:
# the commit of the lightweight v0.0.4, the tag object of the annotated v0.0.5
OLD_SHA=0486f08fc15771ec2a68245a92115c63188395af # v0.0.4
NEW_SHA=cd36b34b0108dbf1c25f0264dcd92b433d506656 # v0.0.5
DEP_URL=https://github.com/jsonnet-libs/docsonnet.git/doc-util

# Fails unless the lock file pins the dependency to the given sha.
function check_lock () {
  cat jsonnetfile.lock.json
  if ! grep -q "\"version\": \"${1}\"" jsonnetfile.lock.json; then
    echo "Lock file not at ${1}" >&2
    exit 1
  fi
}

work=$(mktemp -d)
cp "$(dirname "${BASH_SOURCE[0]}")/jsonnetfile.json" "${work}/"
cd "${work}"

# create the lock file renovate's jsonnet-bundler manager needs
"${JB}" install
check_lock "${OLD_SHA}"
if [[ ! -f vendor/github.com/jsonnet-libs/docsonnet/doc-util/main.libsonnet ]]; then
  echo "Library not vendored" >&2
  exit 1
fi

# a dependency update: renovate bumps the version, then runs `jb update <url>`
sed -i 's/"v0.0.4"/"v0.0.5"/' jsonnetfile.json
"${JB}" update "${DEP_URL}"
check_lock "${NEW_SHA}"

# lock file maintenance: renovate runs `jb update`
"${JB}" update
check_lock "${NEW_SHA}"
