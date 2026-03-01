
import 'flutter_litert_flex_platform_interface.dart';

class FlutterLitertFlex {
  Future<String?> getPlatformVersion() {
    return FlutterLitertFlexPlatform.instance.getPlatformVersion();
  }
}
