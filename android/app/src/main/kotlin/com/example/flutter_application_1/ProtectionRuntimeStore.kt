package com.example.flutter_application_1

import android.content.Context
import androidx.preference.PreferenceManager
import kotlin.math.ceil

object ProtectionRuntimeStore {
    private const val FOCUS_ACTIVE_KEY = "focusActive"
    private const val FOCUS_SESSION_START_KEY = "focusSessionStartMillis"
    private const val FOCUS_SESSION_END_KEY = "focusSessionEndMillis"
    private const val SESSION_GRAYSCALE_KEY = "sessionGrayscaleEnabled"
    private const val SESSION_OVERLAY_KEY = "sessionOverlayEnabled"
    private const val SMART_UNLOCK_END_KEY = "smartUnlockEndMillis"

    private fun prefs(context: Context) =
        PreferenceManager.getDefaultSharedPreferences(context.applicationContext)

    fun setFocusActive(context: Context, active: Boolean) {
        prefs(context).edit().putBoolean(FOCUS_ACTIVE_KEY, active).apply()
    }

    fun getFocusActive(context: Context): Boolean {
        return prefs(context).getBoolean(FOCUS_ACTIVE_KEY, false)
    }

    fun setFocusSessionStartMillis(context: Context, value: Long) {
        prefs(context).edit().putLong(FOCUS_SESSION_START_KEY, value).apply()
    }

    fun getFocusSessionStartMillis(context: Context): Long {
        return prefs(context).getLong(FOCUS_SESSION_START_KEY, 0L)
    }

    fun setFocusSessionEndMillis(context: Context, value: Long) {
        prefs(context).edit().putLong(FOCUS_SESSION_END_KEY, value).apply()
    }

    fun getFocusSessionEndMillis(context: Context): Long {
        return prefs(context).getLong(FOCUS_SESSION_END_KEY, 0L)
    }

    fun setSessionGrayscaleEnabled(context: Context, enabled: Boolean) {
        prefs(context).edit().putBoolean(SESSION_GRAYSCALE_KEY, enabled).apply()
    }

    fun getSessionGrayscaleEnabled(context: Context): Boolean {
        return prefs(context).getBoolean(SESSION_GRAYSCALE_KEY, false)
    }

    fun setSessionOverlayEnabled(context: Context, enabled: Boolean) {
        prefs(context).edit().putBoolean(SESSION_OVERLAY_KEY, enabled).apply()
    }

    fun getSessionOverlayEnabled(context: Context): Boolean {
        return prefs(context).getBoolean(SESSION_OVERLAY_KEY, false)
    }

    fun setSmartUnlockEndMillis(context: Context, value: Long) {
        prefs(context).edit().putLong(SMART_UNLOCK_END_KEY, value).apply()
    }

    fun clearSmartUnlock(context: Context) {
        prefs(context).edit().remove(SMART_UNLOCK_END_KEY).apply()
    }

    fun getSmartUnlockEndMillis(context: Context): Long {
        return prefs(context).getLong(SMART_UNLOCK_END_KEY, 0L)
    }

    fun isSmartUnlockActive(context: Context): Boolean {
        val end = getSmartUnlockEndMillis(context)
        return end > System.currentTimeMillis()
    }

    fun getRemainingSmartUnlockSeconds(context: Context): Int {
        val remaining = getSmartUnlockEndMillis(context) - System.currentTimeMillis()
        if (remaining <= 0) return 0
        return ceil(remaining / 1000.0).toInt()
    }

    fun getRemainingFocusSeconds(context: Context): Int {
        val remaining = getFocusSessionEndMillis(context) - System.currentTimeMillis()
        if (remaining <= 0) return 0
        return ceil(remaining / 1000.0).toInt()
    }

    fun isFocusSessionExpired(context: Context): Boolean {
        val end = getFocusSessionEndMillis(context)
        return getFocusActive(context) && end > 0L && end <= System.currentTimeMillis()
    }

    fun extendFocusSession(context: Context, minutes: Int): Long {
        val now = System.currentTimeMillis()
        val base = maxOf(getFocusSessionEndMillis(context), now)
        val nextEnd = base + minutes * 60_000L
        setFocusSessionEndMillis(context, nextEnd)
        setFocusActive(context, true)
        return nextEnd
    }

    fun startSmartUnlock(context: Context, minutes: Int): Long {
        val end = System.currentTimeMillis() + minutes * 60_000L
        setSmartUnlockEndMillis(context, end)
        return end
    }

    fun clearFocusSessionState(context: Context) {
        prefs(context).edit()
            .putBoolean(FOCUS_ACTIVE_KEY, false)
            .remove(FOCUS_SESSION_START_KEY)
            .remove(FOCUS_SESSION_END_KEY)
            .remove(SESSION_GRAYSCALE_KEY)
            .remove(SESSION_OVERLAY_KEY)
            .remove(SMART_UNLOCK_END_KEY)
            .apply()
    }
}
