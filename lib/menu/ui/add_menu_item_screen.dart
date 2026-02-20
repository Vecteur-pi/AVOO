import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/menu_item.dart';
import '../repository/menu_repository.dart';
import '../services/menu_image_storage_service.dart';

class AddMenuItemScreen extends StatefulWidget {
  const AddMenuItemScreen({super.key, required this.restaurantId});

  final String restaurantId;

  @override
  State<AddMenuItemScreen> createState() => _AddMenuItemScreenState();
}

class _AddMenuItemScreenState extends State<AddMenuItemScreen> {
  final MenuRepository _repository = MenuRepository();
  final MenuImageStorageService _imageStorageService =
      MenuImageStorageService();
  final ImagePicker _imagePicker = ImagePicker();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  bool _isSearching = false;
  bool _isSaving = false;
  bool _isCreatingCustomItem = false;

  MenuItem? _selectedSuggestion;
  MenuCategory _selectedCategory = MenuCategory.food;
  XFile? _customImageFile;
  List<MenuItem> _suggestions = [];
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
    }

    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _suggestions = [];
        _selectedSuggestion = null;
        _isCreatingCustomItem = false;
        _customImageFile = null;
        _nameController.clear();
        _descriptionController.clear();
        _priceController.clear();
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _selectedSuggestion = null;
      _priceController.clear();
      if (_isCreatingCustomItem) {
        _isCreatingCustomItem = false;
        _customImageFile = null;
        _nameController.clear();
        _descriptionController.clear();
      }
    });

    _debounce = Timer(const Duration(milliseconds: 450), () async {
      try {
        final results = await _repository.searchGeneralKnowledge(query);
        if (!mounted) return;
        setState(() {
          _suggestions = results;
          _isSearching = false;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() => _isSearching = false);
      }
    });
  }

  void _selectSuggestion(MenuItem item) {
    setState(() {
      _selectedSuggestion = item;
      _isCreatingCustomItem = false;
      _selectedCategory = item.category;
      _customImageFile = null;
      _nameController.clear();
      _descriptionController.clear();
      _priceController.clear();
    });
  }

  void _startCustomItemCreation() {
    final nameFromSearch = _searchController.text.trim();
    if (nameFromSearch.isEmpty) {
      _showMessage('Commencez par rechercher le nom du plat.');
      return;
    }

    setState(() {
      _isCreatingCustomItem = true;
      _selectedSuggestion = null;
      _selectedCategory = MenuCategory.food;
      _customImageFile = null;
      _nameController.text = nameFromSearch;
      _descriptionController.clear();
      _priceController.clear();
    });
  }

  Future<void> _pickImage() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (picked != null && mounted) {
      setState(() => _customImageFile = picked);
    }
  }

  double? _parsePrice(String raw) {
    final normalized = raw
        .trim()
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll(',', '.');
    return double.tryParse(normalized);
  }

  Future<void> _submit() async {
    if (_isSaving) return;

    if (_selectedSuggestion == null && !_isCreatingCustomItem) {
      _showMessage('Recherchez un plat puis sélectionnez-le, ou ajoutez-le.');
      return;
    }

    if (_isCreatingCustomItem && _customImageFile == null) {
      _showMessage('Ajoutez une image pour le nouvel élément.');
      return;
    }

    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final price = _parsePrice(_priceController.text)!;
      late final String imageUrl;
      late final String name;
      late final String description;
      late final MenuCategory category;

      if (_isCreatingCustomItem) {
        imageUrl = await _imageStorageService.uploadMenuImage(
          File(_customImageFile!.path),
          restaurantId: widget.restaurantId,
        );
        name = _nameController.text.trim();
        description = _descriptionController.text.trim();
        category = _selectedCategory;
      } else {
        final suggestion = _selectedSuggestion!;
        imageUrl = suggestion.imageUrl;
        name = suggestion.name;
        description = suggestion.description;
        category = suggestion.category;
      }

      final item = MenuItem(
        id: '',
        name: name,
        description: description,
        price: price,
        imageUrl: imageUrl,
        category: category,
        quantityRemaining: 0,
        status: MenuStockStatus.normal,
        lastUpdated: DateTime.now(),
      );

      await _repository.addMenuItem(widget.restaurantId, item);

      if (!mounted) return;
      _showMessage('$name ajouté au menu.');
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      _showMessage('Erreur: $error');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _categoryLabel(MenuCategory category) {
    return category == MenuCategory.food ? 'Nourriture' : 'Boisson';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F3),
      appBar: AppBar(
        title: const Text('Ajouter un plat'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1C2024),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSearchCard(),
              const SizedBox(height: 16),
              Form(key: _formKey, child: _buildFormCard()),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSaving
                          ? null
                          : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF4B5563),
                        side: const BorderSide(color: Color(0xFFD1D5DB)),
                        minimumSize: const Size.fromHeight(52),
                      ),
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF739760),
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(52),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text('Ajouter'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Rechercher un plat',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1C2024),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Ex: Pizza, Burger, Jus...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
            ),
          ),
          if (_isSearching)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF739760),
                  ),
                ),
              ),
            ),
          if (_suggestions.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 12),
              constraints: const BoxConstraints(maxHeight: 260),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _suggestions.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = _suggestions[index];
                  final selected = _selectedSuggestion?.id == item.id;

                  return ListTile(
                    selected: selected,
                    onTap: () => _selectSuggestion(item),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 42,
                        height: 42,
                        child: item.imageUrl.isEmpty
                            ? Container(
                                color: const Color(0xFFE5E7EB),
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.fastfood,
                                  color: Color(0xFF9CA3AF),
                                ),
                              )
                            : Image.network(
                                item.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: const Color(0xFFE5E7EB),
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.image_not_supported_outlined,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    title: Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(_categoryLabel(item.category)),
                    trailing: Icon(
                      selected ? Icons.check_circle : Icons.add_circle_outline,
                      color: selected
                          ? const Color(0xFF739760)
                          : const Color(0xFF6B7280),
                    ),
                  );
                },
              ),
            ),
          if (!_isSearching && _searchController.text.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: OutlinedButton.icon(
                onPressed: _startCustomItemCreation,
                icon: const Icon(Icons.add),
                label: Text(
                  _suggestions.isEmpty
                      ? 'Aucun résultat. Ajouter "${_searchController.text.trim()}"'
                      : 'Produit non trouvé ? Ajouter "${_searchController.text.trim()}"',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF739760),
                  side: const BorderSide(color: Color(0xFF739760)),
                  minimumSize: const Size.fromHeight(44),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Détails du plat',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1C2024),
            ),
          ),
          const SizedBox(height: 14),
          if (_isCreatingCustomItem) ...[
            _buildCustomImagePicker(),
            const SizedBox(height: 14),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nom du plat'),
              validator: (value) {
                if (!_isCreatingCustomItem) return null;
                if ((value ?? '').trim().isEmpty) {
                  return 'Le nom est obligatoire.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Description'),
              validator: (value) {
                if (!_isCreatingCustomItem) return null;
                if ((value ?? '').trim().isEmpty) {
                  return 'La description est obligatoire.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<MenuCategory>(
              value: _selectedCategory,
              onChanged: (value) {
                if (value == null) return;
                setState(() => _selectedCategory = value);
              },
              items: const [
                DropdownMenuItem(
                  value: MenuCategory.food,
                  child: Text('Nourriture'),
                ),
                DropdownMenuItem(
                  value: MenuCategory.drink,
                  child: Text('Boisson'),
                ),
              ],
              decoration: const InputDecoration(labelText: 'Catégorie'),
            ),
            const SizedBox(height: 12),
          ] else ...[
            if (_selectedSuggestion == null)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'Recherchez un plat. Si vous le trouvez, sélectionnez-le. Sinon, utilisez le bouton Ajouter pour créer un nouveau plat.',
                  style: TextStyle(color: Color(0xFF6B7280)),
                ),
              )
            else
              _buildSuggestionPreview(_selectedSuggestion!),
          ],
          TextFormField(
            controller: _priceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Prix (FCFA)'),
            validator: (value) {
              final parsed = _parsePrice(value ?? '');
              if (parsed == null || parsed <= 0) {
                return 'Entrez un prix valide.';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCustomImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Image',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            height: 170,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFD1D5DB)),
              color: const Color(0xFFF9FAFB),
            ),
            child: _customImageFile == null
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.cloud_upload_outlined,
                          color: Color(0xFF6B7280),
                          size: 30,
                        ),
                        SizedBox(height: 8),
                        Text('Touchez pour sélectionner une image'),
                      ],
                    ),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(_customImageFile!.path),
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestionPreview(MenuItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        color: const Color(0xFFF9FAFB),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 74,
              height: 74,
              child: item.imageUrl.isEmpty
                  ? Container(
                      color: const Color(0xFFE5E7EB),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.fastfood,
                        color: Color(0xFF9CA3AF),
                      ),
                    )
                  : Image.network(
                      item.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFFE5E7EB),
                        alignment: Alignment.center,
                        child: const Icon(Icons.image_not_supported_outlined),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF4B5563)),
                ),
                const SizedBox(height: 6),
                Text(
                  'Trouvé: ${_categoryLabel(item.category)}',
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
