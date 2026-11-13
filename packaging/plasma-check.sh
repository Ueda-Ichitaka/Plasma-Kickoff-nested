#!/bin/bash
# About: run by the pacman hook kickoff-nested-plasma-check.hook after
# Plasma upgrades. Compares the installed plasma-workspace version with the
# upstream plasma-desktop tag Kickoff Nested was built from and, if they
# differ, tells how to update the repository and rebuild the package. Never
# fails, so pacman is never blocked.
# Usage: plasma-check.sh [upstream-base-file] [installed-version]
#
# SPDX-FileCopyrightText: 2026 Ueda-Ichitaka
# SPDX-License-Identifier: MIT

base_file=${1:-/usr/share/kickoff-nested/upstream-base}
installed=${2-$(pacman -Q plasma-workspace 2>/dev/null | cut -d' ' -f2)}

[[ -r $base_file && -n $installed ]] || exit 0

read -r base < "$base_file"
version=${installed#*:}
version=${version%-*}
tag="v$version"

[[ $tag == "$base" ]] && exit 0

cat <<MSG
==> kickoff-nested was built from Plasma $base, installed Plasma is $tag.
    Update the repository and rebuild the package:
      scripts/update-upstream.sh $tag
      git merge $tag        (then set UPSTREAM_BASE to $tag)
      cd packaging && makepkg -si
MSG
exit 0
