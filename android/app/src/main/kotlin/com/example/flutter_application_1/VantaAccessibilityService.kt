package com.example.flutter_application_1

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.graphics.PixelFormat
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.Gravity
import android.view.WindowManager
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.widget.TextView
import java.util.Calendar

class VantaAccessibilityService : AccessibilityService() {

    companion object {
        const val TAG = "VantaAccessibility"
        var isRunning = false

        var blockedPackages = mutableListOf<String>()
        var blockFromMinutes = 0
        var blockUntilMinutes = 0
        var blockedDays = BooleanArray(7)
        var isActive = false

        // New Digipaws features
        var keywords = mutableListOf<String>()
        var blockShorts = false
        var blockReels = false
        var blockComments = false
        var blockExplore = false
        var grayscaleEnabled = false
        var showTimeOverlay = false
        var warningTitle = "Stay Focused"
        var warningMessage = "This app is blocked by Vanta."

        fun updateConfig(
            packages: List<String>, from: Int, until: Int, days: BooleanArray, active: Boolean,
            keywords: List<String> = emptyList(),
            blockShorts: Boolean = false, blockReels: Boolean = false,
            blockComments: Boolean = false, blockExplore: Boolean = false,
            grayscale: Boolean = false, showOverlay: Boolean = false,
            warnTitle: String = "Stay Focused", warnMessage: String = "This app is blocked by Vanta."
        ) {
            blockedPackages.clear()
            blockedPackages.addAll(packages)
            blockFromMinutes = from
            blockUntilMinutes = until
            blockedDays = days
            isActive = active

            this.keywords.clear()
            this.keywords.addAll(keywords)
            this.blockShorts = blockShorts
            this.blockReels = blockReels
            this.blockComments = blockComments
            this.blockExplore = blockExplore
            grayscaleEnabled = grayscale
            showTimeOverlay = showOverlay
            warningTitle = warnTitle
            warningMessage = warnMessage

            Log.d(TAG, "Config updated: Active=$isActive, Apps=${blockedPackages.size}, Keywords=${keywords.size}")
        }
    }

    private var overlayView: TextView? = null
    private var windowManager: WindowManager? = null
    private var sessionStartTime: Long = 0
    private var currentBlockedPkg: String? = null
    private val handler = Handler(Looper.getMainLooper())

    override fun onServiceConnected() {
        super.onServiceConnected()
        isRunning = true
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        Log.d(TAG, "Accessibility Service Connected")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (!isActive || event == null) return

        val packageName = event.packageName?.toString() ?: return

        when (event.eventType) {
            AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED -> {
                // App blocking
                if (shouldBlock(packageName)) {
                    Log.d(TAG, "BLOCKED: $packageName")
                    triggerBlockAction(packageName)
                    return
                } else {
                    removeOverlay()
                    currentBlockedPkg = null
                }

                // View blocking (Shorts, Reels, Comments, Explore)
                handleViewBlocking(event, packageName)
            }

            AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED -> {
                // Keyword blocking - check content for keywords
                if (keywords.isNotEmpty()) {
                    handleKeywordBlocking(event)
                }

                // View blocking on content change
                handleViewBlocking(event, packageName)
            }
        }
    }

    override fun onInterrupt() {
        Log.d(TAG, "Accessibility Service Interrupted")
    }

    override fun onDestroy() {
        isRunning = false
        removeOverlay()
        super.onDestroy()
    }

    // ─── App Blocking ────────────────────────────────────────────────────────

    private fun shouldBlock(pkg: String): Boolean {
        if (!blockedPackages.contains(pkg)) return false
        if (!isTodayBlocked()) return false
        return isWithinBlockedHours()
    }

    private fun isWithinBlockedHours(): Boolean {
        val now = Calendar.getInstance()
        val currentMinutes = now.get(Calendar.HOUR_OF_DAY) * 60 + now.get(Calendar.MINUTE)
        return if (blockFromMinutes <= blockUntilMinutes) {
            currentMinutes in blockFromMinutes until blockUntilMinutes
        } else {
            currentMinutes >= blockFromMinutes || currentMinutes < blockUntilMinutes
        }
    }

    private fun isTodayBlocked(): Boolean {
        val calendarDay = Calendar.getInstance().get(Calendar.DAY_OF_WEEK)
        val dayIndex = when (calendarDay) {
            Calendar.MONDAY -> 0; Calendar.TUESDAY -> 1; Calendar.WEDNESDAY -> 2
            Calendar.THURSDAY -> 3; Calendar.FRIDAY -> 4; Calendar.SATURDAY -> 5
            Calendar.SUNDAY -> 6; else -> return false
        }
        return dayIndex < blockedDays.size && blockedDays[dayIndex]
    }

