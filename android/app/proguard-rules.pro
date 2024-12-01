# Google Play Core ve SplitCompat için
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Tink (Şifreleme kütüphanesi) için
-keep class com.google.crypto.tink.** { *; }
-dontwarn com.google.crypto.tink.**

# Error Prone Annotations için
-keep class com.google.errorprone.annotations.** { *; }
-dontwarn com.google.errorprone.annotations.**

# Java Annotations için
-keep class javax.annotation.** { *; }
-dontwarn javax.annotation.**

# Google ProtoBuf için
-keep class com.google.protobuf.** { *; }
-dontwarn com.google.protobuf.**

# FlutterSecureStorage
-keep class io.flutter.plugins.fluttersecurestorage.** { *; }
-dontwarn io.flutter.plugins.fluttersecurestorage.**

# SQLCipher
-keep class net.sqlcipher.** { *; }
-dontwarn net.sqlcipher.**

# Eksik sınıfı koru
-keep class com.google.j2objc.annotations.** { *; }
-dontwarn com.google.j2objc.annotations.**
-keep public class io.flutter.** { *; }
-keep public class androidx.** { *; }
-keep public class com.google.** { *; }
-keepattributes *Annotation*
-dontwarn io.flutter.embedding.**
-dontwarn androidx.**

-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
