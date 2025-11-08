import 'dart:async';

import 'package:claimy/app/claimy_app.dart';
import 'package:claimy/features/home/home_shell.dart';
import 'package:claimy/firebase_options.dart';
import 'package:claimy/services/push_notifications_service.dart';
import 'package:claimy/state/app_state.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  final navigatorKey = GlobalKey<NavigatorState>();
  final pushNotifications = PushNotificationsService();
  await pushNotifications.initialize();

  final initialLocale = await AppState.loadSavedLocale();

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(
        initialLocale: initialLocale,
        pushNotificationsService: pushNotifications,
      ),
      child: ClaimyApp(navigatorKey: navigatorKey),
    ),
  );

  pushNotifications.caseLinks.listen((caseId) {
    final context = navigatorKey.currentContext;
    if (context == null || caseId.isEmpty) {
      return;
    }
    final appState = context.read<AppState>();
    if (!appState.isAuthenticated) {
      return;
    }
    unawaited(appState.refreshCasesFromServer());
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => CaseDetailScreen(caseId: caseId)));
  });
}
