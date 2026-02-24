import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/avoo_theme.dart';
import '../services/supabase_registration_repository.dart';
import '../state/registration_controller.dart';
import 'registration_complete_screen.dart';
import 'steps/personal_info_step.dart';
import 'steps/restaurant_info_step.dart';
import 'steps/verification_step.dart';
import 'widgets/glow_button.dart';
import 'widgets/registration_background.dart';

class RegistrationFlowScreen extends StatelessWidget {
  const RegistrationFlowScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          RegistrationController(repository: SupabaseRegistrationRepository()),
      child: const _RegistrationFlowView(),
    );
  }
}

class _RegistrationFlowView extends StatelessWidget {
  const _RegistrationFlowView();

  @override
  Widget build(BuildContext context) {
    return Consumer<RegistrationController>(
      builder: (context, controller, _) {
        return Stack(
          children: [
            const RegistrationBackground(),
            Scaffold(
              backgroundColor: Colors.transparent,
              body: SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final horizontalPadding = width > 600 ? 48.0 : 24.0;
                    final isBusy =
                        controller.isCheckingUnique ||
                        controller.isVerifying ||
                        controller.isSubmitting;
                    final isLast = controller.currentStep == 2;
                    final isFirst = controller.currentStep == 0;
                    final canProceed = isLast
                        ? controller.canSubmit
                        : controller.currentStep == 0
                        ? controller.canProceedStep1
                        : controller.canProceedStep2;

                    Future<void> handlePrimary() async {
                      if (controller.currentStep == 0) {
                        final ok = await controller.submitStep1();
                        if (ok) {
                          controller.goNext();
                        }
                        return;
                      }
                      if (controller.currentStep == 1) {
                        final ok = controller.submitStep2();
                        if (ok) {
                          controller.goNext();
                        }
                        return;
                      }
                      final ok = await controller.completeRegistration();
                      if (ok && context.mounted) {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => const RegistrationCompleteScreen(),
                          ),
                        );
                      } else if (!ok && context.mounted) {
                        final message =
                            controller.submitError ??
                            controller.verificationError ??
                            'Inscription impossible. Vérifiez votre configuration Firebase.';
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(message)));
                      }
                    }

                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        12,
                        horizontalPadding,
                        12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: Image.asset(
                              'assets/images/Logo.png',
                              width: 200, // Reduced slightly to balance "make larger" and "fit on screen" constraints
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Créer votre compte',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                              color: const Color(0xFF146D36),
                              fontWeight: FontWeight.w700,
                              fontSize: 28, // Slightly smaller font
                            ),
                          ),
                          const SizedBox(height: 16),
                          _RegistrationProgressHeader(
                            currentStep: controller.currentStep,
                          ),
                          const SizedBox(height: 16),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 260),
                            child: _buildStepContent(
                              controller: controller,
                              key: ValueKey(controller.currentStep),
                            ),
                          ),
                          const SizedBox(height: 16),
                          GlowButton(
                            label: isLast ? 'Terminer' : 'Suivant',
                            onPressed: (!canProceed || isBusy)
                                ? null
                                : () => handlePrimary(),
                            isLoading: isBusy,
                          ),
                          const SizedBox(height: 12),
                          if (!isLast)
                            Center(
                              child: TextButton(
                                onPressed: isBusy
                                    ? null
                                    : () async {
                                        await controller.saveDraft();
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Brouillon enregistré.',
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFF146D36),
                                ),
                                child: const Text(
                                  'Enregistrer le brouillon',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                    decorationColor: Color(0xFF146D36),
                                  ),
                                ),
                              ),
                            ),
                          if (!isFirst)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                onPressed: isBusy ? null : controller.goBack,
                                icon: const Icon(Icons.chevron_left),
                                label: const Text('Retour'),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
                ),
              ),
            ],
          );
      },
    );
  }
}

Widget _buildStepContent({
  required RegistrationController controller,
  Key? key,
}) {
  switch (controller.currentStep) {
    case 0:
      return PersonalInfoStep(key: key, controller: controller);
    case 1:
      return RestaurantInfoStep(key: key, controller: controller);
    case 2:
    default:
      return VerificationStep(key: key, controller: controller);
  }
}

class _RegistrationProgressHeader extends StatelessWidget {
  const _RegistrationProgressHeader({required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StepDot(
          index: 0,
          label: 'Profil',
          isActive: currentStep >= 0,
          isComplete: currentStep > 0,
        ),
        _StepConnector(isActive: currentStep >= 1),
        _StepDot(
          index: 1,
          label: 'Restaurant',
          isActive: currentStep >= 1,
          isComplete: currentStep > 1,
        ),
        _StepConnector(isActive: currentStep >= 2),
        _StepDot(
          index: 2,
          label: 'Vérification',
          isActive: currentStep >= 2,
          isComplete: currentStep > 2,
        ),
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({
    required this.index,
    required this.label,
    required this.isActive,
    required this.isComplete,
  });

  final int index;
  final String label;
  final bool isActive;
  final bool isComplete;

  @override
  Widget build(BuildContext context) {
    final bgColor = isActive ? const Color(0xFF146D36) : Colors.white;
    final textColor = isActive ? Colors.white : const Color(0xFF111827);

    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF146D36), width: 1.5),
          ),
          child: Center(
            child: isComplete
                ? const Icon(Icons.check, size: 18, color: Colors.white)
                : Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: const Color(0xFF111827),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _StepConnector extends StatelessWidget {
  const _StepConnector({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 1.5,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        decoration: const BoxDecoration(
          color: Color(0xFF146D36),
        ),
      ),
    );
  }
}
