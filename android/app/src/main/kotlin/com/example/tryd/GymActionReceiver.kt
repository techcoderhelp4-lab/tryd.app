package tryd.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class GymActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.getStringExtra("action") ?: return
        MainActivity.gymWorkoutChannel?.invokeMethod("onAction", action)
    }
}
