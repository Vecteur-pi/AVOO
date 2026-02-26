import 'package:flutter/material.dart';

import '../../../theme/avoo_theme.dart';

class StockFormPayload {
  const StockFormPayload({
    required this.name,
    required this.category,
    required this.shortDescription,
    required this.unit,
    required this.initialQuantity,
    required this.alertThreshold,
    required this.purchasePrice,
    required this.supplier,
    required this.location,
    required this.perishable,
    required this.expiryDate,
  });

  final String name;
  final String category;
  final String shortDescription;
  final String unit;
  final double initialQuantity;
  final double alertThreshold;
  final double? purchasePrice;
  final String supplier;
  final String location;
  final bool perishable;
  final DateTime? expiryDate;
}

class AddStockItemBottomSheet extends StatefulWidget {
  const AddStockItemBottomSheet({
    super.key,
    required this.onSave,
    this.initialName,
    this.initialCategory,
    this.initialShortDescription,
    this.initialUnit,
    this.initialQuantity,
    this.initialAlertThreshold,
    this.initialPurchasePrice,
    this.initialSupplier,
    this.initialLocation,
    this.initialPerishable,
    this.initialExpiryDate,
    this.isEditMode = false,
  });

  final Future<void> Function(StockFormPayload payload) onSave;
  final String? initialName;
  final String? initialCategory;
  final String? initialShortDescription;
  final String? initialUnit;
  final double? initialQuantity;
  final double? initialAlertThreshold;
  final double? initialPurchasePrice;
  final String? initialSupplier;
  final String? initialLocation;
  final bool? initialPerishable;
  final DateTime? initialExpiryDate;
  final bool isEditMode;

  @override
  State<AddStockItemBottomSheet> createState() =>
      _AddStockItemBottomSheetState();
}

