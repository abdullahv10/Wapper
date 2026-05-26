package com.example.wappar

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import android.os.Build
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.wapper.app/wallpaper"
    private var methodChannel: MethodChannel? = null
    private var wallpaperReceiver: BroadcastReceiver? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)

        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                // Starts or Refreshes the Foreground Service (Both Timer & Screen Awake)
                "startService", "refreshService" -> {
                    val intent = Intent(this, WallpaperService::class.java)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        startForegroundService(intent)
                    } else {
                        startService(intent)
                    }
                    result.success(null)
                }
                // Stops the Foreground Service entirely
                "stopService" -> {
                    stopService(Intent(this, WallpaperService::class.java))
                    result.success(null)
                }
                // Instantly changes the wallpaper (Skip Button)
                "triggerNow" -> {
                    WallpaperService.triggerNextWallpaper(applicationContext)
                    result.success(null)
                }
                // Applies a specific wallpaper path
                "setWallpaper" -> {
                    val filePath = call.argument<String>("filePath")
                    if (filePath != null) {
                        WallpaperService.applyWallpaper(applicationContext, filePath)
                    }
                    result.success(null)
                }
                // Applies whatever path is saved as pending in SharedPreferences
                "applyPending" -> {
                    val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                    val pendingPath = prefs.getString("flutter.pending_wallpaper_path", null)
                    if (pendingPath != null) {
                        WallpaperService.applyWallpaper(applicationContext, pendingPath)
                    }
                    result.success(null)
                }
                // Opens the manufacturer-specific Auto-Start settings page
                "openAutoStartSettings" -> {
                    try {
                        val intent = Intent()
                        val manufacturer = android.os.Build.MANUFACTURER
                        
                        if ("xiaomi".equals(manufacturer, ignoreCase = true)) {
                            intent.component = android.content.ComponentName("com.miui.securitycenter", "com.miui.permcenter.autostart.AutoStartManagementActivity")
                        } else if ("oppo".equals(manufacturer, ignoreCase = true)) {
                            intent.component = android.content.ComponentName("com.coloros.safecenter", "com.coloros.safecenter.permission.startup.StartupAppListActivity")
                        } else if ("vivo".equals(manufacturer, ignoreCase = true)) {
                            intent.component = android.content.ComponentName("com.vivo.permissionmanager", "com.customizedit.permissions.permissionmanager.ui.WhiteListManagerActivity")
                        } else if ("letv".equals(manufacturer, ignoreCase = true)) {
                            intent.component = android.content.ComponentName("com.letv.android.letvsafe", "com.letv.android.letvsafe.AutobootManageActivity")
                        } else if ("honor".equals(manufacturer, ignoreCase = true)) {
                            intent.component = android.content.ComponentName("com.huawei.systemmanager", "com.huawei.systemmanager.optimize.process.ProtectActivity")
                        } else {
                            intent.action = android.provider.Settings.ACTION_APPLICATION_DETAILS_SETTINGS
                            intent.data = android.net.Uri.parse("package:$packageName")
                        }
                        
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(intent)
                        result.success(true)
                        
                    } catch (e: Exception) {
                        val fallbackIntent = Intent(android.provider.Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                        fallbackIntent.data = android.net.Uri.parse("package:$packageName")
                        fallbackIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(fallbackIntent)
                        result.success(false)
                    }
                }
                else -> result.notImplemented()
            }
        }

        // Listens for background updates from Kotlin and forwards them to Dart UI
        wallpaperReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                val filePath = intent.getStringExtra("filePath")
                if (filePath != null) {
                    methodChannel?.invokeMethod("onWallpaperChanged", filePath)
                }
            }
        }
        
        val filter = IntentFilter("com.example.wappar.WALLPAPER_CHANGED")
        ContextCompat.registerReceiver(this, wallpaperReceiver, filter, ContextCompat.RECEIVER_NOT_EXPORTED)
    }

    // Tracks battery level to support the "Pause on Low Battery" feature
    override fun onResume() {
        super.onResume()
        val batteryStatus: Intent? = IntentFilter(Intent.ACTION_BATTERY_CHANGED).let { ifilter ->
            applicationContext.registerReceiver(null, ifilter)
        }
        val level: Int = batteryStatus?.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) ?: -1
        val scale: Int = batteryStatus?.getIntExtra(BatteryManager.EXTRA_SCALE, -1) ?: -1
        val batteryPct = (level * 100 / scale.toFloat()).toLong()

        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        prefs.edit().putLong("flutter.current_battery_level", batteryPct).apply()
    }

    override fun onDestroy() {
        super.onDestroy()
        wallpaperReceiver?.let { unregisterReceiver(it) }
    }
}