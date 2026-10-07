package com.toki.toki

import android.Manifest
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.ComponentName
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Toki 的原生入口。
 *
 * 除了承载 Flutter 界面，这里还用一条 MethodChannel（toki/device）提供原生能力：
 * 1. 定位（天气按 GPS 取位置）——用系统 LocationManager，不依赖 Google Play 服务；
 * 2. 桌面小组件——把 Flutter 侧的状态与外观推给 AppWidgetProvider 并刷新。
 */
class MainActivity : FlutterActivity() {
    private var deviceChannel: MethodChannel? = null
    private var pendingLocationResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        deviceChannel = channel
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "hasLocationPermission" -> result.success(hasLocationPermission())
                "requestLocationPermission" -> requestLocationPermission(result)
                "getLocation" -> getLocation(result)
                "updateWidget" -> {
                    TokiWidgetProvider.updateAll(this)
                    result.success(true)
                }
                "requestPinWidget" -> result.success(requestPinWidget())
                "requestIgnoreBatteryOptimizations" ->
                    result.success(TokiBackgroundService.requestIgnoreBatteryOptimizations(this))
                "isIgnoringBatteryOptimizations" ->
                    result.success(TokiBackgroundService.isIgnoringBatteryOptimizations(this))
                "setBackgroundService" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: false
                    TokiBackgroundService.setEnabled(this, enabled)
                    result.success(enabled)
                }
                "isBackgroundServiceEnabled" ->
                    result.success(TokiBackgroundService.isEnabled(this))
                else -> result.notImplemented()
            }
        }
    }

    /** 请求把小组件钉到桌面（Android 8+ 的 requestPinAppWidget，需要启动器支持）。 */
    private fun requestPinWidget(): Boolean {
        if (android.os.Build.VERSION.SDK_INT < android.os.Build.VERSION_CODES.O) {
            return false
        }
        val manager = AppWidgetManager.getInstance(this)
        if (!manager.isRequestPinAppWidgetSupported) return false
        return manager.requestPinAppWidget(
            ComponentName(this, TokiWidgetProvider::class.java),
            null,
            null,
        )
    }

    private fun hasLocationPermission(): Boolean {
        val fine = ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.ACCESS_FINE_LOCATION,
        ) == PackageManager.PERMISSION_GRANTED
        val coarse = ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.ACCESS_COARSE_LOCATION,
        ) == PackageManager.PERMISSION_GRANTED
        return fine || coarse
    }

    private var permissionResult: MethodChannel.Result? = null

    private fun requestLocationPermission(result: MethodChannel.Result) {
        if (hasLocationPermission()) {
            result.success(true)
            return
        }
        permissionResult = result
        ActivityCompat.requestPermissions(
            this,
            arrayOf(
                Manifest.permission.ACCESS_COARSE_LOCATION,
                Manifest.permission.ACCESS_FINE_LOCATION,
            ),
            LOCATION_REQUEST_CODE,
        )
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != LOCATION_REQUEST_CODE) return
        permissionResult?.success(hasLocationPermission())
        permissionResult = null
    }

    /** 取一次位置：优先用最近一次已知位置，没有再请求单次更新。 */
    private fun getLocation(result: MethodChannel.Result) {
        if (!hasLocationPermission()) {
            result.error("permission", "没有定位权限", null)
            return
        }
        val manager = getSystemService(Context.LOCATION_SERVICE) as LocationManager
        val last = lastKnown(manager)
        if (last != null) {
            result.success(locationPayload(last))
            return
        }

        val provider = when {
            manager.isProviderEnabled(LocationManager.GPS_PROVIDER) ->
                LocationManager.GPS_PROVIDER
            manager.isProviderEnabled(LocationManager.NETWORK_PROVIDER) ->
                LocationManager.NETWORK_PROVIDER
            else -> null
        }
        if (provider == null) {
            result.error("disabled", "系统定位服务没有打开", null)
            return
        }

        pendingLocationResult = result
        try {
            manager.requestSingleUpdate(
                provider,
                { location ->
                    pendingLocationResult?.success(locationPayload(location))
                    pendingLocationResult = null
                },
                null,
            )
        } catch (error: SecurityException) {
            pendingLocationResult = null
            result.error("permission", "定位权限被拒绝：${error.message}", null)
        }
    }

    private fun lastKnown(manager: LocationManager): Location? {
        val providers = listOf(
            LocationManager.GPS_PROVIDER,
            LocationManager.NETWORK_PROVIDER,
        )
        // 取"最新"的那个，避免拿到很久以前的缓存。
        var best: Location? = null
        for (provider in providers) {
            val location = try {
                manager.getLastKnownLocation(provider)
            } catch (error: SecurityException) {
                null
            }
            if (location == null) continue
            if (best == null || location.time > best.time) best = location
        }
        return best
    }

    private fun locationPayload(location: Location): Map<String, Any> = mapOf(
        "latitude" to location.latitude,
        "longitude" to location.longitude,
        "accuracy" to location.accuracy.toDouble(),
        "time" to location.time,
        "provider" to (location.provider ?: ""),
    )

    companion object {
        const val CHANNEL = "toki/device"
        private const val LOCATION_REQUEST_CODE = 4301
    }
}
