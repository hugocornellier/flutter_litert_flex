## 2.1.1

* Depend on `flutter_litert: ^4.1.1`, which fixes the iOS and macOS
  `Interpreter` slowdown with the XNNPACK delegate in 4.1.0. The Flex
  delegate libraries are unchanged.
* The example app resolves flutter_litert 4.1.1 and flutter_litert_flex 2.x
  (its lock file still pinned flutter_litert 3.9.1 and flutter_litert_flex
  1.3.0).

## 2.1.0

* The Flex delegate libraries for iOS, macOS, Linux and Windows are built
  from TensorFlow v2.21.0 (they were v2.20.0), matching the TensorFlow Lite
  runtime of flutter_litert 4.1.0. They are downloaded from the
  `flex-v2.0.0` release of flutter_litert.
* Requires
  [flutter_litert 4.1.0](https://pub.dev/packages/flutter_litert/versions/4.1.0):
  the package now depends on `flutter_litert: ^4.1.0`.
* Every native download is checked against a pinned SHA-256 (CocoaPods on iOS
  and macOS, CMake on Linux and Windows, as SwiftPM already did), and the
  build fails on a mismatch. A cached library from another release is
  downloaded again.
* macOS: the Flex delegate dylib now needs macOS 12.0 or newer at run time
  (the TensorFlow v2.20.0 one needed macOS 15.2).
* Linux: the x86_64 library needs glibc 2.27 or newer (the TensorFlow v2.20.0
  one needed glibc 2.38). It is 367819776 bytes.
* Windows: the x64 DLL is built with clang-cl, because MSVC cannot build
  TensorFlow v2.21.0. It is 240036352 bytes. It now imports
  `vcruntime140_threads.dll`, which flutter_litert 4.1.0 bundles next to the
  app, so that file does not have to be installed. As before, the DLL also
  needs the Microsoft Visual C++ Redistributable (`msvcp140.dll`,
  `vcruntime140.dll`, `vcruntime140_1.dll`) on the user's machine.
* iOS: the CocoaPods archive dedup also recognises the 16 hex digit object
  name suffix of TensorFlow v2.21.0 builds. Without it, `-force_load` hit
  about 2600 duplicate symbols.

## 2.0.0

* **Breaking:** Android is removed. flutter_litert 4.0.0 runs on LiteRT 2.x on
  Android, and LiteRT 2.x has no flex delegate (Select TF ops), so there is no
  Android library left to bundle. The Android plugin, its Gradle build (which
  pulled `tensorflow-lite` and `tensorflow-lite-select-tf-ops`) and the
  example's Android app are gone. On Android, flutter_litert 4.0.0 reports
  `FlexDelegate.isAvailable` as `false` and `FlexDelegate.create()` throws an
  `UnsupportedError`. Android apps that need flex can stay on flutter_litert
  3.10.x with flutter_litert_flex 1.3.0, or reconvert the model to LiteRT
  built-in ops.
* **Breaking:** requires
  [flutter_litert 4.0.0](https://pub.dev/packages/flutter_litert/versions/4.0.0),
  released with this version. The package now depends on
  `flutter_litert: ^4.0.0`, so pub can no longer pair it with an older
  flutter_litert. See the
  [flutter_litert 4.0.0 changelog](https://pub.dev/packages/flutter_litert/versions/4.0.0/changelog)
  for its migration guide.
* **Breaking:** the iOS minimum is now 15.0 (it was 13.0), matching
  flutter_litert 4.0.0, whose LiteRT frameworks are built for iOS 15.0.
* iOS, macOS, Linux and Windows otherwise keep the same Flex delegate
  libraries and the same build-time download.

## 1.3.0

* Complete the AGP 9 fix from 1.2.0. The previous guard applied `kotlin-android`
  only on AGP < 9, which left AGP 9 builds with no Kotlin compiler at all when the
  consumer disables built-in Kotlin via `android.builtInKotlin=false` (the flag the
  Flutter AGP-9 migrator adds to apps). With neither built-in Kotlin nor KGP active,
  the plugin's Kotlin class was never compiled and consumer apps failed at
  GeneratedPluginRegistrant with "cannot find symbol class FlutterLitertFlexPlugin".
  The Android build script now also applies KGP when built-in Kotlin is disabled
  (the same logic flutter_litert uses), so there is always a Kotlin compiler.
  Verified with a clean `flutter build apk` under AGP 9.2.1 with
  `builtInKotlin=false`. The example app's Kotlin Gradle Plugin application was made
  conditional the same way.

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
