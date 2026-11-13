#!/bin/bash
# About: tests the argument checks of scripts/update-upstream.sh without
# network access: it needs exactly one KDE release tag of the form vX.Y.Z.
# Called by ctest with the script path as argument.
#
# SPDX-FileCopyrightText: 2026 Ueda-Ichitaka
# SPDX-License-Identifier: MIT

set -u
script=$1
failures=0

expect_exit() {
  local name=$1 expected=$2
  shift 2
  bash "$script" "$@" >/dev/null 2>&1
  local actual=$?
  if [[ $actual == "$expected" ]]; then
    echo "PASS: $name"
  else
    echo "FAIL: $name: expected exit $expected, got $actual"
    failures=$((failures + 1))
  fi
}

expect_exit "no argument" 2
expect_exit "two arguments" 2 v6.8.3 v6.8.4
expect_exit "not a release tag" 2 6.8.3
expect_exit "branch name" 2 master

exit $((failures > 0))
