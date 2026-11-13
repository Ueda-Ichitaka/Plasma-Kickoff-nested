/*
    About: rules for subfolder flyouts in Kickoff Nested's app views. A
    flyout opens only on hover or explicitly (click, Right/Enter); Kickoff
    selects the first row of every category automatically, so a change of
    the current row never opens one by itself. When the current row changes
    while a flyout is open, the flyout switches to a folder reached with the
    mouse (after the hover delay) and closes otherwise, including on
    keyboard moves.

    SPDX-FileCopyrightText: 2026 Ueda-Ichitaka
    SPDX-License-Identifier: MIT
*/

.pragma library

var Nothing = 0;
var OpenDelayed = 1;
var Close = 2;

function actionOnCurrentChange(isFolder, hasOpenFlyout, byKeyboard) {
    if (!hasOpenFlyout) {
        return Nothing;
    }
    return isFolder && !byKeyboard ? OpenDelayed : Close;
}
