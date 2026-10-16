# google_mlkit_text_recognition references every ML Kit script recognizer, but
# the app only bundles the default (Latin) one. Without these, R8 stops the
# release build on the missing classes.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
