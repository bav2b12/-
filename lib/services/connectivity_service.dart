import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService extends ChangeNotifier {
  ConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity() {
    _subscription = _connectivity.onConnectivityChanged.listen(_onChange);
    _connectivity.checkConnectivity().then(_onChange);
  }

  final Connectivity _connectivity;
  StreamSubscription<dynamic>? _subscription;
  bool _online = true;

  bool get isOnline => _online;

  void _onChange(dynamic result) {
    if (result is List<ConnectivityResult>) {
      _apply(result);
    } else if (result is ConnectivityResult) {
      _apply(<ConnectivityResult>[result]);
    }
  }

  void _apply(List<ConnectivityResult> result) {
    final online = result.any((item) => item != ConnectivityResult.none);
    if (online == _online) return;
    _online = online;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
