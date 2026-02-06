import 'package:flutter/material.dart';

import 'login/login_screen.dart';
import 'theme/avoo_theme.dart';

void main() {
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
      home: const LoginScreen(),
    );
  }
}
