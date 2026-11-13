/*
    About: first-level subfolder flyout of Kickoff Nested. It is Kicker's
    ItemListDialog plus a `closing` signal emitted when the flyout is
    destroyed. Kicker's flyout list destroys its own dialog when the user
    presses Left in it, without any signal; NestedFlyout listens to `closing`
    to let go of the flyout and give the keyboard focus back to Kickoff.

    SPDX-FileCopyrightText: 2026 Ueda-Ichitaka
    SPDX-License-Identifier: MIT
*/

import QtQuick

ItemListDialog {
    signal closing

    Component.onDestruction: closing()
}
