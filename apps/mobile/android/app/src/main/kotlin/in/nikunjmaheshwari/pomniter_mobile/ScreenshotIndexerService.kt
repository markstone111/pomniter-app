package `in`.nikunjmaheshwari.pomniter_mobile

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.ContentResolver
import android.content.Context
import android.content.Intent
import android.database.ContentObserver
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.HandlerThread
import android.os.IBinder
import android.provider.MediaStore
import androidx.annotation.RequiresApi
import androidx.core.app.NotificationCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicInteger

/**
 * A persistent Android Foreground Service that:
 * 1. Registers a [ContentObserver] on [MediaStore.Images.Media.EXTERNAL_CONTENT_URI]
 * 2. Filters change events to the device's Screenshots/ directory
 * 3. Posts the detected file path back to Flutter via [ScreenshotMethodChannel]
 * 4. Shows a rich, updatable notification with the indexed-today count + pause action
 *
 * Lifecycle:
 * - Started via [Context.startForegroundService] from Flutter MethodChannel.
 * - [START_STICKY]: if the process is killed by the OS, it is automatically restarted
 *   with the last intent — guaranteeing continuous background indexing.
 * - Stopped via [Context.stopService] or the Flutter "stopIndexerService" channel call.
 */
class ScreenshotIndexerService : Service() {

    companion object {
        const val CHANNEL_ID = "pomniter_indexer_channel"
        const val NOTIFICATION_ID = 1001
        const val ACTION_PAUSE = "com.pomniter.ACTION_PAUSE"
        const val ACTION_RESUME = "com.pomniter.ACTION_RESUME"
        const val EXTRA_INDEXED_COUNT = "indexed_count"

        /** Static reference so [ScreenshotMethodChannel] can update the count. */
        var instance: ScreenshotIndexerService? = null
    }

    private lateinit var handlerThread: HandlerThread
    private lateinit var handler: Handler
    private lateinit var contentObserver: ContentObserver
    private lateinit var notificationManager: NotificationManager

    private val isPaused = AtomicBoolean(false)
    private val indexedTodayCount = AtomicInteger(0)

    // ─── Service Lifecycle ────────────────────────────────────────────────────

    override fun onCreate() {
        super.onCreate()
        instance = this
        notificationManager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        createNotificationChannel()

        handlerThread = HandlerThread("PomniterObserverThread").apply { start() }
        handler = Handler(handlerThread.looper)

        startForeground(NOTIFICATION_ID, buildNotification())
        registerScreenshotObserver()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_PAUSE -> {
                isPaused.set(true)
                updateNotification()
            }
            ACTION_RESUME -> {
                isPaused.set(false)
                updateNotification()
            }
        }
        return START_STICKY
    }

    override fun onDestroy() {
        super.onDestroy()
        contentResolver.unregisterContentObserver(contentObserver)
        handlerThread.quitSafely()
        instance = null
    }

    override fun onBind(intent: Intent?): IBinder? = null

    // ─── ContentObserver ──────────────────────────────────────────────────────

    private fun registerScreenshotObserver() {
        contentObserver = object : ContentObserver(handler) {
            override fun onChange(selfChange: Boolean, uri: Uri?) {
                if (isPaused.get() || uri == null) return
                val path = resolvePathFromUri(uri) ?: return
                // Filter: only process files in a Screenshots directory
                if (!path.contains("screenshot", ignoreCase = true)) return
                // Notify Flutter
                ScreenshotMethodChannel.onScreenshotDetected(path)
            }
        }
        contentResolver.registerContentObserver(
            MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
            /* notifyForDescendants = */ true,
            contentObserver,
        )
    }

    private fun resolvePathFromUri(uri: Uri): String? {
        return try {
            val projection = arrayOf(MediaStore.Images.Media.DATA)
            contentResolver.query(uri, projection, null, null, null)?.use { cursor ->
                val col = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.DATA)
                if (cursor.moveToFirst()) cursor.getString(col) else null
            }
        } catch (e: Exception) {
            null
        }
    }

    // ─── Notification ─────────────────────────────────────────────────────────

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Pomniter Screenshot Indexer",
                NotificationManager.IMPORTANCE_LOW,   // Silent — no sound/vibration
            ).apply {
                description = "Watches for new screenshots and indexes them locally."
                setShowBadge(false)
            }
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun buildNotification(): Notification {
        val openAppIntent = packageManager.getLaunchIntentForPackage(packageName)
        val contentPendingIntent = PendingIntent.getActivity(
            this, 0, openAppIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val isPausedNow = isPaused.get()
        val toggleAction = if (isPausedNow) {
            val resumeIntent = Intent(this, ScreenshotIndexerService::class.java).apply {
                action = ACTION_RESUME
            }
            val pi = PendingIntent.getService(
                this, 1, resumeIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            NotificationCompat.Action(
                android.R.drawable.ic_media_play, "Resume", pi,
            )
        } else {
            val pauseIntent = Intent(this, ScreenshotIndexerService::class.java).apply {
                action = ACTION_PAUSE
            }
            val pi = PendingIntent.getService(
                this, 2, pauseIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            NotificationCompat.Action(
                android.R.drawable.ic_media_pause, "Pause", pi,
            )
        }

        val count = indexedTodayCount.get()
        val statusText = when {
            isPausedNow -> "Indexing paused"
            count == 0  -> "Watching for new screenshots…"
            else        -> "$count screenshot${if (count == 1) "" else "s"} indexed today"
        }

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_menu_camera)
            .setContentTitle("Pomniter")
            .setContentText(statusText)
            .setSubText(if (isPausedNow) "PAUSED" else "ACTIVE")
            .setContentIntent(contentPendingIntent)
            .addAction(toggleAction)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .build()
    }

    /** Called by [ScreenshotMethodChannel] after a successful index. */
    fun incrementIndexedCount() {
        indexedTodayCount.incrementAndGet()
        updateNotification()
    }

    private fun updateNotification() {
        notificationManager.notify(NOTIFICATION_ID, buildNotification())
    }
}
