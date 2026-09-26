import 'package:cloud_firestore/cloud_firestore.dart';

class Room {
  const Room({
    required this.id,
    required this.name,
    required this.code,
    required this.ownerId,
    required this.ownerEmail,
    required this.memberIds,
    required this.totalDebt,
    this.createdAt,
  });

  final String id;
  final String name;
  final String code;
  final String ownerId;
  final String ownerEmail;
  final List<String> memberIds;
  final double totalDebt;
  final DateTime? createdAt;

  factory Room.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Room(
      id: doc.id,
      name: data['name'] as String? ?? '',
      code: data['code'] as String? ?? doc.id,
      ownerId: data['ownerId'] as String? ?? '',
      ownerEmail: data['ownerEmail'] as String? ?? '',
      memberIds: List<String>.from(data['memberIds'] as List? ?? const []),
      totalDebt: (data['totalDebt'] as num?)?.toDouble() ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
