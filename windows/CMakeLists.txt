cmake_minimum_required(VERSION 3.14)

set(PROJECT_NAME "flutter_litert_flex")
project(${PROJECT_NAME} LANGUAGES CXX)

# Explicitly opt in to modern CMake behaviors to avoid warnings with recent
# versions of CMake.
cmake_policy(VERSION 3.14...3.25)

# This value is used when generating builds using this plugin, so it must
# not be changed.
set(PLUGIN_NAME "flutter_litert_flex_plugin")

# Any new source files that you add to the plugin should be added here.
list(APPEND PLUGIN_SOURCES
  "flutter_litert_flex_plugin.cpp"
  "flutter_litert_flex_plugin.h"
)

# Define the plugin library target. Its name must not be changed (see comment
# on PLUGIN_NAME above).
add_library(${PLUGIN_NAME} SHARED
  "include/flutter_litert_flex/flutter_litert_flex_plugin_c_api.h"
  "flutter_litert_flex_plugin_c_api.cpp"
  ${PLUGIN_SOURCES}
)

apply_standard_settings(${PLUGIN_NAME})

set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)

target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include")
target_link_libraries(${PLUGIN_NAME} PRIVATE flutter flutter_wrapper_plugin)

# FlexDelegate native library: downloaded once, cached in plugin directory.
# The download is checked against FLEX_SHA256, and a cached copy with another
# hash (an older release, or a broken download) is downloaded again.
set(FLEX_RELEASE "flex-v2.0.0")
set(FLEX_LIB "libtensorflowlite_flex-win.dll")
set(FLEX_SHA256 "718053040d2561bd35f8e1eed8db0b14ad5d233a9245069137c0238a997a9b28")
set(FLEX_URL "https://github.com/hugocornellier/flutter_litert/releases/download/${FLEX_RELEASE}/${FLEX_LIB}")
set(FLEX_PATH "${CMAKE_CURRENT_SOURCE_DIR}/${FLEX_LIB}")

if(EXISTS "${FLEX_PATH}")
  file(SHA256 "${FLEX_PATH}" _flex_have_sha256)
  if(NOT _flex_have_sha256 STREQUAL FLEX_SHA256)
    message(STATUS "[flutter_litert_flex] Cached FlexDelegate has another SHA-256, downloading it again.")
    file(REMOVE "${FLEX_PATH}")
  endif()
endif()

if(NOT EXISTS "${FLEX_PATH}")
  message(STATUS "[flutter_litert_flex] Downloading FlexDelegate for Windows...")
  file(DOWNLOAD "${FLEX_URL}" "${FLEX_PATH}.download"
       STATUS _dl_status
       SHOW_PROGRESS)
  list(GET _dl_status 0 _dl_code)
  if(NOT _dl_code EQUAL 0)
    list(GET _dl_status 1 _dl_msg)
    file(REMOVE "${FLEX_PATH}.download")
    message(FATAL_ERROR "[flutter_litert_flex] Failed to download FlexDelegate: ${_dl_msg}")
  endif()
  file(SHA256 "${FLEX_PATH}.download" _flex_got_sha256)
  if(NOT _flex_got_sha256 STREQUAL FLEX_SHA256)
    file(REMOVE "${FLEX_PATH}.download")
    message(FATAL_ERROR "[flutter_litert_flex] FlexDelegate SHA-256 mismatch for ${FLEX_URL}: expected ${FLEX_SHA256}, got ${_flex_got_sha256}")
  endif()
  file(RENAME "${FLEX_PATH}.download" "${FLEX_PATH}")
  message(STATUS "[flutter_litert_flex] FlexDelegate downloaded.")
endif()

# Bundle the DLL into the app.
set(flutter_litert_flex_bundled_libraries "${FLEX_PATH}" PARENT_SCOPE)
