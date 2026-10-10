import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../l10n/strings.dart';
import '../shared/state_views.dart';
import '../../../app/dimens.dart';

/// Shikoyat va bloklash menyusi.
///
/// 🔴 GOOGLE PLAY TALABI: foydalanuvchilar bir-biriga xabar yoza oladigan
/// ilovada "nomaqbul kontentga shikoyat" va "foydalanuvchini bloklash" yo'llari
/// BO'LISHI SHART. Web'da ikkalasi ham bor edi, ilovada YO'Q edi — reliz aynan
/// shu sababdan rad etilishi mumkin.
///
/// Sabab ro'yxati web bilan AYNAN bir xil (`shared/api/moderation.ts`), aks
/// holda backendda ikki xil qiymat to'planardi.
class ReportBlockMenu extends ConsumerWidget {
  const ReportBlockMenu({
    super.key,
    required this.targetUserId,
    this.targetName,
    this.rideId,
    this.onBlocked,
  });

  final String targetUserId;
  final String? targetName;
  final String? rideId;

  /// Bloklangach chaqiriladi — chat ekrani odatda orqaga qaytadi.
  final VoidCallback? onBlocked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppStrings.of(context);

    // Suhbatdosh ID'si noma'lum bo'lsa menyu ma'nosiz (kimga shikoyat qilamiz?).
    if (targetUserId.isEmpty) return const SizedBox.shrink();

    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      tooltip: t.moreActions,
      itemBuilder: (_) => [
        PopupMenuItem(value: 'report', child: Text(t.reportUser)),
        PopupMenuItem(value: 'block', child: Text(t.blockUser)),
      ],
      onSelected: (value) {
        if (value == 'report') {
          _showReportSheet(context, ref);
        } else {
          _confirmBlock(context, ref);
        }
      },
    );
  }

  Future<void> _showReportSheet(BuildContext context, WidgetRef ref) async {
    final t = AppStrings.of(context);
    final reasons = <String, String>{
      'harassment': t.reasonHarassment,
      'spam': t.reasonSpam,
      'fraud': t.reasonFraud,
      'unsafe': t.reasonUnsafe,
      'other': t.reasonOther,
    };

    var selected = 'harassment';
    final comment = TextEditingController();
    var sending = false;

    await showModalBottomSheet<void>(
      context: context,
      // `useSafeArea` SHART (Android 15+ / targetSdk 36): tizim
      // "edge-to-edge" ni MAJBURIY qiladi va opt-out endi ishlamaydi.
      // Usiz varaqning eng pastki tugmasi imo-ishora paneli ostida
      // qolib, bosib bo'lmaydigan bo'lardi.
      useSafeArea: true,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Padding(
          // Klaviatura maydonni yopib qo'ymasin.
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                t.reportUser,
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpace.lg),
              // `RadioListTile` ATAYIN ishlatilmadi: bu Flutter versiyasida
              // `groupValue`/`onChanged` eskirgan (RadioGroup ancestor talab
              // qilinadi). Oddiy ListTile bir xil natija beradi va ogohlantirish
              // chiqarmaydi.
              for (final entry in reasons.entries)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    selected == entry.key
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: selected == entry.key
                        ? Theme.of(sheetContext).colorScheme.primary
                        : null,
                  ),
                  title: Text(entry.value),
                  onTap: () => setSheetState(() => selected = entry.key),
                ),
              const SizedBox(height: AppSpace.sm),
              TextField(
                controller: comment,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: t.reportCommentHint,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpace.xl),
              FilledButton(
                onPressed: sending
                    ? null
                    : () async {
                        setSheetState(() => sending = true);
                        try {
                          await ref
                              .read(usersRepositoryProvider)
                              .reportUser(
                                userId: targetUserId,
                                reason: selected,
                                rideId: rideId,
                                comment: comment.text.trim().isEmpty
                                    ? null
                                    : comment.text.trim(),
                              );
                          if (sheetContext.mounted) {
                            Navigator.of(sheetContext).pop();
                          }
                          if (context.mounted) {
                            showMessage(context, t.reportSent);
                          }
                        } catch (error) {
                          setSheetState(() => sending = false);
                          if (!context.mounted) return;
                          showApiError(context, error, ref.read(langProvider));
                        }
                      },
                child: sending
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(t.send),
              ),
            ],
          ),
        ),
      ),
    );
    comment.dispose();
  }

  /// Bloklash QAYTARILADI (sozlamalardagi ro'yxatdan), lekin baribir so'raymiz:
  /// tasodifan bosilsa suhbat yo'qolib qolgandek tuyuladi.
  Future<void> _confirmBlock(BuildContext context, WidgetRef ref) async {
    final t = AppStrings.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.blockUser),
        content: Text(t.blockWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(t.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(t.blockUser),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(usersRepositoryProvider).blockUser(targetUserId);
      if (context.mounted) {
        // 🔴 «Qaytarish» — bloklash bekor qilinadigan amal, lekin uni
        // bekor qilish yo'li juda uzoq edi: Profil → Xavfsizlik →
        // Bloklanganlar. Odam buni bilmasa, xato bosilgan blok abadiy
        // qolardi va suhbatdosh sababsiz "yo'qolgan" bo'lib ko'rinardi.
        // Saytda ham xuddi shu tugma bor.
        showMessage(
          context,
          t.blockDone,
          actionLabel: t.undo,
          onAction: () async {
            try {
              await ref.read(usersRepositoryProvider).unblockUser(targetUserId);
              if (context.mounted) showMessage(context, t.unblockDone);
            } catch (error) {
              if (context.mounted) {
                showApiError(context, error, ref.read(langProvider));
              }
            }
          },
        );
      }
      onBlocked?.call();
    } catch (error) {
      if (!context.mounted) return;
      showApiError(context, error, ref.read(langProvider));
    }
  }
}
