import 'package:flutter/material.dart';

import '../../app/dimens.dart';
import '../../l10n/strings.dart';

/// SAVOL-JAVOB — murojaat yozmasdan javob topish.
///
/// 🔴 NEGA (2026-08-25 auditi): yordam bo'limi FAQAT murojaat formasi
/// edi. Odam savol yozadi va JAVOB KUTADI — soatlab, ba'zan ertagacha.
/// Ayni paytda savollarning katta qismi takrorlanadi: «qanday bron
/// qilaman?», «pul qachon o'tadi?», «haydovchi javob bermayapti».
///
/// Bu ikki tomonga zarar: odam kutadi, biz esa bir xil javobni qayta-qayta
/// yozamiz.
///
/// ⚠️ JAVOBLAR HAQIQATNI aytadi, va'da bermaydi. Masalan bekor qilish
/// hozir MUMKIN EMAS (backendda endpoint yo'q) — buni yashirmay, ochiq
/// yozamiz va nima qilish kerakligini aytamiz. Yolg'on javob murojaatni
/// kamaytirmaydi, faqat ishonchni yo'qotadi.
class FaqList extends StatefulWidget {
  const FaqList({super.key});

  @override
  State<FaqList> createState() => _FaqListState();
}

class _FaqListState extends State<FaqList> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    final theme = Theme.of(context);
    final query = _query.trim().toLowerCase();

    final items = t.faqItems
        .where(
          (item) =>
              query.isEmpty ||
              item.$1.toLowerCase().contains(query) ||
              item.$2.toLowerCase().contains(query),
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            hintText: t.faqSearchHint,
            isDense: true,
          ),
          onChanged: (value) => setState(() => _query = value),
        ),
        const SizedBox(height: AppSpace.sm),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpace.lg),
            child: Text(
              // Bo'sh natija BOSHI BERK bo'lmasin: pastda murojaat
              // formasi turibdi va bu yerda shunga ishora qilinadi.
              t.faqNothingFound,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          )
        else
          for (final (question, answer) in items)
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(bottom: AppSpace.md),
              title: Text(question, style: theme.textTheme.bodyMedium),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    answer,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
      ],
    );
  }
}
