import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../theme/avoo_theme.dart';

class MenuPickerSheet extends StatefulWidget {
  const MenuPickerSheet({
    super.key,
    required this.restaurantId,
    required this.ticketRef,
    required this.ticketStatus,
    required this.serverId,
    required this.serverName,
  });

  final String restaurantId;
  final DocumentReference<Map<String, dynamic>> ticketRef;
  final String ticketStatus;
  final String serverId;
  final String serverName;

  @override
  State<MenuPickerSheet> createState() => _MenuPickerSheetState();
}

class _MenuPickerSheetState extends State<MenuPickerSheet> {
  String _query = '';
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final categoriesStream = FirebaseFirestore.instance
        .collection('restaurants')
        .doc(widget.restaurantId)
        .collection('menu_categories')
        .orderBy('order')
        .snapshots();
    final itemsStream = FirebaseFirestore.instance
        .collection('restaurants')
        .doc(widget.restaurantId)
        .collection('menu_items')
        .snapshots();

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Menu',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: TextField(
                onChanged: (value) => setState(() => _query = value.trim()),
                decoration: const InputDecoration(
                  hintText: 'Rechercher un article',
                  prefixIcon: Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: categoriesStream,
                builder: (context, categorySnapshot) {
                  return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: itemsStream,
                    builder: (context, itemSnapshot) {
                      if (categorySnapshot.connectionState == ConnectionState.waiting ||
                          itemSnapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (categorySnapshot.hasError || itemSnapshot.hasError) {
                        return const Center(
                          child: Text('Erreur lors du chargement du menu.'),
                        );
                      }
                      final categories = categorySnapshot.data?.docs
                              .map((doc) => _MenuCategory.fromDoc(doc))
                              .toList() ??
                          [];
                      categories.sort((a, b) {
                        final orderCompare = a.order.compareTo(b.order);
                        if (orderCompare != 0) return orderCompare;
                        return a.name.compareTo(b.name);
                      });
                      final items = itemSnapshot.data?.docs
                              .map((doc) => _MenuItem.fromDoc(doc))
                              .where((item) => item.available)
                              .toList() ??
                          [];
                      items.sort((a, b) => a.name.compareTo(b.name));

                      final filteredItems = _query.isEmpty
                          ? items
                          : items
                              .where((item) =>
                                  item.name.toLowerCase().contains(_query.toLowerCase()))
                              .toList();

                      final grouped = <String, List<_MenuItem>>{};
                      for (final item in filteredItems) {
                        grouped.putIfAbsent(item.categoryId, () => []).add(item);
                      }

                      if (filteredItems.isEmpty) {
                        return const Center(child: Text('Aucun article.'));
                      }

                      final sections = <_MenuSectionData>[];
                      if (categories.isEmpty) {
                        sections.add(
                          _MenuSectionData(
                            category: const _MenuCategory(
                              id: '',
                              name: 'Menu',
                              order: 0,
                            ),
                            items: filteredItems,
                          ),
                        );
                      } else {
                        for (final category in categories) {
                          final itemsInCategory = grouped[category.id];
                          if (itemsInCategory != null && itemsInCategory.isNotEmpty) {
                            sections.add(
                              _MenuSectionData(
                                category: category,
                                items: itemsInCategory,
                              ),
                            );
                          }
                        }
                        final others = <_MenuItem>[];
                        for (final entry in grouped.entries) {
                          if (categories.any((cat) => cat.id == entry.key)) continue;
                          others.addAll(entry.value);
                        }
                        if (others.isNotEmpty) {
                          sections.add(
                            _MenuSectionData(
                              category: const _MenuCategory(
                                id: '',
                                name: 'Autres',
                                order: 999,
                              ),
                              items: others,
                            ),
                          );
                        }
                      }

                      return ListView(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        children: [
                          for (final section in sections)
                            _CategorySection(
                              category: section.category,
                              items: section.items,
                              onAdd: _openAddDialog,
                              busy: _busy,
                            ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openAddDialog(_MenuItem item) async {
    if (_busy) return;
    final result = await showDialog<_AddItemResult>(
      context: context,
      builder: (context) => _AddItemDialog(item: item),
    );
    if (result == null) return;
    await _addItem(item, result.quantity, result.notes);
  }

  Future<void> _addItem(_MenuItem item, int quantity, String notes) async {
    if (_busy) return;
    if (widget.ticketStatus.toLowerCase() == 'closed') {
      _showSnack('Ticket clôturé.');
      return;
    }
    setState(() => _busy = true);
    try {
      final now = FieldValue.serverTimestamp();
      final status = _shouldSendImmediately(widget.ticketStatus) ? 'sent' : 'draft';
      final data = {
        'menu_item_id': item.id,
        'name': item.name,
        'price': item.price,
        'quantity': quantity,
        'notes': notes,
        'route': item.route,
        'status': status,
        'created_at': now,
        'updated_at': now,
        'added_by': widget.serverId,
        'added_by_name': widget.serverName,
      };
      if (status == 'sent') {
        data['sent_at'] = now;
      }
      await widget.ticketRef.collection('items').add(data);
      await widget.ticketRef.update({'updated_at': now});
      _showSnack('Article ajouté.');
    } catch (e) {
      _showSnack('Impossible d’ajouter l’article.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  bool _shouldSendImmediately(String status) {
    final normalized = status.toLowerCase();
    return normalized == 'sent' ||
        normalized == 'preparing' ||
        normalized == 'in_progress' ||
        normalized == 'ready';
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.category,
    required this.items,
    required this.onAdd,
    required this.busy,
  });

  final _MenuCategory category;
  final List<_MenuItem> items;
  final Future<void> Function(_MenuItem) onAdd;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: ExpansionTile(
          title: Text(
            category.name,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          children: [
            for (final item in items)
              ListTile(
                title: Text(item.name),
                subtitle: Text('${item.price.toStringAsFixed(2)} €'),
                trailing: IconButton(
                  onPressed: busy ? null : () => onAdd(item),
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AddItemDialog extends StatefulWidget {
  const _AddItemDialog({required this.item});

  final _MenuItem item;

  @override
  State<_AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<_AddItemDialog> {
  int _quantity = 1;
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.item.name),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _quantity > 1
                    ? () => setState(() => _quantity--)
                    : null,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Text(
                '$_quantity',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              IconButton(
                onPressed: () => setState(() => _quantity++),
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Note (optionnel)',
              filled: true,
              fillColor: AvooColors.fog,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(
              _AddItemResult(
                quantity: _quantity,
                notes: _notesController.text.trim(),
              ),
            );
          },
          child: const Text('Ajouter'),
        ),
      ],
    );
  }
}

class _AddItemResult {
  const _AddItemResult({required this.quantity, required this.notes});

  final int quantity;
  final String notes;
}

class _MenuCategory {
  const _MenuCategory({required this.id, required this.name, required this.order});

  final String id;
  final String name;
  final int order;

  factory _MenuCategory.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final name = (data['name'] ?? data['label'] ?? 'Catégorie').toString();
    final rawOrder = data['order'] ?? data['position'] ?? 999;
    final order = rawOrder is num
        ? rawOrder.toInt()
        : int.tryParse(rawOrder.toString()) ?? 999;
    return _MenuCategory(id: doc.id, name: name, order: order);
  }
}

class _MenuSectionData {
  const _MenuSectionData({required this.category, required this.items});

  final _MenuCategory category;
  final List<_MenuItem> items;
}

class _MenuItem {
  const _MenuItem({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.price,
    required this.route,
    required this.available,
  });

  final String id;
  final String name;
  final String categoryId;
  final double price;
  final String route;
  final bool available;

  factory _MenuItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final name = (data['name'] ?? data['label'] ?? 'Article').toString();
    final categoryId =
        (data['categoryId'] ?? data['category_id'] ?? data['category'] ?? '')
            .toString();
    final availableRaw = data['available'] ?? data['active'];
    final available = availableRaw is bool
        ? availableRaw
        : availableRaw is num
            ? availableRaw != 0
            : true;
    final route = (data['route'] ??
            data['station'] ??
            data['routage'] ??
            data['type'] ??
            'cuisine')
        .toString();
    final price = _readPrice(data);
    return _MenuItem(
      id: doc.id,
      name: name,
      categoryId: categoryId,
      price: price,
      route: route,
      available: available,
    );
  }

  static double _readPrice(Map<String, dynamic> data) {
    if (data['price_cents'] is num) {
      return (data['price_cents'] as num).toDouble() / 100.0;
    }
    final raw = data['price'];
    if (raw is num) return raw.toDouble();
    if (raw is String) return double.tryParse(raw) ?? 0;
    return 0;
  }
}
