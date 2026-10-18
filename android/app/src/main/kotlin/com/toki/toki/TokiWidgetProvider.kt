package com.toki.toki

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import java.util.Calendar
import kotlin.math.max

/**
 * Toki 的桌面小组件。
 *
 * 数据与外观都由 Flutter 侧写到 `widget_state.json`；这里只负责
 * 1) 渲染（见 [TokiWidgetRenderer]）；
 * 2) 定时刷新：按设置里的频率 / 每天固定时间唤醒自己一次，重算倒计时文字
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
            // 配置可能刚变过（例如刚选完刷新频率），重绘后立刻按新设置排期。
            scheduleRefresh(context)
        }

        /** 按 Flutter 侧写入的配置排期；系统在低电模式下可能推迟，属于正常现象。 */
        fun scheduleRefresh(context: Context) {
            val manager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val pending = refreshPendingIntent(context)
            manager.cancel(pending)
            val schedule = TokiWidgetRenderer.refreshSchedule(context)
            if (!schedule.enabled) return

            if (schedule.isDaily) {
                val next = nextDailyTrigger(
                    schedule.dailyHour,
                    schedule.dailyMinute,
                )
                scheduleOneShot(manager, next, pending)
                return
            }

            val intervalMs = max(15, schedule.intervalMinutes) * 60_000L
            val first = System.currentTimeMillis() + intervalMs
            try {
                manager.setInexactRepeating(
                    AlarmManager.RTC,
                    first,
                    intervalMs,
                    pending,
                )
            } catch (error: SecurityException) {
                // 没有权限时退化成"打开应用时才刷新"。
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

        private fun nextDailyTrigger(hour: Int, minute: Int): Long {
            val now = Calendar.getInstance()
            val next = (now.clone() as Calendar).apply {
                set(Calendar.HOUR_OF_DAY, hour)
                set(Calendar.MINUTE, minute)
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
                if (!after(now)) add(Calendar.DAY_OF_YEAR, 1)
            }
            return next.timeInMillis
        }

        private fun scheduleOneShot(
            manager: AlarmManager,
            triggerAtMillis: Long,
            pending: PendingIntent,
        ) {
            try {
                val canExact = Build.VERSION.SDK_INT < Build.VERSION_CODES.S ||
                    manager.canScheduleExactAlarms()
                if (canExact && Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    manager.setExactAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP,
                        triggerAtMillis,
                        pending,
                    )
                } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    manager.setAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP,
                        triggerAtMillis,
                        pending,
                    )
                } else {
                    manager.set(AlarmManager.RTC_WAKEUP, triggerAtMillis, pending)
                }
            } catch (error: SecurityException) {
                // 精确闹钟被系统禁用时，用普通闹钟排下一次。
                manager.set(AlarmManager.RTC, triggerAtMillis, pending)
            }
        }
    }
}
