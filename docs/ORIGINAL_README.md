# YolYolakay — Flutter (native)

To'liq native mobil ilova. Capacitor WebView wrapper (`~/Desktop/yolyolakay-mobile/`)
vaqtinchalik yechim edi — bu loyiha uning o'rnini bosadi.

- **Application ID:** `uz.yolyolakay.mobile` (yonma-yon o'rnatilishi uchun).
  Flutter Store'ga chiqishga tayyor bo'lgach `uz.yolyolakay.app` ga
  almashtiriladi — `android/app/build.gradle.kts` dagi `applicationId` va
  iOS `PRODUCT_BUNDLE_IDENTIFIER`. ⚠ Bunda **eski keystore** bilan imzolash shart.
- **Stack:** Riverpod (codegen'siz) + Dio + GoRouter. `build_runner` YO'Q.

## Ishga tushirish

```bash
flutter run                                    # prod gateway (api.yolyolakay.xyz)
flutter run --dart-define=MOCK_AUTH=true       # backend auth 502 bo'lganda UI'ni bosib ko'rish (kod: 11111)
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8090   # lokal backend (emulyator)

### Reliz yig'ish (Sentry bilan)

Yiqilishlar Sentry'ga tushishi uchun DSN yig'ishda beriladi — u kodda
SAQLANMAYDI:

```bash
flutter build appbundle --release \
  --dart-define=SENTRY_DSN="$SENTRY_DSN"
```

DSN'siz yig'ilsa ilova oddiy ishlaydi, faqat monitoring bo'lmaydi.
Qiymat Vercel'dagi `NEXT_PUBLIC_SENTRY_DSN` bilan bir xil (hozircha
sayt bilan bitta loyiha — izohi `Env.sentryDsn` da).

### 🗺️ Xarita plitkalari — RELIZDA ALMASHTIRILADI

Standart manba `tile.openstreetmap.org` va u **faqat ishlab chiqish
uchun**: OSM Foundation'ning qoidasi ommaviy ilovaga ruxsat bermaydi
(heavy use → bloklanish, xarita bo'sh kulrang bo'lib qoladi).

Provayder KODGA TEGMASDAN almashtiriladi:

```bash
flutter build appbundle --release \
  --dart-define=MAP_TILES_URL='https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key={key}' \
  --dart-define=MAP_TILES_KEY="$MAP_TILES_KEY" \
  --dart-define=MAP_TILES_ATTRIBUTION='© MapTiler' \
  --dart-define=MAP_TILES_DARK_URL='https://api.maptiler.com/maps/streets-v2-dark/{z}/{x}/{y}.png?key={key}'
```

| O'zgaruvchi | Nima qiladi |
|---|---|
| `MAP_TILES_URL` | plitka manzili; `{key}` o'rniga kalit qo'yiladi |
| `MAP_TILES_KEY` | provayder kaliti (bo'lmasa `{key}` o'chiriladi) |
| `MAP_TILES_ATTRIBUTION` | attributsiyaga qo'shiladi; `© OpenStreetMap` **har doim** qoladi |
| `MAP_TILES_DARK_URL` | provayderning tungi uslubi; berilsa ilova o'z rang filtrini ishlatmaydi |

⚠️ Kalit manzilga tushadi, ya'ni u **sir emas** — provayder panelida
uni paket nomi (`uz.yolyolakay.mobile`) bo'yicha cheklash shart.

Tekshirish (ikkala holat ham o'lchanadi):

```bash
flutter test test/map_tiles_test.dart
flutter test test/map_tiles_test.dart \
  --dart-define=MAP_TILES_URL='https://x.tiles/{z}/{x}/{y}.png?key={key}' \
  --dart-define=MAP_TILES_KEY=abc123 --dart-define=MAP_TILES_ATTRIBUTION='© MapTiler'
```

flutter analyze && flutter test

flutter build apk --release --split-per-abi   # do'kondan tashqari tarqatish uchun
flutter build appbundle --release             # Play Store uchun (AAB)
```

> Oddiy `flutter build apk --release` BARCHA ABI'larni bitta faylga soladi —
> ~62 MB. `--split-per-abi` har arxitektura uchun alohida, ancha kichik APK
> beradi; Play Store'ga esa `appbundle` yuboriladi va Google o'zi ajratadi.

## Struktura

```
lib/
  main.dart              tokenlar/prefs birinchi kadrdan oldin yuklanadi
  app/
    app.dart             MaterialApp.router, uz/ru, light+dark
    router.dart          GoRouter + auth redirect
    home_shell.dart      pastki navigatsiya (indexedStack)
    providers.dart       BARCHA providerlar shu yerda
    theme.dart           brend palitra (web tokenlari bilan bir xil)
  core/
    env.dart             API_BASE_URL / MOCK_AUTH
    json.dart            xavfsiz parse yordamchilari
    format.dart          narx/sana/telefon formatlash
    cities.dart          joy -> koordinata ma'lumotnomasi (shahar + tuman)
    geo.dart             haversine masofa
    geocoder.dart        Nominatim — ro'yxatda yo'q manzillar uchun
    push.dart            FCM (Firebase sozlanmagan bo'lsa jimgina o'chiq)
    api/
      api_client.dart    Dio + auth interceptor + single-flight refresh
      api_exception.dart xatolarni foydalanuvchi tiliga o'girish
      token_storage.dart Keystore/Keychain
      device.dart        X-Device-ID / X-OS-Type
      ws_client.dart     doimiy WS ulanish
  data/
    models/              auth, user, ride, booking, chat, billing, rating, parcel
    repositories/        auth, users, rides, notifications, billing, rating, parcels
  features/
    auth/ search/ rides/ trips/ chat/ notifications/ profile/
    billing/             tariflar + to'lov (paywall)
    parcels/             pochta yuborish / topish
    rating/              baho qo'yish oynasi
    map/                 marshrut xaritasi, nuqta tanlash, plitka manbasi
    shared/              xato/bo'sh holatlar, tepadagi banner
  l10n/strings.dart      uz/ru (ARB/codegen'siz)
```

## Backend bilan ishlashda ESLAB QOLINADIGANLAR

Bular jonli tekshiruvda aniqlangan — Swagger ba'zi joyda adashtiradi.

| Nuqta | Holat |
|---|---|
| `POST /rides/` | **draft** yaratadi, qidiruvda ko'rinmaydi → darhol `activate`. Shu sabab repozitoriyda faqat `createAndActivate` bor |
| `GET /rides/my?role=passenger` | safarlarni EMAS, `{bookings:[...]}` qaytaradi — butunlay boshqa shakl |
| Bron obyekti | gateway `PascalCase` beradi (`ID`, `RideID`, `SeatsBooked`…) — `Booking.fromJson` ikkalasini ham qabul qiladi |
| Bron statusi | qabul qilingach `confirmed` (`accepted` emas) |
| `POST /rides/{id}/book` | maydon `seats` (`seats_booked` emas) |
| Mashina maydoni | `gov_number` (`plate_number` → 400) |
| Bo'sh natija | `{"rides": null}` shaklida ham keladi — `asList` shuni ushlaydi |
| Javob qobig'i | goh `{success, data}`, goh yassi — `unwrap` bir shaklga keltiradi |
| `X-Device-ID` / `X-OS-Type` | verify-otp/login uchun majburiy. Native'da CORS yo'q → proxy KERAK EMAS |
| `device_fingerprint` | Header'ga QO'SHIMCHA, tanada ham yuboriladi (pastdagi ⚠ ga qarang) |
| `send-otp` | 3/daqiqa → 429 (OTP ekranida 60s kutish taymeri shu sabab) |
| 502/503/504 | umumiy "tizimda xatolik" EMAS, alohida "server vaqtincha javob bermayapti" |

### ⚠ Backendning IKKI avlodi bor — adashtirmang

Ilova **deploy qilingan gateway** (`api.yolyolakay.xyz`) kontraktiga yozilgan.
Uy mashinasidagi docker konteyner (`yolyolakay_api`, manbasi
`~/Desktop/yolyolakaytoliq/backend`) esa **eski avlod** va yo'llari boshqa:

| Gateway (ilova shunga yozilgan) | Monolit (eski) |
|---|---|
| `/rides`, `/rides/search` | `/trips`, `/trips/search` |
| `/billing/plans`, `/billing/pay` | `/tariffs`, `/payments/create` |
| `/rating` | `/trips/:id/reviews`, `/users/:id/reviews` |
| `/parcels/*` | `/:id/responses` |

Shuning uchun monolitga qarab test qilinsa, tariflar/pochta/baholash `404`
beradi — bu **ilova xatosi emas**. Ularni faqat gateway bilan tekshirish mumkin.

Auth ikkalasida ham bor, lekin farq bilan: monolit `device_fingerprint` ni
so'rov TANASIDA majburiy deb biladi (`400 invalid payload`), gateway esa
`X-Device-ID` headeridan oladi. Ilova IKKALASINI ham yuboradi — ortiqcha
maydonni kerak bo'lmagan xizmat e'tiborsiz qoldiradi.

### Lokal backend bilan telefonda test

```bash
adb reverse tcp:8090 tcp:8090            # telefon localhost:8090 -> kompyuter
flutter run --dart-define=API_BASE_URL=http://localhost:8090 \
            --dart-define=WS_URL=ws://localhost:8090/ws
```

`android/app/src/debug/AndroidManifest.xml` cleartext trafikka ruxsat beradi
(Android 9+ da `http://` bloklanadi) — release manifestda bu YO'Q.

## Qidiruv filtrlari — nega klientda?

`GET /rides/search` FAQAT `origin/dest` koordinatasi, `radius_km` va `min_seats`
ni biladi. Jins, sana, qulayliklar bo'yicha parametr YO'Q — shuning uchun
filtrlar ham, saralash ham natijalar kelgandan keyin qo'llanadi
(`features/search/search_filters.dart`). Web'da ham aynan shunday.

Saralash standarti — **yaqinlik**: backend radius ichidagi safarlarni
tartiblamasdan qaytaradi, `core/geo.dart` haversine bilan masofani hisoblaydi.

## ⚠ Joylar ma'lumotnomasi web bilan bog'liq

`core/cities.dart` dagi **shahar koordinatalari `shared/data/uzCities.ts` bilan
AYNAN bir xil bo'lishi shart.** Qidiruv nom bo'yicha emas, koordinata radiusi
bo'yicha ishlaydi: qiymatlar ajralsa saytda yaratilgan e'lon mobil qidiruvda
umuman ko'rinmaydi (va aksincha).

`lib/core/cities.dart` **generatsiya qilinadi** — qo'lda tahrirlanmaydi:

```bash
python3 tools/fetch_osm_districts.py   # OSM'dan xom ma'lumot (internet, ~5–10 daq)
python3 tools/build_districts.py       # -> tools/districts.json
python3 tools/gen_places.py            # -> Dart yozuvlari
```

Ro'yxatda **49 shahar + 149 tuman**.

- **Shaharlar** — `tools/gen_places.py` ichida, qo'lda. Koordinatalar
  `uzCities.ts` dan AYNAN ko'chirilgan.
- **Tumanlar** — OpenStreetMap `admin_level=6` chegaralarining `admin_centre`
  nuqtasi (tuman markazi shaharchasi), bbox markazi emas: bbox markazi cho'l
  yoki tog' o'rtasiga tushishi mumkin. 200+ koordinatani qo'lda yozishda xato
  muqarrar edi, oqibati esa og'ir — shu sabab generatsiya.
- Nomi shahar bilan ustma-ust tushgan tumanlar tashlanadi (OSM'da "Buxoro
  shahri" alohida obyekt, bizda esa Buxoro allaqachon shahar).

`test/places_test.dart` eng muhim shaharlarning koordinatasini qotirib qo'ygan —
web'da o'zgarsa test yiqiladi. Yangi SHAHAR ikkala loyihaga bir xil qiymat
bilan qo'shilsin.

> Xom OSM fayllari (`tools/osm/`) repozitoriyda — internetsiz ham qayta
> generatsiya qilish mumkin. Viloyat nomi ba'zi tumanlarda eng yaqin shahar
> bo'yicha taxmin qilingan (Overpass `map_to_area` so'rovlari muntazam
> 502/504 beradi); u faqat ro'yxatdagi ostki yozuv, qidiruvga ta'sir qilmaydi.

## Real-time (WS)

Yagona ulanish `core/api/ws_client.dart` da: `wss://.../ws?token=<jwt>` —
yo'l gateway **ildizida** (`/api/v1/ws` emas), token query orqali.
Uzilsa 5 soniyada qayta ulanadi, token har ulanishda qaytadan o'qiladi.

Jonli backend barcha hodisalarni bitta shaklda yuboradi:
`{type: "notification", title, body}`. Boy hodisalar (NEW_BOOKING,
COUNTER_OFFER…) Centrifugo orqali rejalashtirilgan, u deploy qilinmagan —
kelmaydi. Shu sabab noma'lum `type` ham yiqilmasdan ishlanadi.

Chat xabari YUBORISH faqat WS orqali — REST endpointi yo'q.

## Xarita va geokoder

Xarita — `flutter_map` + OpenStreetMap plitkalari. Marshrut ilova ICHIDA
(BottomSheet) ochiladi: tashqi navigator ilovasiga otib yuborish foydalanuvchini
YolYolakay'dan chiqarib yuborardi.

> ⚠ **Relizdan oldin bajarilishi shart:** `tile.openstreetmap.org` — OSM
> Foundation'ning bepul serveri va uning qoidasi ommaviy ilovalarga ruxsat
> bermaydi. Yuklama o'sishidan oldin o'z tile-proksi yoki pullik provayderga
> (MapTiler / Thunderforest / Stadia) o'tish kerak. Almashtirish uchun
> `features/map/map_tiles.dart` dagi **bitta** joy yetadi.
> `© OpenStreetMap` yozuvi ODbL talabi — olib tashlanmasin.

Tungi rejimda plitkalar `invert(1)` + `hue-rotate(180deg)` matritsasi bilan
qoraytiriladi (OSM raster plitkalari faqat yorug' variantda keladi). Faqat
teskarilash yetmaydi — yashil park magentaga aylanadi.

Geokoder (Nominatim) FAQAT ichki ro'yxatda hech nima topilmaganda ishlaydi,
600 ms debounce bilan (qoida: 1 so'rov/soniya, aniq `User-Agent`). U alohida
Dio nusxasidan chiqadi — gateway klienti `Authorization` qo'shadi va begona
xostga token yuborib bo'lmaydi.

## Push (FCM) — fayl kutilmoqda

Kod to'liq tayyor (`core/push.dart`), lekin **`android/app/google-services.json`
loyihada yo'q** — u Firebase konsolidan olinadi va sirli fayl bo'lgani uchun
repozitoriyga qo'shilmagan.

Fayl bo'lmasa `Firebase.initializeApp` xato beradi; bu xato yutiladi va ilova
**pushsiz, lekin butunlay ishlaydigan** holda davom etadi (bildirishnomalar WS
orqali baribir keladi). Fayl qo'shilgach kod o'zgarishi kerak emas:

1. Firebase konsolida `uz.yolyolakay.mobile` paket nomi bilan Android ilova qo'shing.
2. `google-services.json` ni `android/app/` ga tashlang.
3. `android/settings.gradle.kts` ga
   `id("com.google.gms.google-services") version "4.4.2" apply false`,
   `android/app/build.gradle.kts` ga `id("com.google.gms.google-services")` qo'shing.
4. `flutter build apk` — token avtomatik `POST /notifications/tokens` ga ketadi.

## Shriftlar

Sarlavha shrifti — **Fraunces** (web bilan bir xil serif; OFL 1.1, litsenziya
matni `assets/fonts/Fraunces-OFL.txt`).

> ⚠ Fraunces'da **kirill yo'q** (cmap tekshirildi: `0x0400–0x04FF` bo'sh).
> Shuning uchun u butun ilovaga BERILMAYDI — faqat lotin brend sarlavhasiga
> (`app/theme.dart` dagi `displayFontStyle`). Aks holda ruscha interfeys
> tushib qolgan gliflar bilan buzilib ko'rinardi.

## Hali qilinmagan (keyingi bosqichlar)

- [ ] Yo'l geometriyasi bo'yicha marshrut (hozir xaritada to'g'ri kesmalar)
- [ ] `google-services.json` (yuqoriga qarang) va iOS push sertifikati
- [ ] O'z tile-proksi yoki pullik xarita provayderi
- [ ] Yuboruvchi uchun "mening posilkalarim" — backendda `/parcels/my` kerak
- [ ] Foydalanuvchi sharhlari RO'YXATI — backendda o'qish endpointi yo'q
      (hozir faqat baho YUBORISH bor)
- [ ] Avatar surati (`POST /media/upload` tayyor, UI yo'q)
