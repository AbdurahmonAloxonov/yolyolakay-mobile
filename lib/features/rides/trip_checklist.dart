import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/dimens.dart';
import '../../app/providers.dart';
import '../../core/haptics.dart';
import '../../l10n/strings.dart';
import '../../app/theme.dart';

/// SAFAR OLDI RO'YXATI — «hammasi olindimi?»
///
/// 🔴 NEGA YOZILDI (egasi tanlagan band, 2026-08-25): shaharlararo safarда
/// unutilgan narsa qaytib olib kelinmaydi — zaryadlovchi, hujjat, maydalik
/// pul. Ilova safarni TOPADI, lekin unga TAYYORLANISHDA hech qanday
/// yordam bermasdi. Bu mayda funksiya, lekin u ilovani «e'lon taxtasi»
/// dan «yo'l ilovasi» ga aylantiradi — raqobatchilarda buning hech biri
/// yo'q.
///
/// ═══ QOIDALAR ═══
///
///  1. Ro'yxat ROLGA qarab boshqacha: haydovchining ishi yo'lovchinikidan
///     butunlay boshqa (yoqilg'i, zapaska, qaytim uchun maydalik).
///  2. Belgilar SAFAR bo'yicha saqlanadi, umumiy emas: o'tgan safarda
///     belgilangan katak yangi safarga o'tib ketsa, ro'yxat yolg'on
///     tinchlik berardi.
///  3. Bu MASLAHAT, majburiyat emas: hech qanday tugma to'silmaydi va
///     «to'ldirmadingiz» degan ogohlantirish chiqmaydi.
enum ChecklistItem {
  documents,
  cash,
  charger,
  medicine,
  childSeat,
  fuel,
  spareWheel,
  change,
}

/// Yo'lovchi ro'yxati.
const _passengerItems = [
  ChecklistItem.documents,
  ChecklistItem.cash,
  ChecklistItem.charger,
  ChecklistItem.medicine,
  ChecklistItem.childSeat,
];

/// Haydovchi ro'yxati.
const _driverItems = [
  ChecklistItem.documents,
  ChecklistItem.fuel,
  ChecklistItem.spareWheel,
  ChecklistItem.change,
  ChecklistItem.charger,
];

/// Safar oldi ro'yxati kartasi.
class TripChecklist extends ConsumerStatefulWidget {
  const TripChecklist({
    super.key,
    required this.rideId,
    required this.forDriver,
  });

  final String rideId;
  final bool forDriver;

  @override
  ConsumerState<TripChecklist> createState() => _TripChecklistState();
}

class _TripChecklistState extends ConsumerState<TripChecklist> {
  /// Yopiq holatда ochiladi: ro'yxat har ochilganda ekran tepasini
  /// egallab turmasin, lekin nechtasi belgilangani sarlavhada ko'rinsin.
  bool _open = false;

  SharedPreferences get _prefs => ref.read(sharedPrefsProvider);

  String _key(ChecklistItem item) => 'checklist:${widget.rideId}:${item.name}';

  bool _done(ChecklistItem item) => _prefs.getBool(_key(item)) ?? false;

  Future<void> _toggle(ChecklistItem item) async {
    AppHaptics.select();
    final next = !_done(item);
    if (next) {
      await _prefs.setBool(_key(item), true);
    } else {
      await _prefs.remove(_key(item));
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    final theme = Theme.of(context);
    final items = widget.forDriver ? _driverItems : _passengerItems;
    final done = items.where(_done).length;

    return Card(
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              done == items.length
                  ? Icons.checklist_rtl
                  : Icons.checklist_outlined,
              color: done == items.length
                  ? BrandColors.success
                  : theme.colorScheme.outline,
            ),
            title: Text(t.checklistTitle),
            // Yopiq bo'lsa ham nechtasi belgilangani KO'RINADI — loyihada
            // bu qoida (`create_ride_screen` dagi yopiq bo'limlar bilan
            // bir xil): yopiq bo'lim ichidagi holat yashirilmaydi.
            subtitle: Text('$done / ${items.length}'),
            trailing: Icon(_open ? Icons.expand_less : Icons.expand_more),
            onTap: () => setState(() => _open = !_open),
          ),
          if (_open)
            for (final item in items)
              CheckboxListTile(
                value: _done(item),
                onChanged: (_) => _toggle(item),
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
                title: Text(_label(t, item)),
              ),
          if (_open)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.lg,
                0,
                AppSpace.lg,
                AppSpace.md,
              ),
              child: Text(
                t.checklistHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _label(AppStrings t, ChecklistItem item) => switch (item) {
    ChecklistItem.documents => t.checklistDocuments,
    ChecklistItem.cash => t.checklistCash,
    ChecklistItem.charger => t.checklistCharger,
    ChecklistItem.medicine => t.checklistMedicine,
    ChecklistItem.childSeat => t.checklistChildSeat,
    ChecklistItem.fuel => t.checklistFuel,
    ChecklistItem.spareWheel => t.checklistSpareWheel,
    ChecklistItem.change => t.checklistChange,
  };
}
