#!/bin/bash
# About: tests packaging/pkgver.sh, which derives the package version from
# the VERSION file and git: exactly VERSION on the release tag vVERSION,
# VERSION.r<commits>.g<hash> otherwise. Uses a throwaway git repository in a
# temporary directory. Called by ctest with the script path as argument.
#
# SPDX-FileCopyrightText: 2026 Ueda-Ichitaka
# SPDX-License-Identifier: MIT

set -u
script=$1
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
failures=0

check() {
  local name=$1 expected=$2 actual=$3
  if [[ $actual =~ ^${expected}$ ]]; then
    echo "PASS: $name"
  else
    echo "FAIL: $name: expected [$expected], got [$actual]"
    failures=$((failures + 1))
  fi
}

export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null
export GIT_AUTHOR_NAME=test GIT_AUTHOR_EMAIL=test@invalid GIT_COMMITTER_NAME=test GIT_COMMITTER_EMAIL=test@invalid
git -C "$tmp" init -q
echo "1.0.0" > "$tmp/VERSION"
git -C "$tmp" add VERSION
git -C "$tmp" commit -q -m one
git -C "$tmp" tag v6.8.2

check "untagged build" '1\.0\.0\.r1\.g[0-9a-f]{7,}' "$(bash "$script" "$tmp")"

git -C "$tmp" tag -a v1.0.0 -m release
check "release tag" '1\.0\.0' "$(bash "$script" "$tmp")"

git -C "$tmp" commit -q --allow-empty -m two
check "after release tag" '1\.0\.0\.r2\.g[0-9a-f]{7,}' "$(bash "$script" "$tmp")"

exit $((failures > 0))
