package com.hugocornellier.flutter_litert_flex

import io.flutter.embedding.engine.plugins.FlutterPlugin

/** Bundles the TensorFlow Lite Flex delegate native library for Android. */
class FlutterLitertFlexPlugin : FlutterPlugin {
    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        // No method channel needed — this plugin only bundles native libraries.
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    }
}
