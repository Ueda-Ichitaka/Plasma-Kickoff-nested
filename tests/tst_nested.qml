/*
    About: unit tests for applets/kickoff/code/nested.js, the logic that
    turns on nested subfolders in Kickoff: recognizing folder rows, showing
    the folder arrow only in the app views, and keeping stock Kickoff's
    sorting (alphabetical, no separators) in categories with subfolders.
    Uses plain JS mock objects in place of Kicker's C++ models.

    SPDX-FileCopyrightText: 2026 Ueda-Ichitaka
    SPDX-License-Identifier: MIT
*/

import QtQuick
import QtTest

import "../applets/kickoff/code/nested.js" as Nested

TestCase {
    name: "Nested"

    function appRow() {
        return { display: "nmap", isParent: false, hasChildren: false, isSeparator: false };
    }

    function folderRow() {
        return { display: "Scanner", isParent: true, hasChildren: true, isSeparator: false };
    }

    // Mimics Kicker's AppsModel: count, modelForRow(row) returning the child
    // model of folder rows and null otherwise, writable sorted/showSeparators.
    function mockModel(children) {
        return {
            count: children.length,
            sorted: false,
            showSeparators: true,
            modelForRow(row) {
                return row >= 0 && row < children.length ? children[row] : null;
            },
        };
    }

    function test_isFolder_data() {
        return [
            { tag: "folder", row: folderRow(), expected: true },
            { tag: "app", row: appRow(), expected: false },
            { tag: "empty folder", row: { isParent: true, hasChildren: false }, expected: false },
            { tag: "separator", row: { isSeparator: true, isParent: false, hasChildren: false }, expected: false },
            { tag: "missing roles", row: { display: "x" }, expected: false },
            { tag: "null", row: null, expected: false },
            { tag: "undefined", row: undefined, expected: false },
        ];
    }

    function test_isFolder(data) {
        compare(Nested.isFolder(data.row), data.expected);
    }

    function test_showsFolderArrow_data() {
        return [
            { tag: "folder in app view", row: folderRow(), category: false, expected: true },
            { tag: "folder in sidebar", row: folderRow(), category: true, expected: false },
            { tag: "app in app view", row: appRow(), category: false, expected: false },
        ];
    }

    function test_showsFolderArrow(data) {
        compare(Nested.showsFolderArrow(data.row, data.category), data.expected);
    }

    function test_hasSubfolders_data() {
        return [
            { tag: "folder among apps", model: mockModel([null, mockModel([]), null]), expected: true },
            { tag: "apps only", model: mockModel([null, null]), expected: false },
            { tag: "empty", model: mockModel([]), expected: false },
            { tag: "null", model: null, expected: false },
            { tag: "not a model", model: { count: 2 }, expected: false },
        ];
    }

    function test_hasSubfolders(data) {
        compare(Nested.hasSubfolders(data.model), data.expected);
    }

    function test_applyStockSorting_sorts_only_categories_with_subfolders() {
        const blackarch = mockModel([mockModel([null]), null]);
        const office = mockModel([null, null]);
        const root = mockModel([null, office, blackarch]);

        Nested.applyStockSorting(root);

        verify(blackarch.sorted);
        verify(!blackarch.showSeparators);
        verify(!office.sorted);
        verify(office.showSeparators);
        verify(!root.sorted);
        verify(root.showSeparators);
    }

    function test_applyStockSorting_ignores_missing_root() {
        Nested.applyStockSorting(null);
        Nested.applyStockSorting(undefined);
    }
}
