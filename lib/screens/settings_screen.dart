import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/session_provider.dart';
import '../widgets/feedback.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    final room = session.room;
    final email = session.user?.email ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              title: const Text('الحساب'),
              subtitle: Text(email.isEmpty ? 'مستخدم مسجّل' : email),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('المتجر'),
                  subtitle: Text(room?.name ?? '—'),
                ),
                ListTile(
                  title: const Text('كود الغرفة'),
                  subtitle: Text(room?.code ?? session.roomId ?? '—'),
                  trailing: IconButton(
                    tooltip: 'نسخ',
                    icon: const Icon(Icons.copy),
                    onPressed: () async {
                      final code = room?.code ?? session.roomId;
                      if (code == null) return;
                      await Clipboard.setData(ClipboardData(text: code));
                      if (context.mounted) {
                        showAppSnackBar(context, 'تم نسخ الكود');
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('تغيير الغرفة'),
                  content: const Text(
                    'سيتم إلغاء ربط هذا الجهاز بالغرفة الحالية. بيانات المتجر تبقى محفوظة ويمكنك الانضمام لاحقاً بنفس الكود.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('إلغاء'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('تغيير الغرفة'),
                    ),
                  ],
                ),
              );
              if (ok == true && context.mounted) {
                await context.read<SessionProvider>().leaveRoom();
                if (context.mounted) Navigator.of(context).pop();
              }
            },
            icon: const Icon(Icons.swap_horiz),
            label: const Text('تغيير الغرفة'),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () async {
              await context.read<SessionProvider>().signOut();
              if (context.mounted) Navigator.of(context).pop();
            },
            icon: const Icon(Icons.logout),
            label: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );
  }
}
