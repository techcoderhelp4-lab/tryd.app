package tryd.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class WorkoutActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.getStringExtra("action") ?: return
        MainActivity.workoutChannel?.invokeMethod("onAction", action)
    }
}
