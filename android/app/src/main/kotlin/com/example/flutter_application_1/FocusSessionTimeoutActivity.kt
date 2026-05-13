package com.example.flutter_application_1

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.Gravity
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView

class FocusSessionTimeoutActivity : Activity() {
    private val handler = Handler(Looper.getMainLooper())
    private var secondsLeft = 30

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val layout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setBackgroundColor(0xFF000000.toInt())
            setPadding(48, 48, 48, 48)
        }

        val title = TextView(this).apply {
            text = "Focus session complete"
            textSize = 28f
            setTextColor(0xFFFFFFFF.toInt())
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, 16)
            typeface = android.graphics.Typeface.DEFAULT_BOLD
        }

        val message = TextView(this).apply {
            text = "Extend by 10 minutes or end Focus Mode."
            textSize = 16f
            setTextColor(0xAAFFFFFF.toInt())
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, 40)
        }

        val countdown = TextView(this).apply {
            text = "Auto-ending in 30s..."
            textSize = 14f
            setTextColor(0x88FFFFFF.toInt())
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, 32)
        }

        val extendButton = Button(this).apply {
            text = "Extend 10 minutes"
            setOnClickListener {
                ProtectionRuntimeStore.extendFocusSession(this@FocusSessionTimeoutActivity, 10)
                VantaAccessibilityService.reloadRuntimeState(this@FocusSessionTimeoutActivity)
                finish()
            }
        }

        val endButton = Button(this).apply {
            text = "End Focus"
            setOnClickListener {
                ProtectionRuntimeStore.clearFocusSessionState(this@FocusSessionTimeoutActivity)
                VantaAccessibilityService.reloadRuntimeState(this@FocusSessionTimeoutActivity)
                goHome()
            }
        }

        layout.addView(title)
        layout.addView(message)
        layout.addView(countdown)
        layout.addView(extendButton)
        layout.addView(endButton)

        setContentView(layout)

        val runnable = object : Runnable {
            override fun run() {
                secondsLeft--
                if (secondsLeft > 0) {
                    countdown.text = "Auto-ending in ${secondsLeft}s..."
                    handler.postDelayed(this, 1000)
                } else {
                    ProtectionRuntimeStore.clearFocusSessionState(this@FocusSessionTimeoutActivity)
                    VantaAccessibilityService.reloadRuntimeState(this@FocusSessionTimeoutActivity)
                    goHome()
                }
            }
        }
        handler.postDelayed(runnable, 1000)
    }

    override fun onBackPressed() {
        goHome()
    }

    private fun goHome() {
        val intent = Intent(Intent.ACTION_MAIN).apply {
            addCategory(Intent.CATEGORY_HOME)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        startActivity(intent)
        finish()
    }
}
