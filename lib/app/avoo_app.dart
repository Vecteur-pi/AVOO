import 'package:flutter/material.dart';

import '../auth/auth_screen.dart';
import '../theme/avoo_theme.dart';

class AvooApp extends StatelessWidget {
  const AvooApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Avoo',
      debugShowCheckedModeBanner: false,
      theme: AvooTheme.light,
      home: const AuthScreen(),
    );
  }
}
