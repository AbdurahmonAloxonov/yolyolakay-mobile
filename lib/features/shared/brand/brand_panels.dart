import 'package:flutter/material.dart';

import '../../../app/dimens.dart';
import '../../../app/theme.dart';
import 'atlas.dart';
import 'ornament.dart';

/// TAYYOR BLOKLAR — naqshlarni ekranlar bo'ylab BIR XIL ishlatish uchun.
///
/// 🔑 Nega alohida fayl: naqshning o'zi (`ornament.dart`) — alifbo, bu
/// yerdagilar esa SO'ZLAR. Har ekran alifbodan o'zicha so'z yasasa,
/// ilova yana yig'ma bo'lib qoladi — aynan shu xato bir marta
/// bo'lgan (`SectionTitle` qo'shib, tuzatmoqchi bo'lgan muammoni
/// takrorlagandim, 2026-09-02).

/// To'q blokning PASTKI CHEKKASI qanday tugashi.
enum HeaderEdge {
  /// Yumaloq burchak — oddiy, sokin.
  rounded,

  /// MUQARNAS — peshtoq ostidagi asal uyasi qatorlari.
  ///
  /// 🔑 Me'moriy jihatdan aynan shu to'g'ri: muqarnas har doim
  /// ravoqning OSTIDA, ya'ni bir sirtdan ikkinchisiga o'tish joyida
  /// turadi. Tekis chiziq yoki yumaloq burchak — shunchaki «kesish»,
  /// muqarnas esa O'TISH.
  muqarnas,

  /// Chekkasiz — blok ekran tepasini to'ldiradi.
  flat,
}

/// TO'Q BAYONOT BLOKI — ekranning peshtoqi.
///
/// Ilovadagi har ekran shu blok bilan boshlanadi: unda ekranning
/// MAQSADI aytiladi. Naqsh shu blokda eng kuchli bo'ladi (`depth`
/// 1.0), mazmun bo'limlarida esa yengil — aks holda kartalar naqsh
/// bilan raqobat qiladi va ekran charchatadi.
class OrnamentHeader extends StatelessWidget {
  const OrnamentHeader({
    super.key,
    required this.child,
    this.edge = HeaderEdge.muqarnas,
    this.jiyak = false,
    this.palette = 0,
    this.padding = const EdgeInsets.fromLTRB(
      AppSpace.screen,
      AppSpace.xxl,
      AppSpace.screen,
      AppSpace.xl,
    ),
    this.safeAreaTop = true,
    this.rosette = false,
  });

  final Widget child;
  final HeaderEdge edge;

  /// Blokning PASTKI chekkasidagi atlas jiyagi — tokchali kamar.
  ///
  /// 🔴 Avval u ekranning eng TEPASIDA edi va holat qatori (soat,
  /// batareya) ostida qolib ketardi — ya'ni haqiqiy telefonda umuman
  /// ko'rinmasdi. Me'moriy jihatdan ham joyi shu: peshtoqda koshin
  /// kamari ravoq ostidan, muqarnasdan yuqorida o'tadi.
  final bool jiyak;
  final int palette;
  final EdgeInsets padding;
  final bool safeAreaTop;

  /// Palak rozetkasi suv belgisi — blokning o'ng chekkasida.
  /// Faqat GAP KAM bo'lgan bloklarda (kirish, bo'sh holat).
  final bool rosette;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ground = heroSurface(theme);
    final ink = onHeroSurface(theme);

    Widget block = Container(
      width: double.infinity,
      color: ground,
      child: Stack(
        children: [
          // GIRIH — to'q zaminda tasma o'z rangida ko'rinadi.
          // ⚠️ Kesim ZAMIN rangi bilan bir xil bo'lishi shart, aks
          // holda tasma uzilgan joyda begona dog' qoladi.
          //
          // 🔴 SIYRAKROQ VA JIMROQ (10.09.2026). `cell: 96` da naqsh
          // telefon enida o'n bir marta takrorlanardi — bu tugun
          // emas, TO'R. Ustiga `alpha: 0.11` uni kontentdan balandroq
          // ovozda chiqarardi: qorong'i rejimda kartaning o'zi
          // fondan atigi 1.14 : 1 farq qilar edi, naqsh esa undan
          // kuchliroq ko'rinardi. Ekran «shovqinli» tuyulishining
          // sababi shu edi.
          //
          // `cell: 140` da tugun ekran bo'ylab ~8 marta takrorlanadi
          // va NAQSH bo'lib o'qiladi, `alpha: 0.075` esa uni
          // kontentning ostiga qaytaradi. Girih yo'qolmaydi —
          // u zaminning to'qimasi bo'lib qoladi, mustaqil element
          // emas (HIG `materials.md`: material kontentni ustunlikda
          // qoldirishi kerak).
          Positioned.fill(
            child: GirihPattern(
              cell: 140,
              color: ink.withValues(alpha: 0.075),
              cut: ground,
            ),
          ),
          if (rosette)
            Positioned(
              right: -56,
              top: -30,
              child: PalakRosette(size: 240, color: ink, opacity: 0.10),
            ),
          Padding(
            padding: padding,
            child: SafeArea(top: safeAreaTop, bottom: false, child: child),
          ),
          if (jiyak)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AtlasEdge(height: 5, palette: palette),
            ),
        ],
      ),
    );

    if (edge == HeaderEdge.rounded) {
      block = ClipRRect(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppRadius.hero),
        ),
        child: block,
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        block,
        // Muqarnas ravoqchalari SAHIFA zamini rangida chiziladi, ORTIDA
        // esa blokning to'q rangi turadi — ya'ni ular blokdan «o'yib
        // olingan» bo'lib ko'rinadi.
        //
        // 🔴 Ortidagi to'q zamin UNUTILGANDI va tasma yorug' ustiga
        // yorug' chizib, umuman ko'rinmasdi — blok tekis kesilgandek
        // qolaverardi.
        if (edge == HeaderEdge.muqarnas)
          ColoredBox(
            color: ground,
            child: MuqarnasBand(color: theme.scaffoldBackgroundColor, cell: 32),
          ),
      ],
    );
  }
}

