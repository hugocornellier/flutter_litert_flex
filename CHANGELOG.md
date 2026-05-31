## 1.2.0

* Fix Android builds under AGP 9 / Flutter 3.44+ with built-in Kotlin. The
  plugin previously applied the legacy Kotlin Gradle Plugin unconditionally,
  which AGP 9 rejects ("The 'org.jetbrains.kotlin.android' plugin is no longer
  required since AGP 9.0", or "Cannot add extension with name 'kotlin'"). The
  Android build script now applies `kotlin-android` only on AGP < 9 and lets
  built-in Kotlin compile the sources on AGP >= 9, with the Kotlin JVM target
  pinned to 17. Verified against AGP 8.11.1 and 9.0.1 with built-in Kotlin both
  enabled and disabled. No API or minimum-version changes.

## 1.1.0

* Fix iOS Swift Package Manager builds: repackage the FlexDelegate xcframework (correct simulator slice) so SELECT_TF_OPS works under SPM, including on the iOS simulator.

## 1.0.0

* Raise minimum deployment targets to iOS 13.0 / macOS 10.15 to satisfy Swift Package Manager's `FlutterFramework` requirement (fixes SPM build failures).

## 0.0.8

* Migrate example app from CocoaPods to Swift Package Manager on iOS and macOS.

## 0.0.7

* Fix SPM: add missing `FlutterFramework` dependency to iOS and macOS `Package.swift`.

## 0.0.6

* Add SPM support for iOS and macOS

## 0.0.5

* Fix Linux: add plugin shared library target to CMakeLists (fixes `No target "flutter_litert_flex_plugin"` build error).

## 0.0.4

* Fix iOS FlexDelegate: rewrite podspec dedup logic (subset-check instead of naive hash removal), add `-force_load` linker flags, and force-reference plugin symbols to prevent stripping.

## 0.0.3

* Fix macOS podspec: use relative resource path (fixes CocoaPods validation error).

## 0.0.2

* Fix Android: add method channel for FlexDelegate creation via Java API (the Maven artifact only exports JNI symbols, not C plugin symbols).
* Add explicit `org.tensorflow:tensorflow-lite` base dependency for the `Delegate` interface.

## 0.0.1

* Initial release.
* Bundles the TensorFlow Lite Flex delegate (SELECT_TF_OPS) native library for all platforms.
* iOS: Downloads and vendors `TensorFlowLiteFlex.xcframework` (~492 MB) via CocoaPods.
* macOS: Downloads `libtensorflowlite_flex-mac.dylib` (~123 MB) via CocoaPods.
* Linux: Downloads `libtensorflowlite_flex-linux.so` (~333 MB) via CMake.
* Windows: Downloads `libtensorflowlite_flex-win.dll` (~227 MB) via CMake.
* Android: Adds `tensorflow-lite-select-tf-ops` Maven dependency.
