import 'package:flutter/material.dart';

import '../../state/registration_controller.dart';
import '../widgets/registration_field.dart';

class PersonalInfoStep extends StatefulWidget {
  const PersonalInfoStep({super.key, required this.controller});

  final RegistrationController controller;

  @override
  State<PersonalInfoStep> createState() => _PersonalInfoStepState();
}

class _PersonalInfoStepState extends State<PersonalInfoStep> {
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return Form(
      key: controller.formKeyStep1,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        children: [
          RegistrationField(
            label: 'Nom & prénom',
            icon: Icons.person_outline,
            controller: controller.fullNameController,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.name],
            validator: RegistrationValidators.fullName,
          ),
          const SizedBox(height: 14),
          RegistrationField(
            label: 'Email',
            icon: Icons.mail_outline,
            controller: controller.emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            validator: RegistrationValidators.email,
            errorText: controller.emailUniqueError,
          ),
          const SizedBox(height: 14),
          RegistrationField(
            label: 'Numéro de téléphone',
            icon: Icons.phone_outlined,
            controller: controller.phoneController,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.telephoneNumber],
            validator: RegistrationValidators.phone,
            helperText: 'Format international +241...',
            errorText: controller.phoneUniqueError,
          ),
          const SizedBox(height: 14),
          RegistrationField(
            label: 'Mot de passe',
            icon: Icons.lock_outline,
            controller: controller.passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.newPassword],
            validator: RegistrationValidators.password,
            suffix: IconButton(
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
              icon: Icon(
                _obscurePassword ? Icons.visibility : Icons.visibility_off,
                size: 20,
              ),
            ),
          ),
          const SizedBox(height: 14),
          RegistrationField(
            label: 'Pays / ville',
            icon: Icons.public_outlined,
            controller: controller.countryCityController,
            textInputAction: TextInputAction.next,
            validator: RegistrationValidators.countryCity,
            helperText: 'Ex: Gabon / Libreville',
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            value: controller.currency,
            decoration: InputDecoration(
              hintText: 'Devise',
              prefixIcon: const Icon(
                Icons.currency_exchange,
                color: Color(0xFF6AAFA5),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 16,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: const BorderSide(color: Color(0xFFB8D8D2), width: 1.2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: const BorderSide(color: Color(0xFF5CB3A5), width: 1.4),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: const BorderSide(color: Color(0xFFB42318), width: 1.3),
              ),
            ),
            items: const [
              DropdownMenuItem(value: 'FCFA', child: Text('FCFA')),
              DropdownMenuItem(value: 'XOF', child: Text('XOF')),
              DropdownMenuItem(value: 'EUR', child: Text('EUR')),
              DropdownMenuItem(value: 'USD', child: Text('USD')),
            ],
            validator: RegistrationValidators.currency,
            onChanged: (value) {
              if (value != null) {
                controller.updateCurrency(value);
              }
            },
          ),
        ],
      ),
    );
  }
}