class _AddStockItemBottomSheetState extends State<AddStockItemBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _quantityController;
  late final TextEditingController _thresholdController;
  late final TextEditingController _purchasePriceController;
  late final TextEditingController _supplierController;

  bool _isSaving = false;
  late bool _showAdvanced;
  late bool _isPerishable;
  DateTime? _expiryDate;
  String? _errorMessage;

  late String _selectedCategoryId;
  late String _selectedUnit;
  late String _selectedLocation;

  static const List<_CategoryOption> _categories = [
    _CategoryOption(
      id: 'alimentaire',
      label: 'Alimentaire',
      defaultUnit: 'kg',
      supportsPerishables: true,
    ),
    _CategoryOption(
      id: 'boissons',
      label: 'Boissons',
      defaultUnit: 'bouteille',
      supportsPerishables: true,
    ),
    _CategoryOption(
      id: 'preparations_maison',
      label: 'Préparations maison',
      defaultUnit: 'portion',
      supportsPerishables: true,
    ),
    _CategoryOption(
      id: 'emballages',
      label: 'Emballages',
      defaultUnit: 'unité',
      supportsPerishables: false,
    ),
    _CategoryOption(
      id: 'hygiene_nettoyage',
      label: 'Hygiène & Nettoyage',
      defaultUnit: 'bouteille',
      supportsPerishables: false,
    ),
    _CategoryOption(
      id: 'consommables',
      label: 'Consommables',
      defaultUnit: 'unité',
      supportsPerishables: false,
    ),
  ];

  static const List<String> _units = [
    'g',
    'kg',
    'mL',
    'cL',
    'L',
    'unité',
    'pièce',
    'boîte',
    'sachet',
    'bouteille',
    'canette',
    'pack',
    'carton',
    'portion',
  ];

  static const List<String> _locations = [
    'Réserve',
    'Frigo',
    'Congélateur',
    'Bar',
    'Cuisine',
  ];

  _CategoryOption get _selectedCategory =>
      _categories.firstWhere((category) => category.id == _selectedCategoryId);

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _descriptionController = TextEditingController(
      text: widget.initialShortDescription,
    );
    _quantityController = TextEditingController(
      text: widget.initialQuantity?.toString() ?? '',
    );
    _thresholdController = TextEditingController(
      text: widget.initialAlertThreshold?.toString() ?? '5',
    );
    _purchasePriceController = TextEditingController(
      text: widget.initialPurchasePrice?.toString() ?? '',
    );
    _supplierController = TextEditingController(
      text: widget.initialSupplier ?? '',
    );

    _showAdvanced =
        widget.isEditMode ||
        widget.initialPurchasePrice != null ||
        (widget.initialSupplier != null &&
            widget.initialSupplier!.isNotEmpty) ||
        (widget.initialLocation != null && widget.initialLocation!.isNotEmpty);

    _isPerishable = widget.initialPerishable ?? false;
    _expiryDate = widget.initialExpiryDate;

    if (widget.initialCategory != null) {
      final found = _categories.cast<_CategoryOption?>().firstWhere(
        (c) =>
            c?.label == widget.initialCategory ||
            c?.id == widget.initialCategory,
        orElse: () => null,
      );
      _selectedCategoryId = found?.id ?? _categories.first.id;
    } else {
      _selectedCategoryId = _categories.first.id;
    }

    _selectedUnit = widget.initialUnit ?? _categories.first.defaultUnit;
    _selectedLocation = (widget.initialLocation?.isNotEmpty == true)
        ? widget.initialLocation!
        : _locations.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    _thresholdController.dispose();
    _purchasePriceController.dispose();
    _supplierController.dispose();
    super.dispose();
  }

  Future<void> _pickExpiryDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 1, now.month, now.day),
      lastDate: DateTime(now.year + 10, now.month, now.day),
      initialDate: _expiryDate ?? now.add(const Duration(days: 7)),
      locale: const Locale('fr'),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _expiryDate = picked;
      _errorMessage = null;
    });
  }

  void _resetForAnother() {
    _nameController.clear();
    _descriptionController.clear();
    _quantityController.clear();
    _purchasePriceController.clear();
    _supplierController.clear();
    _selectedLocation = _locations.first;
    _isPerishable = false;
    _expiryDate = null;
    _errorMessage = null;
    setState(() {});
  }

  Future<void> _handleSubmit({required bool keepOpen}) async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    final quantity = double.tryParse(_quantityController.text.trim());
    final threshold = double.tryParse(_thresholdController.text.trim());
    if (quantity == null || threshold == null) return;

    if (_selectedCategory.supportsPerishables &&
        _isPerishable &&
        _expiryDate == null) {
      setState(() {
        _errorMessage = 'Veuillez sélectionner une date de péremption.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final purchasePrice = double.tryParse(
        _purchasePriceController.text.trim(),
      );
      final payload = StockFormPayload(
        name: _nameController.text.trim(),
        category: _selectedCategory.label,
        shortDescription: _descriptionController.text.trim(),
        unit: _selectedUnit,
        initialQuantity: quantity,
        alertThreshold: threshold,
        purchasePrice: purchasePrice,
        supplier: _supplierController.text.trim(),
        location: _showAdvanced ? _selectedLocation : '',
        perishable: _selectedCategory.supportsPerishables && _isPerishable,
        expiryDate: _selectedCategory.supportsPerishables && _isPerishable
            ? _expiryDate
            : null,
      );

      await widget.onSave(payload);
      if (!mounted) return;

      if (keepOpen) {
        _resetForAnother();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produit ajouté au stock.')),
        );
      } else {
        Navigator.of(context).pop(true);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = widget.isEditMode
            ? 'Impossible de modifier ce produit. Réessayez.'
            : 'Impossible d\'ajouter ce produit. Réessayez.';
      });
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final keyboardBottomInset = media.viewInsets.bottom;
    final bottomSafe = media.padding.bottom;
    final qtyValue = double.tryParse(_quantityController.text.trim());
    final thresholdValue = double.tryParse(_thresholdController.text.trim());
    final thresholdWarning =
        qtyValue != null && thresholdValue != null && thresholdValue > qtyValue;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.only(bottom: keyboardBottomInset),
          child: SizedBox(
            height: media.size.height * 0.9,
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Expanded(
                  child: Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            widget.isEditMode
                                ? 'Modifier le produit'
                                : 'Ajouter un produit',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: AvooColors.navy,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.isEditMode
                                ? 'Modifiez les informations de ce produit.'
                                : 'Ajoutez un produit en moins de 30 secondes.',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AvooColors.muted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 18),
                          _SectionCard(
                            title: '1. Produit',
                            child: Column(
                              children: [
                                _buildTextField(
                                  controller: _nameController,
                                  label: 'Nom du produit',
                                  hint: 'Ex: Mozzarella',
                                  requiredField: true,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Le nom est obligatoire';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                _buildDropdown(
                                  label: 'Catégorie',
                                  value: _selectedCategoryId,
                                  requiredField: true,
                                  items: _categories
                                      .map(
                                        (category) => DropdownMenuItem(
                                          value: category.id,
                                          child: Text(category.label),
                                        ),
                                      )
                                      .toList(growable: false),
                                  onChanged: (value) {
                                    if (value == null) return;
                                    final category = _categories.firstWhere(
                                      (item) => item.id == value,
                                    );
                                    setState(() {
                                      _selectedCategoryId = value;
                                      _selectedUnit = category.defaultUnit;
                                      if (!category.supportsPerishables) {
                                        _isPerishable = false;
                                        _expiryDate = null;
                                      }
                                    });
                                  },
                                ),
                                const SizedBox(height: 12),
                                _buildTextField(
                                  controller: _descriptionController,
                                  label: 'Sous-type / description',
                                  hint: 'Ex: Mozzarella râpée',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          _SectionCard(
                            title: '2. Stock',
                            child: Column(
                              children: [
                                _buildDropdown(
                                  label: 'Unité de stock',
                                  value: _selectedUnit,
                                  requiredField: true,
                                  helper:
                                      'Choisissez l’unité utilisée pour compter ce produit.',
                                  items: _units
                                      .map(
                                        (unit) => DropdownMenuItem(
                                          value: unit,
                                          child: Text(unit),
                                        ),
                                      )
                                      .toList(growable: false),
                                  onChanged: (value) {
                                    if (value == null) return;
                                    setState(() => _selectedUnit = value);
                                  },
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildTextField(
                                        controller: _quantityController,
                                        label: widget.isEditMode
                                            ? 'Quantité actuelle'
                                            : 'Quantité initiale',
                                        hint: '0',
                                        requiredField: true,
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                              decimal: true,
                                            ),
                                        onChanged: (_) => setState(() {}),
                                        validator: (value) {
                                          final parsed = double.tryParse(
                                            value?.trim() ?? '',
                                          );
                                          if (parsed == null) {
                                            return 'Quantité invalide';
                                          }
                                          if (parsed < 0) {
                                            return 'Doit être positive';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildTextField(
                                        controller: _thresholdController,
                                        label: 'Seuil d’alerte',
                                        hint: '5',
                                        requiredField: true,
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                              decimal: true,
                                            ),
                                        onChanged: (_) => setState(() {}),
                                        helper:
                                            'Alerte quand le stock passe sous cette valeur.',
                                        validator: (value) {
                                          final parsed = double.tryParse(
                                            value?.trim() ?? '',
                                          );
                                          if (parsed == null) {
                                            return 'Seuil invalide';
                                          }
                                          if (parsed < 0) {
                                            return 'Doit être positif';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                if (thresholdWarning) ...[
                                  const SizedBox(height: 10),
                                  Row(
                                    children: const [
                                      Icon(
                                        Icons.info_outline_rounded,
                                        size: 16,
                                        color: AvooColors.warning,
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Le stock initial est déjà sous le seuil.',
                                          style: TextStyle(
                                            color: AvooColors.warning,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          _SectionCard(
                            title: '3. Options avancées',
                            child: Column(
                              children: [
                                InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () {
                                    setState(
                                      () => _showAdvanced = !_showAdvanced,
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AvooColors.background,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AvooColors.line,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          _showAdvanced
                                              ? Icons.expand_less_rounded
                                              : Icons.expand_more_rounded,
                                          color: AvooColors.navy,
                                        ),
                                        const SizedBox(width: 8),
                                        const Expanded(
                                          child: Text(
                                            'Ajouter plus de détails',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: AvooColors.navy,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                AnimatedCrossFade(
                                  firstChild: const SizedBox.shrink(),
                                  secondChild: Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: Column(
                                      children: [
                                        _buildTextField(
                                          controller: _purchasePriceController,
                                          label: 'Prix d’achat unitaire',
                                          hint: 'Ex: 8.50',
                                          keyboardType:
                                              const TextInputType.numberWithOptions(
                                                decimal: true,
                                              ),
                                        ),
                                        const SizedBox(height: 12),
                                        _buildTextField(
                                          controller: _supplierController,
                                          label: 'Fournisseur',
                                          hint: 'Ex: Metro',
                                        ),
                                        const SizedBox(height: 12),
                                        _buildDropdown(
                                          label: 'Emplacement',
                                          value: _selectedLocation,
                                          items: _locations
                                              .map(
                                                (location) => DropdownMenuItem(
                                                  value: location,
                                                  child: Text(location),
                                                ),
                                              )
                                              .toList(growable: false),
                                          onChanged: (value) {
                                            if (value == null) return;
                                            setState(
                                              () => _selectedLocation = value,
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  crossFadeState: _showAdvanced
                                      ? CrossFadeState.showSecond
                                      : CrossFadeState.showFirst,
                                  duration: const Duration(milliseconds: 180),
                                ),
                              ],
                            ),
                          ),
                          if (_selectedCategory.supportsPerishables) ...[
                            const SizedBox(height: 14),
                            _SectionCard(
                              title: '4. Péremption',
                              child: Column(
                                children: [
                                  SwitchListTile.adaptive(
                                    contentPadding: EdgeInsets.zero,
                                    value: _isPerishable,
                                    activeColor: AvooColors.green,
                                    title: const Text(
                                      'Produit périssable ?',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: AvooColors.ink,
                                      ),
                                    ),
                                    onChanged: (value) {
                                      setState(() {
                                        _isPerishable = value;
                                        if (!value) _expiryDate = null;
                                      });
                                    },
                                  ),
                                  if (_isPerishable)
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton.icon(
                                        onPressed: _pickExpiryDate,
                                        icon: const Icon(Icons.event_rounded),
                                        label: Text(
                                          _expiryDate == null
                                              ? 'Choisir une date de péremption'
                                              : _formatDate(_expiryDate!),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AvooColors.navy,
                                          side: const BorderSide(
                                            color: AvooColors.line,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: AvooColors.line)),
                  ),
                  padding: EdgeInsets.fromLTRB(20, 12, 20, bottomSafe + 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_errorMessage != null) ...[
                        Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: AvooColors.error,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isSaving
                                  ? null
                                  : () => Navigator.of(context).pop(),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AvooColors.muted,
                                side: const BorderSide(color: AvooColors.line),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              child: const Text('Annuler'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton(
                              onPressed: _isSaving
                                  ? null
                                  : () => _handleSubmit(keepOpen: false),
                              style: FilledButton.styleFrom(
                                backgroundColor: AvooColors.green,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              child: _isSaving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : const Text('Enregistrer'),
                            ),
                          ),
                        ],
                      ),
                      if (!widget.isEditMode) ...[
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _isSaving
                              ? null
                              : () => _handleSubmit(keepOpen: true),
                          child: const Text(
                            'Enregistrer et ajouter un autre',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool requiredField = false,
    String? helper,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: requiredField ? '$label *' : label,
        hintText: hint,
        helperText: helper,
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
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
          borderSide: const BorderSide(color: AvooColors.green, width: 1.6),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<DropdownMenuItem<String>> items,
    bool requiredField = false,
    String? helper,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: requiredField ? '$label *' : label,
        helperText: helper,
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
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
          borderSide: const BorderSide(color: AvooColors.green, width: 1.6),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AvooColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AvooColors.navy,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _CategoryOption {
  const _CategoryOption({
    required this.id,
    required this.label,
    required this.defaultUnit,
    required this.supportsPerishables,
  });

  final String id;
  final String label;
  final String defaultUnit;
  final bool supportsPerishables;
}
