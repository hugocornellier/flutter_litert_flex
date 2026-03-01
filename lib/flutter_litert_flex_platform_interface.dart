import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_litert_flex_method_channel.dart';

abstract class FlutterLitertFlexPlatform extends PlatformInterface {
  /// Constructs a FlutterLitertFlexPlatform.
  FlutterLitertFlexPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterLitertFlexPlatform _instance = MethodChannelFlutterLitertFlex();

  /// The default instance of [FlutterLitertFlexPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterLitertFlex].
  static FlutterLitertFlexPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterLitertFlexPlatform] when
  /// they register themselves.
  static set instance(FlutterLitertFlexPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
