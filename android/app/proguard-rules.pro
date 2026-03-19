# ProGuard rules for AutoGestion Pro

# No fallar por clases faltantes (R8)
-ignorewarnings

# Mantener atributos de código fuente y números de línea para debugging
-keepattributes SourceFile,LineNumberTable

# Ocultar el nombre del archivo fuente original
-renamesourcefileattribute SourceFile

# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase - Reglas completas y críticas
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-keep interface com.google.firebase.** { *; }
-keep interface com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# Google Play Core (para Flutter embedding)
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }

# Firestore
-keepclassmembers class * {
    @com.google.firebase.firestore.PropertyName <methods>;
    @com.google.firebase.firestore.PropertyName <fields>;
}

# Image Picker
-keep class androidx.lifecycle.** { *; }

# File Picker
-keep class com.mr.flutter.plugin.filepicker.** { *; }

# Modelos de datos - mantener para serialización JSON
# CRÍTICO: ProGuard puede ofuscar nombres de propiedades que usa fromJson/toJson
-keep class com.mahondev.autogestionmax.models.** { *; }

# Mantener todos los métodos fromJson y toJson
-keepclassmembers class * {
    public static ** fromJson(java.util.Map);
    public java.util.Map toJson();
}

# Proteger clases que usan reflexión para JSON
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# Mantener nombres de campos para serialización
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Prevenir problemas con generics en serialización
-keep class * implements java.io.Serializable { *; }
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Mantener clases nativas de Android
-keepclasseswithmembernames class * {
    native <methods>;
}

# Mantener constructores
-keepclassmembers public class * {
    public <init>(...);
}

# Kotlin serialization
-keepattributes *Annotation*, InnerClasses
-dontnote kotlinx.serialization.AnnotationsKt

# Coroutines
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory {}
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler {}

# OkHttp (usado por Firebase)
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep class okio.** { *; }

# OkHttp antiguo (usado por gRPC)
-dontwarn com.squareup.okhttp.**
-keep class com.squareup.okhttp.** { *; }

# gRPC
-dontwarn io.grpc.**
-keep class io.grpc.** { *; }

# Guava y reflexión
-dontwarn com.google.common.**
-dontwarn java.lang.reflect.AnnotatedType
-dontwarn java.lang.ClassValue

# Prevenir warnings de reflexión
-dontwarn javax.annotation.**
-dontwarn org.codehaus.mojo.animal_sniffer.*

# CRÍTICO: Mantener todas las clases de plugins Flutter
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.embedding.engine.** { *; }
-keep class io.flutter.embedding.engine.plugins.** { *; }

# Mantener métodos invocados desde código nativo
-keepclassmembers class * {
    @androidx.annotation.Keep *;
}

# Path Provider
-keep class io.flutter.plugins.pathprovider.** { *; }

# Shared Preferences
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# Imagen Picker & Camera
-keep class io.flutter.plugins.imagepicker.** { *; }
-keep class androidx.camera.** { *; }

# PDF & Printing
-keep class net.nfet.flutter.printing.** { *; }

# Share Plus
-keep class dev.fluttercommunity.plus.share.** { *; }

# URL Launcher
-keep class io.flutter.plugins.urllauncher.** { *; }

# FileProvider (para abrir archivos)
-keep class androidx.core.content.FileProvider { *; }

# Firebase Storage - mantener headers y metadata
-keep class com.google.firebase.storage.** { *; }
-keep interface com.google.firebase.storage.** { *; }

# Prevenir eliminación de código usado dinámicamente
-keepclassmembers class * {
    public <methods>;
    public <fields>;
}

# Mantener enums completos
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# R8 optimizaciones adicionales
-optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*
-optimizationpasses 5
-allowaccessmodification
-dontpreverify
