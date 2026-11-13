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
