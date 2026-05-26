package com.example.wappar

import android.content.Context
import android.util.Log
import androidx.work.Worker
import androidx.work.WorkerParameters

class WallpaperWorker(context: Context, params: WorkerParameters) : Worker(context, params) {
    override fun doWork(): Result {
        Log.d("WallpaperWorker", "🚀 Native WorkManager woke up! Triggering wallpaper change.")
        
        try {
            // Call your existing service directly. No MethodChannels needed!
            WallpaperService.triggerNextWallpaper(applicationContext)
            return Result.success()
        } catch (e: Exception) {
            Log.e("WallpaperWorker", "🛑 Error in background worker: ${e.message}")
            return Result.failure()
        }
    }
}