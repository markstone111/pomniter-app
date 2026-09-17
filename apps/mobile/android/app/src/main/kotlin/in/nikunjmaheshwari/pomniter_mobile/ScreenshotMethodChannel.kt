package `in`.nikunjmaheshwari.pomniter_mobile

import android.content.Context
import android.content.Intent
import android.os.Build
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Manages the bidirectional Flutter ↔ Kotlin MethodChannel for screenshot indexing.
 *
 * Channel name: "com.pomniter.app/indexer"
 *
 * Dart → Kotlin calls:
 *   - "startIndexerService"  → Starts [ScreenshotIndexerService] as a foreground service
 *   - "stopIndexerService"   → Stops the foreground service
 *   - "notifyIndexComplete"  → Increments the notification count (called after successful index)
 *
 * Kotlin → Dart calls (invoked on main thread):
 *   - "onScreenshotDetected" with arg: String filePath
 */
object ScreenshotMethodChannel {

    private const val CHANNEL = "com.pomniter.app/indexer"

    /** Set by [MainActivity] once the FlutterEngine is attached. */
    private var channel: MethodChannel? = null
    private var appContext: Context? = null

    fun register(flutterEngine: FlutterEngine, context: Context) {
        appContext = context.applicationContext
        channel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL,
        ).also { ch ->
            ch.setMethodCallHandler { call, result ->
                when (call.method) {
                    "startIndexerService" -> {
                        startService(context)
                        result.success(null)
                    }
                    "stopIndexerService" -> {
                        stopService(context)
                        result.success(null)
                    }
                    "notifyIndexComplete" -> {
                        ScreenshotIndexerService.instance?.incrementIndexedCount()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    /**
     * Called from [ScreenshotIndexerService]'s ContentObserver when a new screenshot
     * is detected. Marshals to the platform main thread before invoking the Dart method.
     */
    fun onScreenshotDetected(filePath: String) {
        val ch = channel ?: return
        // MethodChannel.invokeMethod must be called on the main (platform) thread
        android.os.Handler(android.os.Looper.getMainLooper()).post {
            ch.invokeMethod("onScreenshotDetected", filePath)
        }
    }

    // ─── Service lifecycle helpers ────────────────────────────────────────────

    private fun startService(context: Context) {
        val intent = Intent(context, ScreenshotIndexerService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.startForegroundService(intent)
        } else {
            context.startService(intent)
        }
    }

    private fun stopService(context: Context) {
        context.stopService(Intent(context, ScreenshotIndexerService::class.java))
    }
}
