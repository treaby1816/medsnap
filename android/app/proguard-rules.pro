# VailMeds v2 Security & Obfuscation ProGuard Rules

# 1. Enable Hardened Obfuscation
-repackageclasses ''
-allowaccessmodification
-printmapping mapping.txt

# 2. Firebase & Core Google Services
-keep class com.google.firebase.** { *; }
-keep interface com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# 3. Flutter Engine & Plugins (Essential)
-keep class io.flutter.** { *; }
-keep class com.it_nomads.fluttersecurestorage.** { *; }
-keep class io.flutter.plugins.** { *; }

# 4. Security SDKs (Root checking & Screen protection)
-keep class com.gantix.rootcatcher.** { *; }
-keep class com.screenprotector.** { *; }

# 5. UI & Third-Party SDKs
-keep class com.airbnb.lottie.** { *; }
-keep class com.paystack.plus.** { *; }
-dontwarn com.paystack.plus.**

# 6. General Stability & Suppression
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**
-dontnote **
-dontwarn com.google.android.gms.**