/// PESHTOQ MEDALYONI — ravoq ichidagi belgi.
///
/// Tanishtiruv ekranlari, bo'sh holatlar va profil suratlari uchun.
/// Ravoq — eng kuchli milliy belgi va u BEZAK EMAS, SHAKL: mazmun
/// aynan shu shaklda kesiladi.
class PeshtoqMedallion extends StatelessWidget {
  const PeshtoqMedallion({
    super.key,
    required this.child,
    this.width = 168,
    this.palette = 0,
    this.tone,
    this.jiyak = true,
  });

  final Widget child;
  final double width;
  final int palette;

  /// Ravoq ichidagi zamin. Berilmasa — to'q blok rangi.
  final Color? tone;
  final bool jiyak;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ground = tone ?? heroSurface(theme);
    final ink = tone == null
        ? onHeroSurface(theme)
        : ThemeData.estimateBrightnessForColor(ground) == Brightness.dark
        ? Colors.white
        : theme.colorScheme.onSurface;

    return SizedBox(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            // Ravoq TIK bo'lishi shart: enidan past bo'lsa uchi
            // yassilanadi va peshtoq tanilmay qoladi.
            height: width * 1.24,
            child: PeshtoqFrame(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(color: ground),
                  // ⚠️ Katak MAYDA bo'lsin: 164 pikselli ravoqda 85
                  // pikselli katakdan atigi ikkitasi sig'adi va naqsh
                  // emas, tasodifiy chiziqlar ko'rinadi.
                  GirihPattern(
                    cell: width * 0.30,
                    color: ink.withValues(alpha: 0.16),
                    cut: ground,
                  ),
                  Center(
                    child: IconTheme(
                      data: IconThemeData(color: ink, size: width * 0.34),
                      child: DefaultTextStyle.merge(
                        style: TextStyle(color: ink),
                        child: child,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Ravoq OSTIDAGI jiyak — poydevor. Busiz ravoq havoda osilib
          // turgandek ko'rinadi.
          if (jiyak) AtlasEdge(height: 5, palette: palette),
        ],
      ),
    );
  }
}

/// SARLAVHA PANELI OSTIDAGI ATLAS IPI.
///
/// `AppBar.bottom` ga qo'yiladi va ekranlar bo'ylab BIR XIL turadi —
/// ya'ni bu bezak emas, TIZIM elementi: ilovaning tikuv chizig'i.
///
/// ⚠️ INGICHKA bo'lishi shart. Atlas MATOSI bu balandlikda ko'rinmaydi
/// (saytda o'lchab topilgan xato — «g'alati ko'k chiziq»), shuning uchun
/// bu yerda [AtlasEdge] ishlatiladi: unda ranglar chiziq BO'YLAB
/// teriladi va eng ingichkasida ham hamma rang ko'rinadi.
class JiyakLine extends StatelessWidget implements PreferredSizeWidget {
  const JiyakLine({super.key, this.height = 3, this.palette = 0});

  final double height;
  final int palette;

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) =>
      // 🔴 JIM (12.09.2026, «premium» ko'rigi): ilgari to'liq to'yingan
      // xonatlas tasmasi har sarlavha ostida BAQIRARDI va uchta baland
      // aksentdan biri edi (narx + avatar + jiyak). Dadillik BITTA joyга
      // (narx) sarflanadi — shuning uchun jiyak endi nozik teksturaga
      // tushadi (0.42 shaffoflik). Naqsh O'CHMADI: xonatlas ip-ranglari
      // joyida, faqat shovqin kamaydi, ilova tinchlandi.
      Opacity(
        opacity: 0.42,
        child: AtlasEdge(height: height, palette: palette, scale: 0.55),
      );
}
