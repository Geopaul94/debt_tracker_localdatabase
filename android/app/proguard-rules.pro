# Flutter specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Google Mobile Ads - Essential for monetization
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**
-keep class com.google.ads.** { *; }
-keep class com.google.android.gms.ads.** { *; }

# SQLite - Core database functionality
-keep class androidx.sqlite.** { *; }
-keep class android.database.** { *; }
-keep class org.sqlite.** { *; }

# Shared Preferences - Essential for app state
-keep class android.content.SharedPreferences** { *; }

# Biometric Authentication
-keep class androidx.biometric.** { *; }
-keep class android.hardware.fingerprint.** { *; }

# WorkManager for background tasks
-keep class androidx.work.** { *; }
-keep class android.arch.work.** { *; }

# Remove all logging in release builds for smaller APK
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int i(...);
    public static int w(...);
    public static int d(...);
    public static int e(...);
    public static int wtf(...);
}

# Remove print statements
-assumenosideeffects class java.io.PrintStream {
    public void println(%);
    public void print(%);
}

# Remove debug information in release
-assumenosideeffects class kotlin.jvm.internal.Intrinsics {
    static void checkParameterIsNotNull(java.lang.Object, java.lang.String);
    static void checkNotNullParameter(java.lang.Object, java.lang.String);
    static void checkExpressionValueIsNotNull(java.lang.Object, java.lang.String);
    static void checkNotNullExpressionValue(java.lang.Object, java.lang.String);
    static void checkReturnedValueIsNotNull(java.lang.Object, java.lang.String);
    static void checkFieldIsNotNull(java.lang.Object, java.lang.String);
}

# Optimization settings
-allowaccessmodification
-mergeinterfacesaggressively
-overloadaggressively
-repackageclasses ''

# Optimization passes
-optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*
-optimizationpasses 5

# Keep your application class and core components
-keep class com.geo.debit_tracker.** { *; }

# Keep native methods
-keepclassmembers class * {
    native <methods>;
}

# Keep Parcelable implementations
-keepclassmembers class * implements android.os.Parcelable {
    static ** CREATOR;
}

# Keep enum classes
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Keep required Google Play Services classes
-keep class com.google.android.gms.** { *; }
-keep interface com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Keep AndroidX components
-keep class androidx.** { *; }
-keep interface androidx.** { *; }
-dontwarn androidx.**

# Keep Play Core for app updates
-keep class com.google.android.play.core.** { *; }

# Keep attributes for debugging and reflection
-keepattributes SourceFile,LineNumberTable,Signature,InnerClasses,EnclosingMethod
-renamesourcefileattribute SourceFile

# Keep annotations
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod

# Keep essential attributes
-keepattributes Signature,RuntimeVisibleAnnotations,AnnotationDefault

# Optimize method calls and field access
-assumevalues class android.os.Build$VERSION {
    int SDK_INT return 21..34;
}

# Keep resource classes
-keep class **.R
-keep class **.R$* {
    <fields>;
}

# Flutter specific optimizations
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.embedding.engine.** { *; }
-keep class io.flutter.plugin.common.** { *; }

# Remove Flutter debug information
-assumenosideeffects class io.flutter.Log {
    public static void v(...);
    public static void d(...);
    public static void i(...);
    public static void w(...);
    public static void e(...);
}

# Keep Google Sign-In classes
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.gms.common.** { *; }

# Keep WorkManager classes
-keep class androidx.work.impl.** { *; }
-keep class androidx.work.WorkManager { *; }

# Keep Biometric classes
-keep class androidx.biometric.BiometricManager { *; }
-keep class androidx.biometric.BiometricPrompt { *; }

# Keep AdMob specific classes
-keep class com.google.android.gms.ads.MobileAds { *; }
-keep class com.google.android.gms.ads.AdRequest { *; }
-keep class com.google.android.gms.ads.AdView { *; }
-keep class com.google.android.gms.ads.InterstitialAd { *; }
-keep class com.google.android.gms.ads.rewarded.RewardedAd { *; }

# Remove warnings for better build
-dontnote **
-dontwarn **
-ignorewarnings 