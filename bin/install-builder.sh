#!/bin/bash

set -e

git config --global advice.detachedHead false

git clone https://github.com/jsonnet-bundler/jsonnet-bundler /src
