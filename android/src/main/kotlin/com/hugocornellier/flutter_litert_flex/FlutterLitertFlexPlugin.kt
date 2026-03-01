package com.hugocornellier.flutter_litert_flex

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.tensorflow.lite.flex.FlexDelegate

/**
 * Bundles the TensorFlow Lite Flex delegate native library for Android
 * and exposes create/destroy via method channel so Dart FFI can obtain
 * the native delegate pointer.
 */
class FlutterLitertFlexPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private val delegates = mutableMapOf<Long, FlexDelegate>()

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "flutter_litert_flex")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        delegates.values.forEach { it.close() }
        delegates.clear()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "createFlexDelegate" -> {
                try {
                    val delegate = FlexDelegate()
                    val handle = delegate.nativeHandle
                    delegates[handle] = delegate
                    result.success(handle)
                } catch (e: Exception) {
                    result.error("FLEX_ERROR", "Failed to create FlexDelegate: ${e.message}", null)
                }
            }
            "deleteFlexDelegate" -> {
                val handle = (call.arguments as? Number)?.toLong()
                if (handle != null) {
                    delegates.remove(handle)?.close()
                }
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }
}
