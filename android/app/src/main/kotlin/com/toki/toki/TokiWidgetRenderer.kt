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
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
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
        val locale = localeOf(state)
        val now = System.currentTimeMillis()

        val content = liveContent(state, locale, now)
        val updated = if (content.hasData) {
            text(
                locale,
                "更新于 ${clock(now)}",
                "Updated ${clock(now)}",
            )
        } else {
            ""
        }

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

        views.setTextViewText(R.id.widget_title, content.title)
        views.setTextColor(R.id.widget_title, accentColor)
        views.setTextViewText(R.id.widget_subtitle, content.subtitle)
        views.setTextColor(R.id.widget_subtitle, textColor)
        views.setTextViewText(R.id.widget_extra, content.extra)
        views.setTextColor(R.id.widget_extra, mutedColor)
        views.setTextViewText(R.id.widget_updated, updated)
        views.setTextColor(R.id.widget_updated, withAlpha(mutedColor, 0.8f))

        views.setOnClickPendingIntent(R.id.widget_root, openAppIntent(context))
        views.setOnClickPendingIntent(R.id.widget_refresh, refreshIntent(context))
        return views
    }

    fun readState(context: Context): JSONObject? {
        val file = stateFile(context)
        if (!file.exists()) return null
        return try {
            JSONObject(file.readText())
        } catch (error: Exception) {
            null
        }
    }

    /** 读取小组件刷新设置；旧版状态没有这些字段时沿用原来的 15 分钟节拍。 */
    fun refreshSchedule(context: Context): RefreshSchedule {
        val state = readState(context)
        val appearance = state?.optJSONObject("appearance") ?: JSONObject()
        val minutes = appearance.optInt("refreshIntervalMinutes", 15)
            .coerceAtLeast(15)
        return RefreshSchedule(
            enabled = appearance.optBoolean("autoRefresh", true),
            intervalMinutes = if (minutes >= 24 * 60) 24 * 60 else minutes,
            dailyHour = appearance.optInt("dailyRefreshHour", 7).coerceIn(0, 23),
            dailyMinute = appearance.optInt("dailyRefreshMinute", 0).coerceIn(0, 59),
        )
    }

    /**
     * 每次重绘都从状态里的未来条目重新选一条，这样倒计时结束后会自动
     * 跳到下一条，而不是一直停在"已过期"。
     */
    private fun liveContent(
        state: JSONObject?,
        locale: String,
        now: Long,
    ): WidgetContent {
        if (state == null) return emptyContent(locale)

        val countdowns = state.optJSONArray("countdowns")
        val events = state.optJSONArray("events")
        if (countdowns != null || events != null) {
            val countdown = firstFutureCountdown(countdowns, now)
            val event = firstActiveEvent(events, now)
            if (countdown != null) {
                val title = countdown.optString("title", "Toki")
                val subtitle = remainingText(
                    countdown.optLong("targetEpochMillis", 0L),
                    locale,
                    now,
                )
                val extra = if (event == null) {
                    ""
                } else {
                    val name = event.optString("title", "")
                    val time = event.optString("timeLabel", "")
                    if (locale.startsWith("en")) {
                        "Next: $name · $time"
                    } else {
                        "下一个：$name · $time"
                    }
                }
                return WidgetContent(true, title, subtitle, extra)
            }
            if (event != null) {
                return WidgetContent(
                    true,
                    text(locale, "下一个日程", "Next event"),
                    event.optString("title", ""),
                    event.optString("timeLabel", ""),
                )
            }
            return emptyContent(locale)
        }

        // 兼容旧版 widget_state.json：没有条目数组时退回原来的一行文本逻辑。
        if (!state.optBoolean("hasData", false)) return emptyContent(locale)
        val subtitle = if (state.optString("kind") == "countdown") {
            remainingText(
                state.optLong("targetEpochMillis", 0L),
                locale,
                now,
            )
        } else {
            state.optString("subtitle", "")
        }
        return WidgetContent(
            true,
            state.optString("title", "Toki"),
            subtitle,
            state.optString("extra", ""),
        )
    }

    private fun emptyContent(locale: String): WidgetContent = WidgetContent(
        false,
        "Toki",
        text(locale, "还没有日程", "Nothing scheduled"),
        text(locale, "打开应用添加", "Open Toki to add"),
    )

    private fun firstFutureCountdown(countdowns: org.json.JSONArray?, now: Long): JSONObject? {
        if (countdowns == null) return null
        for (index in 0 until countdowns.length()) {
            val item = countdowns.optJSONObject(index) ?: continue
            if (item.optLong("targetEpochMillis", 0L) > now) return item
        }
        return null
    }

    private fun firstActiveEvent(events: org.json.JSONArray?, now: Long): JSONObject? {
        if (events == null) return null
        for (index in 0 until events.length()) {
            val item = events.optJSONObject(index) ?: continue
            val end = item.optLong("endEpochMillis", item.optLong("startEpochMillis", 0L))
            if (end > now) return item
        }
        return null
    }

    private fun remainingText(target: Long, locale: String, now: Long): String {
        if (target <= 0L) return text(locale, "还没有日程", "Nothing scheduled")
        val remaining = target - now
        if (remaining <= 0L) {
            return text(locale, "已过期", "Already passed")
        }
        val totalMinutes = remaining / 60_000L
        val days = totalMinutes / (24 * 60)
        val hours = (totalMinutes % (24 * 60)) / 60
        val minutes = totalMinutes % 60
        return when {
            days > 0 -> if (locale.startsWith("en")) {
                "${days}d ${hours}h left"
            } else {
                "还有 ${days} 天 ${hours} 小时"
            }
            hours > 0 -> if (locale.startsWith("en")) {
                "${hours}h ${minutes}m left"
            } else {
                "还有 ${hours} 小时 ${minutes} 分"
            }
            else -> if (locale.startsWith("en")) {
                "${minutes} min left"
            } else {
                "还有 ${minutes} 分钟"
            }
        }
    }

    private fun localeOf(state: JSONObject?): String =
        state?.optString("locale", "zh")?.takeIf { it.isNotBlank() } ?: "zh"

    private fun text(locale: String, chinese: String, english: String): String =
        if (locale.startsWith("en")) english else chinese

    private fun clock(epochMillis: Long): String =
        SimpleDateFormat("HH:mm", Locale.getDefault()).format(Date(epochMillis))

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

    data class RefreshSchedule(
        val enabled: Boolean,
        val intervalMinutes: Int,
        val dailyHour: Int,
        val dailyMinute: Int,
    ) {
        val isDaily: Boolean get() = intervalMinutes >= 24 * 60
    }

    private data class WidgetContent(
        val hasData: Boolean,
        val title: String,
        val subtitle: String,
        val extra: String,
    )
}
