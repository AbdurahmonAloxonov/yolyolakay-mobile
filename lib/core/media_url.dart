import 'env.dart';

/// Backend qaytargan media manzilini OCHILADIGAN holga keltiradi.
///
/// 🔴 NEGA KERAK (egasi, 2026-08-16: "rasm backendga saqlanyapti, lekin na
/// saytda na ilovada ko'rinmayapti"): `POST /media/upload` manzilni NISBIY
/// qaytarishi mumkin (`/uploads/abc.jpg`). Bunday satr profilga yozilib,
/// bazada to'g'ri turadi — lekin `Image.network('/uploads/abc.jpg')` xato
/// beradi, chunki bu to'liq manzil emas. Natijada rasm saqlanadi-yu,
/// hech qayerda ko'rinmaydi va hech qanday xato ham chiqmaydi.
///
/// Shuning uchun ko'rsatishdan OLDIN har doim shu funksiyadan o'tkazamiz.
/// Backend to'liq manzil qaytarsa hech nima o'zgarmaydi — satr tegilmaydi.
///
/// ✅ 2026-08-27: media ENDI OCHIQ, `?token=` yamog'i OLIB TASHLANDI.
/// 2026-08-22 dan beri bu yerda manzilga token qo'shilardi, chunki `.xyz`
/// da media tokensiz 401 qaytarardi va `Image.network` `Authorization`
/// sarlavhasini yubormaydi. Token manzilda ketgani uchun server jurnaliga
/// tushardi — bila turib qabul qilingan vaqtinchalik yechim edi.
/// `.com` ga ko'chgach ikki mustaqil o'lchov uni yopdi: (1) mavjud bo'lmagan
/// faylga tokensiz so'rov **404** qaytaradi (401 emas — ya'ni auth
/// middleware'i marshrutdan oldin ishlamaydi), (2) swaggerda
/// `GET /media/{filename}` da `security` YO'Q, `POST /media/upload` da esa BOR.
/// Sayt tomonda ayni o'zgarish: `src/shared/lib/mediaUrl.ts`.
String? mediaUrl(String? raw) {
  final value = raw?.trim();
  if (value == null || value.isEmpty) return null;

  // Allaqachon to'liq manzil.
  if (value.startsWith('http://') || value.startsWith('https://')) {
    return value;
  }

  // Protokolsiz (`//cdn.example.com/a.jpg`) — HTTPS deb qaraymiz.
  if (value.startsWith('//')) return 'https:$value';

  // Nisbiy yo'l — gateway domeniga ulaymiz. `/api/v1` EMAS: statik fayllar
  // odatda ildizdan beriladi.
  return '${Env.apiBaseUrl}/${value.replaceFirst(RegExp('^/+'), '')}';
}
