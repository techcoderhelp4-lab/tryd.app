## Flutter-specific ProGuard rules

# Keep Flutter engine
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }

# Keep plugin registrant
-keep class io.flutter.plugins.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Gson / JSON
-keep class com.google.gson.** { *; }
-keepattributes Signature
-keepattributes *Annotation*

# Health Connect
-keep class androidx.health.connect.** { *; }
-keep class androidx.health.** { *; }

# Geolocator
-keep class com.baseflow.geolocator.** { *; }

# Play Core (Fixes the R8 Missing Class error)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# Flutter Deferred Components
-dontwarn io.flutter.embedding.engine.deferredcomponents.**

# Material Icons (Prevent disappearance during aggressive shrinking)
-keep class androidx.core.role.** { *; }
-keep class com.google.android.material.** { *; }
-keep interface com.google.android.material.** { *; }
-dontwarn com.google.android.material.**

# Keep SharedPreferences
-keep class android.content.SharedPreferences { *; }

# Don't warn about missing classes in optional deps
-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**

# Socket.io rules
-keep class io.socket.** { *; }
-keep class io.socket.engineio.client.** { *; }
-keep class io.socket.client.** { *; }
-keep class okhttp3.** { *; }
-keep class org.json.** { *; }
-dontwarn okhttp3.**
-dontwarn io.socket.**
-dontwarn io.socket.client.Manager
-dontwarn io.socket.client.Socket
-dontwarn io.socket.engineio.client.Socket
-dontwarn io.socket.engineio.client.Transport
-dontwarn io.socket.engineio.client.transports.WebSocket
-dontwarn io.socket.engineio.client.transports.Polling
-dontwarn io.socket.engineio.client.transports.PollingXHR
-dontwarn io.socket.engineio.client.transports.PollingXHR$Request
-dontwarn io.socket.engineio.client.transports.PollingXHR$Request$1
-dontwarn io.socket.engineio.server.**
-dontwarn io.socket.client.Manager$*
-dontwarn io.socket.client.Socket$*
-dontwarn io.socket.engineio.client.Socket$*
-dontwarn io.socket.engineio.client.Transport$*
-dontwarn io.socket.engineio.client.transports.WebSocket$*
-dontwarn io.socket.engineio.client.transports.Polling$*
-dontwarn io.socket.engineio.client.transports.PollingXHR$*
-dontwarn io.socket.global.**
-dontwarn io.socket.has_binary.**
-dontwarn io.socket.parser.**
-dontwarn io.socket.thread.**
-dontwarn io.socket.utf8.**
-dontwarn io.socket.yeast.**
-dontwarn io.socket.backo.**
