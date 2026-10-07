package com.toki.toki

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.IBinder
import android.provider.Settings
import androidx.core.app.NotificationCompat

/**
 * 可选的"常驻后台"服务。
 *
 * Android 8+ 要求前台服务必须显示一条通知；这里用 **最低重要性 + 静音** 的渠道，
 * 视觉上几乎不打扰（不会响、不会弹横幅），用来降低提醒与小组件刷新被系统杀死进程的概率。
 * 用户在设置里可以随时关闭；关掉后提醒仍然由 AlarmManager 负责（进程被杀也会响）。
 */
class TokiBackgroundService : Service() {

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startForeground(NOTIFICATION_ID, buildNotification(this))
        return START_STICKY
    }

    companion object {
        private const val CHANNEL_ID = "toki_background"
        private const val NOTIFICATION_ID = 7301
        private const val PREFS = "toki_native"
        private const val KEY_ENABLED = "backgroundServiceEnabled"

        fun isEnabled(context: Context): Boolean =
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .getBoolean(KEY_ENABLED, false)

        fun setEnabled(context: Context, enabled: Boolean) {
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .edit()
                .putBoolean(KEY_ENABLED, enabled)
                .apply()
            if (enabled) start(context) else stop(context)
        }

        fun start(context: Context) {
            val intent = Intent(context, TokiBackgroundService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun stop(context: Context) {
            context.stopService(Intent(context, TokiBackgroundService::class.java))
        }

        private fun buildNotification(context: Context): Notification {
            val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val channel = NotificationChannel(
                    CHANNEL_ID,
                    "Toki 后台运行",
                    NotificationManager.IMPORTANCE_MIN,
                ).apply {
                    description = "让提醒与桌面小组件保持新鲜，不会发出声音"
                    setShowBadge(false)
                    enableVibration(false)
                }
                manager.createNotificationChannel(channel)
            }

            val openApp = PendingIntent.getActivity(
                context,
                0,
                Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                },
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            return NotificationCompat.Builder(context, CHANNEL_ID)
                .setContentTitle("Toki 正在后台待命")
                .setContentText("提醒与桌面小组件会保持新鲜")
                .setSmallIcon(R.drawable.ic_widget_timer_outlined)
                .setPriority(NotificationCompat.PRIORITY_MIN)
                .setSilent(true)
                .setOngoing(true)
                .setContentIntent(openApp)
                .build()
        }

        /** 申请把应用加入电池优化白名单（系统会弹一个确认框）。 */
        fun requestIgnoreBatteryOptimizations(context: Context): Boolean {
            if (isIgnoringBatteryOptimizations(context)) return true
            val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                data = Uri.parse("package:${context.packageName}")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            return try {
                context.startActivity(intent)
                true
            } catch (error: Exception) {
                // 个别系统不允许直接跳这个页面，退回应用详情页。
                try {
                    context.startActivity(
                        Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                            data = Uri.parse("package:${context.packageName}")
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        },
                    )
                    true
                } catch (ignored: Exception) {
                    false
                }
            }
        }

        fun isIgnoringBatteryOptimizations(context: Context): Boolean {
            val manager = context.getSystemService(Context.POWER_SERVICE)
                as android.os.PowerManager
            return manager.isIgnoringBatteryOptimizations(context.packageName)
        }
    }
}
