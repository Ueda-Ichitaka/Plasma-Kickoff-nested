/*
    About: tests src/NestedFlyout.qml, the controller that opens Kicker-style
    subfolder flyouts from a Kickoff app view. Uses Kicker's real AppsModel
    over the fixed test menu in data/ (Tools holds the Scanners folder and an
    application), a plain ListView standing in for Kickoff's list view, and
    the same `kicker` bridge and itemListDialogComponent that Kickoff's
    main.qml provides.

    SPDX-FileCopyrightText: 2026 Ueda-Ichitaka
    SPDX-License-Identifier: MIT
*/

import QtQuick
import QtTest
import org.kde.plasma.private.kicker as Kicker
import kickoffnested.kickerparts as KickerParts

TestCase {
    id: testCase
    name: "NestedFlyout"
    when: windowShown
    width: 400
    height: 600

    readonly property Component itemListDialogComponent: Component {
        KickerParts.ItemListDialog {}
    }

    KickerParts.KickerBridge {
        id: kicker
        expanded: true
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

    // Stand-in for KickoffListView: rows expose the model roles as `model`,
    // like Kickoff's delegates, and the view has movedWithKeyboard.
    Component {
        id: viewComponent
        ListView {
            id: listView
            property bool movedWithKeyboard: false
            width: 300
            height: 500
            currentIndex: -1
            delegate: Text {
                required property var model
                required property int index
                width: 300
                height: 20
                text: model.display
            }
            readonly property KickerParts.NestedFlyout flyout: KickerParts.NestedFlyout {
                view: listView
            }
        }
    }

    SignalSpy {
        id: concludedSpy
        signalName: "interactionConcluded"
    }

    property var mixedModel: null
    property int folderRow: -1
    property int appRow: -1

    // Searches the menu tree for a model containing both a folder and an app.
    function findMixed(model, depth) {
        let folder = -1;
        let app = -1;
        for (let row = 0; row < model.count; row++) {
            if (model.modelForRow(row)) {
                if (folder === -1) {
                    folder = row;
                }
            } else if (app === -1) {
                app = row;
            }
        }
        if (folder !== -1 && app !== -1) {
            return { model, folder, app };
        }
        if (depth > 0) {
            for (let row = 0; row < model.count; row++) {
                const child = model.modelForRow(row);
                const found = child ? findMixed(child, depth - 1) : null;
                if (found) {
                    return found;
                }
            }
        }
        return null;
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
        const found = findMixed(menuModel, 3);
        if (found) {
            mixedModel = found.model;
            folderRow = found.folder;
            appRow = found.app;
        }
    }

    function createView() {
        verify(mixedModel !== null, "test menu not loaded: no list with both folders and applications");
        const view = createTemporaryObject(viewComponent, testCase, { model: mixedModel });
        verify(view !== null);
        concludedSpy.target = view.flyout;
        concludedSpy.clear();
        return view;
    }

    function test_openCurrent_on_folder_opens_flyout_with_folder_model() {
        const view = createView();
        view.currentIndex = folderRow;
        view.flyout.openCurrent();
        verify(view.flyout.childDialog !== null);
        compare(view.flyout.childDialog.model, mixedModel.modelForRow(folderRow));
    }

    function test_openCurrent_on_app_opens_nothing() {
        const view = createView();
        view.currentIndex = appRow;
        view.flyout.openCurrent();
        compare(view.flyout.childDialog, null);
    }

    function test_hovering_folder_opens_after_delay() {
        const view = createView();
        view.currentIndex = folderRow;
        view.flyout.hoverEntered(folderRow);
        compare(view.flyout.childDialog, null);
        tryVerify(() => view.flyout.childDialog !== null, 1000);
    }

    function test_hovering_app_opens_nothing() {
        const view = createView();
        view.currentIndex = appRow;
        view.flyout.hoverEntered(appRow);
        wait(view.flyout.spawnDelay * 3);
        compare(view.flyout.childDialog, null);
    }

    // Kickoff selects the first row of every category automatically.
    function test_selecting_folder_without_hover_does_not_open() {
        const view = createView();
        view.currentIndex = folderRow;
        wait(view.flyout.spawnDelay * 3);
        compare(view.flyout.childDialog, null);
    }

    function test_keyboard_move_to_folder_does_not_open() {
        const view = createView();
        view.movedWithKeyboard = true;
        view.currentIndex = folderRow;
        view.flyout.hoverEntered(folderRow);
        wait(view.flyout.spawnDelay * 3);
        compare(view.flyout.childDialog, null);
    }

    function test_moving_to_app_closes_flyout() {
        const view = createView();
        view.currentIndex = folderRow;
        view.flyout.openCurrent();
        verify(view.flyout.childDialog !== null);
        view.currentIndex = appRow;
        compare(view.flyout.childDialog, null);
    }

    function test_collapsing_launcher_closes_flyout() {
        const view = createView();
        view.currentIndex = folderRow;
        view.flyout.openCurrent();
        verify(view.flyout.childDialog !== null);
        kicker.expanded = false;
        compare(view.flyout.childDialog, null);
        kicker.expanded = true;
    }

    function test_changing_model_closes_flyout() {
        const view = createView();
        view.currentIndex = folderRow;
        view.flyout.openCurrent();
        verify(view.flyout.childDialog !== null);
        view.model = null;
        compare(view.flyout.childDialog, null);
    }

    function test_interaction_in_flyout_is_forwarded_and_closes() {
        const view = createView();
        view.currentIndex = folderRow;
        view.flyout.openCurrent();
        const dialog = view.flyout.childDialog;
        verify(dialog !== null);
        dialog.interactionConcluded();
        compare(concludedSpy.count, 1);
        compare(view.flyout.childDialog, null);
    }
}
