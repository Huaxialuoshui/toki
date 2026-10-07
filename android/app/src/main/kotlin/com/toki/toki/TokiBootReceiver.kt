package com.toki.toki

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/** 开机 / 应用更新后重新排期小组件刷新与常驻服务。 */
class TokiBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return
        if (action != Intent.ACTION_BOOT_COMPLETED &&
            action != Intent.ACTION_MY_PACKAGE_REPLACED
        ) {
            return
        }
        TokiWidgetProvider.scheduleRefresh(context)
        if (TokiBackgroundService.isEnabled(context)) {
            TokiBackgroundService.start(context)
        }
    }
}
