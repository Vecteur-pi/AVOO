import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/avoo_theme.dart';
import '../../sync/offline_sync_controller.dart';
import '../services/supabase_registration_repository.dart';
import '../state/registration_controller.dart';
import 'registration_complete_screen.dart';
import 'steps/personal_info_step.dart';
import 'steps/restaurant_info_step.dart';
import 'steps/verification_step.dart';
import 'widgets/primary_sticky_button.dart';

class RegistrationFlowScreen extends StatelessWidget {
  const RegistrationFlowScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => RegistrationController(
        repository: SupabaseRegistrationRepository(),
        offlineSyncController: context.read<OfflineSyncController>(),
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
          } else if (!ok && context.mounted) {
            final message = controller.submitError ??
                controller.verificationError ??
                'Inscription impossible. Vérifiez votre configuration Firebase.';
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
          }
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF4F8F4),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: !isFirst
                ? IconButton(
                    icon: const Icon(Icons.arrow_back, color: AvooColors.ink),
                    onPressed: isBusy ? null : controller.goBack,
                  )
                : null,
            title: _CompactStepIndicator(currentStep: controller.currentStep),
            centerTitle: true,
          ),
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final horizontalPadding = width > 600 ? 48.0 : 24.0;

                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          12,
                          horizontalPadding,
                          40,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (isFirst) ...[
                              Center(
                                child: Image.asset(
                                  'assets/images/Logo.png',
                                  height: 48,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'Créer votre compte',
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .displayMedium
                                    ?.copyWith(
                                      color: AvooColors.ink,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 28,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '1 minute. Vous pourrez compléter le reste plus tard.',
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(color: AvooColors.muted),
                              ),
                              const SizedBox(height: 32),
                            ],
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 260),
                              child: _buildStepContent(
                                controller: controller,
                                key: ValueKey(controller.currentStep),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                PrimaryStickyButton(
                  label: isLast ? 'Terminer' : 'Continuer',
                  onPressed: (!canProceed || isBusy) ? null : () => handlePrimary(),
                  isLoading: isBusy,
                  secondaryLabel: !isLast ? 'Enregistrer le brouillon' : null,
                  onSecondaryPressed: !isLast
                      ? () async {
                          await controller.saveDraft();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Brouillon enregistré.')),
                            );
                          }
                        }
                      : null,
                ),
              ],
            ),
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

class _CompactStepIndicator extends StatelessWidget {
  const _CompactStepIndicator({required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    final stepText = currentStep == 0
        ? 'Profil'
        : currentStep == 1
            ? 'Restaurant'
            : 'Vérification';
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Étape ${currentStep + 1}/3 : $stepText',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AvooColors.muted,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 100,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (currentStep + 1) / 3,
              backgroundColor: AvooColors.line,
              valueColor: const AlwaysStoppedAnimation<Color>(AvooColors.green),
              minHeight: 4,
            ),
          ),
        ),
      ],
    );
  }
}
