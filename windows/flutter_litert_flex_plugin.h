#ifndef FLUTTER_PLUGIN_FLUTTER_LITERT_FLEX_PLUGIN_H_
#define FLUTTER_PLUGIN_FLUTTER_LITERT_FLEX_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace flutter_litert_flex {

class FlutterLitertFlexPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  FlutterLitertFlexPlugin();

  virtual ~FlutterLitertFlexPlugin();

  // Disallow copy and assign.
  FlutterLitertFlexPlugin(const FlutterLitertFlexPlugin&) = delete;
  FlutterLitertFlexPlugin& operator=(const FlutterLitertFlexPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace flutter_litert_flex

#endif  // FLUTTER_PLUGIN_FLUTTER_LITERT_FLEX_PLUGIN_H_
