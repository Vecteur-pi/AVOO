import 'package:flutter/material.dart';

import '../../state/registration_controller.dart';
import '../../utils/registration_validators.dart';
import '../widgets/app_text_field.dart';
import '../widgets/section_card.dart';
import '../widgets/email_autocomplete_field.dart';
import '../widgets/country_autocomplete_field.dart';
import '../../../theme/avoo_theme.dart';

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionCard(
            title: 'Vos informations',
            children: [
              EmailAutocompleteField(
                controller: controller.emailController,
                validator: (val) {
                  return RegistrationValidators.email(val) ??
                         controller.emailUniqueError;
                },
                errorText: controller.emailUniqueError,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Mot de passe',
                icon: Icons.lock_outline,
                controller: controller.passwordController,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                validator: RegistrationValidators.password,
                helperText: 'Min. 8 caractères, 1 majuscule, 1 chiffre.',
                suffix: IconButton(
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    size: 20,
                    color: AvooColors.muted,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Nom & prénom',
                icon: Icons.person_outline,
                controller: controller.fullNameController,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                validator: RegistrationValidators.fullName,
              ),
              const SizedBox(height: 16),
              CountryAutocompleteField(
                controller: controller.countryCityController,
                validator: (val) => RegistrationValidators.countryCity(val),
                onCountrySelected: (country) {
                  // Autofill the country field with just the name
                  controller.countryCityController.text = country.name;
                  
                  // Autofill the phone number field with the dial code if it's currently empty
                  if (controller.phoneController.text.trim().isEmpty) {
                    controller.phoneController.text = '${country.dialCode} ';
                  }
                  
                  // Let the cursor move correctly
                  FocusScope.of(context).nextFocus();
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Numéro de téléphone',
                icon: Icons.phone_outlined,
                controller: controller.phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.telephoneNumber],
                validator: (val) {
                  return RegistrationValidators.phone(val) ??
                         controller.phoneUniqueError;
                },
                errorText: controller.phoneUniqueError,
                helperText: 'Ex: +241612... (Format international conseillé)',
              ),
            ],
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Paramètres du compte',
            children: [
              DropdownButtonFormField<String>(
                value: controller.currency,
                decoration: InputDecoration(
                  labelText: 'Devise par défaut',
                  prefixIcon: const Icon(Icons.currency_exchange, color: AvooColors.ink),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AvooColors.line),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AvooColors.line),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AvooColors.green, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: const [
                  DropdownMenuItem(value: 'FCFA', child: Text('FCFA')),
                  DropdownMenuItem(value: 'EUR', child: Text('Euro (€)')),
                  DropdownMenuItem(value: 'USD', child: Text('US Dollar (\$)')),
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
        ],
      ),
    );
  }
}

