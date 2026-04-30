package tryd.app

import android.content.Intent
import android.os.Build
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {

    companion object {
        var workoutChannel: MethodChannel? = null
        var gymWorkoutChannel: MethodChannel? = null
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        WorkoutNotificationHelper.createChannel(applicationContext)
        setupHealthChannel(flutterEngine)
        setupWorkoutNotifChannel(flutterEngine)
        setupGymWorkoutChannel(flutterEngine)
        handleNotificationIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleNotificationIntent(intent)
    }

    private fun handleNotificationIntent(intent: Intent?) {
        val tab = intent?.getIntExtra("open_tab", -1) ?: -1
        if (tab >= 0) {
            workoutChannel?.invokeMethod("openTab", tab)
        }
    }

    // ── Workout notification channel ─────────────────────────────────────────

    private fun setupWorkoutNotifChannel(flutterEngine: FlutterEngine) {
        workoutChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "tryd.app/workout_notification",
        )
        workoutChannel?.setMethodCallHandler { call, result ->
            val args = call.arguments as? Map<*, *>
            when (call.method) {
                "show", "update" -> {
                    if (args != null) {
                        WorkoutNotificationHelper.show(
                            context = applicationContext,
                            elapsedSeconds = (args["elapsedSeconds"] as? Int) ?: 0,
                            distanceKm = (args["distanceKm"] as? Double) ?: 0.0,
                            pacePerKm = (args["pacePerKm"] as? Double) ?: 0.0,
                            calories = (args["calories"] as? Double) ?: 0.0,
                            isPaused = (args["isPaused"] as? Boolean) ?: false,
                        )
                    }
                    result.success(null)
                }
                "dismiss" -> {
                    WorkoutNotificationHelper.dismiss(applicationContext)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    // ── Gym workout notification channel ────────────────────────────────────

    private fun setupGymWorkoutChannel(flutterEngine: FlutterEngine) {
        gymWorkoutChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "tryd.app/gym_workout_notification",
        )
        gymWorkoutChannel?.setMethodCallHandler { call, result ->
            val args = call.arguments as? Map<*, *>
            when (call.method) {
                "show", "update" -> {
                    if (args != null) {
                        GymNotificationHelper.show(
                            context = applicationContext,
                            phase = (args["phase"] as? String) ?: "Work",
                            currentRound = (args["currentRound"] as? Int) ?: 1,
                            totalRounds = (args["totalRounds"] as? Int) ?: 1,
                            currentExercise = (args["currentExercise"] as? Int) ?: 1,
                            totalExercises = (args["totalExercises"] as? Int) ?: 1,
                            remainingSeconds = (args["remainingSeconds"] as? Int) ?: 0,
                            isPaused = (args["isPaused"] as? Boolean) ?: false,
                        )
                    }
                    result.success(null)
                }
                "dismiss" -> {
                    GymNotificationHelper.dismiss(applicationContext)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    // ── Health Connect channel ───────────────────────────────────────────────

    private fun setupHealthChannel(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "tryd.app/health_connect")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isHealthConnectAvailable" -> {
                        try {
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                                result.success(true)
                            } else {
                                val packageName = "com.google.android.apps.healthdata"
                                val info = try {
                                    packageManager.getPackageInfo(packageName, android.content.pm.PackageManager.GET_SERVICES)
                                } catch (e: Exception) {
                                    null
                                }

                                if (info == null || info.applicationInfo?.enabled == false) {
                                    result.success(false)
                                    return@setMethodCallHandler
                                }

                                val actions = listOf(
                                    "androidx.health.ACTION_BIND_HEALTH_DATA_SERVICE",
                                    "androidx.health.platform.client.ACTION_BIND_HEALTH_DATA_SERVICE"
                                )

                                var canBind = false
                                for (action in actions) {
                                    val intent = Intent(action).setPackage(packageName)
                                    val dummyConn = object : android.content.ServiceConnection {
                                        override fun onServiceConnected(name: android.content.ComponentName?, binder: android.os.IBinder?) {}
                                        override fun onServiceDisconnected(name: android.content.ComponentName?) {}
                                    }
                                    val bound = try {
                                        bindService(intent, dummyConn, android.content.Context.BIND_AUTO_CREATE)
                                    } catch (e: Exception) {
                                        false
                                    }
                                    if (bound) {
                                        canBind = true
                                        try { unbindService(dummyConn) } catch (_: Exception) {}
                                        break
                                    }
                                }

                                result.success(canBind)
                            }
                        } catch (e: Exception) {
                            result.success(false)
                        }
                    }
                    "openHealthConnectSettings" -> {
                        try {
                            val action = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                                "android.health.connect.action.HEALTH_HOME_SETTINGS"
                            } else {
                                "health.connect.action.HEALTH_HOME_SETTINGS"
                            }
                            val intent = Intent(action).apply {
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                if (Build.VERSION.SDK_INT < Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                                    setPackage("com.google.android.apps.healthdata")
                                }
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            try {
                                val intent = Intent(Intent.ACTION_VIEW).apply {
                                    data = android.net.Uri.parse("market://details?id=com.google.android.apps.healthdata")
                                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                }
                                startActivity(intent)
                                result.success(false)
                            } catch (e2: Exception) {
                                result.error("UNAVAILABLE", e2.message, null)
                            }
                        }
                    }
                    "openHealthConnectPermissions" -> {
                        try {
                            val action = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                                "android.health.connect.action.MANAGE_HEALTH_PERMISSIONS"
                            } else {
                                "androidx.health.ACTION_MANAGE_HEALTH_PERMISSIONS"
                            }
                            val intent = Intent(action).apply {
                                putExtra("android.intent.extra.PACKAGE_NAME", packageName)
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                if (Build.VERSION.SDK_INT < Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                                    setPackage("com.google.android.apps.healthdata")
                                }
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            try {
                                val action = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                                    "android.health.connect.action.HEALTH_HOME_SETTINGS"
                                } else {
                                    "health.connect.action.HEALTH_HOME_SETTINGS"
                                }
                                val intent = Intent(action).apply {
                                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                                        setPackage("com.google.android.apps.healthdata")
                                    }
                                }
                                startActivity(intent)
                                result.success(true)
                            } catch (e2: Exception) {
                                result.error("UNAVAILABLE", e2.message, null)
                            }
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
