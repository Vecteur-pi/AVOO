import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../config/app_flags.dart';
import '../../models/verification_method.dart';
import '../../state/registration_controller.dart';
import '../../utils/registration_validators.dart';
import '../widgets/app_text_field.dart';
import '../widgets/section_card.dart';
import '../../../theme/avoo_theme.dart';

class VerificationStep extends StatelessWidget {
  const VerificationStep({super.key, required this.controller});

  final RegistrationController controller;

  @override
  Widget build(BuildContext context) {
    final contact = controller.verificationMethod == VerificationMethod.email
        ? controller.emailController.text.trim()
        : controller.phoneController.text.trim();
        
    final bool showDevBypassText = AppFlags.bypassOtp && kDebugMode;
    final bool showTempBypassText = controller.isTemporaryOtpBypassAvailableForSelectedContact && kDebugMode;

    return Form(
      key: controller.formKeyStep3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionCard(
            title: 'Vérification',
            children: [
              Text(
                'Comment souhaitez-vous recevoir votre code de vérification ?',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AvooColors.muted,
                    ),
              ),
              const SizedBox(height: 16),
              SegmentedButton<VerificationMethod>(
                segments: const [
                  ButtonSegment<VerificationMethod>(
                    value: VerificationMethod.email,
                    label: Text('Par E-mail'),
                    icon: Icon(Icons.email_outlined),
                  ),
                  ButtonSegment<VerificationMethod>(
                    value: VerificationMethod.phone,
                    label: Text('Par SMS'),
                    icon: Icon(Icons.phone_outlined),
                  ),
                ],
                selected: {controller.verificationMethod},
                onSelectionChanged: (Set<VerificationMethod> newSelection) {
                  controller.setVerificationMethod(newSelection.first);
                },
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.resolveWith<Color>(
                    (Set<MaterialState> states) {
                      if (states.contains(MaterialState.selected)) {
                        return AvooColors.brandLight;
                      }
                      return Colors.white;
                    },
                  ),
                  foregroundColor: MaterialStateProperty.resolveWith<Color>(
                    (Set<MaterialState> states) {
                      if (states.contains(MaterialState.selected)) {
                        return AvooColors.green;
                      }
                      return AvooColors.ink;
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Contact sélectionné : $contact',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AvooColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              
              if (showDevBypassText) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: const Text(
                    'Mode dev: BYPASS_OTP actif. La vérification est ignorée.',
                    style: TextStyle(
                      color: Colors.deepOrange,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ] else if (showTempBypassText) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AvooColors.brandLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AvooColors.green.withOpacity(0.3)),
                  ),
                  child: const Text(
                    'Mode temporaire: utilisez le code de secours.',
                    style: TextStyle(
                      color: AvooColors.green,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
              
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: controller.isSendingCode || controller.resendSeconds > 0
                          ? null
                          : controller.sendVerificationCode,
                      icon: const Icon(Icons.send_outlined),
                      label: Text(
                        controller.isOtpBypassActiveForSelectedContact
                            ? 'Marquer comme vérifié'
                            : controller.resendSeconds > 0
                                ? 'Renvoyer (${controller.resendSeconds}s)'
                                : controller.verificationSent
                                    ? 'Renvoyer le code'
                                    : 'Envoyer le code',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AvooColors.green,
                        side: BorderSide(
                          color: (controller.isSendingCode || controller.resendSeconds > 0)
                              ? AvooColors.line
                              : AvooColors.green,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  if (controller.isSendingCode) ...[
                    const SizedBox(width: 16),
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AvooColors.green,
                      ),
                    ),
                  ],
                ],
              ),
              
              if (controller.verificationSent || controller.isOtpBypassActiveForSelectedContact) ...[
                const SizedBox(height: 24),
                AppTextField(
                  label: 'Code de vérification (6 chiffres)',
                  icon: Icons.verified_outlined,
                  controller: controller.verificationCodeController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  maxLength: 6,
                  validator: AppFlags.bypassOtp
                      ? (_) => null
                      : RegistrationValidators.verificationCode,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  helperText: AppFlags.bypassOtp
                      ? 'Bypass actif: vous pouvez terminer sans code.'
                      : controller.isTemporaryOtpBypassAvailableForSelectedContact
                          ? 'Entrez le code de secours.'
                          : 'Entrez le code reçu.',
                ),
              ],
              
              if (controller.verificationError != null) ...[
                const SizedBox(height: 12),
                Text(
                  controller.verificationError!,
                  style: const TextStyle(color: AvooColors.error, fontSize: 13),
                ),
              ],
              if (controller.submitError != null) ...[
                const SizedBox(height: 12),
                Text(
                  controller.submitError!,
                  style: const TextStyle(color: AvooColors.error, fontSize: 13),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

