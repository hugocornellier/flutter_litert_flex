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
