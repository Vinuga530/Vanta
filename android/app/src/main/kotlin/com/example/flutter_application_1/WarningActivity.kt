package com.example.flutter_application_1

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.Gravity
import android.view.View
import android.widget.LinearLayout
import android.widget.TextView

class WarningActivity : Activity() {
    private val handler = Handler(Looper.getMainLooper())

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val title = intent.getStringExtra("title") ?: "Stay Focused"
        val message = intent.getStringExtra("message") ?: "This app is blocked by Vanta."

        val layout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setBackgroundColor(0xFF000000.toInt())
            setPadding(48, 48, 48, 48)
        }

        // Shield emoji
        val shield = TextView(this).apply {
            text = "\uD83D\uDEE1\uFE0F"
            textSize = 64f
            gravity = Gravity.CENTER
        }

        // Title
        val titleView = TextView(this).apply {
            text = title
            textSize = 28f
            setTextColor(0xFFFFFFFF.toInt())
            gravity = Gravity.CENTER
            setPadding(0, 32, 0, 16)
            typeface = android.graphics.Typeface.DEFAULT_BOLD
        }

        // Message
        val messageView = TextView(this).apply {
            text = message
            textSize = 16f
            setTextColor(0xAAFFFFFF.toInt())
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, 48)
        }

        // App name
        val appLabel = TextView(this).apply {
            text = "Vanta"
            textSize = 13f
            setTextColor(0x66FFFFFF.toInt())
            gravity = Gravity.CENTER
            setPadding(0, 48, 0, 0)
        }

        // Countdown
        val countdown = TextView(this).apply {
            text = "Returning home in 5s..."
            textSize = 14f
            setTextColor(0x88FFFFFF.toInt())
            gravity = Gravity.CENTER
            setPadding(0, 16, 0, 0)
        }

        layout.addView(shield)
        layout.addView(titleView)
        layout.addView(messageView)
        layout.addView(countdown)
        layout.addView(appLabel)

        setContentView(layout)

        // Auto-dismiss countdown
        var secondsLeft = 5
        val countdownRunnable = object : Runnable {
            override fun run() {
                secondsLeft--
                if (secondsLeft > 0) {
                    countdown.text = "Returning home in ${secondsLeft}s..."
                    handler.postDelayed(this, 1000)
                } else {
                    goHome()
                }
            }
        }
        handler.postDelayed(countdownRunnable, 1000)
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
