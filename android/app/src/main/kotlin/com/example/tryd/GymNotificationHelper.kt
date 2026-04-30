package tryd.app

import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.RemoteViews
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat

object GymNotificationHelper {

    // Same ID as the foreground service so our custom view replaces the plain one.
    const val NOTIFICATION_ID = 8883
    const val CHANNEL_ID = "tryd_workout_v5"
    private const val ACTION_GYM = "tryd.app.GYM_ACTION"

    fun show(
        context: Context,
        phase: String,
        currentRound: Int,
        totalRounds: Int,
        currentExercise: Int,
        totalExercises: Int,
        remainingSeconds: Int,
        isPaused: Boolean,
    ) {
        val collapsed = buildViews(
            context, phase, currentRound, totalRounds,
            currentExercise, totalExercises, remainingSeconds, isPaused,
            layoutId = R.layout.notification_gym_workout_collapsed,
        )
        val expanded = buildViews(
            context, phase, currentRound, totalRounds,
            currentExercise, totalExercises, remainingSeconds, isPaused,
            layoutId = R.layout.notification_gym_workout,
        )

        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification_workout)
            .setCustomContentView(collapsed)
            .setCustomBigContentView(expanded)
            .setStyle(NotificationCompat.DecoratedCustomViewStyle())
            .setContentIntent(openAppIntent(context))
            .setOngoing(true)
            .setSilent(true)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)
            .setCategory(NotificationCompat.CATEGORY_WORKOUT)
            .build()

        try {
            NotificationManagerCompat.from(context).notify(NOTIFICATION_ID, notification)
        } catch (_: SecurityException) {}
    }

    fun dismiss(context: Context) {
        NotificationManagerCompat.from(context).cancel(NOTIFICATION_ID)
    }

    private fun buildViews(
        context: Context,
        phase: String,
        currentRound: Int,
        totalRounds: Int,
        currentExercise: Int,
        totalExercises: Int,
        remainingSeconds: Int,
        isPaused: Boolean,
        layoutId: Int,
    ): RemoteViews {
        val views = RemoteViews(context.packageName, layoutId)

        views.setTextViewText(R.id.notif_phase, phase.uppercase())
        views.setTextViewText(R.id.notif_round, "$currentRound/$totalRounds")
        views.setTextViewText(R.id.notif_remaining, formatTime(remainingSeconds))

        views.setViewVisibility(R.id.btn_pause,  if (isPaused) View.GONE    else View.VISIBLE)
        views.setViewVisibility(R.id.btn_resume, if (isPaused) View.VISIBLE else View.GONE)

        views.setOnClickPendingIntent(R.id.btn_pause,  actionIntent(context, "pause",  201))
        views.setOnClickPendingIntent(R.id.btn_resume, actionIntent(context, "resume", 202))
        views.setOnClickPendingIntent(R.id.btn_stop,   actionIntent(context, "finish", 203))

        return views
    }

    private fun formatTime(seconds: Int): String {
        val m = seconds / 60
        val s = seconds % 60
        return "${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}"
    }

    private fun openAppIntent(context: Context): PendingIntent {
        val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            ?.apply {
                flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra("open_tab", 3)
            } ?: Intent()
        return PendingIntent.getActivity(
            context, 10, intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
    }

    private fun actionIntent(context: Context, action: String, requestCode: Int): PendingIntent {
        val intent = Intent(ACTION_GYM).apply {
            setPackage(context.packageName)
            putExtra("action", action)
        }
        return PendingIntent.getBroadcast(
            context, requestCode, intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
    }
}
