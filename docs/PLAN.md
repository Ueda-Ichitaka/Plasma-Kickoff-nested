# Kickoff Nested - Implementation Plan

Kickoff (the Plasma 6 "Application Launcher") with nested subfolders shown
as Kicker-style cascading flyouts. This document is the working plan: design,
decisions, steps, tests and risks.

## 1. Goal

Stock Kickoff shows one level of categories. Its root model is created with
`flat: true // have categories, but no subcategories` (`applets/kickoff/main.qml`),
and its views have no code path for opening a folder: activating an entry calls
`model.trigger()`, which does nothing for a group entry.

Kickoff Nested keeps Kickoff's look and behavior and adds:

- subfolders inside every category, e.g. `BlackArch > Scanner > nmap`
- folders open as cascading flyouts, taken from Kicker
  (`ItemListDialog` / `ItemListView` / `ItemListDelegate`)
- opening by hover (100 ms, as in Kicker), click, or Right/Enter
- working in Kickoff's list and grid display modes

It installs as a separate widget next to the system Kickoff; the system
Kickoff is not modified.

## 2. Decisions

| Topic | Decision |
|---|---|
| Opening a folder | Hover (100 ms) + click + Right/Enter |
| Display modes | List and grid |
| Scope | All categories (`flat: false` for the whole root model) |
| Build | Compiled applet (`plasma_add_applet`), like the system Kickoff |
| Install | pacman package via `PKGBUILD` (`makepkg -si`) |
| Repository | plasma-desktop filtered to `applets/kickoff`, `applets/kicker`, `LICENSES` with `git filter-repo --preserve-commit-hashes`, branch `kickoff-nested` on tag `v6.8.2` |
| Upstream base | Plasma 6.8.2, matching the installed `plasma-desktop 6.8.2-1` |
| Plugin id / name | `local.kickoffnested` / "Kickoff Nested" |
| License | New files: MIT (`LICENSE`), with `SPDX-License-Identifier: MIT` and an about-me header. Upstream files keep their SPDX header (GPL-2.0-or-later); changes to them stay under that license. Built applet and package: GPL-2.0-or-later |

## 3. Background (verified against v6.8.2)

### 3.1 Data model

The menu data comes from `org.kde.plasma.private.kicker`, installed by
`plasma-workspace` (source: plasma-workspace `applets/kicker/`). It is shared
by Kicker and Kickoff and needs no change:

- `RootModel.flat: false` keeps subfolders as `AppGroupEntry` rows
  (`appsmodel.cpp`) instead of merging their apps into the parent.
- Folder rows expose the roles `isParent` and `hasChildren`
  (`abstractmodel.cpp`); `modelForRow(i)` returns the folder's own model.
- Sorting puts folders before applications (`AppsModel::sortEntries`).
- `flat: true` forces `sorted = true`; with `flat: false` sorting follows
  Kickoff's `alphaSort` setting.

### 3.2 Kicker's subfolder components

| File (`applets/kicker/`) | Role |
|---|---|
| `ItemListDialog.qml` | Flyout window, a `Kicker.SubMenu` (C++ `PlasmaQuick::Dialog` subclass) |
| `ItemListView.qml` | List inside a flyout; spawns the next flyout after 100 ms hover, Right arrow opens, Left closes, Esc concludes |
| `ItemListDelegate.qml` | Row with folder arrow |
| `ItemAbstractDelegate.qml` | Base row: roles, drag, context menu |
| `HoverBlocker.qml` | Suppresses hover until the mouse really moves |
| `ActionMenu.qml` | Kicker's context menu singleton |
| `code/tools.js` | `fillActionMenu`, `triggerAction`, favorites helpers |

Globals these files use (complete list, from grep):

