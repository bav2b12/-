import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/room.dart';
import '../services/auth_service.dart';
import '../services/prefs_service.dart';
import '../services/room_service.dart';

class SessionProvider extends ChangeNotifier {
  SessionProvider({
    required AuthService auth,
    required PrefsService prefs,
    required RoomService rooms,
  })  : _auth = auth,
        _prefs = prefs,
        _rooms = rooms;

  final AuthService _auth;
  final PrefsService _prefs;
  final RoomService _rooms;

  StreamSubscription<User?>? _authSub;
  StreamSubscription<Room?>? _roomSub;

  User? _user;
  Room? _room;
  String? _roomId;
  bool _ready = false;
  String? _error;

  bool get isReady => _ready;
  bool get isSignedIn => _user != null;
  bool get hasRoom => _roomId != null && _roomId!.isNotEmpty;
  User? get user => _user;
  Room? get room => _room;
  String? get roomId => _roomId;
  String? get error => _error;

  void start() {
    _roomId = _prefs.roomId;
    _authSub = _auth.authState().listen((user) {
      _user = user;
      _bindRoom();
      _ready = true;
      notifyListeners();
    });
  }

  void _bindRoom() {
    _roomSub?.cancel();
    final id = _roomId;
    if (_user == null || id == null || id.isEmpty) {
      _room = null;
      return;
    }
    _roomSub = _rooms.watchRoom(id).listen((room) {
      _room = room;
      notifyListeners();
    });
  }

  Future<void> attachRoom(String roomId) async {
    await _prefs.setRoomId(roomId);
    _roomId = roomId;
    _bindRoom();
    notifyListeners();
  }

  Future<void> leaveRoom() async {
    await _prefs.clearRoomId();
    _roomId = null;
    _room = null;
    await _roomSub?.cancel();
    notifyListeners();
  }

  Future<void> signOut() async {
    await leaveRoom();
    await _auth.signOut();
  }

  void setError(String? message) {
    _error = message;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _roomSub?.cancel();
    super.dispose();
  }
}
