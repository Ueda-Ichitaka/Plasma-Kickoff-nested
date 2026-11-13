#!/bin/bash
# About: tests packaging/plasma-check.sh, the pacman hook script that warns
# when the installed Plasma version differs from the upstream base Kickoff
# Nested was built from. Called by ctest with the script path as argument.
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
  if [[ $actual == *"$expected"* ]]; then
    echo "PASS: $name"
  else
    echo "FAIL: $name: expected output containing [$expected], got [$actual]"
    failures=$((failures + 1))
  fi
}

check_empty() {
  local name=$1 actual=$2
  if [[ -z $actual ]]; then
    echo "PASS: $name"
  else
    echo "FAIL: $name: expected no output, got [$actual]"
    failures=$((failures + 1))
  fi
}

echo "v6.8.2" > "$tmp/base"

check_empty "same version is silent" "$(bash "$script" "$tmp/base" "6.8.2-1" 2>&1)"
check "patch update names the tag" "v6.8.3" "$(bash "$script" "$tmp/base" "6.8.3-1" 2>&1)"
check "patch update names the update command" "scripts/update-upstream.sh v6.8.3" "$(bash "$script" "$tmp/base" "6.8.3-1" 2>&1)"
check "names the built-for base" "v6.8.2" "$(bash "$script" "$tmp/base" "6.8.3-1" 2>&1)"
check "epoch is ignored" "v6.9.0" "$(bash "$script" "$tmp/base" "1:6.9.0-2" 2>&1)"
check_empty "missing base file is silent" "$(bash "$script" "$tmp/missing" "6.8.3-1" 2>&1)"
check_empty "unknown installed version is silent" "$(bash "$script" "$tmp/base" "" 2>&1)"

bash "$script" "$tmp/base" "6.9.0-1" >/dev/null 2>&1
check "never fails pacman (exit 0)" "0" "$?"

exit $((failures > 0))
