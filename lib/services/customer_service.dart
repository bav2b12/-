import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/customer.dart';
import '../models/ledger_entry.dart';

class CustomerService {
  CustomerService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _customers(String roomId) {
    return _db.collection('rooms').doc(roomId).collection('customers');
  }

  CollectionReference<Map<String, dynamic>> _transactions(
    String roomId,
    String customerId,
  ) {
    return _customers(roomId).doc(customerId).collection('transactions');
  }

  Stream<List<Customer>> watchCustomers(String roomId) {
    return _customers(roomId)
        .orderBy('name')
        .snapshots()
        .map((snap) => snap.docs.map(Customer.fromDoc).toList());
  }

  Stream<Customer?> watchCustomer(String roomId, String customerId) {
    return _customers(roomId).doc(customerId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return Customer.fromDoc(doc);
    });
  }

  Stream<List<LedgerEntry>> watchTransactions(String roomId, String customerId) {
    return _transactions(roomId, customerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(LedgerEntry.fromDoc).toList());
  }

  Future<void> addCustomer({
    required String roomId,
    required String name,
    required String phone,
    double initialDebt = 0,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    final roomRef = _db.collection('rooms').doc(roomId);
    final customerRef = _customers(roomId).doc();
    final now = Timestamp.now();

    await _db.runTransaction((tx) async {
      final roomSnap = await tx.get(roomRef);
      final roomDebt = (roomSnap.data()?['totalDebt'] as num?)?.toDouble() ?? 0;

      tx.set(customerRef, {
        'name': name.trim(),
        'phone': phone.trim(),
        'totalDebt': initialDebt,
        'createdAt': now,
        'updatedAt': now,
        'createdBy': user?.email ?? '',
      });

      if (initialDebt > 0) {
        tx.set(_transactions(roomId, customerRef.id).doc(), {
          'type': 'debt',
          'amount': initialDebt,
          'notes': 'رصيد افتتاحي',
          'userEmail': user?.email ?? '',
          'userId': user?.uid ?? '',
          'createdAt': now,
        });
        tx.update(roomRef, {'totalDebt': roomDebt + initialDebt});
      }
    });
  }

  Future<void> addLedgerEntry({
    required String roomId,
    required String customerId,
    required TransactionType type,
    required double amount,
    String notes = '',
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    final roomRef = _db.collection('rooms').doc(roomId);
    final customerRef = _customers(roomId).doc(customerId);
    final txRef = _transactions(roomId, customerId).doc();
    final now = Timestamp.now();
    final delta = type == TransactionType.debt ? amount : -amount;

    await _db.runTransaction((tx) async {
      final customerSnap = await tx.get(customerRef);
      final roomSnap = await tx.get(roomRef);
      if (!customerSnap.exists) {
        throw StateError('العميل غير موجود');
      }

      final current = (customerSnap.data()?['totalDebt'] as num?)?.toDouble() ?? 0;
      final roomDebt = (roomSnap.data()?['totalDebt'] as num?)?.toDouble() ?? 0;
      final nextCustomer = current + delta;
      final nextRoom = roomDebt + delta;

      tx.update(customerRef, {
        'totalDebt': nextCustomer,
        'updatedAt': now,
      });
      tx.update(roomRef, {'totalDebt': nextRoom});
      tx.set(txRef, {
        'type': type == TransactionType.payment ? 'payment' : 'debt',
        'amount': amount,
        'notes': notes.trim(),
        'userEmail': user?.email ?? '',
        'userId': user?.uid ?? '',
        'createdAt': now,
      });
    });
  }
}
