#!/bin/bash
# About: shows this fork's changes to the upstream KDE files in applets/
# against the release in UPSTREAM_BASE, including uncommitted changes.
# Arguments are passed to git diff as options, e.g. --stat.
# Usage: scripts/upstream-diff.sh [git diff options]
#
# SPDX-FileCopyrightText: 2026 Ueda-Ichitaka
# SPDX-License-Identifier: MIT

set -euo pipefail

repo=$(git -C "$(dirname "$0")/.." rev-parse --show-toplevel)
read -r base < "$repo/UPSTREAM_BASE"

git -C "$repo" diff "$base" "$@" -- applets/
