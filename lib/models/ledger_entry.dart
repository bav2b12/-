import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType { debt, payment }

class LedgerEntry {
  const LedgerEntry({
    required this.id,
    required this.type,
    required this.amount,
    required this.notes,
    required this.userEmail,
    required this.userId,
    required this.createdAt,
  });

  final String id;
  final TransactionType type;
  final double amount;
  final String notes;
  final String userEmail;
  final String userId;
  final DateTime createdAt;

  bool get isDebt => type == TransactionType.debt;

  factory LedgerEntry.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final typeRaw = data['type'] as String? ?? 'debt';
    return LedgerEntry(
      id: doc.id,
      type: typeRaw == 'payment' ? TransactionType.payment : TransactionType.debt,
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      notes: data['notes'] as String? ?? '',
      userEmail: data['userEmail'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
