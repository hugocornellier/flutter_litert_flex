<h1 align="center">flutter_litert_flex</h1>

<p align="center">
<a href="https://flutter.dev"><img src="https://img.shields.io/badge/Platform-Flutter-02569B?logo=flutter" alt="Platform"></a>
<a href="https://pub.dev/packages/flutter_litert_flex"><img src="https://img.shields.io/pub/v/flutter_litert_flex?label=pub.dev&labelColor=333940&logo=dart" alt="Pub Version"></a>
<a href="https://github.com/hugocornellier/flutter_litert_flex/blob/main/LICENSE"><img src="https://img.shields.io/badge/License-Apache_2.0-007A88.svg?logo=apache" alt="License"></a>
</p>

FlexDelegate (SELECT_TF_OPS) addon for [`flutter_litert`](https://pub.dev/packages/flutter_litert). Automatically downloads and bundles the TensorFlow Lite Flex delegate native library at build time on iOS, macOS, Linux and Windows.

> **Android is not supported.** flutter_litert 4.0.0 and newer run on LiteRT 2.x on Android, and LiteRT 2.x has no flex delegate, so flutter_litert_flex 2.x has no Android side. Android apps that need flex can stay on `flutter_litert: ^3.10.0` with `flutter_litert_flex: 1.3.0`, or reconvert the model to LiteRT built-in ops.

## When do you need this?

The Flex delegate is required when your `.tflite` model uses TensorFlow ops that aren't available as TFLite builtins. Common cases:

- On-device training with convolutional or batch-normalized layers (gradient ops like `Conv2DBackpropFilter`)
- Checkpoint-based persistence using `tf.raw_ops.Save`/`Restore`
- Models converted with `SELECT_TF_OPS` enabled

If your model only uses `TFLITE_BUILTINS`, you don't need this package.

## Installation

```yaml
dependencies:
  flutter_litert: ^4.1.0
  flutter_litert_flex: ^2.1.0
```

That's it. The native libraries are downloaded automatically on the first build.

### Compatibility

Use the matching [`flutter_litert`](https://pub.dev/packages/flutter_litert) version:

| flutter_litert | flutter_litert_flex | Flex platforms |
| --- | --- | --- |
| 4.1.0 or newer | 2.1.0 | iOS 15+, macOS 12+, Linux, Windows |
| 4.0.x | 2.0.0 | iOS 15+, macOS 15.2+, Linux, Windows |
| 3.10.x | 1.3.0 | Android, iOS, macOS, Linux, Windows |

flutter_litert 4.x and flutter_litert_flex 2.x need iOS 15.0 or newer. The macOS Flex delegate library of flutter_litert_flex 2.1.0 needs macOS 12.0 or newer (Apple Silicon).

> **iOS + Swift Package Manager:** `flutter_litert_flex` must be used alongside `flutter_litert`; the FlexDelegate links against core TFLite symbols that `flutter_litert` provides. Like `flutter_litert`, its xcframework ships `arm64` device + `arm64` *simulator* slices, so iOS **simulator** builds require an **Apple Silicon Mac**; the x86_64 (Intel) simulator is not supported under SPM. CocoaPods builds are unaffected.

## Usage

```dart
import 'package:flutter_litert/flutter_litert.dart';

final options = InterpreterOptions();
options.addDelegate(await FlexDelegate.create());
final interpreter = await Interpreter.fromAsset('model.tflite', options: options);
```

`FlexDelegate.isAvailable` tells you whether the library was bundled. It is always `false` on Android, where `FlexDelegate.create()` throws an `UnsupportedError`.

## Platform details

| Platform | Library | Size | Mechanism |
|----------|---------|------|-----------|
| iOS | `TensorFlowLiteFlex.xcframework` | ~500 MB | CocoaPods or SPM (static framework) |
| macOS | `libtensorflowlite_flex-mac.dylib` | ~132 MB | CocoaPods or SPM (bundled resource) |
| Linux | `libtensorflowlite_flex-linux.so` | ~333 MB | CMake download |
| Windows | `libtensorflowlite_flex-win.dll` | ~227 MB | CMake download |

Libraries are downloaded once, checked against a pinned SHA-256, and cached in the plugin directory. Subsequent builds use the cached copy.

## Credits

Based on TensorFlow Lite v2.21.0. See [`flutter_litert`](https://pub.dev/packages/flutter_litert) for the base inference library.
