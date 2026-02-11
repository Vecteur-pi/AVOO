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
      create: (_) => RegistrationController(
        repository: SupabaseRegistrationRepository(),
      ),
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
        return Scaffold(
          body: Stack(
            children: [
              const RegistrationBackground(),
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final horizontalPadding = width > 600 ? 48.0 : 24.0;
                    final isBusy = controller.isCheckingUnique ||
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
                      }
                    }

                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        18,
                        horizontalPadding,
                        28,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Créer votre compte',
                            style: Theme.of(context).textTheme.displayMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Étape ${controller.currentStep + 1} sur 3',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AvooColors.navy.withOpacity(0.6),
                                ),
                          ),
                          const SizedBox(height: 18),
                          _RegistrationProgressHeader(
                            currentStep: controller.currentStep,
                          ),
                          const SizedBox(height: 18),
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: const Color(0xFFB8D8D2),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 18,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 260),
                              child: _buildStepContent(
                                controller: controller,
                                key: ValueKey(controller.currentStep),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
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
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content:
                                                  Text('Brouillon enregistré.'),
                                            ),
                                          );
                                        }
                                      },
                                child: const Text('Enregistrer le brouillon'),
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
            ],
          ),
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
    final color = isActive ? const Color(0xFF43B6A8) : const Color(0xFFB8D8D2);
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isActive ? color.withOpacity(0.18) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color, width: 1.6),
          ),
          child: Center(
            child: isComplete
                ? const Icon(Icons.check, size: 16, color: Color(0xFF43B6A8))
                : Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isActive
                    ? const Color(0xFF2D6D66)
                    : const Color(0xFF8FA9A5),
                fontWeight: FontWeight.w700,
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
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 14),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF43B6A8) : const Color(0xFFB8D8D2),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}
