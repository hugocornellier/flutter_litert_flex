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
