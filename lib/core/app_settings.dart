import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Tizim sozlamalarini ochish.
///
/// NEGA PAKET EMAS: bizga kerak bo'lgan yagona narsa — ilovaning
/// BILDIRISHNOMA sozlamalari sahifasi. Buning uchun butun boshli paket
/// (`app_settings` va o'xshashlari) qo'shish reliz hajmini va bog'liqlik
/// xavfini oshiradi; Kotlin tomonda esa bu bitta `Intent`.
///
/// Ruxsat "boshqa so'ramang" bilan rad etilgan bo'lsa tizim dialogi endi
/// CHIQMAYDI — foydalanuvchini sozlamalarga olib borishdan boshqa yo'l yo'q.
const _channel = MethodChannel('uz.yolyolakay.mobile/settings');

/// Ilovaning bildirishnoma sozlamalarini ochadi. Ochilmasa `false`.
Future<bool> openNotificationSettings() async {
  try {
    return await _channel.invokeMethod<bool>('openNotificationSettings') ??
        false;
  } catch (error) {
    debugPrint('Sozlamalar ochilmadi: $error');
    return false;
  }
}
