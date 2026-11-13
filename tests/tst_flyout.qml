/*
    About: unit tests for src/flyout.js, the rules that decide what happens
    to an open subfolder flyout when the current row of a Kickoff app view
    changes: by mouse, switch or close it after the hover delay; by keyboard,
    close it at once. A current-row change never opens a flyout by itself;
    Kickoff selects the first row of every category automatically. Also tests which
    arrow key opens a folder: the one pointing the way the flyout opens.

    SPDX-FileCopyrightText: 2026 Ueda-Ichitaka
    SPDX-License-Identifier: MIT
*/

import QtQuick
import QtTest

import "../src/flyout.js" as Flyout

TestCase {
    name: "Flyout"

    // Mouse-driven changes act after the hover delay, so a diagonal move
    // from a folder into its flyout across other rows does not close or
    // switch it; the flyout's own row never changes anything.
    function test_actionOnCurrentChange_data() {
        return [
            { tag: "row by mouse, none open", open: false, keyboard: false, own: false, expected: Flyout.Nothing },
            { tag: "row by mouse, one open", open: true, keyboard: false, own: false, expected: Flyout.UpdateDelayed },
            { tag: "flyout's own row, one open", open: true, keyboard: false, own: true, expected: Flyout.Nothing },
            { tag: "row by keyboard, none open", open: false, keyboard: true, own: false, expected: Flyout.Nothing },
            { tag: "row by keyboard, one open", open: true, keyboard: true, own: false, expected: Flyout.Close },
        ];
    }

    function test_actionOnCurrentChange(data) {
        compare(Flyout.actionOnCurrentChange(data.open, data.keyboard, data.own), data.expected);
    }

    function test_actions_are_distinct() {
        const actions = [Flyout.Nothing, Flyout.UpdateDelayed, Flyout.Close];
        compare(new Set(actions).size, actions.length);
    }

    function test_isOpenKey_data() {
        return [
            { tag: "right, not mirrored", key: Qt.Key_Right, mirrored: false, expected: true },
            { tag: "left, not mirrored", key: Qt.Key_Left, mirrored: false, expected: false },
            { tag: "left, mirrored", key: Qt.Key_Left, mirrored: true, expected: true },
            { tag: "right, mirrored", key: Qt.Key_Right, mirrored: true, expected: false },
            { tag: "down", key: Qt.Key_Down, mirrored: false, expected: false },
        ];
    }

    function test_isOpenKey(data) {
        compare(Flyout.isOpenKey(data.key, data.mirrored), data.expected);
    }
}
