cmake_minimum_required(VERSION 3.10)

set(PROJECT_NAME "flutter_litert_flex")
project(${PROJECT_NAME} LANGUAGES CXX)

# Plugin shared library target (required by Flutter's generated plugin registrant).
set(PLUGIN_NAME "flutter_litert_flex_plugin")

add_library(${PLUGIN_NAME} SHARED
  "flutter_litert_flex_plugin.cc"
)

apply_standard_settings(${PLUGIN_NAME})

set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)

target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include")
target_link_libraries(${PLUGIN_NAME} PRIVATE flutter)
target_link_libraries(${PLUGIN_NAME} PRIVATE PkgConfig::GTK)

# FlexDelegate native library: downloaded once, cached in plugin directory.
# The download is checked against FLEX_SHA256, and a cached copy with another
# hash (an older release, or a broken download) is downloaded again.
set(FLEX_RELEASE "flex-v1.0.0")
set(FLEX_LIB "libtensorflowlite_flex-linux.so")
set(FLEX_SHA256 "2f1b626aa7e72e28dbddd7707ccb05848e140ab3a39771f515b00608205aeffc")
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
  message(STATUS "[flutter_litert_flex] Downloading FlexDelegate for Linux...")
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

# Bundle the .so into the app.
set(flutter_litert_flex_bundled_libraries "${FLEX_PATH}" PARENT_SCOPE)
