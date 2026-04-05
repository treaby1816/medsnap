# ProGuard configuration for the Flutter application.

# Firebase & Firestore: Critical for Auth and DB performance 
-keep class com.google.firebase.** { *; }
-keep interface com.google.firebase.** { *; }

# Flutter Engine: Essential for app stability
-keep class io.flutter.** { *; }

# Lottie Animations: Protects visual "originality" and smooth movement
-keep class com.airbnb.lottie.** { *; }

# Paystack & Payments: Ensures secure and reliable transaction logic
-keep class com.paystack.plus.** { *; }
-dontwarn com.paystack.plus.**

# Google Fonts & UI: Keeps the premium Inter/Outfit aesthetic intact
-keep class com.google.android.gms.fonts.** { *; }
-keep class com.google.android.gms.common.** { *; }

# General Stability: Avoids warnings from mixed library versions
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**
-dontnote **
