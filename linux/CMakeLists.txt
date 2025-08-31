# Project-level configuration.
cmake_minimum_required(VERSION 3.13)
project(runner LANGUAGES CXX)

# The name of the executable created for the application. Change this to change
# the on-disk name of your application.
set(BINARY_NAME "asante_typing")

# The unique GTK application identifier for this application.
# https://wiki.gnome.org/HowDoI/ChooseApplicationID
set(APPLICATION_ID "org.munkulu.asante_typing")

# Enable FHS system-wide install rules only when packaging.
# Default OFF so `flutter build linux` never tries to write to /usr/local.
option(ASANTE_SYSTEM_INSTALL "Enable FHS system-wide install/packaging rules" OFF)

# Explicitly opt in to modern CMake behaviors to avoid warnings with recent versions of CMake.
cmake_policy(SET CMP0063 NEW)

# Root filesystem for cross-building.
if(FLUTTER_TARGET_PLATFORM_SYSROOT)
  set(CMAKE_SYSROOT ${FLUTTER_TARGET_PLATFORM_SYSROOT})
  set(CMAKE_FIND_ROOT_PATH ${CMAKE_SYSROOT})
  set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
  set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
  set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
  set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
endif()

# Define build configuration options.
if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
  set(CMAKE_BUILD_TYPE "Debug" CACHE STRING "Flutter build mode" FORCE)
  set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS "Debug" "Profile" "Release")
endif()

# Compilation settings applied to most targets.
function(APPLY_STANDARD_SETTINGS TARGET)
  target_compile_features(${TARGET} PUBLIC cxx_std_14)
  target_compile_options(${TARGET} PRIVATE -Wall -Werror)
  target_compile_options(${TARGET} PRIVATE "$<$<NOT:$<CONFIG:Debug>>:-O3>")
  target_compile_definitions(${TARGET} PRIVATE "$<$<NOT:$<CONFIG:Debug>>:NDEBUG>")
endfunction()

# Flutter library and tool build rules.
set(FLUTTER_MANAGED_DIR "${CMAKE_CURRENT_SOURCE_DIR}/flutter")
add_subdirectory(${FLUTTER_MANAGED_DIR})

# System-level dependencies.
find_package(PkgConfig REQUIRED)
pkg_check_modules(GTK REQUIRED IMPORTED_TARGET gtk+-3.0)

# Application build; see runner/CMakeLists.txt.
add_subdirectory("runner")

# Run the Flutter tool portions of the build. This must not be removed.
add_dependencies(${BINARY_NAME} flutter_assemble)

# Put the unbundled artifact where it won't be accidentally run.
set_target_properties(${BINARY_NAME}
  PROPERTIES
  RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/intermediates_do_not_run"
)

# Generated plugin build rules, which manage building the plugins and adding them to the application.
include(flutter/generated_plugins.cmake)

# -------------------------------
# Desktop entry & icons (FHS mode)
# -------------------------------
if(ASANTE_SYSTEM_INSTALL)
  include(GNUInstallDirs)

  # Desktop entry
  install(FILES "${CMAKE_CURRENT_SOURCE_DIR}/packaging/org.mukulu.asante_typing.desktop"
          DESTINATION "${CMAKE_INSTALL_DATAROOTDIR}/applications" COMPONENT Runtime)

  # Hicolor icons (all sizes)
  install(DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/packaging/icons/hicolor/"
          DESTINATION "${CMAKE_INSTALL_DATAROOTDIR}/icons/hicolor" COMPONENT Runtime)
  
          # Ensure the installed binary can find its libs in /usr/lib*/asante_typing
  set_target_properties(${BINARY_NAME} PROPERTIES
    INSTALL_RPATH "$ORIGIN/../lib/${BINARY_NAME}"
  )

endif()

