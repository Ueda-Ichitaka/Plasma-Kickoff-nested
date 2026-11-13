# Manual Tests

Checks that need a running Plasma session: popups, window focus, hover and
the panel. Automated tests (`ctest --test-dir build`) cover everything else.
Each plan step in [PLAN.md](PLAN.md) adds its section here.

## Setup

```
cd packaging
makepkg -si
systemctl --user restart plasma-plasmashell.service
```

Watch for QML errors while testing:

```
journalctl --user -f | grep -i -E 'kickoff|kicker|qml'
```

## Step 1 - Build spike

Kickoff Nested is still unchanged Kickoff here; it must behave exactly like
the system launcher.

| # | Check | Expected |
|---|---|---|
| 1.1 | Right-click the launcher in the panel, **Show Alternatives...** | "Kickoff Nested" is listed |
| 1.2 | Select "Kickoff Nested" | Panel icon stays, the launcher opens on click |
| 1.3 | Browse Favorites, Applications, Places | Same as system Kickoff |
| 1.4 | Open the BlackArch category | Flat list of all BlackArch tools, as in system Kickoff |
| 1.5 | Search "nmap", press Enter | nmap starts in a terminal |
| 1.6 | Right-click an app | Context menu with "Add to Favorites" etc. |
| 1.7 | Right-click launcher, **Configure Kickoff Nested...** | Settings dialog opens, changes apply |
| 1.8 | Journal while doing 1.1 to 1.7 | No QML errors from `local.kickoffnested` |
| 1.9 | Switch back via **Show Alternatives...** to Application Launcher | System Kickoff works as before |

## Step 2 - Nesting on

Folders appear but do not open yet; that comes with step 4.

| # | Check | Expected |
|---|---|---|
| 2.1 | Open the BlackArch category (list mode) | Category folders (Cracker, Scanner, ...) listed first, alphabetical, each with an arrow on the right; no flat tool list |
| 2.2 | Sidebar | Categories have no arrow; order as in system Kickoff |
| 2.3 | A category without subfolders (e.g. Office) | Same contents and order as in system Kickoff |
| 2.4 | Settings: show applications as grid, open BlackArch | Folder tiles with a small arrow at the bottom right of the icon |
| 2.5 | Click a folder | Nothing happens, no error in the journal |
| 2.6 | Search "nmap" | Found and starts as before |
| 2.7 | Journal | No QML errors from `local.kickoffnested` (e.g. about `Nested` or `onRefreshed`) |

## Step 3 - Bridge and Kicker parts

Nothing visible changes; the flyout plumbing is in place for step 4.

| # | Check | Expected |
|---|---|---|
| 3.1 | Open and close the launcher a few times, browse BlackArch | Same as after step 2 |
| 3.2 | Journal while doing 3.1 | No errors mentioning `kicker`, `KickerBridge`, `KickerParts` or `itemListDialogComponent` |

## Step 4 - Flyouts in list mode

Settings: applications shown as **list**. Grid mode follows in step 5.

| # | Check | Expected |
|---|---|---|
| 4.1 | Open the BlackArch category, do not move the mouse over a folder | No flyout opens by itself |
| 4.2 | Hover over the Scanner folder | After a short moment a flyout opens next to the row, listing the scanner tools |
| 4.3 | Move the mouse into the flyout and click a tool | Tool starts; flyout and launcher close |
| 4.4 | Hover over a folder, move to another folder | Flyout switches to the other folder |
| 4.5 | With a flyout open, move to a non-folder row (another category with apps, or Favorites) | Flyout closes |
| 4.6 | Click a folder instead of hovering | Flyout opens at once |
| 4.7 | Click inside a flyout (empty area or scroll) | Launcher stays open (risk R1) |
| 4.8 | Flyout open, press Escape | Flyout and launcher close |
| 4.9 | Flyout open, click on the desktop | Flyout and launcher close |
| 4.10 | Pin the launcher (pin button in the header), start a tool from a flyout | Tool starts, flyout closes, launcher stays open |
| 4.11 | Close and reopen the launcher | No flyout left over |
| 4.12 | Sidebar: hover over categories | No flyout from the sidebar |
| 4.13 | Journal while doing 4.1 to 4.12 | No errors from `NestedFlyout`, `ItemListDialog` or `KickerBridge` |

## Step 5 - Flyouts in grid mode

Settings: right-click the launcher, **Configure Kickoff Nested...**, show
applications as **grid**.

