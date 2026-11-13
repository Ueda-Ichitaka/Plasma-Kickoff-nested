/*
    About: rules for subfolder flyouts in Kickoff Nested's app views. A
    flyout opens only on hover or explicitly (click, Right/Enter); Kickoff
    selects the first row of every category automatically, so a change of
    the current row never opens one by itself. When the current row changes
    while a flyout is open, a mouse-driven change acts after the hover delay
    (switch to the new folder, or close), so a diagonal move from a folder
    into its flyout across other rows keeps it; a keyboard move closes it at
    once. From the keyboard, a folder opens with Enter or the arrow key
    pointing the way the flyout opens.

    SPDX-FileCopyrightText: 2026 Ueda-Ichitaka
    SPDX-License-Identifier: MIT
*/

.pragma library

var Nothing = 0;
var UpdateDelayed = 1;
var Close = 2;

// The arrow key pointing the way the flyout opens (Kicker's SubMenu opens to
// the right, to the left when mirrored) opens a folder from the keyboard.
function isOpenKey(key, mirrored) {
    return key === (mirrored ? Qt.Key_Left : Qt.Key_Right);
}

// UpdateDelayed: after the hover delay, show the current row's folder in the
// flyout, or close the flyout if the current row is no folder.
function actionOnCurrentChange(hasOpenFlyout, byKeyboard, isFlyoutRow) {
    if (!hasOpenFlyout || isFlyoutRow) {
        return Nothing;
    }
    return byKeyboard ? Close : UpdateDelayed;
}
