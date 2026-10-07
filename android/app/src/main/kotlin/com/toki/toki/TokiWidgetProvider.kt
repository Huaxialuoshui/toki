package com.toki.toki

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build

/**
 * Toki 的桌面小组件。
 *
 * 数据与外观都由 Flutter 侧写到 `widget_state.json`；这里只负责
 * 1) 渲染（见 [TokiWidgetRenderer]）；
 * 2) 定时刷新：用 AlarmManager 每 15 分钟唤醒自己一次，让倒计时文字保持新鲜
 *    （不依赖应用进程常驻，也不显示任何通知）。
 */
class TokiWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        super.onUpdate(context, appWidgetManager, appWidgetIds)
        val views = TokiWidgetRenderer.render(context)
        for (id in appWidgetIds) {
            appWidgetManager.updateAppWidget(id, views)
        }
        scheduleRefresh(context)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == ACTION_REFRESH) {
            updateAll(context)
            scheduleRefresh(context)
        }
    }

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        scheduleRefresh(context)
    }

    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        cancelRefresh(context)
    }

    companion object {
        const val ACTION_REFRESH = "com.toki.toki.WIDGET_REFRESH"
        private const val REFRESH_INTERVAL_MS = 15 * 60 * 1000L

        /** 立刻重绘所有小组件（Flutter 侧数据变化时调用）。 */
        fun updateAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(
                ComponentName(context, TokiWidgetProvider::class.java),
            )
            if (ids.isEmpty()) return
            val views = TokiWidgetRenderer.render(context)
            for (id in ids) {
                manager.updateAppWidget(id, views)
            }
        }

        /** 排一个 15 分钟的重复唤醒；系统在低电模式下可能推迟，属于正常现象。 */
        fun scheduleRefresh(context: Context) {
            val manager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val pending = refreshPendingIntent(context)
            val first = System.currentTimeMillis() + REFRESH_INTERVAL_MS
            try {
                manager.setInexactRepeating(
                    AlarmManager.RTC,
                    first,
                    REFRESH_INTERVAL_MS,
                    pending,
                )
            } catch (error: SecurityException) {
                // 没有精确闹钟权限时退化成"打开应用时才刷新"。
            }
        }

        fun cancelRefresh(context: Context) {
            val manager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            manager.cancel(refreshPendingIntent(context))
        }

        private fun refreshPendingIntent(context: Context): PendingIntent {
            val intent = Intent(context, TokiWidgetProvider::class.java).apply {
                action = ACTION_REFRESH
            }
            return PendingIntent.getBroadcast(
                context,
                2,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }
    }
}
