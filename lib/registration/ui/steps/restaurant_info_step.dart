import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../state/registration_controller.dart';
import '../widgets/registration_field.dart';

class RestaurantInfoStep extends StatelessWidget {
  const RestaurantInfoStep({super.key, required this.controller});

  final RegistrationController controller;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: controller.formKeyStep2,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RegistrationField(
            label: 'Nom du restaurant',
            icon: Icons.storefront,
            controller: controller.restaurantNameController,
            textInputAction: TextInputAction.next,
            validator: RegistrationValidators.restaurantName,
          ),
          const SizedBox(height: 14),
          RegistrationField(
            label: 'Adresse / quartier',
            icon: Icons.location_on_outlined,
            controller: controller.restaurantAddressController,
            textInputAction: TextInputAction.next,
            validator: RegistrationValidators.restaurantAddress,
          ),
          const SizedBox(height: 14),
          RegistrationField(
            label: 'Téléphone du restaurant',
            icon: Icons.phone_android,
            controller: controller.restaurantPhoneController,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            validator: RegistrationValidators.restaurantPhone,
            helperText: 'Format international +241...',
          ),
          const SizedBox(height: 14),
          RegistrationField(
            label: 'Nombre de tables',
            icon: Icons.table_bar_outlined,
            controller: controller.tablesCountController,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            validator: (value) => RegistrationValidators.tablesCount(
              value,
              controller.configureTablesLater,
            ),
            enabled: !controller.configureTablesLater,
            fillColor:
                controller.configureTablesLater ? const Color(0xFFF5F7F6) : null,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: controller.configureTablesLater,
            title: const Text('Je configure plus tard'),
            onChanged: (value) {
              controller.toggleConfigureTablesLater(value ?? false);
            },
          ),
          const SizedBox(height: 8),
          _LogoPicker(controller: controller),
          const SizedBox(height: 16),
          RegistrationField(
            label: 'Horaires (optionnel)',
            icon: Icons.schedule,
            controller: controller.scheduleController,
            textInputAction: TextInputAction.newline,
            maxLines: 3,
          ),
        ],
      ),
    );
  }
}

class _LogoPicker extends StatelessWidget {
  const _LogoPicker({required this.controller});

  final RegistrationController controller;

  @override
  Widget build(BuildContext context) {
    final logoFile = controller.logoFile;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Logo (optionnel mais recommandé)',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E4DE)),
              ),
              child: logoFile == null
                  ? const Icon(Icons.image_outlined, color: Color(0xFF9AA0A6))
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(
                        File(logoFile.path),
                        fit: BoxFit.cover,
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    logoFile == null
                        ? 'Ajoutez un logo pour votre restaurant.'
                        : 'Logo sélectionné.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    children: [
                      OutlinedButton.icon(
                        onPressed: controller.pickLogo,
                        icon: const Icon(Icons.upload_file),
                        label: Text(logoFile == null ? 'Choisir' : 'Changer'),
                      ),
                      if (logoFile != null)
                        TextButton(
                          onPressed: controller.removeLogo,
                          child: const Text('Supprimer'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
