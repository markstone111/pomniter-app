# Flutter Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# ObjectBox Rules (Preserve C++ JNI bridge & Entity models)
-keepclassmembers class * {
    @io.objectbox.annotation.* <fields>;
    @io.objectbox.annotation.* <methods>;
}
-keep class io.objectbox.** { *; }
-keepclassmembers class io.objectbox.** { *; }
-dontwarn io.objectbox.**

# ONNX Runtime Rules (Preserve C++ JNI bindings & internal tensors)
-keep class ai.onnxruntime.** { *; }
-keepclassmembers class ai.onnxruntime.** { *; }
-dontwarn ai.onnxruntime.**

# General JNI native method preservation
-keepclasseswithmembernames class * {
    native <methods>;
}
