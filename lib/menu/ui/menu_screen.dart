import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/menu_item.dart';
import '../repository/menu_repository.dart';
import 'add_menu_item_screen.dart';
import 'widgets/menu_item_card.dart';
import '../../sync/offline_sync_controller.dart';

const String _allMenuFilterId = 'all';
const String _drinkMenuFilterId = 'drink';
const String _foodMenuFilterId = 'food';

const List<_MenuFilterOption> _menuFilterOptions = [
  _MenuFilterOption(id: _allMenuFilterId, label: 'Tous'),
  _MenuFilterOption(id: _drinkMenuFilterId, label: 'Boissons'),
  _MenuFilterOption(id: _foodMenuFilterId, label: 'Nourritures'),
];

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key, required this.restaurantId});

  final String restaurantId;

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final MenuRepository _repository = MenuRepository();
  final TextEditingController _searchController = TextEditingController();

  String _selectedFilterId = _allMenuFilterId;
  late Stream<List<MenuItem>> _menuStream;

  @override
  void initState() {
    super.initState();
    _menuStream = _repository
        .watchMenuItems(widget.restaurantId)
        .asBroadcastStream();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didUpdateWidget(covariant MenuScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.restaurantId != widget.restaurantId) {
      _menuStream = _repository
          .watchMenuItems(widget.restaurantId)
          .asBroadcastStream();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {}); // Trigger rebuild to filter list
  }

  void _handleDelete(String id) {
    final syncController = context.read<OfflineSyncController>();
    if (!syncController.isOnline) {
      syncController.noteFirestoreWriteQueued();
    }
    _repository.deleteItem(widget.restaurantId, id);
  }

  void _handleDeactivate(String id) {
    final syncController = context.read<OfflineSyncController>();
    if (!syncController.isOnline) {
      syncController.noteFirestoreWriteQueued();
    }
    _repository.deactivateItem(widget.restaurantId, id);
  }

  void _showAddDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddMenuItemScreen(restaurantId: widget.restaurantId),
      ),
    );
  }

  List<MenuItem> _getFilteredItems(List<MenuItem> allItems) {
    final query = _searchController.text.toLowerCase().trim();

    return allItems.where((item) {
      // Filter by category
      if (_selectedFilterId == _drinkMenuFilterId &&
          item.category != MenuCategory.drink) {
        return false;
      }
      if (_selectedFilterId == _foodMenuFilterId &&
          item.category != MenuCategory.food) {
        return false;
      }

      // Filter by search query
      if (query.isNotEmpty && !item.name.toLowerCase().contains(query)) {
        return false;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<MenuItem>>(
      stream: _menuStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFF5F6F3),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF739760)),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: const Color(0xFFF5F6F3),
            body: Center(child: Text('Erreur: ${snapshot.error}')),
          );
        }

        final allItems = snapshot.data ?? [];
        return _buildContent(context, allItems);
      },
    );
  }

  Widget _buildContent(BuildContext context, List<MenuItem> allItems) {
    final filteredItems = _getFilteredItems(allItems);

    // Counts for filter sheet
    final totalCount = allItems.length;
    final drinkCount = allItems
        .where((i) => i.category == MenuCategory.drink)
        .length;
    final foodCount = allItems
        .where((i) => i.category == MenuCategory.food)
        .length;
    final filterCounts = <String, int>{
      _allMenuFilterId: totalCount,
      _drinkMenuFilterId: drinkCount,
      _foodMenuFilterId: foodCount,
    };
    final selectedFilter = _menuFilterOptions.where(
      (option) => option.id == _selectedFilterId,
    );
    final activeFilterLabel = selectedFilter.isEmpty
        ? 'Catégorie'
        : selectedFilter.first.label;
    final hasCategoryFilter = _selectedFilterId != _allMenuFilterId;

    return ColoredBox(
      color: const Color(0xFFF5F6F3),
      child: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Menu',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Serif',
                          letterSpacing: -0.5,
                          color: Color(0xFF111827),
                        ),
                      ),
                      SizedBox(
                        height: 36,
                        child: FilledButton.icon(
                          onPressed: _showAddDialog,
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Ajouter'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            backgroundColor: const Color(0xFF146D36),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Search + Category Filter
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              hintText: 'Rechercher un plat',
                              hintStyle: TextStyle(
                                color: Color(0xFF9CA3AF),
                                fontWeight: FontWeight.w500,
                              ),
                              prefixIcon: Icon(
                                Icons.search_rounded,
                                color: Color(0xFF9CA3AF),
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _showFilterSheet(filterCounts),
                        child: Container(
                          constraints: const BoxConstraints(minWidth: 110),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: hasCategoryFilter
                                ? const Color(0xFF1C2434)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: hasCategoryFilter
                                  ? const Color(0xFF1C2434)
                                  : const Color(0xFFE5E7EB),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.tune_rounded,
                                size: 18,
                                color: hasCategoryFilter
                                    ? Colors.white
                                    : const Color(0xFF4B5563),
                              ),
                              const SizedBox(width: 8),
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 92),
                                child: Text(
                                  hasCategoryFilter
                                      ? activeFilterLabel
                                      : 'Catégorie',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: hasCategoryFilter
                                        ? Colors.white
                                        : const Color(0xFF4B5563),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 18)),

              // List Content
              if (filteredItems.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.restaurant_menu,
                            size: 48,
                            color: Color(0xFFD1D5DB),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchController.text.isNotEmpty ||
                                    hasCategoryFilter
                                ? 'Aucun résultat pour ce filtre.'
                                : 'Votre menu est vide.',
                            style: const TextStyle(
                              color: Color(0xFF6B7280),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (_searchController.text.isNotEmpty ||
                              hasCategoryFilter) ...[
                            const SizedBox(height: 10),
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _selectedFilterId = _allMenuFilterId;
                                });
                              },
                              icon: const Icon(
                                Icons.restart_alt_rounded,
                                size: 18,
                              ),
                              label: const Text('Réinitialiser'),
                            ),
                          ],
                          if (allItems.isEmpty) ...[
                            const SizedBox(height: 12),
                            FilledButton.icon(
                              onPressed: _showAddDialog,
                              icon: const Icon(Icons.add_rounded, size: 18),
                              label: const Text('Ajouter un plat'),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF146D36),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final item = filteredItems[index];
                      return MenuItemCard(
                        key: ValueKey(item.id),
                        item: item,
                        onEdit: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Modifier ${item.name}')),
                          );
                        },
                        onDelete: () => _handleDelete(item.id),
                        onDeactivate: () => _handleDeactivate(item.id),
                      );
                    }, childCount: filteredItems.length),
                  ),
                ),

              // Bottom Padding
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showFilterSheet(Map<String, int> counts) async {
    var tempFilterId = _selectedFilterId;

    final selectedFilter = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        final bottomSafe = MediaQuery.of(sheetContext).padding.bottom;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 10, 20, 12 + bottomSafe),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 52,
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5E7EB),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Filtres',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF111827),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setModalState(
                                () => tempFilterId = _allMenuFilterId,
                              );
                            },
                            child: const Text(
                              'Reset',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Catégories menu',
                          style: TextStyle(
                            color: Color(0xFF6B7280),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _menuFilterOptions
                            .map((option) {
                              final isSelected = option.id == tempFilterId;
                              final count = counts[option.id] ?? 0;
                              return InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  setModalState(() => tempFilterId = option.id);
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFF1C2434)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFF1C2434)
                                          : const Color(0xFFE5E7EB),
                                    ),
                                  ),
                                  child: Text(
                                    '${option.label} ($count)',
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : const Color(0xFF374151),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              );
                            })
                            .toList(growable: false),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF6B7280),
                                side: const BorderSide(
                                  color: Color(0xFFE5E7EB),
                                ),
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
                              onPressed: () {
                                Navigator.of(context).pop(tempFilterId);
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF146D36),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              child: const Text('Appliquer'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (selectedFilter == null || !mounted) return;
    setState(() => _selectedFilterId = selectedFilter);
  }
}

class _MenuFilterOption {
  const _MenuFilterOption({required this.id, required this.label});

  final String id;
  final String label;
}
