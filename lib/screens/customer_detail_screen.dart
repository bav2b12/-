import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/formatters.dart';
import '../core/theme.dart';
import '../core/validators.dart';
import '../models/ledger_entry.dart';
import '../services/customer_service.dart';
import '../widgets/debt_amount_text.dart';
import '../widgets/feedback.dart';

class CustomerDetailScreen extends StatelessWidget {
  const CustomerDetailScreen({
    super.key,
    required this.roomId,
    required this.customerId,
  });

  final String roomId;
  final String customerId;

  Future<void> _record(
    BuildContext context, {
    required TransactionType type,
  }) async {
    final amount = TextEditingController();
    final notes = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final isDebt = type == TransactionType.debt;

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
                  isDebt ? 'إضافة دَيْن / بضاعة' : 'تسجيل دفعة / سداد',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: amount,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'المبلغ'),
                  validator: Validators.positiveMoney,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: notes,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: isDebt ? 'وصف الصنف / ملاحظات (اختياري)' : 'ملاحظات (اختياري)',
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        isDebt ? AlantonyTheme.debtRed : AlantonyTheme.settledGreen,
                  ),
                  onPressed: () {
                    if (formKey.currentState?.validate() ?? false) {
                      Navigator.pop(context, true);
                    }
                  },
                  child: Text(isDebt ? 'تأكيد الدين' : 'تأكيد السداد'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (saved != true || !context.mounted) {
      amount.dispose();
      notes.dispose();
      return;
    }

    try {
      await context.read<CustomerService>().addLedgerEntry(
            roomId: roomId,
            customerId: customerId,
            type: type,
            amount: Validators.parseMoney(amount.text),
            notes: notes.text,
          );
    } catch (error) {
      if (context.mounted) {
        showAppSnackBar(context, friendlyError(error), error: true);
      }
    } finally {
      amount.dispose();
      notes.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final customers = context.read<CustomerService>();

    return StreamBuilder(
      stream: customers.watchCustomer(roomId, customerId),
      builder: (context, customerSnap) {
        final customer = customerSnap.data;
        return Scaffold(
          appBar: AppBar(
            title: Text(customer?.name ?? 'تفاصيل العميل'),
          ),
          body: customer == null
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                customer.name,
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 4),
                              Text(customer.phone),
                              const SizedBox(height: 12),
                              const Text('الرصيد الحالي'),
                              DebtAmountText(amount: customer.totalDebt, large: true),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: AlantonyTheme.debtRed,
                                minimumSize: const Size.fromHeight(48),
                              ),
                              onPressed: () => _record(
                                context,
                                type: TransactionType.debt,
                              ),
                              child: const Text('إضافة دَيْن / بضاعة'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: AlantonyTheme.settledGreen,
                                minimumSize: const Size.fromHeight(48),
                              ),
                              onPressed: () => _record(
                                context,
                                type: TransactionType.payment,
                              ),
                              child: const Text('تسجيل دفعة / سداد'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: StreamBuilder(
                        stream: customers.watchTransactions(roomId, customerId),
                        builder: (context, txSnap) {
                          if (!txSnap.hasData) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          final items = txSnap.data!;
                          if (items.isEmpty) {
                            return const Center(child: Text('لا توجد حركات بعد'));
                          }
                          return ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            itemCount: items.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              return _TransactionTile(entry: items[index]);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.entry});

  final LedgerEntry entry;

  @override
  Widget build(BuildContext context) {
    final isDebt = entry.isDebt;
    final color = isDebt ? AlantonyTheme.debtRed : AlantonyTheme.settledGreen;

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.12),
          child: Icon(
            isDebt ? Icons.trending_up : Icons.trending_down,
            color: color,
          ),
        ),
        title: Text(isDebt ? 'دين / بضاعة' : 'دفعة / سداد'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (entry.notes.isNotEmpty) Text(entry.notes),
            Text(formatTimestamp(entry.createdAt)),
            if (entry.userEmail.isNotEmpty)
              Text(
                entry.userEmail,
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
        trailing: Text(
          '${isDebt ? '+' : '-'} ${Money.format(entry.amount)}',
          style: TextStyle(color: color, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
