#include "include/flutter_litert_flex/flutter_litert_flex_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "flutter_litert_flex_plugin.h"

void FlutterLitertFlexPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  flutter_litert_flex::FlutterLitertFlexPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
