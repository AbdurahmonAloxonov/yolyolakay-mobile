import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../l10n/strings.dart';

/// Bildirishnoma qo'ng'irog'i — o'qilmagan soni bilan.
///
/// Ilgari u FAQAT qidiruv ekranining AppBar'ida edi. Ya'ni "Safarlarim",
/// "Chatlar" yoki "Profil" tabida turgan odam bildirishnomalarga UMUMAN yeta
/// olmasdi — avval qidiruvga qaytishi kerak edi. Web'da qo'ng'iroqcha
/// Header'da doimo turadi.
///
/// Endi bitta vidjet va u har bir asosiy tabning AppBar'ida.
class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppStrings.of(context);
    final unread = ref.watch(unreadCountProvider);

    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: IconButton(
        tooltip: t.notificationsTitle,
        icon: Badge.count(
          count: unread,
          isLabelVisible: unread > 0,
          child: const Icon(Icons.notifications_none),
        ),
        onPressed: () => context.push(Routes.notifications),
      ),
    );
  }
}
