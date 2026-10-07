package com.toki.toki

import android.Manifest
import android.app.ActivityManager
import android.appwidget.AppWidgetManager
import android.content.ActivityNotFoundException
import android.content.ContentValues
import android.content.Context
import android.content.ComponentName
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ShortcutInfo
import android.content.pm.ShortcutManager
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Matrix
import android.graphics.Paint
import android.graphics.drawable.Icon
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.security.MessageDigest

/**
 * Toki 的原生入口。
 *
 * 除了承载 Flutter 界面，这里还用一条 MethodChannel（toki/device）提供原生能力：
 * 1. 定位（天气按 GPS 取位置）——用系统 LocationManager，不依赖 Google Play 服务；
 * 2. 桌面小组件——把 Flutter 侧的状态与外观推给 AppWidgetProvider 并刷新。
 * 3. 自定义应用图标——最近任务里的图标 + 用 requestPinShortcut 生成"带自己图片"的桌面快捷方式；
 * 4. 调用系统图片编辑器——把图片以 content:// 交给别的应用改，改完再拿回来。
 */
class MainActivity : FlutterActivity() {
    private var deviceChannel: MethodChannel? = null
    private var pendingLocationResult: MethodChannel.Result? = null
    private var pendingLocationManager: LocationManager? = null
    private var pendingLocationListener: LocationListener? = null
    private var pendingEditResult: MethodChannel.Result? = null
    private var pendingEditSource: String? = null
    private var pendingEditUri: android.net.Uri? = null
    private var pendingEditMediaStoreUri: android.net.Uri? = null
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
                "setAppIcon" -> setAppIcon(call.argument<String>("path"), result)
                "resetAppIcon" -> resetAppIcon(result)
                "editImage" -> editImage(call.argument<String>("path"), result)
                else -> result.notImplemented()
            }
        }
        // 上次设置过的应用图标在重启后继续生效（最近任务 / 桌面图标）。
        storedIconPath()?.let { path -> decodeBitmap(path)?.let { applyTaskIcon(it) } }
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

    // ---------------------------------------------------------------------
    // 自定义应用图标
    //
    // Android 不允许 App 在运行时直接改 android:icon（那是打包时的资源），
    // 所以这里做两件真实有效、看得见的事：
    //   1. setTaskDescription：换掉「最近任务」里的图标（立即生效，重启后也会恢复）；
    //   2. requestPinShortcut + Icon.createWithAdaptiveBitmap：用你自己的图片
    //      生成一个桌面快捷方式（系统会弹一次确认框，需要用户点「添加」）。
    // 注意：桌面上的「应用图标」本身仍由启动器绘制，只有上面两种方式能改。
    // ---------------------------------------------------------------------

    private fun setAppIcon(path: String?, result: MethodChannel.Result) {
        val bitmap = decodeBitmap(path)
        if (bitmap == null || path == null) {
            result.error("decode", "图片读不出来（路径不对，或者不是图片）", null)
            return
        }
        applyTaskIcon(bitmap)
        storeIconPath(path)
        val shortcut = requestIconShortcut(bitmap)
        result.success(mapOf("recents" to true, "shortcut" to shortcut))
    }

    private fun resetAppIcon(result: MethodChannel.Result) {
        setTaskDescription(ActivityManager.TaskDescription(appLabel()))
        storeIconPath(null)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            try {
                getSystemService(ShortcutManager::class.java)?.removeAllDynamicShortcuts()
            } catch (_: Exception) {
                // 取消失败不影响"恢复默认"的主流程。
            }
        }
        result.success(true)
    }

    private fun applyTaskIcon(bitmap: Bitmap) {
        setTaskDescription(ActivityManager.TaskDescription(appLabel(), bitmap))
    }

    private fun appLabel(): String = applicationInfo.loadLabel(packageManager).toString()

    /** 把用户图片塞进 108dp 自适应图标画布（安全区内居中），避免被启动器裁掉。 */
    private fun adaptiveIcon(source: Bitmap): Bitmap {
        val size = 432
        val inner = 288
        val output = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(output)
        val scale = minOf(inner.toFloat() / source.width, inner.toFloat() / source.height)
        val width = source.width * scale
        val height = source.height * scale
        val matrix = Matrix().apply {
            postScale(scale, scale)
            postTranslate((size - width) / 2f, (size - height) / 2f)
        }
        canvas.drawBitmap(source, matrix, Paint(Paint.FILTER_BITMAP_FLAG))
        return output
    }

    /** 请求系统钉一个带自定义图标的快捷方式；返回是否成功发起请求。 */
    private fun requestIconShortcut(bitmap: Bitmap): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return false
        val manager = getSystemService(ShortcutManager::class.java) ?: return false
        if (!manager.isRequestPinShortcutSupported) return false
        return try {
            val shortcut = ShortcutInfo.Builder(this, SHORTCUT_ID)
                .setShortLabel(appLabel())
                .setLongLabel(appLabel())
                .setIcon(Icon.createWithAdaptiveBitmap(adaptiveIcon(bitmap)))
                .setIntent(
                    Intent(this, MainActivity::class.java).setAction(Intent.ACTION_MAIN),
                )
                .build()
            // 先登记成动态快捷方式（长按图标也能看到），再请求钉到桌面。
            manager.setDynamicShortcuts(listOf(shortcut))
            manager.requestPinShortcut(shortcut, null)
        } catch (error: Exception) {
            false
        }
    }

    private fun storedIconPath(): String? = getSharedPreferences(PREFS, MODE_PRIVATE)
        .getString(KEY_ICON_PATH, null)

    private fun storeIconPath(path: String?) {
        getSharedPreferences(PREFS, MODE_PRIVATE)
            .edit()
            .apply { if (path == null) remove(KEY_ICON_PATH) else putString(KEY_ICON_PATH, path) }
            .apply()
    }

    /** 按需缩放解码，避免一张 4000px 的照片直接进内存。 */
    private fun decodeBitmap(path: String?): Bitmap? {
        if (path.isNullOrEmpty()) return null
        val file = File(path)
        if (!file.exists() || !file.isFile) return null
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeFile(path, bounds)
        if (bounds.outWidth <= 0 || bounds.outHeight <= 0) return null
        val options = BitmapFactory.Options()
        var sample = 1
        var width = bounds.outWidth
        var height = bounds.outHeight
        while (width / 2 >= 512 && height / 2 >= 512) {
            sample *= 2
            width /= 2
            height /= 2
        }
        options.inSampleSize = sample
        return try {
            BitmapFactory.decodeFile(path, options)
        } catch (_: Exception) {
            null
        }
    }

    // ---------------------------------------------------------------------
    // 调用系统图片编辑器
    //
    // 流程：原图 → 放进相册（MediaStore，Pictures/Toki/）拿 content:// URI →
    // ACTION_EDIT 交给系统里的编辑器 → 回来后对比内容：改过就另存成应用私有目录
    // 里的新文件并把新路径返回给 Flutter；最后把相册里那份临时副本删掉。
    //
    // 为什么要绕一趟相册：Google Photos / 系统相册的编辑器只肯编辑"它自己索引到
    // 的图片"，直接共享应用私有目录里的文件会被拒绝（实测会提示
    // "Editing is not supported for this image"）。插进 MediaStore 编辑器才认。
    // 相册不可用时（少数机型 / 无权限）退回 FileProvider 共享缓存文件。
    // ---------------------------------------------------------------------

    private fun editImage(path: String?, result: MethodChannel.Result) {
        if (path.isNullOrEmpty()) {
            result.error("path", "这张图片没有本地文件，改不了", null)
            return
        }
        val source = File(path)
        if (!source.exists() || !source.isFile) {
            result.error("missing", "找不到这张图片", null)
            return
        }
        val shared = shareForEditing(source)
        val uri = shared?.first
        if (uri == null) {
            result.error("copy", "图片复制失败，没法交给编辑器", null)
            return
        }
        val intent = Intent(Intent.ACTION_EDIT)
            .setDataAndType(uri, "image/*")
            .addFlags(
                Intent.FLAG_GRANT_READ_URI_PERMISSION or
                    Intent.FLAG_GRANT_WRITE_URI_PERMISSION,
            )
        if (intent.resolveActivity(packageManager) == null) {
            releaseShared(uri, shared.second)
            result.error("no-editor", "这台设备上没有能编辑图片的应用", null)
            return
        }
        pendingEditResult = result
        pendingEditSource = path
        pendingEditUri = uri
        pendingEditMediaStoreUri = shared.second
        try {
            startActivityForResult(intent, EDIT_REQUEST_CODE)
        } catch (_: ActivityNotFoundException) {
            releaseShared(uri, shared.second)
            clearPendingEdit()
            result.error("no-editor", "这台设备上没有能编辑图片的应用", null)
        }
    }

    /**
     * 把图片交给编辑器：优先插进相册（编辑器才认），失败退回 FileProvider。
     *
     * @return (交给编辑器的 URI, 事后要删掉的相册 URI —— 没插相册时为 null)
     */
    private fun shareForEditing(
        source: File,
    ): Pair<android.net.Uri, android.net.Uri?>? {
        insertIntoGallery(source)?.let { gallery -> return gallery to gallery }
        return try {
            val dir = File(cacheDir, "edit").apply { mkdirs() }
            val cacheFile = File(dir, source.name)
            source.copyTo(cacheFile, overwrite = true)
            FileProvider.getUriForFile(this, "$packageName.fileprovider", cacheFile) to null
        } catch (_: Exception) {
            null
        }
    }

    /** 往 MediaStore 插一份副本，成功返回它的 content URI。 */
    private fun insertIntoGallery(source: File): android.net.Uri? {
        return try {
            val values = ContentValues().apply {
                put(
                    MediaStore.Images.Media.DISPLAY_NAME,
                    "toki_edit_${System.currentTimeMillis()}_${source.name}",
                )
                put(MediaStore.Images.Media.MIME_TYPE, mimeOf(source.name))
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    put(MediaStore.Images.Media.RELATIVE_PATH, "Pictures/Toki")
                    put(MediaStore.Images.Media.IS_PENDING, 1)
                }
            }
            val collection = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                MediaStore.Images.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
            } else {
                MediaStore.Images.Media.EXTERNAL_CONTENT_URI
            }
            val uri = contentResolver.insert(collection, values) ?: return null
            contentResolver.openOutputStream(uri)?.use { output ->
                source.inputStream().use { input -> input.copyTo(output) }
            } ?: return null
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                val done = ContentValues().apply { put(MediaStore.Images.Media.IS_PENDING, 0) }
                contentResolver.update(uri, done, null, null)
            }
            uri
        } catch (_: Exception) {
            null
        }
    }

    /** 编辑结束后清理相册里那份临时副本（删不掉也不影响主流程）。 */
    private fun releaseShared(uri: android.net.Uri, galleryUri: android.net.Uri?) {
        if (galleryUri == null) return
        try {
            contentResolver.delete(galleryUri, null, null)
        } catch (_: Exception) {
            // 留着也行，用户可以在相册里自己删。
        }
    }

    private fun mimeOf(name: String): String =
        when (name.substringAfterLast('.', "").lowercase()) {
            "jpg", "jpeg" -> "image/jpeg"
            "webp" -> "image/webp"
            "gif" -> "image/gif"
            "bmp" -> "image/bmp"
            "heic" -> "image/heic"
            else -> "image/png"
        }

    private fun clearPendingEdit() {
        pendingEditResult = null
        pendingEditSource = null
        pendingEditUri = null
        pendingEditMediaStoreUri = null
    }

    /** 编辑回来了：内容有变化就另存为新文件，否则原样返回原路径。 */
    private fun finishEdit() {
        val pending = pendingEditResult
        val source = pendingEditSource
        val uri = pendingEditUri
        val galleryUri = pendingEditMediaStoreUri
        clearPendingEdit()
        if (pending == null) return

        if (source == null || uri == null) {
            pending.success(mapOf("path" to source, "changed" to false))
            return
        }
        // 编辑器（尤其是 Google Photos 的"保存副本"）可能是异步落盘的：回调回来时
        // 文件还没写完，所以读一次没变化就等一下再读，最多 4 次（约 2.8s）。
        readEdited(
            pending = pending,
            original = File(source),
            uri = uri,
            galleryUri = galleryUri,
            attempt = 0,
        )
    }

    private fun readEdited(
        pending: MethodChannel.Result,
        original: File,
        uri: android.net.Uri,
        galleryUri: android.net.Uri?,
        attempt: Int,
    ) {
        val bytes = readSharedBytes(uri)
        if (bytes != null && !sameContent(original, bytes)) {
            val target = saveEdited(original, bytes)
            releaseShared(uri, galleryUri)
            pending.success(
                mapOf("path" to target, "changed" to (target != original.path)),
            )
            return
        }
        if (attempt < EDIT_READ_ATTEMPTS) {
            locationHandler.postDelayed(
                { readEdited(pending, original, uri, galleryUri, attempt + 1) },
                EDIT_READ_DELAY_MS,
            )
            return
        }
        releaseShared(uri, galleryUri)
        pending.success(mapOf("path" to original.path, "changed" to false))
    }

    private fun readSharedBytes(uri: android.net.Uri): ByteArray? = try {
        contentResolver.openInputStream(uri)?.use { it.readBytes() }
    } catch (_: Exception) {
        null
    }

    /** 把编辑结果另存到应用私有目录，返回新路径（失败就退回原路径）。 */
    private fun saveEdited(original: File, bytes: ByteArray): String = try {
        val dir = File(filesDir, "edited").apply { mkdirs() }
        val out = File(dir, "${System.currentTimeMillis()}_${original.name}")
        out.writeBytes(bytes)
        out.absolutePath
    } catch (_: Exception) {
        original.path
    }

    private fun sameContent(a: File, b: File): Boolean {
        if (a.length() != b.length()) return false
        return try {
            digest(a) == digest(b)
        } catch (_: Exception) {
            false
        }
    }

    private fun sameContent(a: File, b: ByteArray): Boolean {
        if (a.length() != b.size.toLong()) return false
        return try {
            digest(a) == digest(b)
        } catch (_: Exception) {
            false
        }
    }

    private fun digest(bytes: ByteArray): String =
        MessageDigest.getInstance("MD5").digest(bytes)
            .joinToString("") { "%02x".format(it) }

    private fun digest(file: File): String {
        val md = MessageDigest.getInstance("MD5")
        file.inputStream().use { stream ->
            val buffer = ByteArray(16 * 1024)
            while (true) {
                val read = stream.read(buffer)
                if (read <= 0) break
                md.update(buffer, 0, read)
            }
        }
        return md.digest().joinToString("") { "%02x".format(it) }
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

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == EDIT_REQUEST_CODE) {
            // 用户可能点了「取消」，也可能真的改了；统一按"回来后再比对内容"处理。
            finishEdit()
        }
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
        private const val EDIT_REQUEST_CODE = 4302
        private const val EDIT_READ_ATTEMPTS = 4
        private const val EDIT_READ_DELAY_MS = 700L
        private const val PREFS = "toki_native"
        private const val KEY_ICON_PATH = "appIconPath"
        private const val SHORTCUT_ID = "toki_custom_icon"
    }
}
