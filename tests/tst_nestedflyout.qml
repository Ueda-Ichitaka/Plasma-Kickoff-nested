/*
    About: tests src/NestedFlyout.qml, the controller that opens Kicker-style
    subfolder flyouts from a Kickoff app view. Uses Kicker's real AppsModel
    over the fixed test menu in data/ (Tools holds the Scanners folder and an
    application), a plain ListView and GridView standing in for Kickoff's
    list and grid views, and the same `kicker` bridge and itemListDialogComponent that Kickoff's
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

    // Stand-in for KickoffGridView: tiles instead of rows.
    Component {
        id: gridComponent
        GridView {
            id: gridView
            property bool movedWithKeyboard: false
            width: 300
            height: 500
            cellWidth: 100
            cellHeight: 100
            currentIndex: -1
            delegate: Text {
                required property var model
                required property int index
                width: 100
                height: 100
                text: model.display
            }
            readonly property KickerParts.NestedFlyout flyout: KickerParts.NestedFlyout {
                view: gridView
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

    function createView(component = viewComponent) {
        verify(mixedModel !== null, "test menu not loaded: no list with both folders and applications");
        const view = createTemporaryObject(component, testCase, { model: mixedModel });
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

    // Grid mode: the flyout is anchored to the folder tile; Kicker's SubMenu
    // places it beside the tile and flips it at the screen edge.
    function test_grid_openCurrent_on_folder_opens_flyout_at_tile() {
        const view = createView(gridComponent);
        view.currentIndex = folderRow;
        view.flyout.openCurrent();
        verify(view.flyout.childDialog !== null);
        compare(view.flyout.childDialog.model, mixedModel.modelForRow(folderRow));
        compare(view.flyout.childDialog.visualParent, view.currentItem);
    }

    function test_grid_hovering_folder_opens_after_delay() {
        const view = createView(gridComponent);
        view.currentIndex = folderRow;
        view.flyout.hoverEntered(folderRow);
        tryVerify(() => view.flyout.childDialog !== null, 1000);
    }

    function test_grid_moving_to_app_closes_flyout() {
        const view = createView(gridComponent);
        view.currentIndex = folderRow;
        view.flyout.openCurrent();
        verify(view.flyout.childDialog !== null);
        view.currentIndex = appRow;
        compare(view.flyout.childDialog, null);
    }

    function test_list_flyout_is_anchored_to_folder_row() {
        const view = createView();
        view.currentIndex = folderRow;
        view.flyout.openCurrent();
        compare(view.flyout.childDialog.visualParent, view.currentItem);
    }

    // Keyboard opening moves into the flyout and selects its first entry,
    // like Kicker; mouse opening leaves the selection to the mouse.
    function test_keyboard_open_selects_first_flyout_entry() {
        const view = createView();
        view.currentIndex = folderRow;
        view.flyout.openCurrent(true);
        verify(view.flyout.childDialog !== null);
        compare(view.flyout.childDialog.mainItem.currentIndex, 0);
    }

    function test_mouse_open_selects_nothing_in_flyout() {
        const view = createView();
        view.currentIndex = folderRow;
        view.flyout.openCurrent();
        verify(view.flyout.childDialog !== null);
        compare(view.flyout.childDialog.mainItem.currentIndex, -1);
    }

    function test_keyboard_open_of_hovered_flyout_selects_first_entry() {
        const view = createView();
        view.currentIndex = folderRow;
        view.flyout.openCurrent();
        const dialog = view.flyout.childDialog;
        view.flyout.openCurrent(true);
        compare(view.flyout.childDialog, dialog);
        compare(dialog.mainItem.currentIndex, 0);
    }

    // Kickoff's key handlers ask the controller whether a key opens the
    // current folder: Enter always, the arrow pointing the way the flyout
    // opens only where arrows are free (list, not grid).
    function test_openWithKey_data() {
        return [
            { tag: "right on folder", row: "folder", key: Qt.Key_Right, arrows: true, handled: true },
            { tag: "left on folder", row: "folder", key: Qt.Key_Left, arrows: true, handled: false },
            { tag: "return on folder", row: "folder", key: Qt.Key_Return, arrows: true, handled: true },
            { tag: "enter on folder", row: "folder", key: Qt.Key_Enter, arrows: true, handled: true },
            { tag: "right on app", row: "app", key: Qt.Key_Right, arrows: true, handled: false },
            { tag: "return on app", row: "app", key: Qt.Key_Return, arrows: true, handled: false },
            { tag: "right on folder, arrows off", row: "folder", key: Qt.Key_Right, arrows: false, handled: false },
            { tag: "return on folder, arrows off", row: "folder", key: Qt.Key_Return, arrows: false, handled: true },
        ];
    }

    function test_openWithKey(data) {
        const view = createView();
        view.currentIndex = data.row === "folder" ? folderRow : appRow;
        compare(view.flyout.openWithKey(data.key, data.arrows), data.handled);
        compare(view.flyout.childDialog !== null, data.handled);
        if (data.handled) {
            compare(view.flyout.childDialog.mainItem.currentIndex, 0);
        }
    }

    // Left inside a flyout makes Kicker's ItemListView destroy that flyout
    // (itemList.dialog.destroy()). The controller must let go of it and give
    // the keyboard focus back to the folder row.
    function test_flyout_closed_from_inside_returns_focus_to_row() {
        const view = createView();
        view.currentIndex = folderRow;
        view.flyout.openCurrent(true);
        verify(view.flyout.childDialog !== null);
        view.flyout.childDialog.destroy();
        tryVerify(() => view.flyout.childDialog === null);
        tryVerify(() => view.currentItem.activeFocus);
    }

    function test_flyout_opens_again_after_closed_from_inside() {
        const view = createView();
        view.currentIndex = folderRow;
        view.flyout.openCurrent(true);
        view.flyout.childDialog.destroy();
        tryVerify(() => view.flyout.childDialog === null);
        view.flyout.openCurrent(true);
        verify(view.flyout.childDialog !== null);
        compare(view.flyout.childDialog.mainItem.currentIndex, 0);
    }
}