| Global | Used by |
|---|---|
| `kicker.expanded` | `ItemListView` |
| `kicker.reset` (signal) | `ItemListDialog` |
| `itemListDialogComponent` | `ItemListView` |
| `ActionMenu.*` (Kicker's singleton) | `ItemListView`, `ItemAbstractDelegate` |
| `Tools.*` from `code/tools.js` (Kicker's) | `ItemAbstractDelegate`, `ActionMenu` |
| `Plasmoid.containmentDisplayHints`, `Plasmoid.configuration.appNameFormat` | `ItemListDialog`, `ItemListDelegate` (both available in Kickoff) |

### 3.3 Kickoff

- Pure QML, built by `plasma_add_applet(org.kde.plasma.kickoff ...)` into
  `/usr/lib/qt6/plugins/plasma/applets/org.kde.plasma.kickoff.so`.
- Singletons `KickoffSingleton` and `ActionMenu` (same type name as Kicker's,
  different API).
- Root object id `kickoff`; app views `KickoffListView` / `KickoffGridView` /
  `ListOfGridsView`, rows derive from `AbstractKickoffItemDelegate`.
- Sidebar row `n` selects `rootModel.modelForRow(n)` for the right pane
  (`ApplicationsPage.qml`).

## 4. Design

### 4.1 Keep upstream mergeable

KDE updates arrive as merges into `applets/kickoff` and `applets/kicker`.
To keep those merges small:

- **Kickoff is modified in place** in `applets/kickoff/`, not copied.
- **Kicker's subfolder files are used unmodified** from `applets/kicker/`.
- New code lives in new files (new QML components, `code/nested.js`, top-level
  build files), so upstream changes rarely touch it.

### 4.2 Kicker parts as a separate QML module

The Kicker files are compiled into their own internal QML module,
`kickoffnested.kickerparts`, built from `applets/kicker/` sources:
`ItemListDialog.qml`, `ItemListView.qml`, `ItemListDelegate.qml`,
`ItemAbstractDelegate.qml`, `HoverBlocker.qml`, `ActionMenu.qml` (singleton),
`code/tools.js`.

A separate module gives them their own type namespace, so Kicker's
`ActionMenu` and `code/tools.js` do not clash with Kickoff's files of the
same name.

### 4.3 Bridge object in Kickoff

Kickoff's `main.qml` gets a small object that provides what the Kicker
files look up by name:

```qml
QtObject {
    id: kicker
    readonly property bool expanded: kickoff.expanded
    signal reset
    readonly property Component itemListDialogComponent: Component {
        KickerParts.ItemListDialog {}
    }
}
```

`reset` is emitted when Kickoff collapses, so open flyouts close and their
models reset. `ItemListView` refers to `itemListDialogComponent` without a
prefix; whether that resolves through the bridge or needs a root-level
property on `kickoff` is checked in step 1 (section 7, R2).

### 4.4 Changes to Kickoff

| File | Change |
|---|---|
| `main.qml` | `flat: false`; bridge object; emit `kicker.reset()` on collapse |
| `metadata.json`, `CMakeLists.txt` | New plugin id and name, so it installs next to the system Kickoff |
| `KickoffListDelegate.qml`, `KickoffGridDelegate.qml` | Folder arrow or folder badge for rows with `hasChildren` |
| `AbstractKickoffItemDelegate.qml` | For folder rows: hover timer and click open a flyout instead of `trigger()` |
| `KickoffListView.qml`, `KickoffGridView.qml` | Own the open flyout (`childDialog`), close it when the current index changes, Right/Enter/Left key handling |
| `ConfigGeneral.qml`, `main.xml` | Setting "Show subfolders" (default on), bound to `flat` |

The flyout opening logic is shared through a new `NestedFlyoutController.qml`
component used by both views, so the two views stay as close to upstream as
possible.

### 4.5 Flyout placement

- List mode: the flyout opens at the right edge of the row (left edge in RTL),
  like Kicker's own cascade (`Kicker.SubMenu` positions itself relative to its
  `visualParent`).
- Grid mode: `visualParent` is the grid tile; the flyout opens on the side with
  more free screen space. The side choice is a pure function in
  `code/nested.js` so it can be unit tested.

### 4.6 Build layout

```
CMakeLists.txt              top level: find_package ECM, Qt6, KF6, Plasma; adds the two targets
cmake/KickerParts.cmake     ecm_add_qml_module for kickoffnested.kickerparts from applets/kicker/
applets/kickoff/            the applet (modified in place)
applets/kicker/             upstream Kicker, only the files listed in 4.2 are built
tests/                      qmltestrunner tests
packaging/PKGBUILD          builds and installs the pacman package
scripts/update-upstream.sh  re-filters a new KDE release and fetches its tag
scripts/upstream-diff.sh    shows this fork's changes against the upstream tag
docs/                       this plan, manual test checklist, screenshots
```

Dependencies for the standalone build, a subset of plasma-desktop's
`CMakeLists.txt`: `ECM`, `Qt6` (Core, Gui, Qml, Quick), `KF6` (I18n,
CoreAddons), `Plasma`. The exact set is settled in step 1 by building.

The kickerparts module is installed as a normal QML module under
`/usr/lib/qt6/qml/kickoffnested/kickerparts/` by the pacman package.

## 5. Steps

Each step follows the TDD loop (red, green, refactor) where automated tests
are possible, runs `qmllint` on all changed QML, and ends with its manual
checks from `docs/MANUAL-TESTS.md`.

### Step 1 - Build spike

Goal: unchanged Kickoff built from this repo, installed as a separate widget.

1. Test first: `tests/tst_smoke.qml` loads the built QML module (fails: no build yet).
2. Top-level `CMakeLists.txt` building `applets/kickoff` standalone.
3. Plugin id `local.kickoffnested` and name "Kickoff Nested" in `metadata.json` and `CMakeLists.txt`.
4. `packaging/PKGBUILD`; `makepkg -si`; add the widget via "Show Alternatives...".
5. Verify: same behavior as system Kickoff; translations (R4); config dialog opens.
6. Build the kickerparts module (section 4.2) and import it from a test (R2, R3).

Done when: the widget runs, the smoke test passes, kickerparts loads.

### Step 2 - Nesting on

1. Test first: with a mock model containing a folder row, the list and grid
   delegates expose `isFolder === true` and show the folder indicator.
2. `flat: false` in `main.qml`; folder indicator in both delegates.
3. Manual: BlackArch shows its category folders; nothing opens yet.

### Step 3 - Bridge and Kicker parts

1. Test first: bridge `expanded` follows `kickoff.expanded`; collapsing emits `reset`.
2. Bridge object (4.3); kickerparts import in Kickoff.
3. Manual: no QML warnings about `kicker` or `itemListDialogComponent` in the
   journal (`journalctl --user -f -t plasmashell`).

### Step 4 - Flyouts in list mode

1. Test first: `code/nested.js` decision functions (open on hover after
   delay, open on click, ignore separators and non-folders) with mock rows.
2. `NestedFlyoutController.qml`; wire into `KickoffListView` and
   `AbstractKickoffItemDelegate`.
3. Cascading: flyouts open further flyouts (Kicker's own `ItemListView`).
4. Starting an app from any flyout level closes all flyouts and Kickoff.
5. Manual: focus risk R1 checked first; screenshot `docs/screenshots/list-flyout.png`.

### Step 5 - Flyouts in grid mode

1. Test first: placement function picks the side with more space; RTL mirrors.
2. Wire the controller into `KickoffGridView`.
3. Manual: tiles at left, middle and right of the grid; screenshot
   `docs/screenshots/grid-flyout.png`.

### Step 6 - Keyboard

1. Test first: key mapping function (Right/Enter open, Left/Esc back,
   mirrored in RTL).
2. Key handling in both views; Kicker's `ItemListView` already handles keys
   inside flyouts.
3. Manual: full keyboard walk `BlackArch > Scanner > nmap > Enter`.

### Step 7 - Setting and polish

1. Test first: setting off restores `flat: true` behavior.
2. "Show subfolders" checkbox in `ConfigGeneral.qml`, key in `main.xml`.
3. Hover blocking on open (Kicker's `HoverBlocker`), no flicker when moving
   diagonally into a flyout.

### Step 8 - Maintenance tooling

1. `scripts/update-upstream.sh <tag>`: temporary full clone from KDE,
   `git filter-repo --path applets/kickoff --path applets/kicker --path LICENSES --preserve-commit-hashes`,
   fetch the tag into this repo. The merge itself is done by hand.
2. `scripts/upstream-diff.sh`: diff of `applets/` against the base tag.
3. Optional pacman hook that reminds to rebuild after `plasma-desktop`,
   `plasma-workspace` or `libplasma` upgrades.

## 6. Testing

### Automated

Run with `ctest --test-dir build --output-on-failure`. The build uses Qt 6's
`qmltestrunner` (`/usr/lib/qt6/bin/qmltestrunner`); the `qmltestrunner` on
the PATH belongs to Qt 5 (`qt5-declarative`) and cannot load these tests.

- `qmltestrunner` tests in `tests/`, run through `ctest` with the build
  directory's QML import path.
- Logic that decides behavior lives in `applets/kickoff/code/nested.js`
  (pure functions) and is tested directly.
- QML components are tested with mock models (`ListModel` rows with
  `display`, `isParent`, `hasChildren`, `isSeparator`, and a mock
  `modelForRow`).
- `qmllint` over changed files as a gate.

### Manual

A widget's popup, window activation and hover behavior cannot run inside
`qmltestrunner`. `docs/MANUAL-TESTS.md` holds the checklist per step,
executed in a running Plasma session after `makepkg -si` and
`plasmashell --replace` (or logout/login).

## 7. Risks and open questions

| Id | Risk / question | Check | Fallback |
|---|---|---|---|
| R1 | Kickoff's popup may close when a flyout window takes focus. Kicker's QML does nothing special; the handling is assumed to be in `PlasmaQuick::Dialog` (flyout is a transient child of the popup). | Step 4, first thing | Open folders inside the right pane with a back button instead of flyouts |
| R2 | ✅ test-level: `tst_kickerparts` resolves `kicker` through the creating context; a copy with the id renamed fails with `kicker is not defined`. Unqualified `kicker` / `itemListDialogComponent` lookups from a second QML module may not resolve through the context chain under `pragma ComponentBehavior: Bound` and compiled QML. | Step 1 test | Copy the Kicker files into Kickoff with explicit properties instead of globals |
| R3 | ✅ all Kicker parts compile and load as `kickoffnested.kickerparts`. Building Kicker's files outside their original module (`plasma.applet.org.kde.plasma.kicker`) may need adjustments, e.g. `Plasmoid` attached object resolution. | Step 1 | Same as R2 |
| R4 | Translations: with a new plugin id the translation domain changes, so Kickoff's existing `.mo` files are not used. | Step 1 | Set the domain explicitly to `plasma_applet_org.kde.plasma.kickoff` if libplasma allows it, else English strings |
| R5 | Plasma updates: the compiled applet is built against Plasma 6.8.2. | Each Plasma upgrade | Rebuild with `makepkg -si`; step 8 adds a reminder hook |

## 8. Status

| Step | State |
|---|---|
| Repository filtered and on `v6.8.2` | ✅ |
| Build tools installed (`cmake` 4.4.5, `extra-cmake-modules` 6.31.0) | ✅ |
| 1 Build spike | automated part ✅, manual checks (docs/MANUAL-TESTS.md) pending |
| 2 Nesting on | ❌ |
| 3 Bridge and Kicker parts | ❌ |
| 4 Flyouts in list mode | ❌ |
| 5 Flyouts in grid mode | ❌ |
| 6 Keyboard | ❌ |
| 7 Setting and polish | ❌ |
| 8 Maintenance tooling | ❌ |
