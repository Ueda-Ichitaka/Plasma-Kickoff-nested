# About: automated tests of Kickoff Nested, run with ctest. tst_metadata
# checks the built applet plugin, tst_kickerparts loads the Kicker parts QML
# module with qmltestrunner from the build directory.
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
add_test(NAME tst_kickerparts
    COMMAND ${QMLTESTRUNNER} -platform offscreen
        -import "${CMAKE_BINARY_DIR}/bin"
        -input "${CMAKE_CURRENT_SOURCE_DIR}/tst_kickerparts.qml"
)
