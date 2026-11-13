/*
    About: checks that Kicker's subfolder components, built unmodified from
    applets/kicker/ as the internal module kickoffnested.kickerparts, load
    and compile outside their original Kicker applet module, and that their
    unqualified `kicker` lookup resolves through the creating context.

    SPDX-FileCopyrightText: 2026 Ueda-Ichitaka
    SPDX-License-Identifier: MIT
*/

import QtQuick
import QtTest
import kickoffnested.kickerparts as KickerParts

TestCase {
    name: "KickerParts"

    function test_types_compile_data() {
        return [
            { tag: "ItemListDialog" },
            { tag: "ItemListView" },
            { tag: "ItemListDelegate" },
            { tag: "ItemAbstractDelegate" },
            { tag: "HoverBlocker" },
        ];
    }

    function test_types_compile(data) {
        const component = Qt.createComponent("kickoffnested.kickerparts", data.tag);
        compare(component.status, Component.Ready, component.errorString());
    }

    // Kicker's files reach the applet through the unqualified id `kicker`.
    // Created from here, the lookup must resolve to the object below, the
    // same way Kickoff's bridge object is found at runtime.
    QtObject {
        id: kicker
        property bool expanded: false
        signal reset
    }

    Component {
        id: itemListViewComponent
        KickerParts.ItemListView {}
    }

    function test_kicker_id_resolves_from_creating_context() {
        const view = createTemporaryObject(itemListViewComponent, this);
        verify(view !== null);
        view.subMenuForCurrentItem(); // reads kicker.expanded first; throws ReferenceError if unresolved
    }

    function test_hover_blocker_starts_blocking() {
        const component = Qt.createComponent("kickoffnested.kickerparts", "HoverBlocker");
        compare(component.status, Component.Ready, component.errorString());
        const blocker = component.createObject(this);
        verify(blocker !== null);
        verify(blocker.enabled);
        blocker.destroy();
    }
}
