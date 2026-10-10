import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/dimens.dart';
import '../../app/providers.dart';
import '../../core/env.dart';
import '../../l10n/strings.dart';
import '../shared/state_views.dart';
import '../shared/ui.dart';
import 'support_sheet.dart';

/// YORDAMGA CHIQISH — ilovaning istalgan nuqtasidan.
///
/// 🔴 NEGA KERAK (egasi, 22.09.2026: «support'ni ham ko'rinadigan joyga
/// qo'yish kerak, masalan otpdan o'tmay qolsa ham yoki xatolik bo'lsa ham
/// supportga yozish uchun»).
///
/// Ilgari yordam FAQAT profil ostida edi. Ya'ni eng ko'p yordamga muhtoj
/// odam — kodni ololmagan, umuman kira olmayotgan odam — bizga yozish
/// yo'lini topolmasdi va ilovani tashlab ketardi.
///
/// 🔑 IKKI XIL YO'L, chunki kanal ham ikki xil:
///   • KIRGAN odam — ilova ichidagi forma (`POST /helpdesk/tickets`),
///     javobni «Murojaatlarim» da ko'radi;
///   • KIRMAGAN odam — tokeni yo'q, ya'ni forma 401 beradi. Unga
///     Telegram ko'rsatiladi (`Env.supportTelegramUrl`) — bugun
///     ishlaydigan yagona kanal (pochta MX'i hamon sozlanmagan).
Future<void> openSupport(BuildContext context, WidgetRef ref) {
  final authenticated = ref.read(authControllerProvider).isAuthenticated;
  return authenticated
      ? SupportSheet.show(context)
      : AuthSupportSheet.show(context);
}

/// «Yordam kerakmi?» — matnli havola.
///
/// [highlight] — xatodan KEYIN: havola ko'zga tashlanadigan tugmaga
/// aylanadi. Odam xato bilan yuzma-yuz qolganda sokin kulrang yozuvni
/// payqamaydi (bu ayni kirish ekranida o'lchanmagan xavf edi).
class SupportLink extends ConsumerWidget {
  const SupportLink({super.key, this.highlight = false, this.label});

  final bool highlight;
  final String? label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppStrings.of(context);
    final text = label ?? t.supportNeedHelp;

    if (highlight) {
      return OutlinedButton.icon(
        onPressed: () => openSupport(context, ref),
        icon: const Icon(Icons.support_agent_outlined, size: 18),
        label: Text(text),
      );
    }
    return TextButton.icon(
      onPressed: () => openSupport(context, ref),
      icon: const Icon(Icons.help_outline, size: 18),
      label: Text(text),
      style: TextButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

/// Kirmagan odam uchun yordam varag'i.
///
/// ATAYIN FORMA EMAS: token yo'q, `POST /helpdesk/tickets` 401 qaytaradi
/// va odam «yubordim» deb o'ylab qolardi. Shuning uchun bu yerda avval
/// ENG KO'P UCHRAYDIGAN ikki holat tushuntiriladi (ko'pchilik shu yerda
/// hal qiladi va bizga yozishi ham shart emas), keyin Telegram.
class AuthSupportSheet extends StatelessWidget {
  const AuthSupportSheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    // Android 15+ "edge-to-edge" da pastki tugma imo-ishora paneli ostida
    // qolib ketmasin (izohi `SupportSheet` da).
    useSafeArea: true,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const AuthSupportSheet(),
  );

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.lg,
          0,
          AppSpace.lg,
          AppSpace.xl,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.authSupportTitle, style: theme.textTheme.titleLarge),
              const SizedBox(height: AppSpace.md),
              InfoBox(
                tone: InfoTone.neutral,
                child: Text(
                  t.authSupportSmsHint,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: AppSpace.sm),
              InfoBox(
                tone: InfoTone.neutral,
                child: Text(
                  t.authSupportPasswordHint,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: AppSpace.lg),
              // Texnik ma'lumot — operator so'ramasin. Kirgan odamda buni
              // `SupportRepository` o'zi qo'shadi, bu yerda esa murojaat
              // Telegramda qo'lda yoziladi.
              Text(
                t.authSupportTech(Env.appVersion),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
              const SizedBox(height: AppSpace.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async {
                    final opened = await launchUrl(
                      Uri.parse(Env.supportTelegramUrl),
                      mode: LaunchMode.externalApplication,
                    );
                    if (!opened && context.mounted) {
                      showMessage(context, t.linkOpenFailed);
                    }
                  },
                  icon: const Icon(Icons.send_outlined),
                  label: Text(t.authSupportWrite),
                ),
              ),
              const SizedBox(height: AppSpace.sm),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: Text(t.close),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
