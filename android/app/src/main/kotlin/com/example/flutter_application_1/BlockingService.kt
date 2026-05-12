package com.example.flutter_application_1

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
import java.util.Calendar

class BlockingService : Service() {

    companion object {
        const val TAG = "BlockingService"
        const val CHANNEL_ID = "focus_blocker_channel"
        const val NOTIFICATION_ID = 1
    }

    private val handler = Handler(Looper.getMainLooper())
    private var blockedPackages = listOf<String>()
    private var blockFromMinutes = 0
    private var blockUntilMinutes = 0
    private var blockedDays = booleanArrayOf()

    private val checkRunnable = object : Runnable {
        override fun run() {
            checkAndBlock()
            handler.postDelayed(this, 1000) // check every 1 second
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // Read config from intent extras
        blockedPackages = intent?.getStringArrayListExtra("blockedPackages") ?: arrayListOf()
        blockFromMinutes = intent?.getIntExtra("blockFromMinutes", 1260) ?: 1260 // default 21:00
        blockUntilMinutes = intent?.getIntExtra("blockUntilMinutes", 420) ?: 420 // default 07:00
        blockedDays = intent?.getBooleanArrayExtra("blockedDays")
            ?: booleanArrayOf(true, true, true, true, true, false, false)

        Log.d(TAG, "Service started — blocking ${blockedPackages.size} apps")
        Log.d(TAG, "Schedule: $blockFromMinutes → $blockUntilMinutes minutes")
        Log.d(TAG, "Packages: $blockedPackages")

        // Start as foreground service with persistent notification
        startForeground(NOTIFICATION_ID, buildNotification())

        // Start the polling loop
        handler.removeCallbacks(checkRunnable)
        handler.post(checkRunnable)

        return START_STICKY
    }

    override fun onDestroy() {
        handler.removeCallbacks(checkRunnable)
        Log.d(TAG, "Service destroyed")
        super.onDestroy()
    }

    // ─── Core Blocking Logic ─────────────────────────────────────────────────

    private fun checkAndBlock() {
        if (!isWithinBlockedHours()) return
        if (!isTodayBlocked()) return

        val foregroundPkg = getForegroundApp()
        if (foregroundPkg != null && blockedPackages.contains(foregroundPkg)) {
            Log.d(TAG, "BLOCKED: $foregroundPkg → sending to home")
            goToHomeScreen()
        }
    }

    private fun isWithinBlockedHours(): Boolean {
        val now = Calendar.getInstance()
        val currentMinutes = now.get(Calendar.HOUR_OF_DAY) * 60 + now.get(Calendar.MINUTE)

        return if (blockFromMinutes <= blockUntilMinutes) {
            // Same-day range (e.g., 9:00 AM to 5:00 PM)
            currentMinutes in blockFromMinutes until blockUntilMinutes
        } else {
            // Overnight range (e.g., 9:00 PM to 7:00 AM)
            currentMinutes >= blockFromMinutes || currentMinutes < blockUntilMinutes
        }
    }

    private fun isTodayBlocked(): Boolean {
        // Calendar.DAY_OF_WEEK: Sunday=1, Monday=2, ..., Saturday=7
        // blockedDays array: index 0=Mon, 1=Tue, ..., 6=Sun
        val calendarDay = Calendar.getInstance().get(Calendar.DAY_OF_WEEK)
        val dayIndex = when (calendarDay) {
            Calendar.MONDAY -> 0
            Calendar.TUESDAY -> 1
            Calendar.WEDNESDAY -> 2
            Calendar.THURSDAY -> 3
            Calendar.FRIDAY -> 4
            Calendar.SATURDAY -> 5
            Calendar.SUNDAY -> 6
            else -> return false
        }
        return dayIndex < blockedDays.size && blockedDays[dayIndex]
    }

    private fun getForegroundApp(): String? {
        val usageStatsManager =
            getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager

        val endTime = System.currentTimeMillis()
        val beginTime = endTime - 5000

        val usageEvents = usageStatsManager.queryEvents(beginTime, endTime)
        var foregroundPackage: String? = null

        val event = UsageEvents.Event()
        while (usageEvents.hasNextEvent()) {
            usageEvents.getNextEvent(event)
            if (event.eventType == UsageEvents.Event.ACTIVITY_RESUMED) {
                foregroundPackage = event.packageName
            }
        }

        return foregroundPackage
    }

    private fun goToHomeScreen() {
        val intent = Intent(Intent.ACTION_MAIN)
        intent.addCategory(Intent.CATEGORY_HOME)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        startActivity(intent)
    }

    // ─── Notification ────────────────────────────────────────────────────────

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Focus Blocker",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Shows when Focus Blocker is actively protecting you"
                setShowBadge(false)
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    private fun buildNotification(): Notification {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
                .setContentTitle("Focus Mode Active")
                .setContentText("Blocking ${blockedPackages.size} distracting apps")
                .setSmallIcon(android.R.drawable.ic_lock_idle_lock)
                .setOngoing(true)
                .build()
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
                .setContentTitle("Focus Mode Active")
                .setContentText("Blocking ${blockedPackages.size} distracting apps")
                .setSmallIcon(android.R.drawable.ic_lock_idle_lock)
                .setOngoing(true)
                .build()
        }
    }
}
