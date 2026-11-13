/*
    About: logic for nested subfolders in Kickoff Nested. Kicker's root model
    runs with `flat: false`, so categories contain folder rows; these helpers
    recognize folder rows, decide where the folder arrow is shown, and keep
    stock Kickoff's sorting, which is alphabetical without separators only in
    categories that contain subfolders.

    SPDX-FileCopyrightText: 2026 Ueda-Ichitaka
    SPDX-License-Identifier: MIT
*/

.pragma library

// A row is a folder when the model marks it as a parent with entries.
function isFolder(row) {
    return !!row && row.isParent === true && row.hasChildren === true;
}

// The sidebar lists the categories, which are folders themselves; the arrow
// belongs only to folders in the application views.
function showsFolderArrow(row, isCategoryListItem) {
    return !isCategoryListItem && isFolder(row);
}

// Kicker models return a child model from modelForRow() for folder rows only.
function hasSubfolders(model) {
    if (!model || typeof model.modelForRow !== "function") {
        return false;
    }
    for (let row = 0; row < model.count; row++) {
        if (model.modelForRow(row)) {
            return true;
        }
    }
    return false;
}

// Applies stock Kickoff's ordering to every category of the root model that
// contains subfolders. The category models pass these settings on to their
// subfolders when they refresh.
function applyStockSorting(rootModel) {
    if (!rootModel || typeof rootModel.modelForRow !== "function") {
        return;
    }
    for (let row = 0; row < rootModel.count; row++) {
        const category = rootModel.modelForRow(row);
        if (hasSubfolders(category)) {
            category.showSeparators = false;
            category.sorted = true;
        }
    }
}
