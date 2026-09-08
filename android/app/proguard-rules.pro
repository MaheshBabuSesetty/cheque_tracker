# google_mlkit_text_recognition supports Chinese/Devanagari/Japanese/Korean
# scripts as optional (compileOnly) dependencies. This app only uses
# TextRecognitionScript.latin, so those script packages are deliberately
# not bundled — R8 can't prove the plugin's references to them are
# unreachable, so it needs telling not to worry about the missing classes.
-dontwarn com.google.mlkit.vision.text.chinese.ChineseTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.chinese.ChineseTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.devanagari.DevanagariTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.devanagari.DevanagariTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.japanese.JapaneseTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.japanese.JapaneseTextRecognizerOptions
-dontwarn com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions$Builder
-dontwarn com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions

# The `-dontwarn`s above only silence a *build-time* warning about classes
# this app doesn't ship. They do nothing to protect the classes it DOES use
# from being stripped/renamed by R8 minification. That's not just an OCR
# problem: `com.google.mlkit.common.internal.MlKitInitProvider` is a
# ContentProvider ML Kit's manifest declares, instantiated at process start
# before Flutter even runs — R8 stripping anything reachable from its
# internal DI container (com.google.mlkit.common.sdkinternal.*, already
# minified by Google upstream — R8 has no way to know it's reflectively
# wired) crashes the app on launch with "Unable to get provider
# com.google.mlkit.common.internal.MlKitInitProvider" before a single
# screen renders. Debug builds aren't minified, so none of this shows up
# until `flutter build apk/appbundle --release`. Keeping the whole
# `com.google.mlkit` tree (not just `vision.text`) is what Google's own
# ML Kit R8 guidance recommends, precisely because of this DI wiring.
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_text_common.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_common.** { *; }
-dontwarn com.google.mlkit.**
-dontwarn com.google.android.gms.internal.mlkit_vision_text_common.**
