# Keep Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Keep Firestore
-keep class io.grpc.** { *; }
-keepnames class io.grpc.** { *; }
-dontwarn io.grpc.**

# Keep Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep Google Play Core (THIS IS THE MISSING PART)
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**