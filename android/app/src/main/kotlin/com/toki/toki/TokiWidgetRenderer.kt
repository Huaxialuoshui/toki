package com.toki.toki

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.LinearGradient
import android.graphics.Paint
import android.graphics.Path
import android.graphics.RectF
import android.graphics.Shader
import android.widget.RemoteViews
import org.json.JSONObject
import java.io.File
import kotlin.math.max
import kotlin.math.min

/**
 * 把 Flutter 侧写下的 `widget_state.json` 渲染成 RemoteViews。
 *
 * 外观（皮肤 / 图标 / 背景图片 / 圆角 / 配色）全部由 Flutter 侧决定，
 * 这里只负责画：背景统一画成一张位图（支持纯色 / 渐变 / 图片 + 圆角），
 * 文字用 setTextColor，图标按"描边 / 实心"切换资源。
 */
object TokiWidgetRenderer {
    private const val STATE_FILE = "widget_state.json"
    private const val BACKGROUND_FILE = "widget_background.png"

    /** Flutter 侧把状态写到这个文件，原生只读它。 */
    fun stateFile(context: Context): File = File(context.filesDir, STATE_FILE)

    /** 用户选的背景图片会被复制到这里。 */
    fun backgroundFile(context: Context): File = File(context.filesDir, BACKGROUND_FILE)

    fun render(context: Context): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.toki_widget)
        val state = readState(context)
        val appearance = state?.optJSONObject("appearance") ?: JSONObject()

        val hasData = state != null && state.optBoolean("hasData", true)
        val title = if (hasData) state!!.optString("title", "Toki") else "Toki"
        val subtitle = if (hasData) state!!.optString("subtitle", "") else "还没有日程"
        val extra = if (hasData) state!!.optString("extra", "") else "打开应用添加"
        val updated = if (hasData) state!!.optString("updatedLabel", "") else ""

        val textColor = appearance.optInt("textColor", 0xFFECF0F8.toInt())
        val mutedColor = withAlpha(textColor, 0.7f)
        val accentColor = appearance.optInt("accentColor", 0xFF12B5A5.toInt())
        val filledIcons = appearance.optString("iconStyle", "outlined") == "filled"

        views.setImageViewBitmap(
            R.id.widget_background,
            backgroundBitmap(context, appearance),
        )

        views.setImageViewResource(
            R.id.widget_icon,
            if (filledIcons) R.drawable.ic_widget_timer_filled
            else R.drawable.ic_widget_timer_outlined,
        )
        views.setInt(R.id.widget_icon, "setColorFilter", accentColor)

        views.setImageViewResource(
            R.id.widget_refresh,
            if (filledIcons) R.drawable.ic_widget_refresh_filled
            else R.drawable.ic_widget_refresh_outlined,
        )
        views.setInt(R.id.widget_refresh, "setColorFilter", mutedColor)

        views.setTextViewText(R.id.widget_title, title)
        views.setTextColor(R.id.widget_title, accentColor)
        views.setTextViewText(R.id.widget_subtitle, subtitle)
        views.setTextColor(R.id.widget_subtitle, textColor)
        views.setTextViewText(R.id.widget_extra, extra)
        views.setTextColor(R.id.widget_extra, mutedColor)
        views.setTextViewText(R.id.widget_updated, updated)
        views.setTextColor(R.id.widget_updated, withAlpha(mutedColor, 0.8f))

        views.setOnClickPendingIntent(R.id.widget_root, openAppIntent(context))
        views.setOnClickPendingIntent(R.id.widget_refresh, refreshIntent(context))
        return views
    }

    private fun readState(context: Context): JSONObject? {
        val file = stateFile(context)
        if (!file.exists()) return null
        return try {
            JSONObject(file.readText())
        } catch (error: Exception) {
            null
        }
    }

    /**
     * 背景统一画成位图：纯色 / 线性渐变 / 用户图片，都按圆角裁剪。
     * RemoteViews 不支持直接设渐变或圆角，所以走这条路。
     */
    private fun backgroundBitmap(context: Context, appearance: JSONObject): Bitmap {
        val width = 640
        val height = 320
        val radius = appearance.optInt("cornerRadius", 24).toFloat()
        val opaque = appearance.optBoolean("opaqueBackground", true)
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val path = Path().apply {
            addRoundRect(RectF(0f, 0f, width.toFloat(), height.toFloat()), radius, radius, Path.Direction.CW)
        }
        canvas.clipPath(path)

        when (appearance.optString("backgroundType", "solid")) {
            "gradient" -> {
                val start = appearance.optInt("gradientStart", 0xFF1F2440.toInt())
                val end = appearance.optInt("gradientEnd", 0xFF101320.toInt())
                val paint = Paint().apply {
                    shader = LinearGradient(
                        0f, 0f, width.toFloat(), height.toFloat(), start, end, Shader.TileMode.CLAMP,
                    )
                }
                canvas.drawRect(0f, 0f, width.toFloat(), height.toFloat(), paint)
            }
            "image" -> {
                val file = File(appearance.optString("imagePath", ""))
                val decoded = if (file.exists()) BitmapFactory.decodeFile(file.absolutePath) else null
                if (decoded != null) {
                    val paint = Paint(Paint.FILTER_BITMAP_FLAG)
                    val scale = max(width / decoded.width.toFloat(), height / decoded.height.toFloat())
                    val scaledW = decoded.width * scale
                    val scaledH = decoded.height * scale
                    val left = (width - scaledW) / 2f
                    val top = (height - scaledH) / 2f
                    canvas.drawBitmap(
                        decoded,
                        android.graphics.Rect(0, 0, decoded.width, decoded.height),
                        RectF(left, top, left + scaledW, top + scaledH),
                        paint,
                    )
                    val overlay = appearance.optInt("imageOverlay", 0x66_000000)
                    if (overlay != 0) {
                        canvas.drawRect(0f, 0f, width.toFloat(), height.toFloat(), Paint().apply { color = overlay })
                    }
                } else {
                    canvas.drawColor(appearance.optInt("backgroundColor", 0xFF171A24.toInt()))
                }
            }
            else -> canvas.drawColor(appearance.optInt("backgroundColor", 0xFF171A24.toInt()))
        }

        if (!opaque) {
            // "透明"模式：整体再乘一次透明度，保留圆角外的透明。
            val alpha = appearance.optInt("backgroundAlpha", 255).coerceIn(0, 255)
            val paint = Paint().apply { this.alpha = alpha }
            canvas.drawBitmap(bitmap, 0f, 0f, paint)
        }
        return bitmap
    }

    private fun openAppIntent(context: Context): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        return PendingIntent.getActivity(
            context,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun refreshIntent(context: Context): PendingIntent {
        val intent = Intent(context, TokiWidgetProvider::class.java).apply {
            action = TokiWidgetProvider.ACTION_REFRESH
        }
        return PendingIntent.getBroadcast(
            context,
            1,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun withAlpha(color: Int, alpha: Float): Int {
        val a = ((color ushr 24) and 0xFF) * alpha
        return (a.toInt().coerceIn(0, 255) shl 24) or (color and 0x00FFFFFF)
    }
}
