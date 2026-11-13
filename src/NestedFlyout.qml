/*
    About: opens Kicker-style subfolder flyouts from one of Kickoff Nested's
    app views. Attached to a view (list or grid) whose model is a Kicker
    model; folder rows are rows with a child model. The view's rows call
    hoverEntered() when the mouse enters them: on a folder the flyout opens
    after `spawnDelay`. openCurrent() opens it at once (click, Enter). A
    change of the current row alone never opens one (rules in flyout.js).
    The flyout is Kicker's ItemListDialog, created through the
    `itemListDialogComponent` the applet provides, so deeper levels cascade
    the same way as in Kicker. The flyout closes when the current row is no
    folder, the view's model changes, or the launcher collapses (`kicker`
    bridge reset). interactionConcluded is forwarded when the user is done
    inside a flyout (application started, Escape, focus left the flyout).

    SPDX-FileCopyrightText: 2026 Ueda-Ichitaka
    SPDX-License-Identifier: MIT
*/

pragma ComponentBehavior: Bound

import QtQuick

import "flyout.js" as Flyout

Item {
    id: root

    required property Item view
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

    function openCurrent(): void {
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
            return;
        }
        childDialog = itemListDialogComponent.createObject(view, {
            visualParent: view.currentItem,
            model: folderModel,
            visible: Qt.binding(() => !!root.view.Window.window && root.view.Window.window.visible),
            dialogMirrored: view.LayoutMirroring.enabled,
        });
        childDialog.index = index;
        childDialog.interactionConcluded.connect(root.concludeInteraction);
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
