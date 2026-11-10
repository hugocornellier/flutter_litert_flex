/// FlexDelegate (SELECT_TF_OPS) addon for flutter_litert.
///
/// Adding this package to your `pubspec.yaml` automatically downloads and
/// bundles the FlexDelegate native library (~132-500 MB depending on platform)
/// at build time on iOS, macOS, Linux and Windows. No Dart code changes
/// needed; just use `FlexDelegate.create()` from
/// `package:flutter_litert/flutter_litert.dart` as usual.
///
/// ```yaml
/// dependencies:
///   flutter_litert: ^4.1.0
///   flutter_litert_flex: ^2.1.0
/// ```
///
/// Android is not supported: LiteRT 2.x, which flutter_litert 4.0.0 uses on
/// Android, has no flex delegate.
library;
