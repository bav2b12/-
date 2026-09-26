import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/validators.dart';
import '../providers/session_provider.dart';
import '../services/room_service.dart';
import '../widgets/feedback.dart';

class RoomSetupScreen extends StatefulWidget {
  const RoomSetupScreen({super.key});

  @override
  State<RoomSetupScreen> createState() => _RoomSetupScreenState();
}

class _RoomSetupScreenState extends State<RoomSetupScreen> {
  bool _busy = false;

  Future<void> _createRoom() async {
    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            top: 8,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'إنشاء غرفة جديدة',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nameController,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'اسم المتجر / الغرفة',
                    hintText: 'مثال: فرع الأنطوني',
                  ),
                  validator: (v) => Validators.requiredText(v, label: 'اسم المتجر'),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    if (formKey.currentState?.validate() ?? false) {
                      Navigator.pop(context, true);
                    }
                  },
                  child: const Text('إنشاء الغرفة'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed != true || !mounted) {
      nameController.dispose();
      return;
    }

    setState(() => _busy = true);
    try {
      final room = await context.read<RoomService>().createRoom(
            name: nameController.text,
          );
      await context.read<SessionProvider>().attachRoom(room.id);
    } catch (error) {
      if (mounted) showAppSnackBar(context, friendlyError(error), error: true);
    } finally {
      nameController.dispose();
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _joinRoom() async {
    final codeController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            top: 8,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'الانضمام لغرفة قائمة',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: codeController,
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 8,
                  decoration: const InputDecoration(
                    labelText: 'كود الغرفة',
                    hintText: 'مثال: ANT892',
                    counterText: '',
                  ),
                  validator: Validators.roomCode,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    if (formKey.currentState?.validate() ?? false) {
                      Navigator.pop(context, true);
                    }
                  },
                  child: const Text('انضمام'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed != true || !mounted) {
      codeController.dispose();
      return;
    }

    setState(() => _busy = true);
    try {
      final room = await context.read<RoomService>().joinRoom(codeController.text);
      await context.read<SessionProvider>().attachRoom(room.id);
    } catch (error) {
      if (mounted) showAppSnackBar(context, friendlyError(error), error: true);
    } finally {
      codeController.dispose();
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('اختيار الغرفة')),
      body: AbsorbPointer(
        absorbing: _busy,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'اربط حسابك بغرفة المتجر للمتابعة',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              _ChoiceCard(
                icon: Icons.add_home_rounded,
                title: 'إنشاء غرفة جديدة',
                subtitle: 'توليد كود من 6 أحرف وتعيينك كمالك للغرفة',
                onTap: _createRoom,
              ),
              const SizedBox(height: 12),
              _ChoiceCard(
                icon: Icons.login,
                title: 'الانضمام لغرفة قائمة',
                subtitle: 'أدخل كود الغرفة للوصول إلى بيانات المتجر',
                onTap: _joinRoom,
              ),
              if (_busy) ...[
                const SizedBox(height: 24),
                const Center(child: CircularProgressIndicator()),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Icon(icon),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_left),
            ],
          ),
        ),
      ),
    );
  }
}
