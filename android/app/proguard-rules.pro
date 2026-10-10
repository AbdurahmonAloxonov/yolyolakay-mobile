# Flutter engine va plaginlar uchun minimal qoidalar.
# `isMinifyEnabled = true` bilan R8 ishlaydi — Flutter'ning o'z qoidalari
# avtomatik qo'shiladi, bu yerda faqat qo'shimcha istisnolar bo'ladi.
-keep class io.flutter.** { *; }
-dontwarn io.flutter.embedding.**
