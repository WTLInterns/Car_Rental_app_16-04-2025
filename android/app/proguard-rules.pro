# ===============================
# Flutter Wrapper
# ===============================
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Dart
-keep class androidx.lifecycle.DefaultLifecycleObserver

# ===============================
# Google Maps
# ===============================
-keep class com.google.android.gms.maps.** { *; }
-keep interface com.google.android.gms.maps.** { *; }
-keep class com.google.android.gms.location.** { *; }
-keep interface com.google.android.gms.location.** { *; }

# ===============================
# Google Play Core
# ===============================
-keep class com.google.android.play.core.** { *; }
-keep interface com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Google Play App Update
-keep class com.google.android.play.core.appupdate.** { *; }
-keep interface com.google.android.play.core.appupdate.** { *; }

# Google Play Feature Delivery
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }

# ===============================
# Facebook SDK
# ===============================
-keep class com.facebook.** { *; }
-keep interface com.facebook.** { *; }
-keep enum com.facebook.**
-keepattributes Signature

# Facebook App Events
-keep class com.facebook.appevents.** { *; }
-keep class com.facebook.FacebookSdk { *; }

# ===============================
# Google Play Services Advertising ID
# ===============================
-keep class com.google.android.gms.ads.identifier.** { *; }
-keep interface com.google.android.gms.ads.identifier.** { *; }
-keep class com.google.android.gms.common.** { *; }
-keep class com.google.android.gms.tasks.** { *; }
-dontwarn com.google.android.gms.ads.identifier.**
-dontwarn com.google.android.gms.common.**

# Advertising ID Permission
-keepattributes *Annotation*
-keep class * extends java.lang.annotation.Annotation { *; }

# ===============================
# Location Services
# ===============================
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# ===============================
# Geolocator Plugin
# ===============================
-keep class com.baseflow.geolocator.** { *; }
-keep interface com.baseflow.geolocator.** { *; }

# Permission Handler
-keep class com.baseflow.permissionhandler.** { *; }
-keep interface com.baseflow.permissionhandler.** { *; }

# ===============================
# HTTP and Network
# ===============================
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**

# Gson
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# ===============================
# Your App's Model Classes
# ===============================
-keep class com.yourcompany.worldtriplink.** { *; }

# ===============================
# Image Loading (cached_network_image, etc.)
# ===============================
-keep class com.davemorrissey.labs.subscaleview.** { *; }

# Shared Preferences
-keep class androidx.preference.** { *; }

# SQLite (sqflite)
-keep class org.sqlite.** { *; }
-keep class org.sqlite.database.** { *; }

# WebView
-keep class android.webkit.** { *; }

# ===============================
# Prevent obfuscation of native methods
# ===============================
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep custom exceptions
-keep public class * extends java.lang.Exception

# Keep Parcelable implementations
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Keep Serializable classes
-keepnames class * implements java.io.Serializable
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Keep enum classes
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Remove logging in release builds
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int i(...);
    public static int w(...);
    public static int d(...);
    public static int e(...);
}

# Keep line numbers for debugging stack traces
-keepattributes SourceFile,LineNumberTable

# Renaming
-repackageclasses ''
-allowaccessmodification
-optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*

# ===============================
# Razorpay SDK Fix
# ===============================
-keep class com.razorpay.** { *; }
-dontwarn com.razorpay.**
-keep class proguard.annotation.Keep
-keep class proguard.annotation.KeepClassMembers
