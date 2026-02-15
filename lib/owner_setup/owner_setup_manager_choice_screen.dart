import 'package:flutter/material.dart';

import '../theme/avoo_theme.dart';

enum ManagerChoiceOption { selfManage, appointManager }

class OwnerSetupManagerChoiceScreen extends StatelessWidget {
  const OwnerSetupManagerChoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return MediaQuery(
      data: mediaQuery.copyWith(textScaler: TextScaler.noScaling),
      child: Scaffold(
        backgroundColor: const Color(0xFFD8E4D0),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: AvooColors.green,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 2,
                      vertical: 6,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_back, size: 28),
                      SizedBox(width: 8),
                      Text(
                        'Retour',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.84),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: AvooColors.green,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Icon(
                              Icons.auto_awesome_outlined,
                              color: Colors.white,
                              size: 36,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Text(
                              'Gestion du resto',
                              style: TextStyle(
                                color: AvooColors.green,
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                height: 1.06,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Étape 1 sur 4',
                        style: TextStyle(
                          color: Color(0xFF49556C),
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.84),
                    borderRadius: BorderRadius.circular(28),
                    border: const Border(
                      left: BorderSide(color: Color(0xFF6D995D), width: 6),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Question',
                        style: TextStyle(
                          color: Color(0xFF636D81),
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Qui va gérer le restaurant au quotidien ?',
                        style: TextStyle(
                          color: AvooColors.navy,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          height: 1.16,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _ManagerChoiceCard(
                  background: const Color(0xFF5C8550),
                  icon: Icons.account_circle_outlined,
                  title: 'Je gère moi-même',
                  subtitle: 'Parfait pour les propriétaires actifs',
                  hint: 'Ton compte aura aussi le rôle « Gérant »',
                  onTap: () {
                    Navigator.of(context).pop(ManagerChoiceOption.selfManage);
                  },
                ),
                const SizedBox(height: 12),
                _ManagerChoiceCard(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0C1930), Color(0xFF1F2D45)],
                  ),
                  icon: Icons.person_add_alt_1_rounded,
                  title: 'Je nomme un gérant',
                  subtitle: 'Déléguer la gestion quotidienne',
                  hint: "Création d'un compte gérant (email/tel)",
                  onTap: () {
                    Navigator.of(
                      context,
                    ).pop(ManagerChoiceOption.appointManager);
                  },
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDE5EF),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFC2D2E8)),
                  ),
                  child: const Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: '💡 '),
                        TextSpan(
                          text: 'Conseil',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        TextSpan(
                          text:
                              ' : Vous pourrez toujours modifier ces paramètres plus tard dans les réglages de votre restaurant.',
                        ),
                      ],
                    ),
                    style: TextStyle(
                      color: Color(0xFF4D66A8),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      height: 1.28,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ManagerChoiceCard extends StatelessWidget {
  const _ManagerChoiceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.hint,
    required this.onTap,
    this.background,
    this.gradient,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String hint;
  final VoidCallback onTap;
  final Color? background;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(32),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          decoration: BoxDecoration(
            color: background,
            gradient: gradient,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(icon, color: Colors.white, size: 38),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                            height: 1.08,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.82),
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            height: 1.12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xB3FFFFFF),
                    size: 36,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.arrow_right_alt_rounded,
                      color: Color(0xE6FFFFFF),
                      size: 36,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        hint,
                        style: const TextStyle(
                          color: Color(0xE6FFFFFF),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          height: 1.15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
