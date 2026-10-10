import 'screen_title.dart';
import 'package:flutter/material.dart';

import '../../app/theme.dart';
import 'brand/brand_panels.dart';

/// YIG'ILADIGAN SARLAVHA — ro'yxat pastga surilganda sarlavha kichrayadi
/// va joy bo'shatadi.
///
/// 🔴 NEGA (2026-08-25 auditi): butun ilovada `SliverAppBar` atigi uch
/// joyda edi. Qolgan hamma ekranda sarlavha QOTIB turardi va telefon
/// ekranining eng qimmat qismidan — tepasidan — doimiy 56 piksel yeb
/// yotardi. Ro'yxatni ko'rib chiqayotgan odamga esa "Suhbatlar" degan
/// so'z o'ninchi marta kerak emas: u qayerda ekanini biladi.
///
/// Endi sarlavha KATTA boshlanadi (brend shrifti bilan, ekranga "kirish"
/// hissi beradi) va birinchi surishdayoq oddiy qatorga yig'iladi.
///
/// ⚠️ NEGA `NestedScrollView` VA SLIVERLARGA O'TKAZILMADI: ekranlarning
/// tanasi turli xil — ro'yxat, skelet, xato ko'rinishi, bo'sh holat.
/// Ularning hammasini sliverga aylantirish har ekranni qayta yozish
/// demak edi. `NestedScrollView` esa mavjud tanani O'ZGARTIRMASDAN
/// qabul qiladi: `YolRefresh` (tortib-yangilash) ham ishlayveradi.
class CollapsingScaffold extends StatelessWidget {
  const CollapsingScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: floatingActionButton,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerScrolled) => [
          SliverAppBar.large(
            /*
             * 🔴 SARLAVHA EKRAN O'QIGICHGA NOMSIZ EDI (2026-09-04,
             * o'lchandi). `SliverAppBar.large` sarlavhani IKKI marta
             * chizadi: yig'ilgan holatdagi (ko'rinmas) nusxa va
             * yoyilgan ko'rinadigani. Flutter `header` bayrog'ini
             * BO'SH nusxaga qo'yardi — TalkBack «sarlavha» deb e'lon
             * qilar, lekin nomini aytmasdi.
             *
             * Belgi ko'rinadigan matnning ustiga qo'yildi.
             */
            title: Semantics(
              header: true,
              child: ScreenTitle(
                title,
                // Brend sarlavha shrifti FAQAT yig'iladigan holatda: u katta
                // o'lchamda ta'sirli, 16 pikselli oddiy AppBar'da esa
                // tizim shriftidan farqi bilinmaydi.
                style: displayFontStyle(
                  Theme.of(context).appBarTheme.titleTextStyle,
                ),
              ),
            ),
            actions: actions,
            // Atlas ipi — oddiy `AppBar` li ekranlardagidek. Bu ekranlar
            // (bildirishnomalar, suhbatlar) yig'iladigan sarlavha
            // ishlatgani uchun tikuv chizig'isiz qolib ketgandi.
            bottom: const JiyakLine(),
            // Ro'yxat sarlavha ostiga kirganda soya paydo bo'lsin — aks
            // holda matn sarlavhaga "yopishib" o'qilmay qoladi.
            forceElevated: innerScrolled,
          ),
        ],
        body: body,
      ),
    );
  }
}
