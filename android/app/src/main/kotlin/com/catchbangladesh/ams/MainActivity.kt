package com.catchbangladesh.ams

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val TAG = "ScannerMainActivity"
    private val CHANNEL = "com.catchbangladesh.ams/scanner"
    
    // Identified standard action and key
    private val SCAN_ACTION = "com.android.scanner.service_settings"
    private val SCAN_DATA_KEY = "data"

    private var scannerReceiver: ScannerBroadcastReceiver? = null
    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 1. Initialize the persistent MethodChannel
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)

        // 2. Setup the MethodCallHandler
        methodChannel?.setMethodCallHandler { call, result ->
            if (call.method == "triggerHardwareScan") {
                Log.d(TAG, "Triggering hardware scan laser")
                val intent = Intent("com.java.scan.open")
                sendBroadcast(intent)
                result.success(null)
            } else {
                result.notImplemented()
            }
        }

        // 3. Register the BroadcastReceiver to catch scan data
        scannerReceiver = ScannerBroadcastReceiver()
        val intentFilter = IntentFilter(SCAN_ACTION)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(scannerReceiver, intentFilter, Context.RECEIVER_EXPORTED)
        } else {
            registerReceiver(scannerReceiver, intentFilter)
        }
        
        Log.d(TAG, "Scanner service registered with filter: $SCAN_ACTION")
    }

    override fun onDestroy() {
        super.onDestroy()
        scannerReceiver?.let { unregisterReceiver(it) }
        methodChannel = null
    }

    private inner class ScannerBroadcastReceiver : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == SCAN_ACTION) {
                // Matching the identified .ui.ScanService standard
                val barcodeData = intent.getStringExtra(SCAN_DATA_KEY)
                Log.d(TAG, "Scan received on action $SCAN_ACTION: $barcodeData")

                barcodeData?.let {
                    methodChannel?.invokeMethod("onScanReceived", it)
                }
            }
        }
    }
}
