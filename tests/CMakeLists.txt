# About: automated tests of Kickoff Nested, run with ctest. tst_metadata
# checks the built applet plugin, tst_config the configuration schema
# (applets/kickoff/main.xml); the QML tests run with Qt 6's
# qmltestrunner: tst_kickerparts loads the Kicker parts QML module from the
# build directory, tst_nested tests applets/kickoff/code/nested.js,
# tst_kickerbridge opens a Kicker flyout through the Kickoff bridge,
# tst_flyout tests src/flyout.js, tst_nestedflyout src/NestedFlyout.qml.
# The menu-based tests use the fixed test menu in data/.
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

ecm_add_test(tst_config.cpp
    TEST_NAME tst_config
    LINK_LIBRARIES Qt6::Test
)
target_compile_definitions(tst_config PRIVATE CONFIG_SCHEMA_FILE="${CMAKE_SOURCE_DIR}/applets/kickoff/main.xml")

find_program(QMLTESTRUNNER qmltestrunner HINTS "${QT6_INSTALL_PREFIX}/${QT6_INSTALL_BINS}" REQUIRED)
foreach(qml_test tst_kickerparts tst_nested tst_kickerbridge tst_flyout tst_nestedflyout)
    add_test(NAME ${qml_test}
        COMMAND ${QMLTESTRUNNER} -platform offscreen
            -import "${CMAKE_BINARY_DIR}/bin"
            -input "${CMAKE_CURRENT_SOURCE_DIR}/${qml_test}.qml"
    )
endforeach()

# Tests reading Kicker's menu models see only the fixed menu in data/, with
# their own home, config and cache directories so the user's menu and KDE
# cache stay untouched.
set(TEST_XDG_HOME "${CMAKE_CURRENT_BINARY_DIR}/xdg-home")
file(MAKE_DIRECTORY "${TEST_XDG_HOME}/config" "${TEST_XDG_HOME}/data" "${TEST_XDG_HOME}/cache")
set_tests_properties(tst_kickerbridge tst_nestedflyout PROPERTIES ENVIRONMENT
    "XDG_MENU_PREFIX=test-;XDG_CONFIG_HOME=${TEST_XDG_HOME}/config;XDG_DATA_HOME=${TEST_XDG_HOME}/data;XDG_CACHE_HOME=${TEST_XDG_HOME}/cache;XDG_CONFIG_DIRS=${CMAKE_CURRENT_SOURCE_DIR}/data/xdg-config:/etc/xdg;XDG_DATA_DIRS=${CMAKE_CURRENT_SOURCE_DIR}/data/xdg-data:/usr/local/share:/usr/share"
)
