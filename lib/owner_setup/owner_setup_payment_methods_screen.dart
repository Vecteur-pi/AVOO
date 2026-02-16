import 'package:flutter/material.dart';

import '../theme/avoo_theme.dart';

class OwnerSetupPaymentMethodsScreen extends StatefulWidget {
  const OwnerSetupPaymentMethodsScreen({
    super.key,
    required this.restaurantName,
    required this.initialMethods,
  });

  final String restaurantName;
  final List<String> initialMethods;

  @override
  State<OwnerSetupPaymentMethodsScreen> createState() =>
      _OwnerSetupPaymentMethodsScreenState();
}

class _OwnerSetupPaymentMethodsScreenState
    extends State<OwnerSetupPaymentMethodsScreen> {
  static const List<String> _defaults = <String>[
    'Espèces',
    'Carte bancaire',
    'Mobile Money',
    'Apple Pay',
    'Google Pay',
    'Virement',
    'Chèque',
  ];

  final TextEditingController _customMethodController = TextEditingController();
  final FocusNode _customMethodFocusNode = FocusNode();
  late final Set<String> _selectedMethods;
  late final List<String> _extraMethods;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialMethods
        .map((method) => method.trim())
        .where((method) => method.isNotEmpty)
        .toSet();
    _selectedMethods = <String>{...initial};
    _extraMethods =
        initial.where((method) => !_defaults.contains(method)).toList()..sort();
  }

  @override
  void dispose() {
    _customMethodController.dispose();
    _customMethodFocusNode.dispose();
    super.dispose();
  }

  List<String> get _allMethods {
    final methods = <String>[..._defaults, ..._extraMethods];
    methods.sort();
    return methods;
  }

  void _toggleMethod(String method, bool selected) {
    setState(() {
      if (selected) {
        _selectedMethods.add(method);
      } else {
        _selectedMethods.remove(method);
      }
    });
  }

  void _addCustomMethod() {
    final text = _customMethodController.text.trim();
    if (text.isEmpty) {
      _customMethodFocusNode.requestFocus();
      return;
    }
    setState(() {
      if (!_defaults.contains(text) && !_extraMethods.contains(text)) {
        _extraMethods.add(text);
        _extraMethods.sort();
      }
      _selectedMethods.add(text);
      _customMethodController.clear();
    });
    _customMethodFocusNode.requestFocus();
  }

  Future<void> _submit() async {
    if (_saving || _selectedMethods.isEmpty) return;
    setState(() {
      _saving = true;
    });
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;
    Navigator.of(context).pop(_selectedMethods.toList()..sort());
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final restaurantName = widget.restaurantName.trim().isEmpty
        ? 'Votre restaurant'
        : widget.restaurantName.trim();

    return MediaQuery(
      data: mediaQuery.copyWith(textScaler: TextScaler.noScaling),
      child: Scaffold(
        backgroundColor: const Color(0xFFD8E4D0),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextButton(
                  onPressed: _saving ? null : () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: AvooColors.green,
                    alignment: Alignment.centerLeft,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_back, size: 26),
                      SizedBox(width: 8),
                      Text(
                        'Retour',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.86),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Mode de paiement',
                        style: TextStyle(
                          color: AvooColors.navy,
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        restaurantName,
                        style: const TextStyle(
                          color: Color(0xFF415067),
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Sélectionnez tous les moyens de paiement acceptés.',
                        style: TextStyle(
                          color: Color(0xFF50617B),
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFCFE0C5),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_selectedMethods.length} mode(s) sélectionné(s)',
                          style: const TextStyle(
                            color: AvooColors.navy,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _allMethods.map((method) {
                                final selected = _selectedMethods.contains(
                                  method,
                                );
                                return FilterChip(
                                  selected: selected,
                                  onSelected: (value) =>
                                      _toggleMethod(method, value),
                                  label: Text(method),
                                  labelStyle: TextStyle(
                                    color: selected
                                        ? Colors.white
                                        : const Color(0xFF41516A),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                  selectedColor: AvooColors.green,
                                  backgroundColor: Colors.white.withOpacity(
                                    0.78,
                                  ),
                                  side: BorderSide(
                                    color: selected
                                        ? const Color(0xFF4D7A37)
                                        : const Color(0xFFD4DBD0),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _customMethodController,
                                focusNode: _customMethodFocusNode,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _addCustomMethod(),
                                decoration: InputDecoration(
                                  hintText: 'Ajouter un autre mode',
                                  hintStyle: const TextStyle(
                                    color: Color(0xFF8B97A8),
                                    fontWeight: FontWeight.w600,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.86),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 52,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: _addCustomMethod,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AvooColors.green,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  padding: EdgeInsets.zero,
                                ),
                                child: const Icon(Icons.add_rounded, size: 28),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 66,
                  child: ElevatedButton(
                    onPressed: _selectedMethods.isEmpty ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedMethods.isEmpty
                          ? const Color(0xFFC6CCD8)
                          : AvooColors.green,
                      foregroundColor: _selectedMethods.isEmpty
                          ? const Color(0xFF667387)
                          : Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'Enregistrer les modes',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
