import 'package:flutter/material.dart';

import '../auth/user_profile.dart';
import '../config/app_flags.dart';
import '../theme/avoo_theme.dart';
import 'owner_setup_manager_form_screen.dart';
import 'owner_setup_manager_choice_screen.dart';
import 'owner_setup_service.dart';
import 'owner_setup_state.dart';

class OwnerSetupGate extends StatelessWidget {
  const OwnerSetupGate({
    super.key,
    required this.profile,
    required this.dashboard,
    this.service = const OwnerSetupService(),
  });

  final UserProfile profile;
  final Widget dashboard;
  final OwnerSetupService service;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<OwnerSetupState>(
      stream: service.watch(profile.restaurantId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: const Color(0xFFE8F0DF),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 42),
                    const SizedBox(height: 10),
                    Text(
                      'Impossible de charger la configuration propriétaire.',
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final setupState =
            snapshot.data ?? OwnerSetupState.initial(profile.restaurantId);

        if (!AppFlags.forceOwnerSetup &&
            setupState.setupCompleted &&
            setupState.requiredStepsCompleted) {
          return dashboard;
        }

        return OwnerSetupScreen(
          profile: profile,
          state: setupState,
          service: service,
        );
      },
    );
  }
}

class OwnerSetupScreen extends StatefulWidget {
  const OwnerSetupScreen({
    super.key,
    required this.profile,
    required this.state,
    required this.service,
  });

  final UserProfile profile;
  final OwnerSetupState state;
  final OwnerSetupService service;

  @override
  State<OwnerSetupScreen> createState() => _OwnerSetupScreenState();
}

class _OwnerSetupScreenState extends State<OwnerSetupScreen> {
  OwnerSetupStep? _savingStep;
  bool _finishing = false;

