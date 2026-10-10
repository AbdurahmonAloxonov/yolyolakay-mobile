import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';

/// ILOVA YANGILANISHINI TEKSHIRISH (Google Play In-App Update).
///
/// 🔴 NEGA KERAK (egasi, 2026-08-20): "yangilanish kelganda userlar bilmay
/// qolishining oldini olishimiz kerak — ko'p ilovada 'yangilang' degan modal
/// chiqadi, bizda ham shunday bo'lsin".
///
/// Ilova ochilganda Play'dan yangi versiya bor-yo'qligini so'raydi. Bor bo'lsa
/// Play'ning O'Z modalini ko'rsatadi ("Обновление доступно — Обновить"),
/// yangilanishni fon'da yuklaydi va tayyor bo'lgach ilovani qayta ishga
/// tushirib qo'yadi. Bularning HAMMASINI Play bajaradi — bizda alohida UI,
/// versiya solishtirish yoki backend kerak emas.
///
/// FLEXIBLE tanlandi, IMMEDIATE emas: flexible foydalanuvchini bloklamaydi
/// (u "keyinroq" deb ishlashda davom etishi mumkin), immediate esa to'liq
/// ekranni egallab, yangilanmaguncha ilovaga kir* olmaydi. Majburiy
/// yangilanish (masalan xavfsizlik xatosi) kerak bo'lganda immediate'ga
/// o'tish mumkin, lekin oddiy relizda flexible to'g'ri.
///
/// ⚠️ CHEKLOVLAR (Play'ning o'zi qo'yadi, bizda emas):
///   • FAQAT Android va FAQAT Play Store orqali o'rnatilgan ilovada;
///   • sideload (qo'lda APK) da ishlamaydi — o'sha odam Play'dan qayta
///     o'rnatishi kerak;
///   • Play'da o'sha (yangiroq) versiya CHIQARILGAN bo'lishi shart —
///     yopiq testda ham ishlaydi.
///
/// Har qanday xato JIM yutiladi: yangilanish tekshiruvi ilovaning ochilishini
/// hech qachon to'smasligi kerak (Play xizmati yo'q qurilma, offline, eski
/// do'kon versiyasi — bularning hech biri xato emas).
abstract final class AppUpdate {
  /// Ilova ishga tushganda bir marta chaqiriladi.
  static Future<void> checkOnStartup() async {
    // iOS'da In-App Update yo'q (App Store'da boshqacha oqim); web/desktop
    // umuman tegishli emas.
    if (kIsWeb || !Platform.isAndroid) return;

    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability != UpdateAvailability.updateAvailable) {
        return;
      }
      // Flexible: Play modalini ko'rsatadi, "Обновить" bosilsa fon'da
      // yuklaydi. `startFlexibleUpdate` yuklab BO'LGUNCHA kutadi.
      final result = await InAppUpdate.startFlexibleUpdate();
      if (result == AppUpdateResult.success) {
        // Yuklandi — Play o'zi "qayta ishga tushirish" bildirishnomasini
        // beradi va `completeFlexibleUpdate` uni qo'llaydi. Foydalanuvchi
        // rad etsa keyingi ochilishda qayta taklif qilinadi.
        await InAppUpdate.completeFlexibleUpdate();
      }
    } catch (error) {
      // Play yo'q / offline / do'konda yangi versiya yo'q — normal holatlar.
      if (kDebugMode) debugPrint('[AppUpdate] tekshiruv o\'tkazib yuborildi: $error');
    }
  }
}