| # | Check | Expected |
|---|---|---|
| 5.1 | Open the BlackArch category | Folder tiles with a small arrow; no flyout opens by itself |
| 5.2 | Hover over a folder tile in the left column | Flyout opens beside the tile (to its right), covering the neighbouring tiles |
| 5.3 | Hover over a folder tile in the right column | Flyout opens beside the tile; if it does not fit on screen, it opens to the left |
| 5.4 | Click a folder tile | Flyout opens at once |
| 5.5 | Start a tool from the flyout | Tool starts; flyout and launcher close |
| 5.6 | Flyout open, move to another folder tile | Flyout switches to that folder |
| 5.7 | Panel at the bottom of the screen, flyout of a tile in the lowest row | Flyout moves up to stay on screen |
| 5.8 | Favorites and All Applications in grid mode | Unchanged, no flyouts |
| 5.9 | Journal while doing 5.1 to 5.8 | No errors from `NestedFlyout` or `ItemListDialog` |

While in steps 4 and 5, please save screenshots for the README:
`docs/screenshots/list-flyout.png` (list mode, `BlackArch > Scanner` open)
and `docs/screenshots/grid-flyout.png` (grid mode, flyout from a tile).

## Step 6 - Keyboard

Open the launcher with the Meta key, use only the keyboard.

| # | Check | Expected |
|---|---|---|
| 6.1 | List mode: type nothing, Down to the sidebar, select BlackArch, Right into the app list | Focus on the first folder; no flyout opens by itself |
| 6.2 | On a folder, press Right | Flyout opens, its first entry is selected |
| 6.3 | Up/Down inside the flyout | Selection moves inside the flyout |
| 6.4 | Left inside the flyout | Flyout closes, focus back on the folder row in Kickoff |
| 6.5 | On a folder, press Enter | Flyout opens, its first entry is selected |
| 6.6 | Select a tool in the flyout, press Enter | Tool starts; flyout and launcher close |
| 6.7 | Flyout open, press Escape | Flyout and launcher close |
| 6.8 | In the app list, press Left on any row | Focus moves to the sidebar, as in stock Kickoff |
| 6.9 | Flyout open, type letters | Search field takes the input, as in Kicker |
| 6.10 | Grid mode: arrow keys on folder tiles | Move between tiles; no flyout |
| 6.11 | Grid mode: Enter on a folder tile | Flyout opens with first entry selected |
| 6.12 | Settings: swap sidebar to the right, list mode, Left on a folder | Flyout opens to the left; Right goes to the sidebar |
| 6.13 | Journal while doing 6.1 to 6.12 | No errors from `NestedFlyout`, `NestedFlyoutDialog` or `ItemListView` |

## Step 7 - Setting and polish

| # | Check | Expected |
|---|---|---|
| 7.1 | Right-click the launcher, **Configure Kickoff Nested...** | "Show subfolders" checkbox under General, checked, with a help button |
| 7.2 | Uncheck "Show subfolders", apply, open BlackArch | Flat list of all BlackArch tools, sorted as in system Kickoff; no arrows, no flyouts |
| 7.3 | Check it again, apply | Folders and flyouts are back |
| 7.4 | List mode: open the Scanner flyout, move the mouse diagonally into it across other folder rows | Flyout stays on Scanner |
| 7.5 | Category with folders and apps (if any): open a flyout, move diagonally into it across an app row | Flyout stays open |
| 7.6 | Open a flyout, move the mouse onto another folder row and rest there | Flyout switches after a short moment |
| 7.7 | Open a flyout, move onto an app row and rest there | Flyout closes after a short moment |
| 7.8 | Open a flyout, press Down in the Kickoff list | Flyout closes at once |
| 7.9 | Journal while doing 7.1 to 7.8 | No errors |

## Step 8 - Maintenance tooling

| # | Check | Expected |
|---|---|---|
| 8.1 | `cd packaging && makepkg -si` | Package version `1.0.0.r<n>.g<hash>`; pacman may warn about a downgrade from the earlier `6.8.2.r...` versions once, confirm it |
| 8.2 | Output of 8.1 | Hook line "Checking Kickoff Nested against the installed Plasma version...", no warning (Plasma 6.8.2 installed) |
| 8.3 | `/usr/lib/kickoff-nested/plasma-check /usr/share/kickoff-nested/upstream-base 6.8.3-1` | Warning with `scripts/update-upstream.sh v6.8.3` |
| 8.4 | `scripts/upstream-diff.sh --stat` | Only `applets/kickoff/` files listed |
| 8.5 | Next real Plasma upgrade (e.g. to 6.8.3) via `sudo pacman -Syu` | Hook prints the update steps after the transaction |

## Step 9 - CI/CD

| # | Check | Expected |
|---|---|---|
| 9.1 | Push a branch | GitHub Actions run "Package" succeeds; artifact `kickoff-nested-package` holds the `.pkg.tar.zst` |
| 9.2 | `git tag -a v1.0.0 -m "Kickoff Nested 1.0.0" && git push origin v1.0.0` | Run succeeds and creates the release "Kickoff Nested 1.0.0" with the package |
| 9.3 | Download the release package, `sudo pacman -U` it | Installs version `1.0.0-1` |
