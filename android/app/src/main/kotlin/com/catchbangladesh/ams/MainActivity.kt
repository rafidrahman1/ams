package com.catchbangladesh.ams

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

@Suppress("unused")
class MainActivity : FlutterActivity() {
    private val channelName = "com.catchbangladesh.ams/scanner"

    // Hardware scanners use different broadcast actions / extra keys per OEM.
    private val scanActions = setOf(
        "scan.rcv.message",
        "orgaiot.intent.action.scan",
        "com.kte.scan.result",
        "com.android.scanner.service_settings",
    )
    private val scanDataKeys = listOf(
        "barcodeData",
        "data",
        "barcode",
        "SCAN_RESULT",
        "scannerdata",
    )

    private var scannerReceiver: BroadcastReceiver? = null
    private var methodChannel: MethodChannel? = null

    // Debounce protection for scanner trigger
    private var lastScanTime: Long = 0
    private val DEBOUNCE_DELAY = 500L // Milliseconds
    private var isScanActive = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)

        methodChannel?.setMethodCallHandler { call: MethodCall, result: MethodChannel.Result ->
            when (call.method) {
                "startHardwareScan" -> {
                    val currentTime = System.currentTimeMillis()
                    if (isScanActive) {
                        result.success(false)
                        return@setMethodCallHandler
                    }
                    if (currentTime - lastScanTime > DEBOUNCE_DELAY) {
                        lastScanTime = currentTime
                        isScanActive = true
                        sendBroadcast(Intent("com.java.scan.open"))
                        result.success(true)
                    } else {
                        result.success(false)
                    }
                }
                "stopHardwareScan" -> {
                    isScanActive = false
                    lastScanTime = 0
                    sendBroadcast(Intent("com.java.scan.close"))
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        scannerReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                val action = intent?.action
                if (action != null && action in scanActions) {
                    val barcode = extractBarcode(intent)
                    if (!barcode.isNullOrBlank()) {
                        isScanActive = false
                        methodChannel?.invokeMethod("onScanReceived", barcode)
                    }
                }
            }
        }

        val intentFilter = IntentFilter().apply {
            scanActions.forEach(::addAction)
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(scannerReceiver, intentFilter, Context.RECEIVER_EXPORTED)
        } else {
            registerReceiver(scannerReceiver, intentFilter)
        }
    }

    private fun extractBarcode(intent: Intent?): String? {
        if (intent == null) return null
        for (key in scanDataKeys) {
            val value = intent.getStringExtra(key)?.trim()
            if (!value.isNullOrBlank()) {
                return value
            }
        }
        return null
    }

    override fun onDestroy() {
        scannerReceiver?.let { unregisterReceiver(it) }
        scannerReceiver = null
        methodChannel = null
        super.onDestroy()
    }
}
