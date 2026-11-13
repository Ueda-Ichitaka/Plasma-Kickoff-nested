/*
    About: opens Kicker-style subfolder flyouts from one of Kickoff Nested's
    app views. Attached to a view (list or grid) whose model is a Kicker
    model; folder rows are rows with a child model. The view's rows call
    hoverEntered() when the mouse enters them: on a folder the flyout opens
    after `spawnDelay`. openCurrent() opens it at once (click); with
    byKeyboard (Enter, arrow key) it also moves focus into the flyout and
    selects its first entry. A change of the current row alone never opens
    one (rules in flyout.js).
    The first flyout is a NestedFlyoutDialog (Kicker's ItemListDialog with a
    `closing` signal); deeper levels are created by Kicker's own list through
    the `itemListDialogComponent` the applet provides, so they cascade as in
    Kicker. The flyout closes when the current row is no folder, the view's
    model changes, or the launcher collapses (`kicker` bridge reset). When it
    closes itself (Left inside it), focus returns to the folder row.
    interactionConcluded is forwarded when the user is done inside a flyout
    (application started, Escape, focus left the flyout).

    SPDX-FileCopyrightText: 2026 Ueda-Ichitaka
    SPDX-License-Identifier: MIT
*/

pragma ComponentBehavior: Bound

import QtQuick

import "flyout.js" as Flyout

Item {
    id: root

    required property Item view
    // Kicker's ItemListView forwards typing to it and expects it to be set
    property Item mainSearchField: null
    property int spawnDelay: 100
    property var childDialog: null

    signal interactionConcluded

    visible: false

    function isFolderRow(index: int): bool {
        const model = view?.model;
        return index >= 0 && !!model && typeof model.modelForRow === "function" && !!model.modelForRow(index);
    }

    function hoverEntered(index: int): void {
        if (isFolderRow(index) && view.movedWithKeyboard !== true) {
            spawnTimer.restart();
        }
    }

    function openCurrent(byKeyboard = false): void {
        spawnTimer.stop();
        const index = view.currentIndex;
        if (!isFolderRow(index) || !view.currentItem) {
            close();
            return;
        }
        const folderModel = view.model.modelForRow(index);
        if (childDialog) {
            childDialog.model = folderModel;
            childDialog.visualParent = view.currentItem;
            childDialog.index = index;
        } else {
            const dialog = flyoutComponent.createObject(view, {
                mainSearchField: mainSearchField,
                visualParent: view.currentItem,
                model: folderModel,
                visible: Qt.binding(() => !!root.view.Window.window && root.view.Window.window.visible),
                dialogMirrored: view.LayoutMirroring.enabled,
            });
            dialog.index = index;
            dialog.interactionConcluded.connect(root.concludeInteraction);
            dialog.closing.connect(() => root.flyoutClosing(dialog));
            childDialog = dialog;
        }
        if (byKeyboard) {
            focusFlyout();
        }
    }

    // For the view's key handler: opens the current folder on Enter, or on the
    // arrow key pointing the way the flyout opens when `allowArrows` (lists;
    // grids use the arrows to move between tiles). Returns whether it did.
    function openWithKey(key: int, allowArrows: bool): bool {
        const isEnter = key === Qt.Key_Return || key === Qt.Key_Enter;
        const isArrow = allowArrows && Flyout.isOpenKey(key, view.LayoutMirroring.enabled);
        if ((!isEnter && !isArrow) || !isFolderRow(view.currentIndex)) {
            return false;
        }
        openCurrent(true);
        return true;
    }

    // Like Kicker's keyboard-opened submenus: activate the flyout window and
    // select its first entry, so the arrow keys continue inside it.
    function focusFlyout(): void {
        const list = childDialog.mainItem;
        childDialog.requestActivate();
        list.forceActiveFocus(Qt.TabFocusReason);
        if (list.currentIndex === -1 && list.count > 0) {
            list.currentIndex = 0;
        }
    }

    function close(): void {
        spawnTimer.stop();
        if (childDialog) {
            if (!childDialog.aboutToBeDestroyed) {
                childDialog.delayedDestroy();
            }
            childDialog = null;
        }
    }

    function concludeInteraction(): void {
        close();
        interactionConcluded();
    }

    // The flyout destroyed itself (Left in Kicker's list, or its list ran
    // empty). Flyouts closed by close() are no longer childDialog here.
    function flyoutClosing(dialog: var): void {
        if (dialog !== childDialog) {
            return;
        }
        childDialog = null;
        if (kicker.expanded && view.currentItem) {
            view.Window.window?.requestActivate();
            view.currentItem.forceActiveFocus(Qt.TabFocusReason);
        }
    }

    Component {
        id: flyoutComponent
        NestedFlyoutDialog {}
    }

    Timer {
        id: spawnTimer
        interval: root.spawnDelay
        onTriggered: root.openCurrent()
    }

    Connections {
        target: root.view

        function onCurrentIndexChanged(): void {
            const action = Flyout.actionOnCurrentChange(
                root.isFolderRow(root.view.currentIndex),
                root.childDialog !== null,
                root.view.movedWithKeyboard === true);
            if (action === Flyout.OpenDelayed) {
                spawnTimer.restart();
            } else if (action === Flyout.Close) {
                root.close();
            }
        }

        function onModelChanged(): void {
            root.close();
        }
    }

    Connections {
        target: kicker

        function onReset(): void {
            root.close();
        }
    }
}