    private fun triggerBlockAction(pkg: String) {
        // Show warning screen instead of just going home
        try {
            val intent = Intent(this, WarningActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                putExtra("title", warningTitle)
                putExtra("message", warningMessage)
                putExtra("blockedApp", pkg)
            }
            startActivity(intent)
        } catch (e: Exception) {
            // Fallback to home
            val homeIntent = Intent(Intent.ACTION_MAIN).apply {
                addCategory(Intent.CATEGORY_HOME)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            startActivity(homeIntent)
        }
    }

    // ─── View Blocking ───────────────────────────────────────────────────────

    private fun handleViewBlocking(event: AccessibilityEvent, pkg: String) {
        val rootNode = rootInActiveWindow ?: return

        try {
            // YouTube Shorts
            if (blockShorts && pkg == "com.google.android.youtube") {
                if (findNodeByText(rootNode, "Shorts") || findNodeById(rootNode, "reel_player_page_container")) {
                    performGlobalAction(GLOBAL_ACTION_BACK)
                    return
                }
            }

            // Instagram Reels
            if (blockReels && pkg == "com.instagram.android") {
                if (findNodeByText(rootNode, "Reels") || findNodeById(rootNode, "clips_tab")) {
                    performGlobalAction(GLOBAL_ACTION_BACK)
                    return
                }
            }

            // Comments
            if (blockComments) {
                if (findNodeById(rootNode, "comment") || findNodeByText(rootNode, "Add a comment") ||
                    findNodeByText(rootNode, "Comments")) {
                    // Try to collapse/dismiss comment section
                    val commentNodes = findAllNodesByText(rootNode, "Comments")
                    for (node in commentNodes) {
                        if (node.isClickable) {
                            node.performAction(AccessibilityNodeInfo.ACTION_CLICK)
                            break
                        }
                    }
                }
            }

            // Explore
            if (blockExplore) {
                if (findNodeByText(rootNode, "Explore") || findNodeById(rootNode, "explore_tab")) {
                    performGlobalAction(GLOBAL_ACTION_BACK)
                    return
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "View blocking error: ${e.message}")
        } finally {
            rootNode.recycle()
        }
    }

    // ─── Keyword Blocking ────────────────────────────────────────────────────

    private fun handleKeywordBlocking(event: AccessibilityEvent) {
        val rootNode = rootInActiveWindow ?: return
        try {
            val allText = collectAllText(rootNode)
            val lowerText = allText.lowercase()

            for (keyword in keywords) {
                if (lowerText.contains(keyword.lowercase())) {
                    Log.d(TAG, "Keyword match: '$keyword' found!")
                    performGlobalAction(GLOBAL_ACTION_BACK)
                    return
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Keyword blocking error: ${e.message}")
        } finally {
            rootNode.recycle()
        }
    }

    // ─── Screen Time Overlay ─────────────────────────────────────────────────

    private fun showTimeOverlayView() {
        if (overlayView != null || !showTimeOverlay) return
        if (windowManager == null) return

        try {
            val tv = TextView(this).apply {
                text = "0:00"
                textSize = 14f
                setTextColor(0xCCFFFFFF.toInt())
                setBackgroundColor(0x66000000)
                setPadding(16, 8, 16, 8)
            }

            val params = WindowManager.LayoutParams(
                WindowManager.LayoutParams.WRAP_CONTENT,
                WindowManager.LayoutParams.WRAP_CONTENT,
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                    WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY
                else
                    WindowManager.LayoutParams.TYPE_SYSTEM_OVERLAY,
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE,
                PixelFormat.TRANSLUCENT
            ).apply {
                gravity = Gravity.TOP or Gravity.CENTER_HORIZONTAL
                y = 100
            }

            windowManager?.addView(tv, params)
            overlayView = tv
            sessionStartTime = System.currentTimeMillis()
            updateOverlayTimer()
        } catch (e: Exception) {
            Log.e(TAG, "Failed to show overlay: ${e.message}")
        }
    }

    private fun updateOverlayTimer() {
        handler.postDelayed(object : Runnable {
            override fun run() {
                overlayView?.let {
                    val elapsed = (System.currentTimeMillis() - sessionStartTime) / 1000
                    val mins = elapsed / 60
                    val secs = elapsed % 60
                    it.text = "$mins:${secs.toString().padStart(2, '0')}"
                    handler.postDelayed(this, 1000)
                }
            }
        }, 1000)
    }

    private fun removeOverlay() {
        overlayView?.let {
            try { windowManager?.removeView(it) } catch (_: Exception) {}
            overlayView = null
        }
    }

    // ─── Node Helpers ────────────────────────────────────────────────────────

    private fun findNodeByText(root: AccessibilityNodeInfo, text: String): Boolean {
        val nodes = root.findAccessibilityNodeInfosByText(text)
        val found = nodes.isNotEmpty()
        nodes.forEach { it.recycle() }
        return found
    }

    private fun findNodeById(root: AccessibilityNodeInfo, partialId: String): Boolean {
        return traverseForId(root, partialId)
    }

    private fun traverseForId(node: AccessibilityNodeInfo, partialId: String): Boolean {
        val viewId = node.viewIdResourceName
        if (viewId != null && viewId.contains(partialId)) return true
        for (i in 0 until node.childCount) {
            val child = node.getChild(i) ?: continue
            if (traverseForId(child, partialId)) {
                child.recycle()
                return true
            }
            child.recycle()
        }
        return false
    }

    private fun findAllNodesByText(root: AccessibilityNodeInfo, text: String): List<AccessibilityNodeInfo> {
        return root.findAccessibilityNodeInfosByText(text)
    }

    private fun collectAllText(node: AccessibilityNodeInfo): String {
        val sb = StringBuilder()
        if (node.text != null) sb.append(node.text).append(" ")
        if (node.contentDescription != null) sb.append(node.contentDescription).append(" ")
        for (i in 0 until node.childCount) {
            val child = node.getChild(i) ?: continue
            sb.append(collectAllText(child))
            child.recycle()
        }
        return sb.toString()
    }
}
