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
| Opening a folder | Hover (100 ms) + click + Enter; Right (away from the sidebar) in list mode |
| Escape in a flyout | Closes flyouts and launcher, as in Kicker (Kicker's files stay unmodified); Left goes back one level |
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

Kicker's flyout files expect two names from their applet:

- `kicker`, an object with `expanded` and a `reset` signal. Provided by
  `src/KickerBridge.qml` (part of the kickerparts module), instantiated in
  Kickoff's `main.qml` as `KickerParts.KickerBridge { id: kicker; expanded: kickoff.expanded }`.
  Like Kicker's `main.qml`, it emits `reset` whenever the launcher collapses.
- `itemListDialogComponent`, looked up unqualified. QML resolves such names
  on the root objects of the creating contexts, so it is a property of
  Kickoff's root object, as in Kicker:
  `readonly property Component itemListDialogComponent: Component { KickerParts.ItemListDialog {} }`.

Both lookups are covered by `tests/tst_kickerbridge.qml`, which opens a real
flyout from Kicker's `AppsModel` over the installed menu; copies of the test
without either name fail with "is not defined".

### 4.4 Changes to Kickoff

| File | Change |
|---|---|
| `main.qml` | `flat: false`; bridge object; emit `kicker.reset()` on collapse |
| `metadata.json`, `CMakeLists.txt` | New plugin id and name, so it installs next to the system Kickoff |
| `KickoffListDelegate.qml`, `KickoffGridDelegate.qml` | Folder arrow or folder badge for rows with `hasChildren` |
| `AbstractKickoffItemDelegate.qml` | `isFlyoutFolder`; mouse-enter on a folder calls `nestedFlyout.hoverEntered()`, click/Enter calls `nestedFlyout.openCurrent()` instead of `trigger()` |
| `KickoffListView.qml`, `KickoffGridView.qml` | Own a `NestedFlyout` (`nestedFlyout`); collapse the launcher when an interaction in a flyout concludes, unless pinned |
| `ConfigGeneral.qml`, `main.xml` | Setting "Show subfolders" (default on), bound to `flat` |

The flyout opening logic lives in `src/NestedFlyout.qml` with its rules in
`src/flyout.js`, both part of the kickerparts module so they can be tested.
Each app view owns one `NestedFlyout` (property `nestedFlyout` on its inner
view); `AbstractKickoffItemDelegate` reports mouse-enter on folders
(`hoverEntered`) and opens folders on click/Enter (`openCurrent`). A change
of the current row never opens a flyout by itself, because Kickoff selects the
first row of every category automatically; it only switches an open flyout
to another folder reached with the mouse, or closes it.

### 4.5 Flyout placement

Kicker's `SubMenu::popupPosition()` (plasma-workspace `applets/kicker/submenu.cpp`)
places a flyout beside its `visualParent`: to the right, to the left when it
would not fit on the screen (mirrored for RTL), and moved up when it would
run off the bottom of the screen. Both modes use it unchanged:

- List mode: the flyout opens beside the folder row.
- Grid mode: the flyout opens beside the folder tile and covers the tiles
  next to it while open (decided over placing it outside the launcher's
  edge, which would need an extra anchor helper).

No placement code of our own is needed.

### 4.6 Build layout

```
CMakeLists.txt              top level: find_package ECM, Qt6, KF6, Plasma; adds the two targets
src/                        own QML used by the kickerparts module (KickerBridge, NestedFlyout, NestedFlyoutDialog, flyout.js)
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

1. Test first (`tests/tst_nested.qml`): `code/nested.js` recognizes folder
   rows, shows the arrow only outside the sidebar, and applies stock sorting.
2. `flat: false` in `main.qml`; folder arrow in both delegates.
3. Sorting as stock Kickoff: `flat: true` forced alphabetical order without
   separators only in categories with subfolders. On every root refresh,
   `Nested.applyStockSorting()` sets `sorted: true` and
   `showSeparators: false` on exactly those category models; the sidebar
   and other categories keep following `alphaSort`.
4. Manual: BlackArch shows its category folders; nothing opens yet.

### Step 3 - Bridge and Kicker parts

1. Test first (`tests/tst_kickerbridge.qml`): collapsing emits `reset`,
   expanding does not; a folder row of Kicker's `ItemListView` over the real
   menu opens a flyout through the bridge and `itemListDialogComponent`.
2. Bridge (4.3) in `src/KickerBridge.qml`; kickerparts import, bridge and
   `itemListDialogComponent` in Kickoff's `main.qml`.
3. Manual: no QML warnings about `kicker` or `itemListDialogComponent` in the
   journal (`journalctl --user -f -t plasmashell`).

### Step 4 - Flyouts in list mode

1. Test first: `tests/tst_flyout.qml` (rules in `src/flyout.js`) and
   `tests/tst_nestedflyout.qml` (`src/NestedFlyout.qml` with Kicker's real
   `AppsModel` over the fixed test menu in `tests/data/`).
2. `src/NestedFlyout.qml`; wire into `KickoffListView` and
   `AbstractKickoffItemDelegate`.
3. Cascading: flyouts open further flyouts (Kicker's own `ItemListView`).
4. Starting an app from any flyout level closes all flyouts and Kickoff.
5. Manual: focus risk R1 checked first; screenshot `docs/screenshots/list-flyout.png`.

### Step 5 - Flyouts in grid mode

1. Tests: `tests/tst_nestedflyout.qml` runs the controller on a `GridView`
   (opens anchored to the tile, hover delay, closing); placement is Kicker's
   own (4.5).
2. Wire the controller into `KickoffGridView`.
3. Manual: tiles at left, middle and right of the grid; screenshot
   `docs/screenshots/grid-flyout.png`.

### Step 6 - Keyboard

1. Test first: `isOpenKey` in `src/flyout.js` (the arrow pointing the way
   the flyout opens; mirrored with the content area), `openWithKey`,
   keyboard focus into the flyout with its first entry selected, and focus
   back to the folder row when the flyout closes itself
   (`tests/tst_flyout.qml`, `tests/tst_nestedflyout.qml`).
2. List: Enter and the open arrow on a folder call
   `nestedFlyout.openWithKey()`; other Left/Right presses still reach
   `BasePage` (sidebar switch). Kickoff mirrors its content area when the
   sidebar is on the right, and Kicker's flyout follows that mirroring, so
   the open arrow always points away from the sidebar. Grid: Enter only,
   the arrows keep moving between tiles.
3. Inside flyouts Kicker's `ItemListView` handles Up/Down, Right (deeper),
   Left (closes that flyout) and Escape (closes everything). Left on the
   first level destroys the flyout without a signal; `src/NestedFlyoutDialog.qml`
   adds a `closing` signal so `NestedFlyout` returns focus to the row.
4. Manual: full keyboard walk `BlackArch > Scanner > nmap > Enter`.

### Step 7 - Setting and polish

1. Test first: `tests/tst_config.cpp` checks the schema entry
   `showSubfolders` (Bool, default true) in `applets/kickoff/main.xml`.
2. "Show subfolders" checkbox in `ConfigGeneral.qml` (with help text); the
   root model uses `flat: !Plasmoid.configuration.showSubfolders`. Off gives
   stock Kickoff: no folder rows, so no arrows, no flyouts, and
   `applyStockSorting` finds nothing to change.
3. Diagonal moves, test first (`tests/tst_flyout.qml`,
   `tests/tst_nestedflyout.qml`): a mouse-driven change of the current row
   while a flyout is open switches or closes it only after the hover delay;
   entering the flyout (its list's `hovered`) cancels that and makes the
   flyout's row current again, as Kicker's `ItemListView` does for its
   parent menu. Keyboard moves close it at once. Hover blocking inside
   flyouts is Kicker's own `HoverBlocker` in `ItemListDialog`.

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
- Pure logic is tested with plain JS mock objects.
- Components working with Kicker's models (`tst_kickerbridge`,
  `tst_nestedflyout`) use the real `AppsModel` over a fixed test menu in
  `tests/data/` (`XDG_MENU_PREFIX=test-`), with their own XDG home, config
  and cache directories in the build tree. The model's `appletInterface`
  is cleared after loading, because context-menu actions of application rows
  dereference the real Plasma applet behind it.
- `qmllint` over changed files as a gate.

### Manual

A widget's popup, window activation and hover behavior cannot run inside
`qmltestrunner`. `docs/MANUAL-TESTS.md` holds the checklist per step,
executed in a running Plasma session after `makepkg -si` and
`plasmashell --replace` (or logout/login).

## 7. Risks and open questions

| Id | Risk / question | Check | Fallback |
|---|---|---|---|
| R1 | Evidence ✅, manual check 4.7 pending: libplasma's `Dialog::focusOutEvent` (v6.8.2, `src/plasmaquick/dialog.cpp`) keeps a popup open while a transient child has focus, and Kicker's `SubMenu` makes itself a transient child of the window it opens from. Kickoff's popup may close when a flyout window takes focus. Kicker's QML does nothing special; the handling is assumed to be in `PlasmaQuick::Dialog` (flyout is a transient child of the popup). | Step 4, first thing | Open folders inside the right pane with a back button instead of flyouts |
| R2 | ✅ test-level: `tst_kickerparts` resolves `kicker` through the creating context; a copy with the id renamed fails with `kicker is not defined`. Unqualified `kicker` / `itemListDialogComponent` lookups from a second QML module may not resolve through the context chain under `pragma ComponentBehavior: Bound` and compiled QML. | Step 1 test | Copy the Kicker files into Kickoff with explicit properties instead of globals |
| R3 | ✅ all Kicker parts compile and load as `kickoffnested.kickerparts`. Building Kicker's files outside their original module (`plasma.applet.org.kde.plasma.kicker`) may need adjustments, e.g. `Plasmoid` attached object resolution. | Step 1 | Same as R2 |
| R4 | Translations: with a new plugin id the translation domain changes, so Kickoff's existing `.mo` files are not used. | Step 1 | Set the domain explicitly to `plasma_applet_org.kde.plasma.kickoff` if libplasma allows it, else English strings |
| R5 | Plasma updates: the compiled applet is built against Plasma 6.8.2. | Each Plasma upgrade | Rebuild with `makepkg -si`; step 8 adds a reminder hook |

## 8. Status

| Step | State |
|---|---|
| Repository filtered and on `v6.8.2` | ✅ |
| Build tools installed (`cmake` 4.4.5, `extra-cmake-modules` 6.31.0) | ✅ |
| 1 Build spike | ✅ |
| 2 Nesting on | automated part ✅, manual checks (docs/MANUAL-TESTS.md) pending |
| 3 Bridge and Kicker parts | automated part ✅, manual checks (docs/MANUAL-TESTS.md) pending |
| 4 Flyouts in list mode | automated part ✅, manual checks (docs/MANUAL-TESTS.md) pending |
| 5 Flyouts in grid mode | automated part ✅, manual checks (docs/MANUAL-TESTS.md) pending |
| 6 Keyboard | automated part ✅, manual checks (docs/MANUAL-TESTS.md) pending |
| 7 Setting and polish | automated part ✅, manual checks (docs/MANUAL-TESTS.md) pending |
| 8 Maintenance tooling | ❌ |