# -----------------------------------------
# Install rules: Bundle vs. System (FHS)
# -----------------------------------------
if(ASANTE_SYSTEM_INSTALL)
  include(GNUInstallDirs)

  # === Installation (FHS compliant) ===
  # Binary → /usr/bin
  # Libs   → /usr/lib/asante_typing
  # Assets → /usr/share/asante_typing/flutter_assets
  # Desktop entry + icons → /usr/share/...

  set(INSTALL_BUNDLE_DATA_DIR "${CMAKE_INSTALL_DATAROOTDIR}/${BINARY_NAME}")
  set(INSTALL_BUNDLE_LIB_DIR  "${CMAKE_INSTALL_LIBDIR}/${BINARY_NAME}")

  # Binary
  install(TARGETS ${BINARY_NAME}
          RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}"
          COMPONENT Runtime)

  # ICU data + Flutter engine
  install(FILES "${FLUTTER_ICU_DATA_FILE}"
          DESTINATION "${INSTALL_BUNDLE_DATA_DIR}" COMPONENT Runtime)
  install(FILES "${FLUTTER_LIBRARY}"
          DESTINATION "${INSTALL_BUNDLE_LIB_DIR}" COMPONENT Runtime)

  # Plugin-bundled native libs (if any)
  foreach(bundled_library ${PLUGIN_BUNDLED_LIBRARIES})
    install(FILES "${bundled_library}"
            DESTINATION "${INSTALL_BUNDLE_LIB_DIR}" COMPONENT Runtime)
  endforeach()

  # Native assets (optional)
  set(NATIVE_ASSETS_DIR "${PROJECT_BUILD_DIR}native_assets/linux/")
  install(DIRECTORY "${NATIVE_ASSETS_DIR}"
          DESTINATION "${INSTALL_BUNDLE_LIB_DIR}" COMPONENT Runtime OPTIONAL)

  # Flutter assets
  set(FLUTTER_ASSET_DIR_NAME "flutter_assets")
  install(CODE "file(REMOVE_RECURSE \"${INSTALL_BUNDLE_DATA_DIR}/${FLUTTER_ASSET_DIR_NAME}\")" COMPONENT Runtime)
  install(DIRECTORY "${PROJECT_BUILD_DIR}/${FLUTTER_ASSET_DIR_NAME}"
          DESTINATION "${INSTALL_BUNDLE_DATA_DIR}" COMPONENT Runtime)

  # If Flutter didn't define AOT_LIBRARY for this config, copy from the built bundle.
  if (NOT AOT_LIBRARY AND EXISTS "${PROJECT_BUILD_DIR}/../lib/libapp.so")
    # PROJECT_BUILD_DIR points to .../bundle; AOT lives one level up in ../lib/
    set(AOT_LIBRARY "${PROJECT_BUILD_DIR}/../lib/libapp.so")
  endif()

  # Make /usr/bin/asante_typing find libflutter_linux_gtk.so in multi-arch/lib dir.
  set_target_properties(${BINARY_NAME} PROPERTIES
    INSTALL_RPATH "$ORIGIN/../lib/${BINARY_NAME}:$ORIGIN/../lib/x86_64-linux-gnu/${BINARY_NAME}"
  )


  # AOT library (only in non-Debug)
  if(NOT CMAKE_BUILD_TYPE MATCHES "Debug")
    install(FILES "${AOT_LIBRARY}"
            DESTINATION "${INSTALL_BUNDLE_LIB_DIR}" COMPONENT Runtime)
  endif()

  # RPATH so /usr/bin/asante_typing finds libs in /usr/lib/asante_typing
  set(CMAKE_INSTALL_RPATH "$ORIGIN/../lib/${BINARY_NAME}")

else()
  # === Installation (Bundle for flutter build) ===
  # This creates a relocatable bundle inside the build tree (no root required).

  set(BUILD_BUNDLE_DIR      "${PROJECT_BINARY_DIR}/bundle")
  set(BUILD_BUNDLE_LIB_DIR  "${BUILD_BUNDLE_DIR}/lib")
  set(BUILD_BUNDLE_DATA_DIR "${BUILD_BUNDLE_DIR}/data")

  # Clean + make bundle dirs
  install(CODE "file(REMOVE_RECURSE \"${BUILD_BUNDLE_DIR}\")")
  install(CODE "file(MAKE_DIRECTORY \"${BUILD_BUNDLE_LIB_DIR}\")")
  install(CODE "file(MAKE_DIRECTORY \"${BUILD_BUNDLE_DATA_DIR}\")")

  # Binary goes at bundle root
  install(TARGETS ${BINARY_NAME}
          RUNTIME DESTINATION "${BUILD_BUNDLE_DIR}" COMPONENT Runtime)

  # ICU data + Flutter engine into bundle
  install(FILES "${FLUTTER_ICU_DATA_FILE}"
          DESTINATION "${BUILD_BUNDLE_DATA_DIR}" COMPONENT Runtime)
  install(FILES "${FLUTTER_LIBRARY}"
          DESTINATION "${BUILD_BUNDLE_LIB_DIR}" COMPONENT Runtime)

  # Plugin-bundled native libs (if any)
  foreach(bundled_library ${PLUGIN_BUNDLED_LIBRARIES})
    install(FILES "${bundled_library}"
            DESTINATION "${BUILD_BUNDLE_LIB_DIR}" COMPONENT Runtime)
  endforeach()

  # Native assets (optional)
  set(NATIVE_ASSETS_DIR "${PROJECT_BUILD_DIR}native_assets/linux/")
  install(DIRECTORY "${NATIVE_ASSETS_DIR}"
          DESTINATION "${BUILD_BUNDLE_LIB_DIR}" COMPONENT Runtime OPTIONAL)

  # Flutter assets
  set(FLUTTER_ASSET_DIR_NAME "flutter_assets")
  install(DIRECTORY "${PROJECT_BUILD_DIR}/${FLUTTER_ASSET_DIR_NAME}"
          DESTINATION "${BUILD_BUNDLE_DATA_DIR}" COMPONENT Runtime)

  # AOT library (only in non-Debug)
  if(NOT CMAKE_BUILD_TYPE MATCHES "Debug")
    install(FILES "${AOT_LIBRARY}"
            DESTINATION "${BUILD_BUNDLE_LIB_DIR}" COMPONENT Runtime)
  endif()

  # RPATH so bundle binary finds libs in ./lib
  set(CMAKE_INSTALL_RPATH "$ORIGIN/lib")
endif()
