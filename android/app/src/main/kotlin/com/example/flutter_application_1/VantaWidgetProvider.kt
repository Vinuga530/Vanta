package com.example.flutter_application_1

import android.app.usage.UsageStatsManager
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import java.util.Calendar

class VantaWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, appWidgetId)
        }
    }

    private fun updateWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
        val views = RemoteViews(context.packageName, R.layout.widget_layout)

        // Get today's screen time
        val totalMinutes = getTodayScreenTime(context)
        val hours = totalMinutes / 60
        val mins = totalMinutes % 60
        val timeStr = if (hours > 0) "${hours}h ${mins}m" else "${mins}m"

        views.setTextViewText(R.id.widget_time, timeStr)
        views.setTextViewText(R.id.widget_label, "Screen Time Today")

        // Get blocked count
        val blockedCount = VantaAccessibilityService.blockedPackages.size
        views.setTextViewText(R.id.widget_blocked, "$blockedCount apps blocked")

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    private fun getTodayScreenTime(context: Context): Int {
        return try {
            val usm = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
            val cal = Calendar.getInstance()
            cal.set(Calendar.HOUR_OF_DAY, 0)
            cal.set(Calendar.MINUTE, 0)
            cal.set(Calendar.SECOND, 0)
            val startTime = cal.timeInMillis
            val endTime = System.currentTimeMillis()

            val stats = usm.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, startTime, endTime)
            var totalMs: Long = 0
            stats?.forEach { totalMs += it.totalTimeInForeground }
            (totalMs / 60000).toInt()
        } catch (e: Exception) {
            0
        }
    }
}
