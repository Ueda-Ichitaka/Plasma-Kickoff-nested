# About: standalone build of Kickoff Nested. Builds the Kickoff applet from
# applets/kickoff/, Kicker's subfolder components from applets/kicker/ as a
# separate QML module (cmake/KickerParts.cmake), and the tests, without the
# rest of plasma-desktop. The
# version and minimum dependency versions follow the upstream plasma-desktop
# release this fork is based on.
#
# SPDX-FileCopyrightText: 2026 Ueda-Ichitaka
# SPDX-License-Identifier: MIT

cmake_minimum_required(VERSION 3.25)

project(kickoff-nested VERSION 6.8.2)

set(PROJECT_DEP_VERSION "6.8.0")
set(QT_MIN_VERSION "6.11.0")
set(KF6_MIN_VERSION "6.30.0")

find_package(ECM ${KF6_MIN_VERSION} REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH})

include(KDEInstallDirs)
include(KDECMakeSettings)
include(KDECompilerSettings NO_POLICY_SCOPE)
include(ECMQmlModule)
include(FeatureSummary)

find_package(Qt6 ${QT_MIN_VERSION} CONFIG REQUIRED COMPONENTS Core Gui Qml Quick)
qt_policy(SET QTP0004 NEW)
find_package(KF6 ${KF6_MIN_VERSION} REQUIRED COMPONENTS CoreAddons)
find_package(Plasma ${PROJECT_DEP_VERSION} REQUIRED)

add_subdirectory(applets/kickoff)
include(cmake/KickerParts.cmake)

if(BUILD_TESTING)
    add_subdirectory(tests)
endif()

feature_summary(WHAT ALL FATAL_ON_MISSING_REQUIRED_PACKAGES)
