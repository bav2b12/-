import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';

class PrefsService {
  PrefsService(this._prefs);

  final SharedPreferences _prefs;

  static Future<PrefsService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return PrefsService(prefs);
  }

  String? get roomId => _prefs.getString(PrefsKeys.roomId);

  Future<void> setRoomId(String roomId) {
    return _prefs.setString(PrefsKeys.roomId, roomId);
  }

  Future<void> clearRoomId() {
    return _prefs.remove(PrefsKeys.roomId);
  }
}
