# Kickoff Nested

The KDE Plasma 6 Application Launcher (Kickoff) with nested subfolders.

Stock Kickoff shows one level of categories and lists every application of a
category in one flat list, even when the menu defines subfolders. Kickoff
Nested keeps Kickoff's look and adds the cascading subfolder flyouts of the
classic Application Menu (Kicker):

```
Applications                    BlackArch > Scanner >  nmap
  Favorites                                            masscan
  BlackArch   > Cracker      >                         rustscan
  Development   Exploitation >                         ...
  Internet      Scanner      >
  ...           ...
```

It was made for menus such as BlackArch's (`BlackArch > Scanner > nmap`),
and works for every category with subfolders.

## Status

Work in progress. The implementation plan is in [docs/PLAN.md](docs/PLAN.md);
its status table shows which steps are done. The build and install
instructions below describe the finished project and work from plan step 1
on.

## Features

- Kickoff's layout, search, favorites, places and power buttons, unchanged
- Subfolders in every category, opened as Kicker-style cascading flyouts
- Opens on hover (100 ms), click, or Right/Enter; Left/Esc goes back
- Works in Kickoff's list and grid display modes
- "Show subfolders" setting to switch back to Kickoff's flat behavior
- Installs as a separate widget; the system Kickoff stays untouched

## Screenshots

Screenshots are added to `docs/screenshots/` when the flyouts work
(plan steps 4 and 5):

| File | Shows |
|---|---|
| `docs/screenshots/list-flyout.png` | List mode, `BlackArch > Scanner` flyout |
| `docs/screenshots/grid-flyout.png` | Grid mode, flyout from a folder tile |
| `docs/screenshots/settings.png` | "Show subfolders" setting |

## Requirements

- Arch Linux based system (developed on EndeavourOS)
- Plasma 6.8.2 (`plasma-desktop`, `plasma-workspace`, `libplasma`)
- Build tools: `base-devel`, `cmake`, `extra-cmake-modules`, `ninja`

```
sudo pacman -S --needed base-devel cmake extra-cmake-modules ninja
```

The applet is compiled against the installed Plasma version. After a Plasma
upgrade, rebuild and reinstall it (see Install).

## Quickstart

```
git clone <this repository> kickoff-nested
cd kickoff-nested/packaging
makepkg -si
```

Then switch your launcher: right-click the Application Launcher in the panel,
choose **Show Alternatives...**, and select **Kickoff Nested**.

## Install

### Package (recommended)

`packaging/PKGBUILD` builds the applet and installs it as a pacman package:

```
cd packaging
makepkg -si
```

- Installs the applet plugin to `/usr/lib/qt6/plugins/plasma/applets/`
- Installs the Kicker parts QML module to `/usr/lib/qt6/qml/kickoffnested/`
- Remove with `sudo pacman -R kickoff-nested`

Restart Plasma once after the first install so it picks up the new widget:

```
systemctl --user restart plasma-plasmashell.service
```

### Development build

```
cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Debug
cmake --build build
ctest --test-dir build --output-on-failure
```

Plasma loads applets only from its plugin path, so a development build is
tried out through the package install above.

## Usage

- Hover over a folder, or click it, to open its flyout; flyouts cascade
- Keyboard: Up/Down move, Right/Enter open a folder, Left/Esc go back
- Settings: right-click the launcher, **Configure Kickoff Nested...**,
  **Show subfolders**

## How it works

- The menu data comes from Plasma's shared launcher backend
  (`org.kde.plasma.private.kicker`, part of `plasma-workspace`). With
  `flat: false` it keeps subfolders as folder rows.
- `applets/kickoff/` is Kickoff, modified in place: folder rows open a flyout
  instead of starting an application.
- The flyouts are Kicker's own components, built unmodified from
  `applets/kicker/` as a separate QML module.

Details: [docs/PLAN.md](docs/PLAN.md).

## Repository layout

```
applets/kickoff/   Kickoff (upstream plasma-desktop, modified)
applets/kicker/    Kicker (upstream plasma-desktop, subfolder parts reused)
docs/              plan, manual test checklist, screenshots
LICENSES/          license texts referenced by the SPDX headers
LICENSE            MIT license for the files written for this project
.gitignore         build output, makepkg output, editor files
```

Files added by later plan steps (`CMakeLists.txt`, `cmake/`, `tests/`,
`packaging/`, `scripts/`) are listed in [docs/PLAN.md](docs/PLAN.md),
section 4.6.

The repository is plasma-desktop filtered to the paths above, with their
full upstream history, based on tag `v6.8.2`.

## Updating to a new Plasma release

The history was filtered with

```
git filter-repo --path applets/kickoff --path applets/kicker --path LICENSES --preserve-commit-hashes
```

which gives the same commit ids for the same upstream commits on every run.
A new KDE release can therefore be filtered the same way and merged:

1. Filter a fresh clone of https://invent.kde.org/plasma/plasma-desktop
   with the command above (plan step 8 adds `scripts/update-upstream.sh`).
2. Fetch the new tag from the filtered clone into this repository.
3. `git merge <tag>`, resolve conflicts, rebuild, reinstall.

## License

The project mixes two licenses:

| Files | License |
|---|---|
| Files written for Kickoff Nested (build files, scripts, new QML/JS, tests, docs) | MIT, see [LICENSE](LICENSE); each carries `SPDX-License-Identifier: MIT` |
| Upstream KDE files in `applets/kickoff/` and `applets/kicker/`, including our changes to them | Their own SPDX header, mostly GPL-2.0-or-later |
| The compiled applet and the pacman package, which combine both | GPL-2.0-or-later |

MIT is compatible with the GPL, so the MIT files can be combined with the
KDE code; the combination as a whole has to follow GPL-2.0-or-later. All
license texts are in `LICENSES/`.

## Credits

Kickoff and Kicker are developed by the KDE community; see the SPDX headers
in `applets/` for the authors. Upstream:
https://invent.kde.org/plasma/plasma-desktop
