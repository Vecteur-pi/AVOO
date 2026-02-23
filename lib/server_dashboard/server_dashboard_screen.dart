import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth/user_profile.dart';
import '../auth/user_provider.dart';
import '../theme/avoo_theme.dart';

class ServerDashboardScreen extends StatelessWidget {
  const ServerDashboardScreen({super.key, required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AvooColors.bone,
      appBar: AppBar(
        title: const Text('Dashboard Serveur'),
        backgroundColor: AvooColors.bone,
        foregroundColor: AvooColors.ink,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => context.read<UserProvider>().signOut(),
            icon: const Icon(Icons.logout),
            tooltip: 'Se déconnecter',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hey ${profile.name} 👋',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AvooColors.ink,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Bienvenue sur votre espace. Les fonctionnalités serveur seront bientôt disponibles.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[700],
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
