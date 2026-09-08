package com.sobha.chequetracker

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Blocks screenshots and hides sensitive content from the recent-apps
        // thumbnail — the app handles Emirates ID scans, cheque images, and
        // cheque amounts throughout its screens. Skipped in debug builds so
        // the team can still take screenshots while developing/testing.
        // See the security audit's F-6.
        if (!BuildConfig.DEBUG) {
            window.setFlags(
                WindowManager.LayoutParams.FLAG_SECURE,
                WindowManager.LayoutParams.FLAG_SECURE,
            )
        }
    }
}
