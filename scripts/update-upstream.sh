#!/bin/bash
# About: brings a new KDE plasma-desktop release into this repository. Clones
# plasma-desktop into .upstream/, filters it exactly like this repository was
# filtered (applets/kickoff, applets/kicker, LICENSES, commit hashes in
# messages preserved), so the same upstream commits get the same ids, and
# fetches the release tag. Merging is left to the user.
# Usage: scripts/update-upstream.sh vX.Y.Z
#
# SPDX-FileCopyrightText: 2026 Ueda-Ichitaka
# SPDX-License-Identifier: MIT

set -euo pipefail

if [[ $# -ne 1 || ! $1 =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "usage: $0 vX.Y.Z   (a KDE plasma-desktop release tag)" >&2
  exit 2
fi
tag=$1
url=${UPSTREAM_URL:-https://invent.kde.org/plasma/plasma-desktop.git}

if ! command -v git-filter-repo >/dev/null; then
  echo "git-filter-repo is required: sudo pacman -S git-filter-repo" >&2
  exit 1
fi

repo=$(git -C "$(dirname "$0")/.." rev-parse --show-toplevel)
work="$repo/.upstream"
rm -rf "$work"
trap 'rm -rf "$work"' EXIT

echo "Cloning $url at $tag ..."
git clone --quiet --no-tags --single-branch --branch "$tag" "$url" "$work"
git -C "$work" filter-repo --path applets/kickoff --path applets/kicker --path LICENSES \
  --preserve-commit-hashes --force --quiet
git -C "$repo" fetch --quiet --no-tags "$work" "refs/tags/$tag:refs/tags/$tag"

cat <<MSG
Fetched $tag (filtered). Next steps:
  scripts/upstream-diff.sh        # current changes against $(cat "$repo/UPSTREAM_BASE")
  git merge $tag                  # resolve conflicts in applets/kickoff/
  echo $tag > UPSTREAM_BASE
  cmake --build build && ctest --test-dir build
MSG
