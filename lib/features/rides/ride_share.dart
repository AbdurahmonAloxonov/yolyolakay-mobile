import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/providers.dart';
import '../../core/env.dart';
import '../../core/share_safely.dart';
import '../../core/format.dart';
import '../../data/models/ride.dart';
import '../../l10n/strings.dart';

/// Safarni ULASHISH — Telegramga tashlash uchun tayyor matn + havola.
///
/// 🔴 NEGA KERAK: O'zbekistonda safar odamlar orasida Telegram orqali
/// tarqaladi. Ilgari odam safarni ko'rsatish uchun ekranni SURATGA olardi —
/// suratdan havola ochilmaydi, ya'ni ko'rgan odam safarni topa olmasdi.
///
/// Havola SAYTGA boradi (`/uz/trip/{id}`), ilovaga emas: xabarni ko'radigan
/// odamda ilova bo'lmasligi mumkin, sayt esa hammada ochiladi. Ilova
/// o'rnatilgan bo'lsa, deep link uni baribir ilovada ochadi.
///
/// Matn 4 qatordan oshmaydi: Telegram uzun xabarni yig'ib qo'yadi va
/// eng muhim qism — narx bilan vaqt — ko'rinmay qolardi.
String rideShareText(Ride ride, AppStrings t) {
  final from = ride.originAddress.trim();
  final to = ride.destinationAddress.trim();
  final route = [if (from.isNotEmpty) from, if (to.isNotEmpty) to].join(' → ');

  final when = formatDateTime(ride.departureTime, t.lang);
  final price = '${formatPrice(ride.pricePerSeat)} ${t.sum}';

  return [
    if (route.isNotEmpty) route,
    // Vaqt yo'q bo'lsa "—" yozilmaydi: ulashiladigan matnda bu chiziqcha
    // "ma'lumot buzuq" degandek ko'rinadi.
    if (when.isNotEmpty && when != '—') when,
    '$price · ${ride.availableSeats} ${t.seats}',
    '',
    rideShareUrl(ride.id, t.lang),
  ].join('\n');
}

/// Safarning saytdagi manzili — til prefiksi bilan.
///
/// 🔴 `lang.name` EMAS, `langCode(lang)` (16.09.2026 da prodda o'lchandi).
///
/// Dart enum'ning nomi `uzCyrl`, saytdagi til prefiksi esa `uz-cyrl`.
/// Ilgari bu yerda `lang.name` turardi, ya'ni KIRILL tilidagi odamning
/// ulashgan havolasi `…/uzCyrl/trip/…` bo'lardi va u O'LIK edi:
///
///     GET /uzCyrl/trip/{id}  → 307 → /uz/uzCyrl/trip/{id} → 404
///     GET /uz-Cyrl/trip/{id} → 200  (sayt katta-kichikni o'zi tekshiradi)
///
/// Ya'ni kirillda yuriladigan odam safarni ham, KUZATUV havolasini ham
/// ulashsa — yaqiniga o'lik havola ketardi. Bu tuzoq loyihada ma'lum
/// edi (`phone_screen.dart` da ogohlantirish yozilgan), lekin shu joy
/// o'tkazib yuborilgan ekan.
String rideShareUrl(String rideId, Lang lang) =>
    '${Env.siteUrl}/${langCode(lang)}/trip/$rideId';

Future<void> shareRide(BuildContext context, Ride ride) async {
  final t = AppStrings.of(context);
  await shareSafely(context, ShareParams(text: rideShareText(ride, t)));
}

/// «SAFARIMNI KUZAT» — yaqinlariga yuboriladigan xavfsizlik xabari.
///
/// 🔴 NEGA KERAK: SOS tugmasi bizda BOR, lekin u HODISADAN KEYIN ishlaydi.
/// Bu esa oldini oladi: onasi yoki turmush o'rtog'i kim bilan, qanaqa
/// mashinada va qayerga ketayotganini OLDINDAN biladi. Uber/Yandex'da
/// «Share trip status» aynan shu maqsadda.
///
/// Oddiy ulashishdan FARQI — mashina va haydovchi ma'lumoti: uni faqat
/// bron tasdiqlangach yuborish mantiqiy.
///
/// ✅ 16.09.2026 — ENDI BU HAQIQIY JONLI KUZATUV.
///
/// 🔴 Ilgari bu yerda ochiq tan olingan cheklov turardi: «bu jonli
/// kuzatuv EMAS, havola safar sahifasiga olib boradi, mashina
/// harakatini ko'rsatmaydi». Ya'ni funksiya NOMI va'da bergan narsani
/// bajarmasdi — xavfsizlik funksiyasida eng yomon holat. Biz buni
/// backendga yozdik va ular KUZATUV TOKENINI qo'shdi.
///
/// Endi havolada token bo'ladi (`?watch=wt_...`) va uni ochgan odam —
/// ro'yxatdan o'tmagan bo'lsa ham — mashinani xaritada KO'RADI.
/// Prodda o'lchandi: mehmon 200 va haqiqiy koordinata oladi.
///
/// 🔑 Token XAVFSIZ: faqat SHU safarga ishlaydi (boshqasiga 403), bekor
/// qilinsa darhol o'ladi, va faqat lat/lon/heading beradi — telefon,
/// ism, bron ro'yxati YO'Q (hammasi prodda o'lchandi).
///
/// ⚠️ Token OLINMASA (tarmoq yo'q, yoki bron hali tasdiqlanmagan) —
/// havola ESKICHA, tokensiz ketadi. Odam baribir safarni ko'radi,
/// shunchaki mashinasiz. Xabarni umuman yubormaslikdan bu yaxshi.
String tripWatchText(Ride ride, AppStrings t, {String? watchToken}) {
  final route = [
    if (ride.originAddress.trim().isNotEmpty) ride.originAddress.trim(),
    if (ride.destinationAddress.trim().isNotEmpty)
      ride.destinationAddress.trim(),
  ].join(' → ');

  final car = ride.car;
  final carLine = [
    if ((car?.title ?? '').isNotEmpty) car!.title,
    if ((car?.plate ?? '').isNotEmpty) car!.plate!.toUpperCase(),
  ].join(' · ');

  final when = formatDateTime(ride.departureTime, t.lang);
  final driver = prettyName(ride.driver?.name) ?? '';

  return [
    t.watchTripIntro,
    if (route.isNotEmpty) route,
    if (when.isNotEmpty && when != '—') when,
    if (driver.isNotEmpty) '${t.driver}: $driver',
    if (carLine.isNotEmpty) carLine,
    '',
    watchToken == null
        ? rideShareUrl(ride.id, t.lang)
        : '${rideShareUrl(ride.id, t.lang)}?watch=$watchToken',
  ].join('\n');
}

/// Kuzatuv havolasini ulashadi.
///
/// Token FAQAT shu yerda, bosilganda olinadi: oldindan olsak har safar
/// ekrani ochilganda serverda keraksiz token yig'ilib borardi.
Future<void> shareTripWatch(
  BuildContext context,
  WidgetRef ref,
  Ride ride,
) async {
  final t = AppStrings.of(context);

  String? token;
  try {
    token = await ref.read(ridesRepositoryProvider).watchToken(ride.id);
  } catch (_) {
    // Sababini bilmaymiz (tarmoq yoki 403) — lekin xabarni TO'XTATMAYMIZ:
    // tokensiz havola ham safarni ko'rsatadi. Izohi yuqorida.
  }
  if (!context.mounted) return;
  await shareSafely(
    context,
    ShareParams(text: tripWatchText(ride, t, watchToken: token)),
  );
}
