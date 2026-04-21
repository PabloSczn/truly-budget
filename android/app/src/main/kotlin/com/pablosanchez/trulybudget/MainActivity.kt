package com.pablosanchez.trulybudget

import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        configureAndroid15EdgeToEdge()
    }

    override fun onPostResume() {
        super.onPostResume()
        configureAndroid15EdgeToEdge()
    }

    private fun configureAndroid15EdgeToEdge() {
        if (Build.VERSION.SDK_INT < 35) return

        window.setDecorFitsSystemWindows(false)

        val attributes = window.attributes
        attributes.layoutInDisplayCutoutMode =
            WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_ALWAYS
        window.attributes = attributes
    }
}
