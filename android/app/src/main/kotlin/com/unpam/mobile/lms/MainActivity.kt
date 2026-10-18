package com.unpam.mobile.lms

import android.os.Build
import android.os.Bundle
import android.view.Display
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableHighRefreshRate()
    }

    override fun onResume() {
        super.onResume()
        enableHighRefreshRate()
    }

    private fun enableHighRefreshRate() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val window = window ?: return
            val display = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                display
            } else {
                @Suppress("DEPRECATION")
                window.windowManager?.defaultDisplay
            } ?: return

            val modes = display.supportedModes
            var bestMode: Display.Mode? = null
            var maxRate = 60f

            for (mode in modes) {
                if (mode.refreshRate > maxRate) {
                    maxRate = mode.refreshRate
                    bestMode = mode
                }
            }

            if (bestMode != null) {
                val params = window.attributes
                params.preferredDisplayModeId = bestMode.modeId
                window.attributes = params
            }
        }
    }
}