  Future<void> _toggleStep(OwnerSetupStep step, bool currentValue) async {
    if (_savingStep != null || _finishing) return;
    setState(() {
      _savingStep = step;
    });
    try {
      await widget.service.setStep(
        widget.state.restaurantId,
        step,
        !currentValue,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mise à jour impossible. Réessayez.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _savingStep = null;
        });
      }
    }
  }

  Future<void> _finishSetup() async {
    if (_finishing || !widget.state.requiredStepsCompleted) return;
    setState(() {
      _finishing = true;
    });
    try {
      await widget.service.markSetupCompleted(widget.state.restaurantId);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Finalisation impossible. Réessayez.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _finishing = false;
        });
      }
    }
  }

  Future<void> _openManagerChoice() async {
    if (_savingStep != null || _finishing) return;

    final selection = await Navigator.of(context).push<ManagerChoiceOption>(
      MaterialPageRoute(builder: (_) => const OwnerSetupManagerChoiceScreen()),
    );
    if (!mounted || selection == null) return;

    if (selection == ManagerChoiceOption.selfManage) {
      await _applyOwnerAsManager();
      return;
    }

    final managerInput = await Navigator.of(context).push<ManagerContactInput>(
      MaterialPageRoute(builder: (_) => const OwnerSetupManagerFormScreen()),
    );
    if (!mounted || managerInput == null) return;

    await _applyAppointedManager(managerInput);
  }

  Future<void> _applyOwnerAsManager() async {
    if (_savingStep != null || _finishing) return;
    setState(() {
      _savingStep = OwnerSetupStep.managerCreated;
    });
    try {
      await widget.service.assignOwnerAsManager(
        restaurantId: widget.state.restaurantId,
        ownerUid: widget.profile.uid,
        ownerName: widget.profile.name,
        ownerEmail: widget.profile.email,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mise à jour impossible. Réessayez.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _savingStep = null;
        });
      }
    }
  }

  Future<void> _applyAppointedManager(ManagerContactInput input) async {
    if (_savingStep != null || _finishing) return;

    setState(() {
      _savingStep = OwnerSetupStep.managerCreated;
    });
    try {
      await widget.service.saveManagerInvitation(
        restaurantId: widget.state.restaurantId,
        fullName: input.fullName,
        email: input.email,
        phone: input.phone,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invitation gérant enregistrée.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mise à jour impossible. Réessayez.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _savingStep = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final progress = state.completedStepsCount / 4.0;
    final continueEnabled = state.requiredStepsCompleted && !_finishing;
    final restaurantName = state.restaurantName.trim();
    final exampleSuffixMatch = RegExp(
      r'^(.*?)(\s*\(.*\))$',
    ).firstMatch(restaurantName);
    final mediaQuery = MediaQuery.of(context);

    return MediaQuery(
      data: mediaQuery.copyWith(textScaler: TextScaler.noScaling),
      child: Scaffold(
        backgroundColor: _OwnerSetupColors.screen,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(10, 16, 10, 14),
                  decoration: BoxDecoration(
                    color: _OwnerSetupColors.surface,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.84),
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.09),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'Bienvenue',
                                      textScaler: TextScaler.noScaling,
                                      style: TextStyle(
                                        fontSize: 31,
                                        height: 1.04,
                                        letterSpacing: -0.3,
                                        fontWeight: FontWeight.w800,
                                        color: AvooColors.green,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: RichText(
                                      textScaler: TextScaler.noScaling,
                                      text: TextSpan(
                                        style: const TextStyle(
                                          color: Color(0xFF36455E),
                                          fontSize: 16,
                                          height: 1.1,
                                          letterSpacing: 0,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        children: [
                                          const TextSpan(text: 'Restaurant: '),
                                          TextSpan(
                                            text:
                                                exampleSuffixMatch?.group(1) ??
                                                restaurantName,
                                            style: const TextStyle(
                                              color: AvooColors.green,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          if (exampleSuffixMatch != null)
                                            TextSpan(
                                              text: exampleSuffixMatch.group(2),
                                              style: const TextStyle(
                                                color: Color(0xFF8E97AB),
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Padding(
                              padding: EdgeInsets.only(top: 2),
                              child: _WelcomeManAnimation(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
                        decoration: BoxDecoration(
                          color: _OwnerSetupColors.primaryCard,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.09),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Prochaine étape',
                              textScaler: TextScaler.noScaling,
                              style: TextStyle(
                                color: Color(0xFFDCEAD2),
                                fontSize: 14,
                                height: 1.08,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "Configurer Avo'o en 5 minutes",
                                maxLines: 1,
                                softWrap: false,
                                textScaler: TextScaler.noScaling,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  height: 1.15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(99),
                              child: LinearProgressIndicator(
                                minHeight: 8,
                                value: progress,
                                backgroundColor: const Color(
                                  0xFF93AE82,
                                ).withOpacity(0.8),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFFE7F1DD),
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              '${state.completedStepsCount} sur 4 étapes complétées',
                              textScaler: TextScaler.noScaling,
                              style: const TextStyle(
                                color: Color(0xFFE2ECDC),
                                fontSize: 14,
                                height: 1.1,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      _SetupStepTile(
                        title: '1. Créer un gérant',
                        icon: Icons.manage_accounts_outlined,
                        isDone: state.managerCreated,
                        isOptional: false,
                        isSaving: _savingStep == OwnerSetupStep.managerCreated,
                        onTap: _openManagerChoice,
                      ),
                      _SetupStepTile(
                        title: '2. Ajouter les tables',
                        icon: Icons.restaurant_outlined,
                        isDone: state.tablesAdded,
                        isOptional: false,
                        isSaving: _savingStep == OwnerSetupStep.tablesAdded,
                        onTap: () => _toggleStep(
                          OwnerSetupStep.tablesAdded,
                          state.tablesAdded,
                        ),
                      ),
                      _SetupStepTile(
                        title: '3. Générer QR codes',
                        icon: Icons.qr_code_2_outlined,
                        isDone: state.qrGenerated,
                        isOptional: false,
                        isSaving: _savingStep == OwnerSetupStep.qrGenerated,
                        onTap: () => _toggleStep(
                          OwnerSetupStep.qrGenerated,
                          state.qrGenerated,
                        ),
                      ),
                      _SetupStepTile(
                        title: '4. Activer paiements',
                        icon: Icons.credit_card_outlined,
                        isDone: state.paymentsEnabled,
                        isOptional: true,
                        isSaving: _savingStep == OwnerSetupStep.paymentsEnabled,
                        onTap: () => _toggleStep(
                          OwnerSetupStep.paymentsEnabled,
                          state.paymentsEnabled,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 66,
                        child: ElevatedButton(
                          onPressed: continueEnabled ? _finishSetup : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: continueEnabled
                                ? _OwnerSetupColors.primaryCard
                                : const Color(0xFFD3D5DE),
                            foregroundColor: continueEnabled
                                ? Colors.white
                                : const Color(0xFF8E97AA),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(26),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                          ),
                          child: _finishing
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'Continuer la configuration',
                                      maxLines: 1,
                                      softWrap: false,
                                      textScaler: TextScaler.noScaling,
                                      style: TextStyle(
                                        fontSize: 17,
                                        height: 1.05,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.chevron_right, size: 30),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SetupStepTile extends StatelessWidget {
  const _SetupStepTile({
    required this.title,
    required this.icon,
    required this.isDone,
    required this.isOptional,
    required this.isSaving,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final bool isDone;
  final bool isOptional;
  final bool isSaving;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final showDoneStyle = isDone && !isSaving;
    final statusLabel = isDone ? 'Fait' : (isOptional ? 'Option' : 'À faire');
    final statusColor = isDone
        ? const Color(0xFF91BC84)
        : (isOptional
              ? const Color(0xFFA1BE94)
              : _OwnerSetupColors.primaryPill);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.symmetric(
        horizontal: showDoneStyle ? 18 : 8,
        vertical: showDoneStyle ? 16 : 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.84),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: showDoneStyle ? 52 : 36,
            height: showDoneStyle ? 52 : 36,
            decoration: BoxDecoration(
              color: showDoneStyle
                  ? const Color(0xFF6F985C)
                  : const Color(0xFFF0F1F4),
              borderRadius: BorderRadius.circular(showDoneStyle ? 18 : 12),
            ),
            child: Icon(
              showDoneStyle ? Icons.check_rounded : icon,
              color: showDoneStyle ? Colors.white : const Color(0xFF545F71),
              size: showDoneStyle ? 34 : 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SizedBox(
              height: showDoneStyle ? 34 : 28,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  title,
                  maxLines: 1,
                  softWrap: false,
                  textScaler: TextScaler.noScaling,
                  style: TextStyle(
                    fontSize: showDoneStyle ? 17 : 19,
                    height: 1.04,
                    fontWeight: FontWeight.w800,
                    color: showDoneStyle
                        ? const Color(0xFF697387)
                        : AvooColors.navy,
                    decoration: showDoneStyle
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                    decorationColor: const Color(0xFF697387),
                    decorationThickness: showDoneStyle ? 2.6 : 0,
                  ),
                ),
              ),
            ),
          ),
          if (!showDoneStyle) ...[
            const SizedBox(width: 8),
            SizedBox(
              width: 78,
              height: 48,
              child: ElevatedButton(
                onPressed: isSaving ? null : onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: statusColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        statusLabel,
                        textScaler: TextScaler.noScaling,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          height: 1.0,
                        ),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WelcomeManAnimation extends StatelessWidget {
  const _WelcomeManAnimation();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        width: 116,
        height: 116,
        child: Image.asset(
          'assets/images/welcome_man_transparent_trim.png',
          fit: BoxFit.contain,
          alignment: Alignment.center,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}

class _OwnerSetupColors {
  static const Color screen = Color(0xFFD8E4D0);
  static const Color surface = Color(0xFFCBDBC3);
  static const Color primaryCard = Color(0xFF709B5F);
  static const Color primaryPill = Color(0xFF699753);
}
