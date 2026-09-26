import 'package:cloud_firestore/cloud_firestore.dart';

class Customer {
  const Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.totalDebt,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
  });

  final String id;
  final String name;
  final String phone;
  final double totalDebt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy;

  bool get hasDebt => totalDebt > 0.0001;

  factory Customer.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Customer(
      id: doc.id,
      name: data['name'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      totalDebt: (data['totalDebt'] as num?)?.toDouble() ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      createdBy: data['createdBy'] as String?,
    );
  }
}
