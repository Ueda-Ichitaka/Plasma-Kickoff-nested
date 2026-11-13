/*
    About: rules for subfolder flyouts in Kickoff Nested's app views. A
    flyout opens only on hover or explicitly (click, Right/Enter); Kickoff
    selects the first row of every category automatically, so a change of
    the current row never opens one by itself. When the current row changes
    while a flyout is open, the flyout switches to a folder reached with the
    mouse (after the hover delay) and closes otherwise, including on
    keyboard moves. From the keyboard, a folder opens with Enter or the
    arrow key pointing the way the flyout opens.

    SPDX-FileCopyrightText: 2026 Ueda-Ichitaka
    SPDX-License-Identifier: MIT
*/

.pragma library

var Nothing = 0;
var OpenDelayed = 1;
var Close = 2;

// The arrow key pointing the way the flyout opens (Kicker's SubMenu opens to
// the right, to the left when mirrored) opens a folder from the keyboard.
function isOpenKey(key, mirrored) {
    return key === (mirrored ? Qt.Key_Left : Qt.Key_Right);
}

function actionOnCurrentChange(isFolder, hasOpenFlyout, byKeyboard) {
    if (!hasOpenFlyout) {
        return Nothing;
    }
    return isFolder && !byKeyboard ? OpenDelayed : Close;
}
