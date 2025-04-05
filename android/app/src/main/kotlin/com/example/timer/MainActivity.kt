package com.example.timer

import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.os.SystemClock

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.timer/stopwatch"
    
    private var startTime: Long = 0
    private var pauseTime: Long = 0
    private var isRunning: Boolean = false
    private var accumulatedTime: Long = 0

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            when (call.method) {
                "startStopwatch" -> {
                    startStopwatch()
                    result.success(null)
                }
                "stopStopwatch" -> {
                    stopStopwatch()
                    result.success(null)
                }
                "resetStopwatch" -> {
                    resetStopwatch()
                    result.success(null)
                }
                "getElapsedTime" -> {
                    result.success(getElapsedTime())
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun startStopwatch() {
        if (!isRunning) {
            startTime = SystemClock.elapsedRealtime()
            isRunning = true
        }
    }

    private fun stopStopwatch() {
        if (isRunning) {
            pauseTime = SystemClock.elapsedRealtime()
            accumulatedTime += pauseTime - startTime
            isRunning = false
        }
    }

    private fun resetStopwatch() {
        startTime = 0
        pauseTime = 0
        accumulatedTime = 0
        isRunning = false
    }

    private fun getElapsedTime(): Int {
        return if (isRunning) {
            val currentTime = SystemClock.elapsedRealtime()
            (accumulatedTime + (currentTime - startTime)).toInt()
        } else {
            accumulatedTime.toInt()
        }
    }
}