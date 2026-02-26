import 'package:flutter/material.dart';

import 'app_text_field.dart';

class EmailAutocompleteField extends StatefulWidget {
  const EmailAutocompleteField({
    super.key,
    required this.controller,
    required this.validator,
    this.errorText,
  });

  final TextEditingController controller;
  final String? Function(String?) validator;
  final String? errorText;

  @override
  State<EmailAutocompleteField> createState() => _EmailAutocompleteFieldState();
}

class _EmailAutocompleteFieldState extends State<EmailAutocompleteField> {
  final FocusNode _focusNode = FocusNode();

  static const List<String> _domains = [
    'gmail.com',
    'yahoo.fr',
    'yahoo.com',
    'hotmail.fr',
    'hotmail.com',
    'outlook.fr',
    'outlook.com',
    'icloud.com',
  ];

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return RawAutocomplete<String>(
          focusNode: _focusNode,
          textEditingController: widget.controller,
          optionsBuilder: (TextEditingValue textEditingValue) {
            final text = textEditingValue.text;
            if (!text.contains('@')) {
              return const Iterable<String>.empty();
            }

            final parts = text.split('@');
            if (parts.length > 2) return const Iterable<String>.empty();
            
            final prefix = parts[0];
            final domainQuery = parts[1].toLowerCase();

            final matches = _domains.where((domain) {
              return domain.startsWith(domainQuery);
            }).map((domain) => '$prefix@$domain').toList();

            // Do not show suggestion if the user has exactly typed it completely
            if (matches.length == 1 && matches.first == text) {
              return const Iterable<String>.empty();
            }

            return matches;
          },
          fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
            return AppTextField(
              label: 'Email',
              icon: Icons.mail_outline,
              controller: textController,
              focusNode: focusNode,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              validator: widget.validator,
              errorText: widget.errorText,
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
                  constraints: const BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);
                      return InkWell(
                        onTap: () => onSelected(option),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Text(
                            option,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF111827),
                            ),
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
