import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../l10n/strings.dart';
import '../shared/brand/suzani_icons.dart';
import '../shared/state_views.dart';
import 'add_car_sheet.dart';
import '../../../app/dimens.dart';
import '../../data/models/user.dart';
import '../shared/refreshable.dart';
import '../shared/skeleton.dart';
import '../shared/brand/brand_panels.dart';

/// Mening mashinalarim.
///
/// Ilgari bu ro'yxat profil ekraniga to'g'ridan-to'g'ri joylashtirilgan edi va
/// profilni cho'zib yuborardi. Endi alohida ekran — profilda faqat bitta qator.
///
/// ⚠️ TAHRIRLASH VA O'CHIRISH YO'Q: `/users/me/cars` gateway'da faqat GET va
/// POST (2026-08-07 swagger). Ya'ni davlat raqamini xato kiritgan haydovchi uni
/// tuzata olmaydi — faqat yangi mashina qo'shishi mumkin. Bu backend cheklovi,
/// xatga qo'shilgan.
class CarsScreen extends ConsumerWidget {
  const CarsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppStrings.of(context);
    final theme = Theme.of(context);
    final me = ref.watch(meProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t.myCars), bottom: const JiyakLine()),
      // 🔴 TORTISH YUKLANISH VA XATODA HAM ISHLASIN (2026-09-04):
      // ilgari `YolRefresh` faqat `data:` shoxida edi, ya'ni ro'yxat
      // KELMAGANDA tortadigan narsaning o'zi yo'q edi. Izohi
      // `YolRefreshable` da.
      body: YolRefreshable<MeResponse>(
        value: me,
        onRefresh: () => ref.refresh(meProvider.future),
        loading: const ListSkeleton(),
        builder: (data) => ListView(
          padding: const EdgeInsets.all(AppSpace.lg),
          children: [
            if (data.cars.isEmpty)
              // qulaylik: chiqish yo'li SHART EMAS — «Mashina qo'shish»
              // tugmasi DARHOL ostida turibdi. Ikkinchisini qo'ysak,
              // bitta ekranda bir xil ikkita tugma bo'lardi.
              EmptyView(suzani: SuzaniIcon.car, title: t.noCars)
            else
              Card(
                child: Column(
                  children: [
                    for (var i = 0; i < data.cars.length; i++) ...[
                      if (i > 0) const Divider(height: 1, indent: 56),
                      ListTile(
                        leading: const Icon(Icons.directions_car_outlined),
                        title: Text(data.cars[i].title),
                        /*
                           * HOLAT — PASTKI QATORDA, yon tomonda emas.
                           *
                           * Ikkala holat ham BIR XIL tilda: yozuvli nishon
                           * (izohi `moderationApproved` da).
                           *
                           * 🔴 Nishon `trailing` da turganda u kengligi
                           * bilan mashina NOMINI siqib, «Chevrolet
                           * Cobalt» ni ikki qatorga bo'lib yuborardi.
                           * Nomi — asosiy ma'lumot, holat esa ikkinchi
                           * darajali; shuning uchun holat pastga tushdi.
                           */
                        subtitle: Wrap(
                          spacing: AppSpace.sm,
                          runSpacing: AppSpace.xs,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(data.cars[i].govNumber),
                            Chip(
                              avatar: Icon(
                                data.cars[i].isApproved
                                    ? Icons.check_circle
                                    : Icons.hourglass_empty,
                                size: 15,
                                // 🔴 PUSHTI BELGI FERUZA CHIP ICHIDA
                                // turardi (2026-09-03 ko'rigi): chip
                                // «tekshirilgan / yaxshi» deb turibdi,
                                // ichidagi belgi esa «asosiy amal»
                                // rangida edi — bitta elementda ikki
                                // xil ma'no. Endi belgi chipning O'Z
                                // matn rangida.
                                color: data.cars[i].isApproved
                                    ? theme.chipTheme.labelStyle?.color
                                    : theme.colorScheme.outline,
                              ),
                              label: Text(
                                data.cars[i].isApproved
                                    ? t.moderationApproved
                                    : t.moderationPending,
                              ),
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: AppSpace.lg),
            // Ikkinchi mashina qo'shish — ilgari umuman imkoni yo'q edi
            // (`addCar` repozitoriyada bor-u, ekran yo'q edi).
            FilledButton.icon(
              onPressed: () => AddCarSheet.show(context),
              icon: const Icon(Icons.add),
              label: Text(t.addCar),
            ),
          ],
        ),
      ),
    );
  }
}
