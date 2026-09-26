import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'providers/session_provider.dart';
import 'screens/auth_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/room_setup_screen.dart';
import 'screens/splash_screen.dart';
import 'widgets/connectivity_banner.dart';

class AlantonyApp extends StatelessWidget {
  const AlantonyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'الأنطوني',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AlantonyTheme.light(),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            children: [
              const ConnectivityBanner(),
              Expanded(child: child ?? const SizedBox.shrink()),
            ],
          ),
        );
      },
      home: const _RootGate(),
    );
  }
}

class _RootGate extends StatelessWidget {
  const _RootGate();

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();

    if (!session.isReady) {
      return const SplashScreen();
    }
    if (!session.isSignedIn) {
      return const AuthScreen();
    }
    if (!session.hasRoom) {
      return const RoomSetupScreen();
    }
    return const DashboardScreen();
  }
}
