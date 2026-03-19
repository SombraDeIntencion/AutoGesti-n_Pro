package com.mahondev.autogestionmax

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import androidx.activity.enableEdgeToEdge
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterFragmentActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)
    }
    private val CHANNEL = "com.mahondev.autogestionmax/native_helper"
    private var permissionResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "checkPermission" -> {
                        val permission = call.argument<String>("permission") ?: ""
                        result.success(checkPermissionStatus(permission))
                    }
                    "requestPermission" -> {
                        val permission = call.argument<String>("permission") ?: ""
                        requestPermissionNative(permission, result)
                    }
                    "openAppSettings" -> {
                        openAppSettings()
                        result.success(true)
                    }
                    "openFile" -> {
                        val path = call.argument<String>("path") ?: ""
                        val mimeType = call.argument<String>("mimeType")
                        result.success(openFile(path, mimeType))
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun checkPermissionStatus(type: String): String {
        val permission = mapPermission(type) ?: return "granted"
        val status = ContextCompat.checkSelfPermission(this, permission)
        return if (status == PackageManager.PERMISSION_GRANTED) "granted" else "denied"
    }

    private fun requestPermissionNative(type: String, result: MethodChannel.Result) {
        val permission = mapPermission(type)
        if (permission == null) {
            result.success("granted")
            return
        }

        val status = ContextCompat.checkSelfPermission(this, permission)
        if (status == PackageManager.PERMISSION_GRANTED) {
            result.success("granted")
            return
        }

        permissionResult = result
        ActivityCompat.requestPermissions(this, arrayOf(permission), PERMISSION_REQUEST_CODE)
    }

    private fun mapPermission(type: String): String? {
        return when (type) {
            "camera" -> Manifest.permission.CAMERA
            "storage" -> {
                if (Build.VERSION.SDK_INT <= 32) {
                    Manifest.permission.WRITE_EXTERNAL_STORAGE
                } else {
                    null // Android 13+: scoped storage, no permission needed
                }
            }
            else -> null
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == PERMISSION_REQUEST_CODE) {
            val granted = grantResults.isNotEmpty() &&
                    grantResults[0] == PackageManager.PERMISSION_GRANTED
            if (granted) {
                permissionResult?.success("granted")
            } else {
                val shouldShow = if (permissions.isNotEmpty()) {
                    ActivityCompat.shouldShowRequestPermissionRationale(this, permissions[0])
                } else false
                permissionResult?.success(if (shouldShow) "denied" else "permanentlyDenied")
            }
            permissionResult = null
        }
    }

    private fun openAppSettings() {
        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
        intent.data = Uri.parse("package:$packageName")
        startActivity(intent)
    }

    private fun openFile(path: String, mimeType: String?): Boolean {
        return try {
            val file = File(path)
            if (!file.exists()) return false

            val uri = FileProvider.getUriForFile(
                this,
                "$packageName.fileprovider",
                file
            )

            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(uri, mimeType ?: getMimeType(path))
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }

            startActivity(intent)
            true
        } catch (e: Exception) {
            false
        }
    }

    private fun getMimeType(path: String): String {
        return when {
            path.endsWith(".pdf", true) -> "application/pdf"
            path.endsWith(".jpg", true) || path.endsWith(".jpeg", true) -> "image/jpeg"
            path.endsWith(".png", true) -> "image/png"
            path.endsWith(".zip", true) -> "application/zip"
            else -> "*/*"
        }
    }

    companion object {
        private const val PERMISSION_REQUEST_CODE = 1001
    }
}
