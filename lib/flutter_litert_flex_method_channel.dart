import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_litert_flex_platform_interface.dart';

/// An implementation of [FlutterLitertFlexPlatform] that uses method channels.
class MethodChannelFlutterLitertFlex extends FlutterLitertFlexPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_litert_flex');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }
}
