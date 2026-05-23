import Flutter

public class FlutterLitertFlexPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    // No-op. This plugin only provides the FlexDelegate native library
    // via its vendored xcframework. The Dart FlexDelegate class in
    // flutter_litert finds the symbols via DynamicLibrary.process().
  }
}
