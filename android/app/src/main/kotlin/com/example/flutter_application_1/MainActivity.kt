package com.example.flutter_application_1

import android.app.AppOpsManager
import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.os.Build
import android.os.Process
import android.provider.Settings
import android.text.TextUtils
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Calendar

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.focusblocker/blocking"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "hasAccessibilityPermission" -> {
                        result.success(isAccessibilityServiceEnabled())
                    }
                    "openAccessibilitySettings" -> {
                        openAccessibilitySettings()
                        result.success(true)
                    }
                    "hasUsagePermission" -> {
                        result.success(hasUsageStatsPermission())
                    }
                    "openUsageSettings" -> {
                        val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(intent)
                        result.success(true)
                    }
                    "updateBlockingConfig" -> {
                        val blockedPackages = call.argument<ArrayList<String>>("blockedPackages") ?: arrayListOf()
                        val blockFromMinutes = call.argument<Int>("blockFromMinutes") ?: 1260
                        val blockUntilMinutes = call.argument<Int>("blockUntilMinutes") ?: 420
                        val blockedDays = call.argument<List<Boolean>>("blockedDays")?.toBooleanArray() ?: BooleanArray(7)
                        val active = call.argument<Boolean>("active") ?: false
                        val keywords = call.argument<ArrayList<String>>("keywords") ?: arrayListOf()
                        val blockShorts = call.argument<Boolean>("blockShorts") ?: false
                        val blockReels = call.argument<Boolean>("blockReels") ?: false
                        val blockComments = call.argument<Boolean>("blockComments") ?: false
                        val blockExplore = call.argument<Boolean>("blockExplore") ?: false
                        val grayscale = call.argument<Boolean>("grayscaleEnabled") ?: false
                        val showOverlay = call.argument<Boolean>("showTimeOverlay") ?: false
                        val warningTitle = call.argument<String>("warningTitle") ?: "Stay Focused"
                        val warningMessage = call.argument<String>("warningMessage") ?: "This app is blocked by Vanta."

                        VantaAccessibilityService.updateConfig(
                            packages = blockedPackages,
                            from = blockFromMinutes,
                            until = blockUntilMinutes,
                            days = blockedDays,
                            active = active,
                            keywords = keywords,
                            blockShorts = blockShorts,
                            blockReels = blockReels,
                            blockComments = blockComments,
                            blockExplore = blockExplore,
                            grayscale = grayscale,
                            showOverlay = showOverlay,
                            warnTitle = warningTitle,
                            warnMessage = warningMessage
                        )
                        result.success(true)
                    }
                    "getInstalledApps" -> {
                        result.success(getInstalledAppsList())
                    }
                    "getUsageStats" -> {
                        val daysBack = call.argument<Int>("daysBack") ?: 0
                        result.success(getUsageStatsForDay(daysBack))
                    }
                    "enableAntiUninstall" -> {
                        val intent = Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN)
                        val cn = ComponentName(this, VantaDeviceAdminReceiver::class.java)
                        intent.putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, cn)
                        intent.putExtra(DevicePolicyManager.EXTRA_ADD_EXPLANATION, "Vanta needs admin to prevent uninstall.")
                        startActivity(intent)
                        result.success(true)
                    }
                    "disableAntiUninstall" -> {
                        try {
                            val dpm = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
                            val cn = ComponentName(this, VantaDeviceAdminReceiver::class.java)
                            dpm.removeActiveAdmin(cn)
                        } catch (_: Exception) {}
                        result.success(true)
                    }
                    "setGrayscaleMode" -> {
                        val enabled = call.argument<Boolean>("enabled") ?: false
                        VantaAccessibilityService.grayscaleEnabled = enabled
                        result.success(true)
                    }
                    "setShowTimeOverlay" -> {
                        val show = call.argument<Boolean>("show") ?: false
                        VantaAccessibilityService.showTimeOverlay = show
                        result.success(true)
                    }
                    else -> {
                        result.notImplemented()
                    }
                }
            }
    }

    private fun isAccessibilityServiceEnabled(): Boolean {
        val expectedComponentName = packageName + "/" + VantaAccessibilityService::class.java.canonicalName
        val enabledServicesSetting = Settings.Secure.getString(
            contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ) ?: return false

        val colonSplitter = TextUtils.SimpleStringSplitter(':')
        colonSplitter.setString(enabledServicesSetting)

        while (colonSplitter.hasNext()) {
            val componentName = colonSplitter.next()
            if (componentName.equals(expectedComponentName, ignoreCase = true)) {
                return true
            }
        }
        return false
    }

    private fun hasUsageStatsPermission(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = appOps.checkOpNoThrow(
            AppOpsManager.OPSTR_GET_USAGE_STATS,
            Process.myUid(),
            packageName
        )
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun openAccessibilitySettings() {
        val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        startActivity(intent)
    }

    private fun getInstalledAppsList(): List<Map<String, String>> {
        val pm = packageManager
        val apps = mutableListOf<Map<String, String>>()
        val packages = pm.getInstalledApplications(PackageManager.GET_META_DATA)

        for (appInfo in packages) {
            // Skip system apps without a launcher icon
            if (pm.getLaunchIntentForPackage(appInfo.packageName) == null) continue
            // Skip our own app
            if (appInfo.packageName == packageName) continue

            val name = pm.getApplicationLabel(appInfo).toString()
            apps.add(mapOf(
                "packageName" to appInfo.packageName,
                "appName" to name
            ))
        }
        return apps.sortedBy { it["appName"]?.lowercase() ?: "" }
    }

    private fun getUsageStatsForDay(daysBack: Int): Map<String, Any> {
        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val pm = packageManager

        val cal = Calendar.getInstance()
        cal.add(Calendar.DAY_OF_YEAR, -daysBack)
        cal.set(Calendar.HOUR_OF_DAY, 0)
        cal.set(Calendar.MINUTE, 0)
        cal.set(Calendar.SECOND, 0)
        cal.set(Calendar.MILLISECOND, 0)
        val startTime = cal.timeInMillis

        cal.add(Calendar.DAY_OF_YEAR, 1)
        val endTime = cal.timeInMillis

        val stats = usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY, startTime, endTime
        )

        val appsList = mutableListOf<Map<String, Any>>()

        if (stats != null) {
            for (stat in stats) {
                val totalMinutes = (stat.totalTimeInForeground / 60000).toInt()
                if (totalMinutes <= 0) continue

                val appName = try {
                    pm.getApplicationLabel(
                        pm.getApplicationInfo(stat.packageName, 0)
                    ).toString()
                } catch (_: Exception) {
                    stat.packageName
                }

                appsList.add(mapOf(
                    "packageName" to stat.packageName,
                    "appName" to appName,
                    "usageMinutes" to totalMinutes,
                    "openCount" to 0
                ))
            }
        }

        return mapOf("apps" to appsList)
    }
}
