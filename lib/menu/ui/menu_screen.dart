import 'package:flutter/material.dart';

import '../models/menu_item.dart';
import '../repository/menu_repository.dart';
import 'add_menu_item_screen.dart';
import 'widgets/menu_item_card.dart';

enum _MenuTab { all, drinks, food }

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key, required this.restaurantId});

  final String restaurantId;

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final MenuRepository _repository = MenuRepository();
  final TextEditingController _searchController = TextEditingController();
  
  _MenuTab _selectedTab = _MenuTab.all;
  late Stream<List<MenuItem>> _menuStream;

  @override
  void initState() {
    super.initState();
    _menuStream = _repository.watchMenuItems(widget.restaurantId).asBroadcastStream();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didUpdateWidget(covariant MenuScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.restaurantId != widget.restaurantId) {
      _menuStream = _repository.watchMenuItems(widget.restaurantId).asBroadcastStream();
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
    _repository.deleteItem(widget.restaurantId, id);
  }

  void _handleDeactivate(String id) {
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
    final query = _searchController.text.toLowerCase();
    
    return allItems.where((item) {
      // Filter by Tab
      if (_selectedTab == _MenuTab.drinks && item.category != MenuCategory.drink) return false;
      if (_selectedTab == _MenuTab.food && item.category != MenuCategory.food) return false;
      
      // Filter by Search Query
      if (query.isNotEmpty && !item.name.toLowerCase().contains(query)) return false;
      
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
            body: Center(child: CircularProgressIndicator(color: Color(0xFF739760))),
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
    
    // Counts for tabs
    final totalCount = allItems.length;
    final drinkCount = allItems.where((i) => i.category == MenuCategory.drink).length;
    final foodCount = allItems.where((i) => i.category == MenuCategory.food).length;

    return ColoredBox(
      color: const Color(0xFFF5F6F3),
      child: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 32, 20, 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Menu',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'serif',
                          color: Color(0xFF141E28),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _showAddDialog,
                        icon: const Icon(Icons.add, size: 20),
                        label: const Text('Ajouter un plat'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF739760),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          textStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Search Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 16),
                        const Icon(Icons.search, color: Color(0xFF9CA3AF), size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              hintText: 'Rechercher un plat...',
                              hintStyle: TextStyle(
                                color: Color(0xFF9CA3AF),
                                fontSize: 16,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // Tabs
              SliverToBoxAdapter(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      _buildTab(
                        label: 'Tous les plats ($totalCount)', 
                        tab: _MenuTab.all,
                      ),
                      const SizedBox(width: 8),
                      _buildTab(
                        label: 'Boissons ($drinkCount)', 
                        tab: _MenuTab.drinks,
                      ),
                      const SizedBox(width: 8),
                      _buildTab(
                        label: 'Nourritures ($foodCount)', 
                        tab: _MenuTab.food,
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // List Content
              if (filteredItems.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.restaurant_menu, size: 48, color: Color(0xFFD1D5DB)),
                          const SizedBox(height: 16),
                          Text(
                            _searchController.text.isNotEmpty 
                                ? 'Aucun résultat trouvé.' 
                                : 'Votre menu est vide.',
                            style: const TextStyle(color: Color(0xFF6B7280)),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
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
                      },
                      childCount: filteredItems.length,
                    ),
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

  Widget _buildTab({required String label, required _MenuTab tab}) {
    final isSelected = _selectedTab == tab;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = tab;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2C3E50) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? null : Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF4B5563),
          ),
        ),
      ),
    );
  }
}
