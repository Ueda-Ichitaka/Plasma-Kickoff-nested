# About: builds Kicker's subfolder flyout components from the unmodified
# upstream files in applets/kicker/ as the internal QML module
# kickoffnested.kickerparts. A module of their own keeps Kicker's ActionMenu
# singleton and code/tools.js apart from Kickoff's files of the same name.
# The module also holds our own src/ files: KickerBridge.qml, which provides
# the `kicker` object those components expect, and NestedFlyout.qml with
# flyout.js, which open the flyouts from Kickoff's app views. Included from
# the top-level CMakeLists.txt.
#
# SPDX-FileCopyrightText: 2026 Ueda-Ichitaka
# SPDX-License-Identifier: MIT

set(KICKER_DIR "${CMAKE_SOURCE_DIR}/applets/kicker")

set_source_files_properties("${KICKER_DIR}/ActionMenu.qml" PROPERTIES QT_QML_SINGLETON_TYPE TRUE)

ecm_add_qml_module(kickoffnested_kickerparts URI "kickoffnested.kickerparts" GENERATE_PLUGIN_SOURCE)

ecm_target_qml_sources(kickoffnested_kickerparts SOURCES
    "${KICKER_DIR}/ActionMenu.qml"
    "${KICKER_DIR}/HoverBlocker.qml"
    "${KICKER_DIR}/ItemAbstractDelegate.qml"
    "${KICKER_DIR}/ItemListDelegate.qml"
    "${KICKER_DIR}/ItemListDialog.qml"
    "${KICKER_DIR}/ItemListView.qml"
)
ecm_target_qml_sources(kickoffnested_kickerparts SOURCES "${KICKER_DIR}/code/tools.js" PATH code)
ecm_target_qml_sources(kickoffnested_kickerparts SOURCES
    "${CMAKE_SOURCE_DIR}/src/KickerBridge.qml"
    "${CMAKE_SOURCE_DIR}/src/NestedFlyout.qml"
    "${CMAKE_SOURCE_DIR}/src/flyout.js"
)

ecm_finalize_qml_module(kickoffnested_kickerparts DESTINATION "${KDE_INSTALL_QMLDIR}")
