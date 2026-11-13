/*
    About: unit tests for src/flyout.js, the rules that decide what happens
    to an open subfolder flyout when the current row of a Kickoff app view
    changes: switch it to another folder reached with the mouse, close it
    otherwise. A current-row change never opens a flyout by itself; Kickoff
    selects the first row of every category automatically.

    SPDX-FileCopyrightText: 2026 Ueda-Ichitaka
    SPDX-License-Identifier: MIT
*/

import QtQuick
import QtTest

import "../src/flyout.js" as Flyout

TestCase {
    name: "Flyout"

    function test_actionOnCurrentChange_data() {
        return [
            { tag: "folder by mouse, none open", folder: true, open: false, keyboard: false, expected: Flyout.Nothing },
            { tag: "folder by mouse, one open", folder: true, open: true, keyboard: false, expected: Flyout.OpenDelayed },
            { tag: "folder by keyboard, none open", folder: true, open: false, keyboard: true, expected: Flyout.Nothing },
            { tag: "folder by keyboard, one open", folder: true, open: true, keyboard: true, expected: Flyout.Close },
            { tag: "app, one open", folder: false, open: true, keyboard: false, expected: Flyout.Close },
            { tag: "app, none open", folder: false, open: false, keyboard: false, expected: Flyout.Nothing },
            { tag: "app by keyboard, one open", folder: false, open: true, keyboard: true, expected: Flyout.Close },
        ];
    }

    function test_actionOnCurrentChange(data) {
        compare(Flyout.actionOnCurrentChange(data.folder, data.open, data.keyboard), data.expected);
    }

    function test_actions_are_distinct() {
        const actions = [Flyout.Nothing, Flyout.OpenDelayed, Flyout.Close];
        compare(new Set(actions).size, actions.length);
    }
}
