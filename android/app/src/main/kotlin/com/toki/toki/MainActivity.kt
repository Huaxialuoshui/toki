package com.toki.toki

import android.Manifest
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.ComponentName
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Handler
import android.os.Looper
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
    private var pendingLocationManager: LocationManager? = null
    private var pendingLocationListener: LocationListener? = null
    private val locationHandler by lazy { Handler(Looper.getMainLooper()) }
    private val locationTimeout = Runnable {
        val pending = pendingLocationResult
        clearPendingLocation()
        pending?.error("timeout", "定位超时：可能没有信号，或者系统定位没有打开", null)
    }

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

        // 上一次如果还在等，先取消，避免回调错位。
        clearPendingLocation()
        pendingLocationResult = result
        pendingLocationManager = manager
        val listener = LocationListener { location ->
            val payload = locationPayload(location)
            val pending = pendingLocationResult
            clearPendingLocation()
            pending?.success(payload)
        }
        pendingLocationListener = listener
        try {
            manager.requestSingleUpdate(
                provider,
                listener,
                Looper.getMainLooper(),
            )
            // 系统可能一直不给回调（例如在室内没有 GPS 信号），所以必须有超时兜底，
            // 否则 Flutter 侧会一直等下去。
            locationHandler.postDelayed(locationTimeout, LOCATION_TIMEOUT_MS)
        } catch (error: SecurityException) {
            clearPendingLocation()
            result.error("permission", "定位权限被拒绝：${error.message}", null)
        }
    }

    /** 取消正在等待的定位回调（含超时计时器）。 */
    private fun clearPendingLocation() {
        locationHandler.removeCallbacks(locationTimeout)
        val manager = pendingLocationManager
        val listener = pendingLocationListener
        if (manager != null && listener != null) {
            try {
                manager.removeUpdates(listener)
            } catch (_: Exception) {
                // 清理而已，失败无所谓。
            }
        }
        pendingLocationManager = null
        pendingLocationListener = null
        pendingLocationResult = null
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
        private const val LOCATION_TIMEOUT_MS = 15_000L
    }
}
