# Keep all classes and members related to Razorpay
-keep class com.razorpay.** { *; }
-dontwarn com.razorpay.**

# Keep Google Pay (nbu.paisa) classes referenced by Razorpay
-keep class com.google.android.apps.nbu.paisa.inapp.client.api.** { *; }
-dontwarn com.google.android.apps.nbu.paisa.inapp.client.api.**

# Keep ProGuard annotations (unchanged)
-keep class proguard.annotation.Keep { *; }
-keep class proguard.annotation.KeepClassMembers { *; }

# Keep all members annotated with @Keep (unchanged)
-keep @proguard.annotation.Keep class * { *; }
-keep @proguard.annotation.KeepClassMembers class * { *; }

# Prevent warnings for ProGuard annotations (unchanged)
-dontwarn proguard.annotation.**