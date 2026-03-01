<h1 align="center">flutter_litert_flex</h1>

<p align="center">
<a href="https://flutter.dev"><img src="https://img.shields.io/badge/Platform-Flutter-02569B?logo=flutter" alt="Platform"></a>
<a href="https://pub.dev/packages/flutter_litert_flex"><img src="https://img.shields.io/pub/v/flutter_litert_flex?label=pub.dev&labelColor=333940&logo=dart" alt="Pub Version"></a>
<a href="https://github.com/hugocornellier/flutter_litert_flex/blob/main/LICENSE"><img src="https://img.shields.io/badge/License-Apache_2.0-007A88.svg?logo=apache" alt="License"></a>
</p>

FlexDelegate (SELECT_TF_OPS) addon for [`flutter_litert`](https://pub.dev/packages/flutter_litert). Automatically downloads and bundles the TensorFlow Lite Flex delegate native library at build time for all platforms.

## When do you need this?

The Flex delegate is required when your `.tflite` model uses TensorFlow ops that aren't available as TFLite builtins. Common cases:

- **On-device training** with convolutional or batch-normalized layers (gradient ops like `Conv2DBackpropFilter`)
- **Checkpoint-based persistence** using `tf.raw_ops.Save`/`Restore`
- Models converted with `SELECT_TF_OPS` enabled

If your model only uses `TFLITE_BUILTINS`, you don't need this package.

## Installation

```yaml
dependencies:
  flutter_litert: ^1.0.3
  flutter_litert_flex: ^0.0.1
```

That's it. The native libraries are downloaded automatically on the first build.

## Usage

```dart
import 'package:flutter_litert/flutter_litert.dart';

final options = InterpreterOptions();
options.addDelegate(FlexDelegate());
final interpreter = await Interpreter.fromAsset('model.tflite', options: options);
```

No `FlexDelegate.download()` call needed when using this package.

## Platform details

| Platform | Library | Size | Mechanism |
|----------|---------|------|-----------|
| iOS | `TensorFlowLiteFlex.xcframework` | ~492 MB | CocoaPods (static framework) |
| macOS | `libtensorflowlite_flex-mac.dylib` | ~123 MB | CocoaPods (bundled resource) |
| Linux | `libtensorflowlite_flex-linux.so` | ~333 MB | CMake download |
| Windows | `libtensorflowlite_flex-win.dll` | ~227 MB | CMake download |
| Android | `tensorflow-lite-select-tf-ops` | auto | Maven dependency |

Libraries are downloaded once and cached in the plugin directory. Subsequent builds use the cached copy.

## Credits

Based on TensorFlow Lite v2.20.0. See [`flutter_litert`](https://pub.dev/packages/flutter_litert) for the base inference library.
