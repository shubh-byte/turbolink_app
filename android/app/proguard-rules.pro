# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# TurboLink Method Channels
-keep class com.turbolink.turbolink_app.** { *; }

# Suppress warnings for missing Play Core classes (referenced by Flutter engine)
-dontwarn com.google.android.play.core.**
