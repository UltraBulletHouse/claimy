import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:claimy/app/claimy_app.dart';
import 'package:claimy/state/app_state.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:claimy/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    ChangeNotifierProvider(create: (_) => AppState(), child: const ClaimyApp()),
  );
}
