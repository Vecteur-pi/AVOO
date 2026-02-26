import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../state/registration_controller.dart';
import '../../utils/registration_validators.dart';
import '../widgets/app_text_field.dart';
import '../widgets/section_card.dart';
import '../widgets/schedule_bottom_sheet.dart';
import '../../../theme/avoo_theme.dart';

class RestaurantInfoStep extends StatelessWidget {
  const RestaurantInfoStep({super.key, required this.controller});

  final RegistrationController controller;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: controller.formKeyStep2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionCard(
            title: 'Établissement',
            children: [
              AppTextField(
                label: 'Nom du restaurant',
                icon: Icons.storefront,
                controller: controller.restaurantNameController,
                textInputAction: TextInputAction.next,
                validator: RegistrationValidators.restaurantName,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Adresse / quartier',
                icon: Icons.location_on_outlined,
                controller: controller.restaurantAddressController,
                textInputAction: TextInputAction.next,
                validator: RegistrationValidators.restaurantAddress,
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'Téléphone du restaurant',
                      icon: Icons.phone_android,
                      controller: controller.restaurantPhoneController,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      validator: RegistrationValidators.restaurantPhone,
                      helperText: 'Ex: +241612... (Format international)',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // "Même que mon numéro" quick fill button
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () {
                    final phoneText = controller.phoneController.text.trim();
                    if (phoneText.isNotEmpty) {
                      controller.restaurantPhoneController.text = phoneText;
                    }
                  },
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Même que mon numéro personnel'),
                  style: TextButton.styleFrom(
                    foregroundColor: AvooColors.green,
                    padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Configuration options
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AvooColors.line),
            ),
            child: CheckboxListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: AvooColors.green,
              title: const Text(
                'Je configure le reste plus tard',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              value: controller.configureTablesLater,
              onChanged: (value) {
                controller.toggleConfigureTablesLater(value ?? false);
              },
            ),
          ),
          if (!controller.configureTablesLater) ...[
            const SizedBox(height: 16),
            ExpansionSection(
              title: 'Options (facultatif)',
              leadingIcon: Icons.settings_outlined,
              children: [
                const SizedBox(height: 8),
                _LogoPicker(controller: controller),
                const SizedBox(height: 24),
                _SchedulePickerCard(controller: controller),
                const SizedBox(height: 8),
              ],
            ),
          ],
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
          'Logo',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AvooColors.ink,
              ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AvooColors.line),
              ),
              child: logoFile == null
                  ? const Icon(Icons.image_outlined, color: AvooColors.muted)
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(
                        File(logoFile.path),
                        fit: BoxFit.cover,
                      ),
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    logoFile == null
                        ? 'Ajoutez un logo pour votre restaurant.'
                        : 'Logo sélectionné.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AvooColors.muted,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    children: [
                      ElevatedButton.icon(
                        onPressed: controller.pickLogo,
                        icon: const Icon(Icons.upload_file, size: 18),
                        label: Text(logoFile == null ? 'Choisir' : 'Changer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AvooColors.green,
                          elevation: 0,
                          side: const BorderSide(color: AvooColors.line),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      if (logoFile != null)
                        TextButton(
                          onPressed: controller.removeLogo,
                          style: TextButton.styleFrom(
                            foregroundColor: AvooColors.error,
                          ),
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

class _SchedulePickerCard extends StatefulWidget {
  const _SchedulePickerCard({required this.controller});

  final RegistrationController controller;

  @override
  State<_SchedulePickerCard> createState() => _SchedulePickerCardState();
}

class _SchedulePickerCardState extends State<_SchedulePickerCard> {
  @override
  void initState() {
    super.initState();
    widget.controller.scheduleController.addListener(_onScheduleChange);
  }

  @override
  void dispose() {
    widget.controller.scheduleController.removeListener(_onScheduleChange);
    super.dispose();
  }

  void _onScheduleChange() {
    setState(() {}); // Rebuild when schedule changes
  }

  @override
  Widget build(BuildContext context) {
    final scheduleText = widget.controller.scheduleController.text;
    final hasSchedule = scheduleText.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Horaires',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AvooColors.ink,
              ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () async {
            final result = await ScheduleBottomSheet.show(
              context,
              scheduleText,
            );
            if (result != null) {
              widget.controller.scheduleController.text = result;
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: hasSchedule ? AvooColors.green : AvooColors.line,
                width: hasSchedule ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.schedule,
                  color: hasSchedule ? AvooColors.green : AvooColors.ink,
                  size: 24,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasSchedule ? 'Horaires définis' : 'Définir les horaires',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AvooColors.ink,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hasSchedule ? scheduleText : 'Configurez vos ouvertures',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: hasSchedule ? AvooColors.ink : AvooColors.muted,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right,
                  color: AvooColors.muted,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

