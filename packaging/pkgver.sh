#!/bin/bash
# About: prints the package version of Kickoff Nested for the PKGBUILD's
# pkgver(). The release version comes from the VERSION file; a build exactly
# on the release tag vVERSION gets that version, any other build
# VERSION.r<commits>.g<hash>. Upstream KDE tags (v6.x) are ignored.
# Usage: pkgver.sh <repository>
#
# SPDX-FileCopyrightText: 2026 Ueda-Ichitaka
# SPDX-License-Identifier: MIT

set -euo pipefail

repo=$1
read -r version < "$repo/VERSION"

if git -C "$repo" describe --exact-match --tags --match "v$version" HEAD >/dev/null 2>&1; then
  echo "$version"
else
  printf '%s.r%s.g%s\n' "$version" \
    "$(git -C "$repo" rev-list --count HEAD)" \
    "$(git -C "$repo" rev-parse --short HEAD)"
fi
