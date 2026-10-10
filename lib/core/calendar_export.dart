import 'dart:convert';

import 'package:share_plus/share_plus.dart';

/// Safarni telefon KALENDARIGA qo'shish (`.ics` fayl).
///
/// 🔴 NEGA KERAK: shaharlararo safar bir necha kun oldin rejalashtiriladi.
/// Odam bron qiladi va... unutadi. Ilova ichidagi eslatma yordam beradi,
/// lekin kalendar undan kuchliroq: u ILOVADAN TASHQARIDA yashaydi,
/// boshqa qurilmalarga sinxronlanadi va ilova o'chirilsa ham qoladi.
///
/// 🔴 NEGA YANGI PAKET EMAS: `.ics` — oddiy matn formati (RFC 5545) va uni
/// qo'lda yozish bir necha qatordan iborat. Kalendar paketlari esa
/// kalendarga YOZISH ruxsatini so'raydi — bitta safar uchun butun
/// kalendarga kirish so'rash haddan tashqari. Fayl esa tizim oynasi
/// orqali ochiladi: qaysi kalendarga qo'shishni odam o'zi tanlaydi.
///
/// ⚠️ Vaqt UTC'da yoziladi (`Z` bilan) — kalendar uni foydalanuvchi
/// mintaqasiga o'zi o'giradi. Mahalliy vaqtni mintaqasiz yozish eng ko'p
/// uchraydigan `.ics` xatosi: safar boshqa soatda ko'rinib qoladi.
String buildIcs({
  required String uid,
  required DateTime start,
  required String title,
  String? description,
  String? location,
  Duration duration = const Duration(hours: 2),
}) {
  String stamp(DateTime dt) {
    final u = dt.toUtc();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${u.year}${two(u.month)}${two(u.day)}'
        'T${two(u.hour)}${two(u.minute)}${two(u.second)}Z';
  }

  // Vergul, nuqta-vergul va yangi qator `.ics` da MAXSUS belgilar —
  // qochirilmasa fayl buziladi va kalendar uni umuman ochmaydi.
  String esc(String raw) => raw
      .replaceAll('\\', '\\\\')
      .replaceAll(',', '\\,')
      .replaceAll(';', '\\;')
      .replaceAll('\n', '\\n');

  return [
    'BEGIN:VCALENDAR',
    'VERSION:2.0',
    'PRODID:-//YolYolakay//UZ//EN',
    'CALSCALE:GREGORIAN',
    'BEGIN:VEVENT',
    'UID:$uid@yolyolakay.co.uz',
    'DTSTAMP:${stamp(DateTime.now())}',
    'DTSTART:${stamp(start)}',
    'DTEND:${stamp(start.add(duration))}',
    'SUMMARY:${esc(title)}',
    if ((description ?? '').isNotEmpty) 'DESCRIPTION:${esc(description!)}',
    if ((location ?? '').isNotEmpty) 'LOCATION:${esc(location!)}',
    // Kalendarning O'Z eslatmasi — ilova o'chirilgan bo'lsa ham ishlaydi.
    'BEGIN:VALARM',
    'TRIGGER:-PT1H',
    'ACTION:DISPLAY',
    'DESCRIPTION:${esc(title)}',
    'END:VALARM',
    'END:VEVENT',
    'END:VCALENDAR',
  ].join('\r\n');
}

/// `.ics` ni tizim oynasi orqali ochadi — kalendar ilovasi uni oladi.
///
/// `XFile.fromData` — vaqtinchalik FAYLSIZ (`path_provider` kerak emas).
/// Xotira kartasi yasashda ham shu usul ishlatilgan.
Future<void> shareIcs({
  required String fileName,
  required String content,
}) async {
  final xfile = XFile.fromData(
    utf8.encode(content),
    mimeType: 'text/calendar',
    name: '$fileName.ics',
  );
  await SharePlus.instance.share(ShareParams(files: [xfile]));
}
