#!/bin/bash

set -e

# our version, the upstream version plus a rebuild counter, eg. 0.6.0.1
VERSION=${1}

NAME=jb
ARCH=$(uname -p)

VERSION_REGEX="^([0-9]+\.[0-9]+\.[0-9]+)\.[0-9]+$"

if [[ ! "${VERSION}" =~ ${VERSION_REGEX} ]]; then
  echo Not a four part version - aborting: "${VERSION}" >&2
  exit 1
fi
UPSTREAM_VERSION=${BASH_REMATCH[1]}

echo "Building ${NAME} ${VERSION} (upstream ${UPSTREAM_VERSION}) for ${ARCH}"
git checkout --force "v${UPSTREAM_VERSION}"
mkdir -p "/usr/local/${NAME}/${VERSION}/bin"
CGO_ENABLED=0 go build -trimpath -ldflags "-s -w -X main.Version=v${UPSTREAM_VERSION}" -o "/usr/local/${NAME}/${VERSION}/bin/${NAME}" ./cmd/jb

go version -m "/usr/local/${NAME}/${VERSION}/bin/${NAME}" | head -n 1
"/usr/local/${NAME}/${VERSION}/bin/${NAME}" --version

echo "Compressing ${NAME} ${VERSION} for ${ARCH}"
tar -cJf "/cache/${NAME}-${VERSION}-${ARCH}.tar.xz" -C "/usr/local/${NAME}" "${VERSION}"
