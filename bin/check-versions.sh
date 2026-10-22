#!/bin/bash

# Fails when a rebuild trigger changed but builder.json gets no new version,
# because binary-builder never rebuilds an existing release.
# Triggers: the golang version in the Dockerfile and the upstream version in renovate.Dockerfile.
# Usage: check-versions.sh <base-ref>, eg. `HEAD^1` on the merge commit of a pull request

set -e

if [[ $# -ne 1 ]]; then
  echo "Usage: check-versions.sh <base-ref>" >&2
  exit 1
fi

BASE=${1}

triggers=()
if git diff "${BASE}" HEAD -- Dockerfile | grep -q '^[-+]RUN install-tool golang '; then
  triggers+=("golang in Dockerfile")
fi
if ! git diff --quiet "${BASE}" HEAD -- renovate.Dockerfile; then
  triggers+=("renovate.Dockerfile")
fi

if [[ ${#triggers[@]} -eq 0 ]]; then
  echo "No rebuild trigger changed"
  exit 0
fi

# the base has no builder.json before the first versions are added
base_versions=$(git show "${BASE}:builder.json" 2> /dev/null | jq -r '.versions[]?' || true)
if [[ -z "${base_versions}" ]]; then
  new_versions=$(jq -r '.versions[]' builder.json)
else
  # grep takes each line of the base versions as a pattern
  new_versions=$(jq -r '.versions[]' builder.json | grep -vxF -e "${base_versions}" || true)
fi

if [[ -z "${new_versions}" ]]; then
  echo "Changed: ${triggers[*]}, but builder.json has no new version." >&2
  echo "Add the next version to \`versions\` in builder.json, see README.md." >&2
  exit 1
fi

echo "Changed: ${triggers[*]}, new versions: ${new_versions//$'\n'/, }"
