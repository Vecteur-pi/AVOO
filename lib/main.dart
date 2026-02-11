import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'firebase_options.dart';
import 'auth/auth_gate.dart';
import 'theme/avoo_theme.dart';
import 'supabase/supabase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
  }
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const AvooApp());
}

class AvooApp extends StatelessWidget {
  const AvooApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Avoo',
      debugShowCheckedModeBanner: false,
      theme: AvooTheme.light,
      home: const AuthGate(),
    );
  }
}
