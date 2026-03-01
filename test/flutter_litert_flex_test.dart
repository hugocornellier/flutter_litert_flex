import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_litert_flex/flutter_litert_flex.dart';
import 'package:flutter_litert_flex/flutter_litert_flex_platform_interface.dart';
import 'package:flutter_litert_flex/flutter_litert_flex_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterLitertFlexPlatform
    with MockPlatformInterfaceMixin
    implements FlutterLitertFlexPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final FlutterLitertFlexPlatform initialPlatform = FlutterLitertFlexPlatform.instance;

  test('$MethodChannelFlutterLitertFlex is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFlutterLitertFlex>());
  });

  test('getPlatformVersion', () async {
    FlutterLitertFlex flutterLitertFlexPlugin = FlutterLitertFlex();
    MockFlutterLitertFlexPlatform fakePlatform = MockFlutterLitertFlexPlatform();
    FlutterLitertFlexPlatform.instance = fakePlatform;

    expect(await flutterLitertFlexPlugin.getPlatformVersion(), '42');
  });
}
