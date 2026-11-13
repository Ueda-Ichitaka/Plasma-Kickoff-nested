/*
    About: tests the bridge between Kickoff and Kicker's flyout components.
    KickerBridge stands in for Kicker's root object `kicker` (expanded,
    reset on collapse); the test root provides itemListDialogComponent the
    way Kickoff's main.qml does. With Kicker's real AppsModel over the fixed
    test menu in data/, a folder row of ItemListView must open a flyout.

    SPDX-FileCopyrightText: 2026 Ueda-Ichitaka
    SPDX-License-Identifier: MIT
*/

import QtQuick
import QtTest
import org.kde.plasma.private.kicker as Kicker
import kickoffnested.kickerparts as KickerParts

TestCase {
    id: testCase
    name: "KickerBridge"
    when: windowShown
    width: 400
    height: 400

    // Looked up unqualified by ItemListView, as on Kickoff's root object.
    readonly property Component itemListDialogComponent: Component {
        KickerParts.ItemListDialog {}
    }

    KickerParts.KickerBridge {
        id: kicker
    }

    SignalSpy {
        id: resetSpy
        target: kicker
        signalName: "reset"
    }

    // A root AppsModel only populates with an applet interface set
    // (AppsModel::refresh in plasma-workspace); the test object stands in.
    // It is cleared again once loaded (see releaseAppletInterface), since
    // context-menu actions of application rows dereference the real applet
    // behind it (ContainmentInterface::mayAddLauncher).
    Kicker.AppsModel {
        id: menuModel
        flat: false
        appletInterface: testCase
    }

    Component {
        id: itemListViewComponent
        KickerParts.ItemListView {
            width: 300
            height: 300
        }
    }

    // Clearing the interface keeps the loaded entries: refresh() returns
    // early for a root model without one.
    function releaseAppletInterface() {
        verify(menuModel.count > 0, "test menu not loaded");
        menuModel.appletInterface = null;
        compare(menuModel.count > 0, true);
    }

    function initTestCase() {
        releaseAppletInterface();
    }

    function init() {
        kicker.expanded = false;
        resetSpy.clear();
    }

    function test_reset_emitted_when_collapsing() {
        kicker.expanded = true;
        compare(resetSpy.count, 0);
        kicker.expanded = false;
        compare(resetSpy.count, 1);
    }

    function test_no_reset_when_expanding() {
        kicker.expanded = true;
        compare(resetSpy.count, 0);
    }

    function firstFolderRow(model) {
        for (let row = 0; row < model.count; row++) {
            if (model.modelForRow(row)) {
                return row;
            }
        }
        return -1;
    }

    function test_folder_row_opens_flyout() {
        const row = firstFolderRow(menuModel);
        verify(row !== -1, "test menu not loaded: no folder rows");
        kicker.expanded = true;
        const view = createTemporaryObject(itemListViewComponent, testCase, { model: menuModel });
        verify(view !== null);
        view.currentIndex = row;
        tryVerify(() => view.currentItem !== null);

        view.subMenuForCurrentItem();

        verify(view.childDialog !== null);
        compare(view.childDialog.model, menuModel.modelForRow(row));
        view.clearChildDialog();
    }
}
