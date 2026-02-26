import 'package:flutter/material.dart';

import '../../utils/countries_data.dart';
import 'app_text_field.dart';

class CountryAutocompleteField extends StatefulWidget {
  const CountryAutocompleteField({
    super.key,
    required this.controller,
    required this.onCountrySelected,
    required this.validator,
    this.errorText,
  });

  final TextEditingController controller;
  final ValueChanged<CountryData> onCountrySelected;
  final String? Function(String?) validator;
  final String? errorText;

  @override
  State<CountryAutocompleteField> createState() => _CountryAutocompleteFieldState();
}

class _CountryAutocompleteFieldState extends State<CountryAutocompleteField> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return RawAutocomplete<CountryData>(
          focusNode: _focusNode,
          textEditingController: widget.controller,
          displayStringForOption: (CountryData option) => option.name,
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text == '') {
              return commonCountries;
            }
            final query = textEditingValue.text.toLowerCase();
            return commonCountries.where((CountryData option) {
              return option.name.toLowerCase().contains(query);
            });
          },
          onSelected: (CountryData selection) {
            widget.onCountrySelected(selection);
          },
          fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
            return AppTextField(
              label: 'Pays',
              icon: Icons.public_outlined,
              controller: textController,
              focusNode: focusNode,
              textInputAction: TextInputAction.next,
              validator: widget.validator,
              errorText: widget.errorText,
              helperText: 'Recherchez ou sélectionnez un pays',
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: constraints.maxWidth,
                  constraints: const BoxConstraints(maxHeight: 250),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);
                      return InkWell(
                        onTap: () => onSelected(option),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                option.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF111827),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                option.dialCode,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF4B5563),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
