import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:claimy/app/claimy_app.dart';
import 'package:claimy/state/app_state.dart';

void main() {
  runApp(
    ChangeNotifierProvider(create: (_) => AppState(), child: const ClaimyApp()),
  );
}
