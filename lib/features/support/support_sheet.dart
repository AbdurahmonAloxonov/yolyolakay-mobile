import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/dimens.dart';
import '../../app/providers.dart';
import '../../core/env.dart';
import '../../core/format.dart';
import '../../data/models/support.dart';
import '../../l10n/strings.dart';
import '../shared/state_views.dart';
import '../shared/ui.dart';
import 'faq.dart';
import '../shared/brand/loom_loader.dart';

/// Ilova ichidagi qo'llab-quvvatlash murojaati.
///
/// 🔴 NEGA KERAK: ilgari "Yordam" tugmasi TO'G'RIDAN Telegramga olib
/// chiqardi. Ikki muammosi bor edi:
///   1. odam ilovadan chiqib ketardi va ko'pincha qaytmasdi;
///   2. operator "qaysi versiya, qanaqa telefon, qaysi safar?" deb
///      so'rashi kerak edi — odam esa bilmaydi yoki yozmaydi.
/// Endi ilova texnik ma'lumotni O'ZI qo'shadi (`SupportRepository`).
///
/// 🔴 TELEGRAM OLIB TASHLANMADI va olib tashlanmaydi: yo'lda, hodisa
/// bo'lganda odam forma to'ldirib o'tirmaydi — tirik odamga yozadi.
/// Shu sabab shoshilinch yo'l oynaning tepasida turadi.
///
/// ✅ 2026-08-16 KECHQURUN: backend operator javobi maydonini qo'shdi,
/// shuning uchun javob endi SHU YERDA ko'rinadi — «Murojaatlarim»
/// ro'yxatida. Ilgari "javob Telegram orqali keladi" deb uzr so'ralardi.
class SupportSheet extends ConsumerStatefulWidget {
  const SupportSheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    // `useSafeArea` SHART (Android 15+ / targetSdk 36): tizim
    // "edge-to-edge" ni MAJBURIY qiladi va opt-out endi ishlamaydi.
    // Usiz varaqning eng pastki tugmasi imo-ishora paneli ostida
    // qolib, bosib bo'lmaydigan bo'lardi.
    useSafeArea: true,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const SupportSheet(),
  );

  @override
  ConsumerState<SupportSheet> createState() => _SupportSheetState();
}

class _SupportSheetState extends ConsumerState<SupportSheet> {
  final _text = TextEditingController();
  String? _topic;
  bool _sending = false;
  bool _sent = false;

  /// Ro'yxat ko'rinishimi (aks holda yangi murojaat formasi).
  bool _showList = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _openTelegram() async {
    final t = AppStrings.of(context);
    final opened = await launchUrl(
      Uri.parse(Env.supportTelegramUrl),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) showMessage(context, t.linkOpenFailed);
  }

