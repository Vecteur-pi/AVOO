import 'package:flutter/material.dart';

import '../models/stock_product.dart';
import 'stocks_repository.dart';
import 'widgets/stock_product_card.dart';

// Dummy Categories setup for local filtering logic
const CategoryBoissons = StockCategory(id: 'cat_boissons', name: 'Boissons');
const CategoryNourritures = StockCategory(id: 'cat_nourritures', name: 'Nourritures');

class StocksScreen extends StatefulWidget {
  const StocksScreen({super.key, required this.restaurantId});

  final String restaurantId;

  @override
  State<StocksScreen> createState() => _StocksScreenState();
}

class _StocksScreenState extends State<StocksScreen> {
  final TextEditingController _searchController = TextEditingController();
  StockCategory _selectedCategory = CategoryBoissons;
  
  final StocksRepository _repository = StocksRepository();
  late Stream<List<StockProduct>> _stocksStream;

  @override
  void initState() {
    super.initState();
    _stocksStream = _repository.watchStocks(widget.restaurantId).asBroadcastStream();
  }

  @override
  void didUpdateWidget(covariant StocksScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.restaurantId != widget.restaurantId) {
      _stocksStream = _repository.watchStocks(widget.restaurantId).asBroadcastStream();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<StockProduct>>(
      stream: _stocksStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF739760)));
        }
        
        if (snapshot.hasError) {
          return Center(child: Text('Erreur de chargement: ${snapshot.error}'));
        }

        final products = snapshot.data ?? [];
        return _buildContent(context, products);
      },
    );
  }

  Widget _buildContent(BuildContext context, List<StockProduct> allProducts) {
    final theme = Theme.of(context);
    
    // Filter logic
    final query = _searchController.text.toLowerCase();
    
    final filteredProducts = allProducts.where((p) {
      // Dynamic category check
      final isBoisson = p.category.name.toLowerCase().contains('boisson');
      final matchesCategory = _selectedCategory == CategoryBoissons ? isBoisson : !isBoisson;
      
      final matchesQuery = p.name.toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList();

    // Alert badge logic
    final totalAlerts = allProducts.where((p) => p.status != StockStatus.normal).length;
    
    final boissonCount = allProducts.where((p) => p.category.name.toLowerCase().contains('boisson')).length;
    final nourritureCount = allProducts.length - boissonCount;

    return ColoredBox(
      color: const Color(0xFFF5F6F3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Stocks',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: const Color(0xFF111827),
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    fontFamily: 'Serif',
                  ),
                ),
                if (totalAlerts > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDE8E8), // Light red
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: Color(0xFFE02424),
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$totalAlerts alertes',
                          style: const TextStyle(
                            color: Color(0xFFE02424),
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
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
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Rechercher un produit',
                  hintStyle: TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontWeight: FontWeight.w500,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: Color(0xFF9CA3AF),
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 20),

          // Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: _buildTab(
                    label: 'Boissons ($boissonCount)',
                    category: CategoryBoissons,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTab(
                    label: 'Nourritures ($nourritureCount)',
                    category: CategoryNourritures,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),

          // List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100), // Bottom padding for nav bar overlap safety
              itemCount: filteredProducts.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final product = filteredProducts[index];
                return StockProductCard(
                  product: product,
                  onOrderTap: () {
                    // Action Commander
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab({required String label, required StockCategory category}) {
    final isSelected = _selectedCategory == category;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = category;
        });
      },
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2D3B4F) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: isSelected ? null : Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: isSelected
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF4B5563),
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
