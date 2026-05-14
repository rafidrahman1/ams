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

    // Actions that emit barcode data
    private val scanActions = setOf(
        "orgaiot.intent.action.scan", 
        "com.kte.scan.result",
        "com.android.scanner.service_settings"
    )
    private val scanDataKey = "data"

    private var scannerReceiver: BroadcastReceiver? = null
    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 1. Initialize the persistent MethodChannel
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)

        // 2. Set up the MethodCallHandler
        methodChannel?.setMethodCallHandler { call: MethodCall, result: MethodChannel.Result ->
            when (call.method) {
                "startHardwareScan" -> {
                    sendBroadcast(Intent("com.java.scan.open"))
                    result.success(true)
                }
                "stopHardwareScan" -> {
                    sendBroadcast(Intent("com.java.scan.close"))
                    result.success(true)
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
        scannerReceiver?.let { unregisterReceiver(it) }
        scannerReceiver = null
        methodChannel = null
        super.onDestroy()
    }
}
