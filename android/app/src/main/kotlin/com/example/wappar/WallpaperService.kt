package com.example.wappar

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.app.WallpaperManager
import android.content.BroadcastReceiver
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.database.sqlite.SQLiteDatabase
import android.graphics.BitmapFactory
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale

class WallpaperService : Service() {

    private val CHANNEL_ID = "WapperServiceChannel"
    private var screenOffReceiver: BroadcastReceiver? = null
    private var timerJob: Job? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()

        val pendingIntent = PendingIntent.getActivity(
            this, 0,
            packageManager.getLaunchIntentForPackage(packageName),
            PendingIntent.FLAG_IMMUTABLE
        )

        val notification: Notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Wappar Automation Active")
            .setContentText("Managing your wallpapers seamlessly in the background")
            .setSmallIcon(android.R.drawable.ic_menu_gallery)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setSilent(true)
            .setPriority(NotificationCompat.PRIORITY_MIN)
            .build()

        startForeground(1, notification)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d("WallpaperService", "🚀 Service Started / Refreshed")
        refreshAutomationState()
        return START_STICKY
    }

    private fun refreshAutomationState() {
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val isTimerMode = prefs.getBoolean("flutter.mode_is_time_interval", true)
        
        if (isTimerMode) {
            unregisterScreenOffReceiver()
            startTimerLoop(prefs)
        } else {
            stopTimerLoop()
            registerScreenOffReceiver()
        }
    }

    private fun startTimerLoop(prefs: android.content.SharedPreferences) {
        timerJob?.cancel()
        
        val intervalString = prefs.getString("flutter.automation_interval", "30 minutes") ?: "30 minutes"
        val minutes = when {
            intervalString.contains("15") -> 15L
            intervalString.contains("30") -> 30L
            intervalString.contains("1") -> 60L
            intervalString.contains("2") -> 120L
            intervalString.contains("4") -> 240L
            intervalString.contains("8") -> 480L
            else -> 30L
        }
        
        Log.d("WallpaperService", "✅ Starting Native Timer Loop for $minutes minutes")
        
        timerJob = CoroutineScope(Dispatchers.IO).launch {
            while(isActive) {
                delay(minutes * 60 * 1000L) 
                Log.d("WallpaperService", "⏰ Timer tick! Changing wallpaper.")
                triggerNextWallpaper(applicationContext)
            }
        }
    }

    private fun stopTimerLoop() {
        timerJob?.cancel()
        timerJob = null
    }

    private fun registerScreenOffReceiver() {
        if (screenOffReceiver == null) {
            screenOffReceiver = object : BroadcastReceiver() {
                override fun onReceive(context: Context, intent: Intent) {
                    if (intent.action == Intent.ACTION_SCREEN_OFF) {
                        Log.d("WallpaperService", "🚀 Screen OFF detected")
                        triggerNextWallpaper(context)
                    }
                }
            }
            val filter = IntentFilter(Intent.ACTION_SCREEN_OFF)
            registerReceiver(screenOffReceiver, filter)
            Log.d("WallpaperService", "✅ Screen-off receiver registered")
        }
    }

    private fun unregisterScreenOffReceiver() {
        screenOffReceiver?.let {
            try { unregisterReceiver(it) } catch (e: Exception) {}
            screenOffReceiver = null
            Log.d("WallpaperService", "🛑 Screen-off receiver unregistered")
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        unregisterScreenOffReceiver()
        stopTimerLoop()
        Log.d("WallpaperService", "🛑 WallpaperService destroyed")
    }

    override fun onBind(intent: Intent?): IBinder? = null

    // 🚀 RESTORED: The missing function!
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Wapper Automation Service",
                NotificationManager.IMPORTANCE_MIN
            ).apply {
                setShowBadge(false)
                description = "Keeps wallpaper automation running"
            }
            getSystemService(NotificationManager::class.java)?.createNotificationChannel(channel)
        }
    }

    companion object {
        private const val TAG = "WallpaperService"

        fun triggerNextWallpaper(context: Context) {
            CoroutineScope(Dispatchers.IO).launch {
                Log.d(TAG, "🚀 triggerNextWallpaper() called")

                val prefs = context.getSharedPreferences(
                    "FlutterSharedPreferences", Context.MODE_PRIVATE
                )

                val pauseOnLowBattery = prefs.getBoolean("pause_on_low_battery", false)
                val batteryLevel = prefs.getLong("current_battery_level", 100)
                if (pauseOnLowBattery && batteryLevel < 20) {
                    Log.d(TAG, "👀 Low battery ($batteryLevel%). Skipping.")
                    return@launch
                }

                val dbPath = context.getDatabasePath("wapper.db").absolutePath
                val db: SQLiteDatabase
                try {
                    db = SQLiteDatabase.openDatabase(dbPath, null, SQLiteDatabase.OPEN_READWRITE)
                } catch (e: Exception) {
                    Log.e(TAG, "🛑 Could not open DB: ${e.message}")
                    return@launch
                }

                try {
                    val isScheduleEnabled = prefs.getBoolean("is_schedule_enabled", false)
                    val isShuffleMode = prefs.getBoolean("is_shuffle_mode", false)

                    var targetCollectionId: String? = null
                    if (isScheduleEnabled) {
                        targetCollectionId = getActiveScheduleCollection(db)
                    }
                    if (targetCollectionId == null) {
                        targetCollectionId = getNextSequentialCollection(db, prefs)
                    }

                    if (targetCollectionId == null) return@launch

                    val nextImagePath = getNextImage(db, prefs, targetCollectionId, isShuffleMode)

                    if (nextImagePath == null) return@launch

                    Log.d(TAG, "✅ Next wallpaper: $nextImagePath")
                    applyWallpaper(context, nextImagePath)

                    val cv = ContentValues().apply {
                        put("key", "last_wallpaper")
                        put("value", nextImagePath)
                    }
                    db.insertWithOnConflict("app_settings", null, cv, SQLiteDatabase.CONFLICT_REPLACE)

                    val broadcastIntent = Intent("com.example.wappar.WALLPAPER_CHANGED").apply {
                        putExtra("filePath", nextImagePath)
                        setPackage(context.packageName)
                    }
                    context.sendBroadcast(broadcastIntent)

                } catch (e: Exception) {
                    Log.e(TAG, "🛑 ERROR in triggerNextWallpaper: ${e.message}")
                } finally {
                    db.close()
                }
            }
        }

        private fun getActiveScheduleCollection(db: SQLiteDatabase): String? {
            val cursor = db.rawQuery("SELECT collectionId, timeRange FROM schedules", null)
            val now = Calendar.getInstance()
            val nowMinutes = (now.get(Calendar.HOUR_OF_DAY) * 60) + now.get(Calendar.MINUTE)
            val sdf = SimpleDateFormat("hh:mm a", Locale.US)

            cursor.use {
                while (it.moveToNext()) {
                    val cId = it.getString(0)
                    val timeRange = it.getString(1)
                    try {
                        val times = timeRange.split(" - ")
                        if (times.size != 2) continue

                        val startDate = sdf.parse(times[0].trim()) ?: continue
                        val endDate   = sdf.parse(times[1].trim()) ?: continue

                        val startCal = Calendar.getInstance().apply { time = startDate }
                        val endCal   = Calendar.getInstance().apply { time = endDate }

                        val startMins = (startCal.get(Calendar.HOUR_OF_DAY) * 60) + startCal.get(Calendar.MINUTE)
                        val endMins   = (endCal.get(Calendar.HOUR_OF_DAY) * 60) + endCal.get(Calendar.MINUTE)

                        val matches = if (endMins <= startMins) {
                            nowMinutes >= startMins || nowMinutes < endMins
                        } else {
                            nowMinutes >= startMins && nowMinutes < endMins
                        }

                        if (matches) return cId
                    } catch (e: Exception) {}
                }
            }
            return null
        }

        private fun getNextSequentialCollection(db: SQLiteDatabase, prefs: android.content.SharedPreferences): String? {
            val collections = mutableListOf<String>()
            db.rawQuery("SELECT id FROM collections WHERE active = 1 ORDER BY rowid", null).use {
                while (it.moveToNext()) collections.add(it.getString(0))
            }
            if (collections.isEmpty()) return null

            var colIndex = prefs.getLong("current_collection_index", 0).toInt()
            if (colIndex >= collections.size) {
                colIndex = 0
                prefs.edit().putLong("current_collection_index", 0L).putLong("current_image_index", 0L).apply()
            }
            return collections[colIndex]
        }

        private fun getNextImage(db: SQLiteDatabase, prefs: android.content.SharedPreferences, collectionId: String, shuffle: Boolean): String? {
            val paths = mutableListOf<String>()
            db.rawQuery("SELECT filePath FROM wallpapers WHERE collectionId = ? ORDER BY rowid", arrayOf(collectionId)).use {
                while (it.moveToNext()) paths.add(it.getString(0))
            }
            if (paths.isEmpty()) return null

            val editor = prefs.edit()

            return if (shuffle) {
                paths.random()
            } else {
                var imgIndex = prefs.getLong("current_image_index", 0).toInt()
                if (imgIndex >= paths.size) imgIndex = 0

                val path = paths[imgIndex]
                val nextImgIndex = imgIndex + 1

                if (nextImgIndex >= paths.size) {
                    val collections = mutableListOf<String>()
                    db.rawQuery("SELECT id FROM collections WHERE active = 1 ORDER BY rowid", null).use { c ->
                        while (c.moveToNext()) collections.add(c.getString(0))
                    }
                    val colIndex = prefs.getLong("current_collection_index", 0).toInt()
                    val nextColIndex = if (collections.isEmpty()) 0 else (colIndex + 1) % collections.size

                    editor.putLong("current_collection_index", nextColIndex.toLong())
                    editor.putLong("current_image_index", 0L)
                } else {
                    editor.putLong("current_image_index", nextImgIndex.toLong())
                }

                editor.apply()
                path
            }
        }

        fun applyWallpaper(context: Context, filePath: String) {
            try {
                val originalBitmap = BitmapFactory.decodeFile(filePath) ?: throw Exception("BitmapFactory returned null")
                
                // 1. Get the TRUE hardware screen dimensions (including status/nav bars)
                val windowManager = context.getSystemService(Context.WINDOW_SERVICE) as android.view.WindowManager
                val metrics = android.util.DisplayMetrics()
                windowManager.defaultDisplay.getRealMetrics(metrics)
                
                val screenWidth = metrics.widthPixels
                val screenHeight = metrics.heightPixels

                // 2. Center-Crop Math (Mimics BoxFit.cover exactly)
                val bitmapRatio = originalBitmap.width.toFloat() / originalBitmap.height.toFloat()
                val screenRatio = screenWidth.toFloat() / screenHeight.toFloat()

                val finalBitmap: android.graphics.Bitmap
                
                if (bitmapRatio > screenRatio) {
                    // Image is wider: scale height to fit screen, crop sides
                    val newWidth = (screenHeight * bitmapRatio).toInt()
                    val scaledBitmap = android.graphics.Bitmap.createScaledBitmap(originalBitmap, newWidth, screenHeight, true)
                    val xOffset = (newWidth - screenWidth) / 2
                    finalBitmap = android.graphics.Bitmap.createBitmap(scaledBitmap, xOffset, 0, screenWidth, screenHeight)
                } else {
                    // Image is taller: scale width to fit screen, crop top/bottom
                    val newHeight = (screenWidth / bitmapRatio).toInt()
                    val scaledBitmap = android.graphics.Bitmap.createScaledBitmap(originalBitmap, screenWidth, newHeight, true)
                    val yOffset = (newHeight - screenHeight) / 2
                    finalBitmap = android.graphics.Bitmap.createBitmap(scaledBitmap, 0, yOffset, screenWidth, screenHeight)
                }

                // 3. Apply the perfectly fitted wallpaper
                val wm = WallpaperManager.getInstance(context)
                
                // CRITICAL: Tell the launcher to stop trying to parallax scroll, which stops the aggressive zooming
                wm.setWallpaperOffsetSteps(0f, 0f)
                
                wm.setBitmap(finalBitmap, null, true, WallpaperManager.FLAG_SYSTEM or WallpaperManager.FLAG_LOCK)
                Log.d("WallpaperService", "✅ Center-cropped wallpaper applied ($screenWidth x $screenHeight)")

            } catch (e: Exception) {
                Log.e("WallpaperService", "🛑 applyWallpaper error: ${e.message}")
            }
        }
    }
}