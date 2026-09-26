import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'providers/session_provider.dart';
import 'services/auth_service.dart';
import 'services/connectivity_service.dart';
import 'services/customer_service.dart';
import 'services/prefs_service.dart';
import 'services/room_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Firebase.initializeApp();

  // Offline-first: queue reads/writes locally and sync when the network returns.
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  if (kIsWeb) {
    try {
      await FirebaseFirestore.instance.enablePersistence(
        const PersistenceSettings(synchronizeTabs: true),
      );
    } catch (_) {
      // Persistence may already be enabled after a hot restart.
    }
  }

  final prefs = await PrefsService.create();
  final auth = AuthService();
  final rooms = RoomService();
  final customers = CustomerService();
  final connectivity = ConnectivityService();

  runApp(
    MultiProvider(
      providers: [
        Provider<PrefsService>.value(value: prefs),
        Provider<AuthService>.value(value: auth),
        Provider<RoomService>.value(value: rooms),
        Provider<CustomerService>.value(value: customers),
        ChangeNotifierProvider<ConnectivityService>.value(value: connectivity),
        ChangeNotifierProvider(
          create: (_) => SessionProvider(
            auth: auth,
            prefs: prefs,
            rooms: rooms,
          )..start(),
        ),
      ],
      child: const AlantonyApp(),
    ),
  );
}
