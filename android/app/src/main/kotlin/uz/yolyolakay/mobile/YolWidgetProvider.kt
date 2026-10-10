package uz.yolyolakay.mobile

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.RemoteViews

/**
 * «YAQIN SAFAR» VIDJETI — bosh ekranda.
 *
 * Ma'lumotni ILOVA yozadi (`HomeWidgetBridge` → `MainActivity`), bu
 * yerda faqat chiziladi. Vidjet o'zi tarmoqqa CHIQMAYDI va tizim
 * taymeri bilan yangilanmaydi (`updatePeriodMillis="0"`) — sabab Dart
 * tomonidagi izohda.
 *
 * ⚠️ Matnlar bu yerda TARJIMA QILINMAYDI: til ilovada tanlanadi va
 * tayyor satr bo'lib keladi. Android resurslarida ikkinchi nusxa
 * saqlansa, ular ertaga ajralib ketardi.
 */
class YolWidgetProvider : AppWidgetProvider() {

    companion object {
        /** `MainActivity` bilan AYNAN bir xil bo'lishi shart. */
        const val PREFS = "yol_widget"

        /** Hamma vidjet nusxasini qayta chizadi. */
        fun refresh(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(
                android.content.ComponentName(context, YolWidgetProvider::class.java),
            )
            if (ids.isEmpty()) return
            YolWidgetProvider().onUpdate(context, manager, ids)
        }
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        val data = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

        val route = data.getString("route", "") ?: ""
        val whenText = data.getString("when", "") ?: ""
        val note = data.getString("note", "") ?: ""
        val empty = data.getString("empty", "") ?: ""
        val hasTrip = route.isNotEmpty()

        // Ilovani ochish — butun vidjet bosiladi. Ma'lumotsiz vidjet
        // ham «o'lik to'rtburchak» bo'lib qolmasligi kerak.
        val open = PendingIntent.getActivity(
            context,
            0,
            Intent(context, MainActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.yol_widget)

            views.setViewVisibility(R.id.widget_route, visibility(hasTrip))
            views.setViewVisibility(R.id.widget_when, visibility(hasTrip && whenText.isNotEmpty()))
            // Qo'shimcha qator (narx yoki bo'sh joy) bo'lmasa UMUMAN
            // chizilmaydi: bo'sh qator vidjetda «buzuq» bo'lib ko'rinadi.
            views.setViewVisibility(R.id.widget_note, visibility(hasTrip && note.isNotEmpty()))
            views.setViewVisibility(R.id.widget_empty, visibility(!hasTrip && empty.isNotEmpty()))

            views.setTextViewText(R.id.widget_route, route)
            views.setTextViewText(R.id.widget_when, whenText)
            views.setTextViewText(R.id.widget_note, note)
            views.setTextViewText(R.id.widget_empty, empty)

            views.setOnClickPendingIntent(R.id.widget_root, open)

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    private fun visibility(show: Boolean): Int = if (show) View.VISIBLE else View.GONE
}
