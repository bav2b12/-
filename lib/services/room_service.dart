import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/constants.dart';
import '../core/validators.dart';
import '../models/room.dart';

class RoomService {
  RoomService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _rooms => _db.collection('rooms');

  Stream<Room?> watchRoom(String roomId) {
    return _rooms.doc(roomId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return Room.fromDoc(doc);
    });
  }

  Future<Room> createRoom({required String name}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('يجب تسجيل الدخول أولاً');
    }

    final trimmed = name.trim();
    String code = '';
    DocumentReference<Map<String, dynamic>>? ref;

    for (var attempt = 0; attempt < 8; attempt++) {
      code = _generateCode();
      ref = _rooms.doc(code);
      final existing = await ref.get();
      if (!existing.exists) break;
      if (attempt == 7) {
        throw StateError('تعذر توليد كود فريد، حاول مرة أخرى');
      }
    }

    await ref!.set({
      'name': trimmed,
      'code': code,
      'ownerId': user.uid,
      'ownerEmail': user.email ?? '',
      'memberIds': [user.uid],
      'totalDebt': 0.0,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return Room(
      id: code,
      name: trimmed,
      code: code,
      ownerId: user.uid,
      ownerEmail: user.email ?? '',
      memberIds: [user.uid],
      totalDebt: 0,
    );
  }

  Future<Room> joinRoom(String rawCode) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('يجب تسجيل الدخول أولاً');
    }

    final code = Validators.normalizeRoomCode(rawCode);
    final ref = _rooms.doc(code);
    final snapshot = await ref.get();
    if (!snapshot.exists) {
      throw StateError('كود الغرفة غير صحيح');
    }

    await ref.update({
      'memberIds': FieldValue.arrayUnion([user.uid]),
    });

    return Room.fromDoc(await ref.get());
  }

  String _generateCode() {
    final random = Random.secure();
    final chars = AppConstants.roomCodeAlphabet;
    return List.generate(
      AppConstants.roomCodeLength,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
  }
}
