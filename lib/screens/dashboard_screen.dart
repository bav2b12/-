import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/formatters.dart';
import '../core/validators.dart';
import '../models/customer.dart';
import '../providers/session_provider.dart';
import '../services/customer_service.dart';
import '../widgets/debt_amount_text.dart';
import '../widgets/feedback.dart';
import 'customer_detail_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Customer> _filter(List<Customer> customers) {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return customers;
    return customers.where((c) {
      return c.name.toLowerCase().contains(q) || c.phone.contains(q);
    }).toList();
  }

  Future<void> _copyCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    showAppSnackBar(context, 'تم نسخ كود الغرفة: $code');
  }

  Future<void> _addCustomer() async {
    final name = TextEditingController();
    final phone = TextEditingController();
    final debt = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 8,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'إضافة عميل جديد',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: name,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'اسم العميل'),
                  validator: (v) => Validators.requiredText(v, label: 'اسم العميل'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phone,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'رقم الهاتف'),
                  validator: Validators.phone,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: debt,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'دين افتتاحي (اختياري)',
                    hintText: '0',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return null;
                    return Validators.positiveMoney(value);
                  },
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    if (formKey.currentState?.validate() ?? false) {
                      Navigator.pop(context, true);
                    }
                  },
                  child: const Text('حفظ العميل'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (saved != true || !mounted) {
      name.dispose();
      phone.dispose();
      debt.dispose();
      return;
    }

    final roomId = context.read<SessionProvider>().roomId;
    if (roomId == null) return;

    try {
      final initial = debt.text.trim().isEmpty ? 0.0 : Validators.parseMoney(debt.text);
      await context.read<CustomerService>().addCustomer(
            roomId: roomId,
            name: name.text,
            phone: phone.text,
            initialDebt: initial,
          );
      if (mounted) showAppSnackBar(context, 'تمت إضافة العميل');
    } catch (error) {
      if (mounted) showAppSnackBar(context, friendlyError(error), error: true);
    } finally {
      name.dispose();
      phone.dispose();
      debt.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    final room = session.room;
    final roomId = session.roomId;
    final code = room?.code ?? roomId ?? '';
    final storeName = room?.name ?? 'الأنطوني';
    final totalDebt = room?.totalDebt ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(storeName, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            InkWell(
              onTap: code.isEmpty ? null : () => _copyCode(code),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    code,
                    style: const TextStyle(fontSize: 13, letterSpacing: 1.4),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.copy, size: 14),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'الإعدادات',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                const Text('إجمالي الديون'),
                const Spacer(),
                Text(
                  Money.format(totalDebt),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addCustomer,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('إضافة عميل جديد'),
      ),
      body: roomId == null
          ? const SizedBox.shrink()
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: TextField(
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'بحث بالاسم أو رقم الهاتف',
                    ),
                  ),
                ),
                Expanded(
                  child: StreamBuilder(
                    stream: context.read<CustomerService>().watchCustomers(roomId),
                    builder: (context, snapshot) {
                      if (snapshot.hasError && !snapshot.hasData) {
                        return const Center(
                          child: Text('جاري التحميل من الذاكرة المحلية...'),
                        );
                      }
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final filtered = _filter(snapshot.data!);
                      if (filtered.isEmpty) {
                        return const Center(
                          child: Text('لا يوجد عملاء مطابقون'),
                        );
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final customer = filtered[index];
                          return _CustomerCard(customer: customer, roomId: roomId);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({required this.customer, required this.roomId});

  final Customer customer;
  final String roomId;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          customer.name,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(customer.phone),
        trailing: DebtAmountText(amount: customer.totalDebt),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CustomerDetailScreen(
                roomId: roomId,
                customerId: customer.id,
              ),
            ),
          );
        },
      ),
    );
  }
}
