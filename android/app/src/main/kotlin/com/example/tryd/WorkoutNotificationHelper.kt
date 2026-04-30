package tryd.app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.SystemClock
import android.view.View
import android.widget.RemoteViews
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat

object WorkoutNotificationHelper {

    const val NOTIFICATION_ID = 8881
    const val CHANNEL_ID = "tryd_workout_v5"
    private const val CHANNEL_ID_OLD = "tryd_workout_v4"
    private const val ACTION_WORKOUT = "tryd.app.WORKOUT_ACTION"

    fun createChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        // Delete old channel so Android picks up new importance settings
        nm.deleteNotificationChannel(CHANNEL_ID_OLD)

        if (nm.getNotificationChannel(CHANNEL_ID) != null) return
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Workout Tracking",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "Live workout stats on the lock screen"
            setSound(null, null)
            enableVibration(false)
            setShowBadge(true)
            lockscreenVisibility = NotificationCompat.VISIBILITY_PUBLIC
        }
        nm.createNotificationChannel(channel)
    }

    fun show(
        context: Context,
        elapsedSeconds: Int,
        distanceKm: Double,
        pacePerKm: Double,
        calories: Double,
        isPaused: Boolean,
    ) {
        val collapsed = buildViews(context, elapsedSeconds, distanceKm, pacePerKm, isPaused,
            layoutId = R.layout.notification_workout_collapsed)
        val expanded = buildViews(context, elapsedSeconds, distanceKm, pacePerKm, isPaused,
            layoutId = R.layout.notification_workout)
        val openPendingIntent = openAppIntent(context)

        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification_workout)
            .setCustomContentView(collapsed)
            .setCustomBigContentView(expanded)
            .setStyle(NotificationCompat.DecoratedCustomViewStyle())
            .setContentIntent(openPendingIntent)
            .setOngoing(true)
            .setSilent(true)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)
            .setCategory(NotificationCompat.CATEGORY_WORKOUT)
            .build()

        try {
            NotificationManagerCompat.from(context).notify(NOTIFICATION_ID, notification)
        } catch (_: SecurityException) {
            // POST_NOTIFICATIONS not granted
        }
    }

    fun dismiss(context: Context) {
        NotificationManagerCompat.from(context).cancel(NOTIFICATION_ID)
    }

    private fun buildViews(
        context: Context,
        elapsedSeconds: Int,
        distanceKm: Double,
        pacePerKm: Double,
        isPaused: Boolean,
        layoutId: Int = R.layout.notification_workout,
    ): RemoteViews {
        val views = RemoteViews(context.packageName, layoutId)

        views.setTextViewText(R.id.notif_distance, "%.2f".format(distanceKm))
        views.setTextViewText(R.id.notif_pace, formatPace(pacePerKm))

        // Chronometer base: elapsedRealtime minus how many ms into the workout we are.
        // Auto-ticks every second when started=true → fixes the +5s lag completely.
        val base = SystemClock.elapsedRealtime() - elapsedSeconds * 1000L
        views.setChronometer(R.id.notif_time, base, null, !isPaused)

        // Toggle pause / resume button visibility
        views.setViewVisibility(R.id.btn_pause, if (isPaused) View.GONE else View.VISIBLE)
        views.setViewVisibility(R.id.btn_resume, if (isPaused) View.VISIBLE else View.GONE)

        views.setOnClickPendingIntent(R.id.btn_pause, actionIntent(context, "pause", 101))
        views.setOnClickPendingIntent(R.id.btn_resume, actionIntent(context, "resume", 102))
        views.setOnClickPendingIntent(R.id.btn_stop, actionIntent(context, "finish", 103))

        return views
    }

    private fun openAppIntent(context: Context): PendingIntent {
        val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            ?.apply {
                flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra("open_tab", 1) // running screen tab
            }
            ?: Intent()
        return PendingIntent.getActivity(
            context, 0, intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
    }

    private fun actionIntent(context: Context, action: String, requestCode: Int): PendingIntent {
        val intent = Intent(ACTION_WORKOUT).apply {
            setPackage(context.packageName)
            putExtra("action", action)
        }
        return PendingIntent.getBroadcast(
            context, requestCode, intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
    }

    private fun formatPace(pacePerKm: Double): String {
        if (pacePerKm <= 0 || pacePerKm.isInfinite() || pacePerKm.isNaN()) return "--:--"
        val m = pacePerKm.toInt()
        val s = ((pacePerKm - m) * 60).toInt()
        return "$m:${s.toString().padStart(2, '0')}"
    }

    private fun formatDuration(totalSeconds: Int): String {
        val h = totalSeconds / 3600
        val m = (totalSeconds % 3600) / 60
        val s = totalSeconds % 60
        return if (h > 0) {
            "$h:${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}"
        } else {
            "${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}"
        }
    }
}
