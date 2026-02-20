import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../login/login_screen.dart';
import '../owner_dashboard/owner_dashboard_screen.dart';
import '../owner_setup/owner_setup_gate.dart';
import '../theme/avoo_theme.dart';
import 'user_profile.dart';
import 'user_provider.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        switch (userProvider.status) {
          case AuthStatus.initial:
          case AuthStatus.loading:
            return const _LoadingScreen();
          case AuthStatus.unauthenticated:
            return const LoginScreen();
          case AuthStatus.error:
            return _MissingProfileScreen(
              message: userProvider.errorMessage ?? 'Erreur inconnue',
            );
          case AuthStatus.authenticated:
            final profile = userProvider.profile;
            if (profile == null) {
              return const _MissingProfileScreen(
                message: 'Profil introuvable.',
              );
            }
            if (!profile.active) {
              return const _AccessDeniedScreen(
                title: 'Compte inactif',
                message:
                    'Ce compte est inactif. Contactez un administrateur pour réactiver l’accès.',
              );
            }
            
            // Logic for owner redirection could also be moved to UserProvider or a separate service
            // For now, keeping it here to match previous behavior but cleaner
            if (UserProfileService.isOwnerRole(profile.role)) {
               return OwnerSetupGate(
                profile: profile,
                dashboard: OwnerDashboardScreen(profile: profile),
              );
            }

            return FutureBuilder<bool>(
              future: UserProfileService.shouldUseOwnerSetup(profile),
              builder: (context, ownerSnapshot) {
                if (ownerSnapshot.connectionState == ConnectionState.waiting) {
                  return const _LoadingScreen();
                }
                final shouldUseOwnerSetup = ownerSnapshot.data ?? false;
                if (shouldUseOwnerSetup) {
                  return OwnerSetupGate(
                    profile: profile,
                    dashboard: OwnerDashboardScreen(profile: profile),
                  );
                }
                return _SignedInScreen(profile: profile);
              },
            );
        }
      },
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class _MissingProfileScreen extends StatelessWidget {
  const _MissingProfileScreen({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AvooColors.bone,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning_amber_rounded, size: 48),
            const SizedBox(height: 16),
            Text(
              'Profil utilisateur introuvable.',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.read<UserProvider>().signOut(),
              child: const Text('Se déconnecter'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignedInScreen extends StatelessWidget {
  const _SignedInScreen({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AvooColors.bone,
      appBar: AppBar(
        title: const Text('Accueil'),
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
              'Bonjour ${profile.name},',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(
              "Vous êtes connecté, mais les pages serveur ont été retirées de cette version.",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.read<UserProvider>().signOut(),
              child: const Text('Se déconnecter'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccessDeniedScreen extends StatelessWidget {
  const _AccessDeniedScreen({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AvooColors.bone,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 48),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.read<UserProvider>().signOut(),
              child: const Text('Se déconnecter'),
            ),
          ],
        ),
      ),
    );
  }
}
