# About: automated tests of Kickoff Nested, run with ctest. tst_metadata
# checks the built applet plugin; the QML tests run with Qt 6's
# qmltestrunner: tst_kickerparts loads the Kicker parts QML module from the
# build directory, tst_nested tests applets/kickoff/code/nested.js,
# tst_kickerbridge opens a Kicker flyout through the Kickoff bridge.
#
# SPDX-FileCopyrightText: 2026 Ueda-Ichitaka
# SPDX-License-Identifier: MIT

find_package(Qt6 ${QT_MIN_VERSION} CONFIG REQUIRED COMPONENTS Test)
include(ECMAddTests)

set(APPLET_PLUGIN_FILE "${CMAKE_BINARY_DIR}/bin/plasma/applets/local.kickoffnested.so")

ecm_add_test(tst_metadata.cpp
    TEST_NAME tst_metadata
    LINK_LIBRARIES Qt6::Test KF6::CoreAddons
)
target_compile_definitions(tst_metadata PRIVATE APPLET_PLUGIN_FILE="${APPLET_PLUGIN_FILE}")

find_program(QMLTESTRUNNER qmltestrunner HINTS "${QT6_INSTALL_PREFIX}/${QT6_INSTALL_BINS}" REQUIRED)
foreach(qml_test tst_kickerparts tst_nested tst_kickerbridge)
    add_test(NAME ${qml_test}
        COMMAND ${QMLTESTRUNNER} -platform offscreen
            -import "${CMAKE_BINARY_DIR}/bin"
            -input "${CMAKE_CURRENT_SOURCE_DIR}/${qml_test}.qml"
    )
endforeach()