  Future<void> _send(List<(String, String)> topics) async {
    final t = AppStrings.of(context);
    final text = _text.text.trim();
    if (text.isEmpty) {
      showMessage(context, t.supportEmptyText);
      return;
    }

    // Mavzu tanlanmagan bo'lsa "Boshqa" — majburiy qilish odamni
    // to'xtatadi, holbuki matnning o'zi baribir hammasini aytadi.
    final subject = topics
        .firstWhere((e) => e.$1 == _topic, orElse: () => topics.last)
        .$2;

    setState(() => _sending = true);
    try {
      await ref
          .read(supportRepositoryProvider)
          .createTicket(subject: subject, description: text);
      if (!mounted) return;
      setState(() => _sent = true);
    } catch (error) {
      if (!mounted) return;
      showApiError(context, error, ref.read(langProvider));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    final theme = Theme.of(context);

    // (kalit, backendga ketadigan mavzu) — oxirgisi zaxira.
    final topics = <(String, String)>[
      ('complaint', t.supportTopicComplaint),
      ('accident', t.supportTopicAccident),
      ('lost', t.supportTopicLostItem),
      ('payment', t.supportTopicPayment),
      ('other', t.supportTopicOther),
    ];

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpace.lg,
          right: AppSpace.lg,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpace.xl,
        ),
        child: SingleChildScrollView(
          child: _showList
              ? _ticketsView(t, theme)
              : (_sent ? _successView(t, theme) : _formView(t, theme, topics)),
        ),
      ),
    );
  }

  /// Yuborilgandan keyingi holat — va'da BERILMAYDI, haqiqat aytiladi.
  Widget _successView(AppStrings t, ThemeData theme) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            color: theme.colorScheme.primary,
            size: 28,
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Text(t.supportSent, style: theme.textTheme.titleLarge),
          ),
        ],
      ),
      const SizedBox(height: AppSpace.md),
      InfoBox(
        tone: InfoTone.warning,
        child: Text(t.supportSentHint, style: theme.textTheme.bodyMedium),
      ),
      const SizedBox(height: AppSpace.lg),
      SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: _openTelegram,
          icon: const Icon(Icons.send_outlined),
          label: Text(t.supportUrgent),
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
  );

  /// Mening murojaatlarim — operator javobi bilan.
  Widget _ticketsView(AppStrings t, ThemeData theme) {
    final tickets = ref.watch(supportTicketsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                t.supportMyTickets,
                style: theme.textTheme.titleLarge,
              ),
            ),
            TextButton(
              onPressed: () => setState(() {
                _showList = false;
                _sent = false;
              }),
              child: Text(t.supportNewTicket),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.md),
        tickets.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(AppSpace.xl),
            child: Center(child: LoomLoader()),
          ),
          error: (error, _) => ErrorView(
            error: error,
            onRetry: () => ref.invalidate(supportTicketsProvider),
          ),
          data: (list) {
            if (list.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpace.xl),
                child: Center(
                  child: Text(
                    t.supportNoTickets,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ),
              );
            }
            return Column(
              children: [
                for (final ticket in list) ...[
                  _TicketCard(ticket: ticket),
                  const SizedBox(height: AppSpace.sm),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _formView(
    AppStrings t,
    ThemeData theme,
    List<(String, String)> topics,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(t.supportTitle, style: theme.textTheme.titleLarge),
          ),
          // ✅ 2026-08-16 kechqurun: backend javob maydonini qo'shgach
          // murojaat tarixi ma'noga ega bo'ldi — ungacha ro'yxatda
          // ko'rsatadigan javob yo'q edi.
          TextButton(
            onPressed: () => setState(() => _showList = true),
            child: Text(t.supportMyTickets),
          ),
        ],
      ),
      const SizedBox(height: AppSpace.sm),

      // Shoshilinch yo'l TEPADA: hodisa bo'lganda odam formani o'qimaydi.
      OutlinedButton.icon(
        onPressed: _openTelegram,
        icon: const Icon(Icons.bolt_outlined, size: 18),
        label: Text(t.supportUrgent),
      ),

      // SAVOL-JAVOB — formadan OLDIN. Ko'p savolga javob shu yerda va
      // odam kutmasdan topadi (izohi `FaqList` da).
      const SizedBox(height: AppSpace.lg),
      SectionLabel(t.faqTitle),
      const FaqList(),

      const SizedBox(height: AppSpace.lg),
      SectionLabel(t.supportSubject),
      Wrap(
        spacing: AppSpace.sm,
        runSpacing: AppSpace.sm,
        children: [
          for (final (key, label) in topics)
            ChoiceChip(
              label: Text(label),
              selected: _topic == key,
              onSelected: (v) => setState(() => _topic = v ? key : null),
            ),
        ],
      ),

      const SizedBox(height: AppSpace.lg),
      SectionLabel(t.supportDescribe),
      TextField(
        controller: _text,
        maxLines: 5,
        minLines: 3,
        textCapitalization: TextCapitalization.sentences,
        // ⚠️ `hintMaxLines` maydonning O'ZI qadar: umumiy tema 4 qator
        // beradi, bu maslahat esa uzunroq (320 px va 1.3 shkalada
        // 846 px kerak, qatorga 248 px to'g'ri keladi) va oxirgi
        // so'zlari kesilib qolardi.
        decoration: InputDecoration(hintText: t.supportHint, hintMaxLines: 5),
      ),

      const SizedBox(height: AppSpace.lg),
      SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: _sending ? null : () => _send(topics),
          child: _sending
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(t.supportSend),
        ),
      ),
    ],
  );
}

/// Bitta murojaat — javob bo'lsa u ham ko'rinadi.
class _TicketCard extends StatelessWidget {
  const _TicketCard({required this.ticket});

  final SupportTicket ticket;

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    final theme = Theme.of(context);

    return InfoBox(
      tone: ticket.isResolved ? InfoTone.positive : InfoTone.neutral,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  ticket.subject,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (ticket.createdAt != null)
                Text(
                  formatDate(ticket.createdAt, t.lang),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpace.xs),
          Text(
            // Texnik ma'lumot matn OXIRIGA qo'shiladi — uni odamga
            // ko'rsatishning ma'nosi yo'q, u operator uchun.
            ticket.description.split('--- texnik').first.trim(),
            style: theme.textTheme.bodySmall,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpace.sm),
          if (ticket.isResolved && (ticket.resolution ?? '').isNotEmpty) ...[
            Text(
              t.supportAnswer,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(ticket.resolution!, style: theme.textTheme.bodyMedium),
          ] else
            Text(
              t.supportWaiting,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
        ],
      ),
    );
  }
}
