package com.wise.signals.flutter

import android.content.Context
import android.os.Handler
import android.os.Looper
import com.wise.fingerprint.IdentifyOptions
import com.wise.fingerprint.WiseConfiguration
import com.wise.fingerprint.WiseException
import com.wise.fingerprint.WiseFingerprint
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.util.concurrent.Executors

/**
 * Flutter plugin for the Wise Signals Android SDK.
 *
 * Marshals the Dart `identify(config, options)` call to the native
 * `com.wise.fingerprint.WiseFingerprint` SDK (sdks/android) — signal collection,
 * derived ids, cert pinning and the `/v1/identify` transport all run there. This
 * plugin only translates the channel `Map` ↔ the native types and runs the
 * blocking `identify()` off the platform thread.
 */
class WiseSignalsPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private var context: Context? = null

    // identify() does blocking network I/O — keep it off the platform thread.
    private val executor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, CHANNEL)
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        context = null
        executor.shutdown()
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        if (call.method != "identify") {
            result.notImplemented()
            return
        }

        @Suppress("UNCHECKED_CAST")
        val configMap = call.argument<Map<String, Any?>>("config")
        @Suppress("UNCHECKED_CAST")
        val optionsMap = call.argument<Map<String, Any?>>("options") ?: emptyMap()
        val ctx = context

        val apiKey = configMap?.get("apiKey") as? String
        if (apiKey == null || ctx == null) {
            result.error("INVALID_CONFIGURATION", "apiKey and a valid context are required", null)
            return
        }

        val configuration = WiseConfiguration(
            apiKey = apiKey,
            endpoint = configMap["endpoint"] as? String,
            region = configMap["region"] as? String ?: "ap",
            timeoutMs = (configMap["timeoutMs"] as? Number)?.toInt() ?: 5000,
            pinnedSpkiHashes = (configMap["pinnedSpkiHashes"] as? List<*>)
                ?.filterIsInstance<String>() ?: emptyList(),
        )

        @Suppress("UNCHECKED_CAST")
        val extra = (optionsMap["extra"] as? Map<*, *>)
            ?.entries
            ?.mapNotNull { (k, v) -> if (k is String && v is String) k to v else null }
            ?.toMap()
        val identifyOptions = IdentifyOptions(
            linkedId = optionsMap["linkedId"] as? String,
            tag = optionsMap["tag"] as? String,
            extra = extra?.ifEmpty { null },
        )

        executor.execute {
            try {
                val wise = WiseFingerprint(ctx, configuration)
                val r = wise.identify(identifyOptions)
                val payload = mapOf(
                    "requestId" to r.requestId,
                    "ingestedAt" to r.ingestedAt,
                    "region" to r.region,
                    "visitorId" to r.visitorId,
                    "confidence" to r.confidence,
                    "identifiedAt" to r.identifiedAt,
                )
                // Channel replies must be delivered on the main thread.
                mainHandler.post { result.success(payload) }
            } catch (e: WiseException) {
                mainHandler.post { result.error(codeFor(e), e.message, null) }
            } catch (e: Exception) {
                mainHandler.post { result.error("NETWORK_ERROR", e.message, null) }
            }
        }
    }

    private companion object {
        const val CHANNEL = "wise_signals"

        /** Map the native error taxonomy to the bridge's stable string codes
         *  (mirrors `WiseErrorCode` on the Dart side). Messages carry NO PII. */
        fun codeFor(e: WiseException): String = when (e) {
            is WiseException.InvalidConfiguration -> "INVALID_CONFIGURATION"
            WiseException.Network -> "NETWORK_ERROR"
            WiseException.Timeout -> "TIMEOUT"
            is WiseException.Http -> "HTTP_ERROR"
            WiseException.InvalidResponse -> "INVALID_RESPONSE"
            WiseException.PinningFailed -> "PINNING_FAILED"
        }
    }
}
