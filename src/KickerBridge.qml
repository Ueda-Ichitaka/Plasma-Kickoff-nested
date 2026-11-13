/*
    About: stands in for Kicker's root object inside Kickoff Nested. Kicker's
    flyout components (ItemListView, ItemListDialog) look up an object with
    the id `kicker` and use its `expanded` property and `reset` signal.
    Kickoff's main.qml instantiates this bridge with `id: kicker` and binds
    `expanded` to its own; like Kicker, the bridge emits `reset` whenever the
    launcher collapses, so open flyouts close and their models reset.

    SPDX-FileCopyrightText: 2026 Ueda-Ichitaka
    SPDX-License-Identifier: MIT
*/

import QtQml

QtObject {
    property bool expanded: false

    signal reset

    onExpandedChanged: {
        if (!expanded) {
            reset();
        }
    }
}
