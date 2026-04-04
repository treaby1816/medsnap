package com.vailmeds.v2

import android.os.Bundle
import android.util.Log
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity: FlutterActivity() {
    private val TAG = "VailMedsBoot"
    private var nativeOnCreateTime: Long = 0

    override fun onCreate(savedInstanceState: Bundle?) {
        nativeOnCreateTime = System.currentTimeMillis()
        Log.d(TAG, "--------------------------------------------------")
        Log.d(TAG, "[$nativeOnCreateTime] BOOT: Native onCreate() triggered")
        
        // INSPECT THE URL/INTENT
        val data = intent?.data
        if (data != null) {
            Log.d(TAG, "[$nativeOnCreateTime] URL DETECTED: Incoming URL: $data")
        } else {
            Log.d(TAG, "[$nativeOnCreateTime] INTENT: No incoming URL data detected.")
        }
        
        super.onCreate(savedInstanceState)
    }

    override fun onStart() {
        super.onStart()
        Log.d(TAG, "[${System.currentTimeMillis()}] STATE: onStart() - App visible")
    }

    override fun onResume() {
        super.onResume()
        Log.d(TAG, "[${System.currentTimeMillis()}] STATE: onResume() - UI Thread Active")
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        val flutterEngineTime = System.currentTimeMillis()
        val diff = flutterEngineTime - nativeOnCreateTime
        Log.d(TAG, "[$flutterEngineTime] ENGINE: Flutter Engine transitioning... (Time since onCreate: ${diff}ms)")
        
        super.configureFlutterEngine(flutterEngine)
        Log.d(TAG, "[$flutterEngineTime] ENGINE: Handshake Complete. Returning control to Dart Isolate.")
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        Log.d(TAG, "[${System.currentTimeMillis()}] INTENT: New Intent Received (Deep Link/URL update)")
        val data = intent.data
        if (data != null) {
            Log.w(TAG, "NEW URL TRIGGERED: $data")
        }
    }
}