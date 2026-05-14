package com.catchbangladesh.ams

import android.app.admin.DeviceAdminReceiver
import android.content.Context
import android.content.Intent

/**
 * Device Admin Receiver for asset management system.
 * This class handles device administration policies and callbacks.
 */
class AssetManagementDeviceAdminReceiver : DeviceAdminReceiver() {

    override fun onEnabled(context: Context, intent: Intent) {
        super.onEnabled(context, intent)
        // Called when device admin is enabled
        android.util.Log.d("DeviceAdmin", "Device Admin enabled")
    }

    override fun onDisabled(context: Context, intent: Intent) {
        super.onDisabled(context, intent)
        // Called when device admin is disabled
        android.util.Log.d("DeviceAdmin", "Device Admin disabled")
    }

    override fun onPasswordChanged(context: Context, intent: Intent) {
        super.onPasswordChanged(context, intent)
        // Called when device password changes
        android.util.Log.d("DeviceAdmin", "Password changed")
    }

    override fun onPasswordFailed(context: Context, intent: Intent) {
        super.onPasswordFailed(context, intent)
        // Called when password entry fails
        android.util.Log.d("DeviceAdmin", "Password failed")
    }

    override fun onPasswordSucceeded(context: Context, intent: Intent) {
        super.onPasswordSucceeded(context, intent)
        // Called when device is unlocked
        android.util.Log.d("DeviceAdmin", "Password succeeded")
    }

    override fun onLockTaskModeEntering(context: Context, intent: Intent, pkg: String) {
        super.onLockTaskModeEntering(context, intent, pkg)
        // Called when lock task mode is entering
        android.util.Log.d("DeviceAdmin", "Lock task mode entering for package: $pkg")
    }

    override fun onLockTaskModeExiting(context: Context, intent: Intent) {
        super.onLockTaskModeExiting(context, intent)
        // Called when lock task mode is exiting
        android.util.Log.d("DeviceAdmin", "Lock task mode exiting")
    }
}

