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

    // Action that emits barcode data
    private val scanActions = setOf("scan.rcv.message")
    private val scanDataKey = "barcodeData"

    private var scannerReceiver: BroadcastReceiver? = null
    private var methodChannel: MethodChannel? = null
    private var uhfReader: UhfSerialReader? = null

    // Debounce protection for scanner trigger
    private var lastScanTime: Long = 0
    private val DEBOUNCE_DELAY = 500L // Milliseconds
    private var isScanActive = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 1. Initialize the persistent MethodChannel
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
        uhfReader = UhfSerialReader(
            onTag = { tag -> methodChannel?.invokeMethod("onUhfTag", tag) },
            onStatus = { _ -> },
        )

        // 2. Set up the MethodCallHandler
        methodChannel?.setMethodCallHandler { call: MethodCall, result: MethodChannel.Result ->
            when (call.method) {
                "startHardwareScan" -> {
                    val currentTime = System.currentTimeMillis()
                    if (isScanActive) {
                        // Scan already in progress, ignore
                        result.success(false)
                        return@setMethodCallHandler
                    }
                    if (currentTime - lastScanTime > DEBOUNCE_DELAY) {
                        lastScanTime = currentTime
                        isScanActive = true
                        sendBroadcast(Intent("com.java.scan.open"))
                        result.success(true)
                    } else {
                        // Debounce delay not met, ignore
                        result.success(false)
                    }
                }
                "stopHardwareScan" -> {
                    isScanActive = false
                    lastScanTime = 0 // Reset debounce timer
                    sendBroadcast(Intent("com.java.scan.close"))
                    result.success(true)
                }
                "isUhfAvailable" -> {
                    result.success(true)
                }
                "startUhfInventory" -> {
                    val success = uhfReader?.start() == true
                    result.success(success)
                }
                "stopUhfInventory" -> {
                    val success = uhfReader?.stop() == true
                    result.success(success)
                }
                else -> result.notImplemented()
            }
        }

        // 3. Register the BroadcastReceiver to catch scan data
        scannerReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                val action = intent?.action
                if (action != null && action in scanActions) {
                    val barcode = intent.getStringExtra(scanDataKey)?.trim()
                    if (!barcode.isNullOrBlank()) {
                        isScanActive = false // Reset scan state when data is received
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

    override fun onDestroy() {
        uhfReader?.stop()
        uhfReader = null
        scannerReceiver?.let { unregisterReceiver(it) }
        scannerReceiver = null
        methodChannel = null
        super.onDestroy()
    }
}
