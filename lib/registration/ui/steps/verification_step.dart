import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/verification_method.dart';
import '../../state/registration_controller.dart';
import '../widgets/registration_field.dart';

class VerificationStep extends StatelessWidget {
  const VerificationStep({super.key, required this.controller});

  final RegistrationController controller;

  @override
  Widget build(BuildContext context) {
    final contact = controller.verificationMethod == VerificationMethod.email
        ? controller.emailController.text.trim()
        : controller.phoneController.text.trim();
    return Form(
      key: controller.formKeyStep3,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choisissez la méthode de vérification',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          RadioListTile<VerificationMethod>(
            value: VerificationMethod.email,
            groupValue: controller.verificationMethod,
            title: const Text('Vérifier par e-mail'),
            subtitle: Text(controller.emailController.text.trim()),
            onChanged: (value) {
              if (value != null) {
                controller.setVerificationMethod(value);
              }
            },
          ),
          RadioListTile<VerificationMethod>(
            value: VerificationMethod.phone,
            groupValue: controller.verificationMethod,
            title: const Text('Vérifier par téléphone'),
            subtitle: Text(controller.phoneController.text.trim()),
            onChanged: (value) {
              if (value != null) {
                controller.setVerificationMethod(value);
              }
            },
          ),
          const SizedBox(height: 8),
          Text(
            'Nous enverrons un code à : $contact',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: controller.isSendingCode || controller.resendSeconds > 0
                    ? null
                    : controller.sendVerificationCode,
                icon: const Icon(Icons.send_outlined),
                label: Text(
                  controller.resendSeconds > 0
                      ? 'Renvoyer (${controller.resendSeconds}s)'
                      : controller.verificationSent
                          ? 'Renvoyer le code'
                          : 'Envoyer le code',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF43B6A8),
                  side: const BorderSide(color: Color(0xFF43B6A8)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
              ),
              if (controller.isSendingCode) ...[
                const SizedBox(width: 12),
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          RegistrationField(
            label: 'Code de vérification',
            icon: Icons.verified_outlined,
            controller: controller.verificationCodeController,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            validator: RegistrationValidators.verificationCode,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            helperText: 'Entrez le code reçu par e-mail ou SMS.',
          ),
          if (controller.verificationError != null) ...[
            const SizedBox(height: 8),
            Text(
              controller.verificationError!,
              style: const TextStyle(color: Color(0xFFB42318)),
            ),
          ],
          if (controller.submitError != null) ...[
            const SizedBox(height: 8),
            Text(
              controller.submitError!,
              style: const TextStyle(color: Color(0xFFB42318)),
            ),
          ],
        ],
      ),
    );
  }
}
