import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/avoo_theme.dart';
import '../models/stock_product.dart';
import 'stocks_repository.dart';
import 'widgets/add_stock_item_bottom_sheet.dart';
import 'widgets/stock_product_card.dart';

class StocksScreen extends StatefulWidget {
  const StocksScreen({
    super.key,
    required this.restaurantId,
    this.userRole = 'owner',
    this.repository,
  });

  final String restaurantId;
  final String userRole;
  final StocksRepositoryBase? repository;

  @override
  State<StocksScreen> createState() => _StocksScreenState();
}

class _StocksScreenState extends State<StocksScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Map<String, double> _optimisticQuantities = <String, double>{};
  final Map<String, Timer> _pendingQuantitySaves = <String, Timer>{};

  late StocksRepositoryBase _repository;
  late Stream<List<StockProduct>> _stocksStream;

  String? _selectedCategoryId;
  bool _showArchived = false;
  Timer? _clockTimer;
  DateTime _clockNow = DateTime.now();

  bool get _canManageStocks {
    final normalized = widget.userRole.toLowerCase().trim();
    if (normalized.isEmpty) {
      return true;
    }
    return normalized == 'owner' ||
        normalized == 'admin' ||
        normalized == 'manager' ||
        normalized == 'gerant' ||
        normalized == 'gérant' ||
        normalized == 'proprietaire' ||
        normalized == 'propriétaire';
  }

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? StocksRepository();
    _stocksStream = _buildStream();
    _searchController.addListener(_onSearchChanged);
    _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _clockNow = DateTime.now();
      });
    });
  }

  @override
  void didUpdateWidget(covariant StocksScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.restaurantId != widget.restaurantId ||
        oldWidget.repository != widget.repository) {
      _repository = widget.repository ?? StocksRepository();
      _stocksStream = _buildStream();
    }
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    _clockTimer?.cancel();
    for (final timer in _pendingQuantitySaves.values) {
      timer.cancel();
    }
    _pendingQuantitySaves.clear();
    super.dispose();
  }

  Stream<List<StockProduct>> _buildStream() {
    return _repository.watchStocks(widget.restaurantId).asBroadcastStream();
  }

  void _onSearchChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  Future<void> _retryLoading() async {
    setState(() {
      _stocksStream = _buildStream();
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<StockProduct>>(
      stream: _stocksStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _StocksErrorState(onRetry: _retryLoading);
        }

        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: AvooColors.green),
          );
        }

        final products = snapshot.data ?? <StockProduct>[];
        return _buildContent(products);
      },
    );
  }

  Widget _buildContent(List<StockProduct> allProducts) {
    final query = _searchController.text.trim().toLowerCase();
    final activeCount = allProducts.where((item) => !item.isArchived).length;
    final archivedCount = allProducts.where((item) => item.isArchived).length;
    final alertCount = allProducts
        .where((item) => !item.isArchived && item.status != StockStatus.normal)
        .length;
    final categories = _extractCategories(allProducts);

    if (_selectedCategoryId != null &&
        categories.every((category) => category.id != _selectedCategoryId)) {
      _selectedCategoryId = null;
    }

    final productsById = allProducts.map((item) => item.id).toSet();
    _optimisticQuantities.removeWhere((id, _) => !productsById.contains(id));

    final filteredProducts =
        allProducts
            .where((product) => _matchesFilters(product, query))
            .toList(growable: false)
          ..sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );

    final latestUpdate = _latestUpdate(allProducts) ?? _clockNow;

    return ColoredBox(
      color: const Color(0xFFF4F5F8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Stocks',
                        style: TextStyle(
                          color: Color(0xFF111827),
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          height: 1.02,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Gérez vos produits en temps réel',
                        style: TextStyle(
                          color: Color(0xFF697386),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_canManageStocks)
                  FilledButton.icon(
                    onPressed: _openAddProductSheet,
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: const Text('Ajouter'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AvooColors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    icon: Icons.inventory_2_outlined,
                    label: 'PRODUITS',
                    value: '$activeCount',
                    valueColor: const Color(0xFF101828),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetricCard(
                    icon: Icons.error_outline_rounded,
                    label: 'ALERTES',
                    value: '$alertCount',
                    valueColor: const Color(0xFFF45D01),
                    iconColor: const Color(0xFFF45D01),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetricCard(
                    icon: Icons.schedule_rounded,
                    label: 'ACTUS',
                    value: _formatClock(latestUpdate),
                    valueColor: const Color(0xFF101828),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E6EC)),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Rechercher un produit',
                        hintStyle: TextStyle(
                          color: Color(0xFF9AA3B1),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: Color(0xFF9AA3B1),
                          size: 22,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                PopupMenuButton<String?>(
                  onSelected: (value) {
                    setState(() {
                      _selectedCategoryId = value;
                    });
                  },
                  itemBuilder: (context) {
                    final items = <PopupMenuEntry<String?>>[
                      const PopupMenuItem<String?>(
                        value: null,
                        child: Text('Toutes catégories'),
                      ),
                    ];
                    for (final category in categories) {
                      items.add(
                        PopupMenuItem<String?>(
                          value: category.id,
                          child: Text(category.label),
                        ),
                      );
                    }
                    return items;
                  },
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E6EC)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.filter_alt_outlined,
                          color: Color(0xFF374151),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _selectedCategoryLabel(categories),
                          style: const TextStyle(
                            color: Color(0xFF4B5563),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _ArchiveTab(
              activeCount: activeCount,
              archivedCount: archivedCount,
              showArchived: _showArchived,
              onChanged: (showArchived) {
                setState(() {
                  _showArchived = showArchived;
                });
              },
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: filteredProducts.isEmpty
                ? _EmptyStockState(
                    isSearching: query.isNotEmpty,
                    isArchivedMode: _showArchived,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 104),
                    itemCount: filteredProducts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      final displayedQuantity =
                          _optimisticQuantities[product.id] ??
                          product.quantityRemaining;

                      return StockProductCard(
                        product: product,
                        displayedQuantity: displayedQuantity,
                        readOnly: !_canManageStocks,
                        onIncrease: () => _changeQuantity(product, 10),
                        onDecrease: () => _changeQuantity(product, -10),
                        onMenuTap: () => _showProductActions(
                          product: product,
                          displayedQuantity: displayedQuantity,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  bool _matchesFilters(StockProduct product, String query) {
    final matchesCategory =
        _selectedCategoryId == null ||
        product.category.id == _selectedCategoryId;

    final matchesSearch =
        query.isEmpty ||
        product.name.toLowerCase().contains(query) ||
        product.category.name.toLowerCase().contains(query);

    final matchesArchiveTab =
        query.isNotEmpty ||
        (_showArchived ? product.isArchived : !product.isArchived);

    return matchesCategory && matchesSearch && matchesArchiveTab;
  }

  List<_CategoryOption> _extractCategories(List<StockProduct> products) {
    final byId = <String, _CategoryOption>{};
    for (final product in products) {
      byId.putIfAbsent(
        product.category.id,
        () => _CategoryOption(
          id: product.category.id,
          label: product.category.name,
        ),
      );
    }
    final list = byId.values.toList(growable: false)
      ..sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
    return list;
  }

  String _selectedCategoryLabel(List<_CategoryOption> categories) {
    if (_selectedCategoryId == null) {
      return 'Catégorie';
    }
    final selected = categories.where((item) => item.id == _selectedCategoryId);
    if (selected.isEmpty) {
      return 'Catégorie';
    }
    return selected.first.label;
  }

  DateTime? _latestUpdate(List<StockProduct> products) {
    if (products.isEmpty) {
      return null;
    }
    var latest = products.first.lastUpdated;
    for (final product in products) {
      if (product.lastUpdated.isAfter(latest)) {
        latest = product.lastUpdated;
      }
    }
    return latest;
  }

  void _changeQuantity(StockProduct product, double delta) {
    if (!_canManageStocks || product.isArchived) {
      return;
    }

    final current =
        _optimisticQuantities[product.id] ?? product.quantityRemaining;
    final next = math.max(0.0, current + delta);

    setState(() {
      _optimisticQuantities[product.id] = next;
    });

    _pendingQuantitySaves[product.id]?.cancel();
    _pendingQuantitySaves[product.id] = Timer(
      const Duration(milliseconds: 320),
      () async {
        try {
          await _repository.updateStockQuantity(
            restaurantId: widget.restaurantId,
            itemId: product.id,
            quantity: next,
          );
        } catch (_) {
          if (!mounted) {
            return;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Impossible de mettre à jour la quantité.'),
            ),
          );
        }
      },
    );
  }

  Future<void> _openAddProductSheet() async {
    if (!_canManageStocks) {
      return;
    }

    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return AddStockItemBottomSheet(
          onSave: (payload) {
            return _repository.createStockItem(
              restaurantId: widget.restaurantId,
              name: payload.name,
              category: payload.category,
              initialQuantity: payload.initialQuantity,
              unit: payload.unit,
              minStock: payload.alertThreshold,
              shortDescription: payload.shortDescription,
              purchasePrice: payload.purchasePrice,
              supplier: payload.supplier,
              location: payload.location,
              perishable: payload.perishable,
              expiresAt: payload.expiryDate,
            );
          },
        );
      },
    );
  }

  Future<void> _openEditProductSheet(
    StockProduct product,
    double displayedQuantity,
  ) async {
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return AddStockItemBottomSheet(
          isEditMode: true,
          initialName: product.name,
          initialCategory: product.category.name,
          initialShortDescription: product.description,
          initialUnit: product.unit,
          initialQuantity: displayedQuantity,
          initialAlertThreshold: product.minStock,
          initialPurchasePrice: product.purchasePrice,
          initialSupplier: product.supplier,
          initialLocation: product.location,
          initialPerishable: product.perishable,
          initialExpiryDate: product.expiresAt,
          onSave: (payload) {
            return _repository.updateStockItem(
              restaurantId: widget.restaurantId,
              itemId: product.id,
              name: payload.name,
              quantity: payload.initialQuantity,
              category: payload.category,
              unit: payload.unit,
              minStock: payload.alertThreshold,
              shortDescription: payload.shortDescription,
              purchasePrice: payload.purchasePrice,
              supplier: payload.supplier,
              location: payload.location,
              perishable: payload.perishable,
              expiresAt: payload.expiryDate,
            );
          },
        );
      },
    );
  }

  Future<void> _showProductActions({
    required StockProduct product,
    required double displayedQuantity,
  }) async {
    if (!_canManageStocks) {
      return;
    }

    final selectedAction = await showModalBottomSheet<_ProductAction>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            top: false,
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text('Modifier'),
                  onTap: () => Navigator.of(context).pop(_ProductAction.edit),
                ),
                if (product.isArchived)
                  ListTile(
                    leading: const Icon(Icons.unarchive_outlined),
                    title: const Text('Restaurer'),
                    onTap: () =>
                        Navigator.of(context).pop(_ProductAction.restore),
                  )
                else
                  ListTile(
                    leading: const Icon(Icons.archive_outlined),
                    title: const Text('Archiver'),
                    onTap: () =>
                        Navigator.of(context).pop(_ProductAction.archive),
                  ),
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline,
                    color: AvooColors.error,
                  ),
                  title: const Text('Supprimer'),
                  textColor: AvooColors.error,
                  onTap: () => Navigator.of(context).pop(_ProductAction.delete),
                ),
                ListTile(
                  title: const Center(child: Text('Annuler')),
                  onTap: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selectedAction == null || !mounted) {
      return;
    }

    switch (selectedAction) {
      case _ProductAction.edit:
        await _openEditProductSheet(product, displayedQuantity);
        break;
      case _ProductAction.archive:
        await _archiveProduct(product);
        break;
      case _ProductAction.restore:
        await _restoreProduct(product);
        break;
      case _ProductAction.delete:
        await _deleteProduct(product);
        break;
    }
  }

  Future<void> _archiveProduct(StockProduct product) async {
    try {
      await _repository.archiveStockItem(
        restaurantId: widget.restaurantId,
        itemId: product.id,
      );

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: const Text('Élément archivé'),
            action: SnackBarAction(
              label: 'Annuler',
              onPressed: () {
                unawaited(
                  _repository.restoreStockItem(
                    restaurantId: widget.restaurantId,
                    itemId: product.id,
                  ),
                );
              },
            ),
          ),
        );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d’archiver ce produit.')),
      );
    }
  }

  Future<void> _restoreProduct(StockProduct product) async {
    try {
      await _repository.restoreStockItem(
        restaurantId: widget.restaurantId,
        itemId: product.id,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Produit restauré')));
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de restaurer ce produit.')),
      );
    }
  }

  Future<void> _deleteProduct(StockProduct product) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Supprimer ce produit ?'),
          content: Text('Cette action supprimera "${product.name}".'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(backgroundColor: AvooColors.error),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    try {
      await _repository.deleteStockItem(
        restaurantId: widget.restaurantId,
        itemId: product.id,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Produit supprimé')));
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de supprimer ce produit.')),
      );
    }
  }

  String _formatClock(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

enum _ProductAction { edit, archive, restore, delete }

class _CategoryOption {
  const _CategoryOption({required this.id, required this.label});

  final String id;
  final String label;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.valueColor,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor ?? const Color(0xFF9AA3B1), size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _ArchiveTab extends StatelessWidget {
  const _ArchiveTab({
    required this.activeCount,
    required this.archivedCount,
    required this.showArchived,
    required this.onChanged,
  });

  final int activeCount;
  final int archivedCount;
  final bool showArchived;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEBEDF1),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(6),
      child: Row(
        children: [
          Expanded(
            child: _TabButton(
              label: 'Actifs ($activeCount)',
              selected: !showArchived,
              onTap: () => onChanged(false),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _TabButton(
              label: 'Archivés ($archivedCount)',
              selected: showArchived,
              onTap: () => onChanged(true),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 48,
        decoration: BoxDecoration(
          color: selected ? AvooColors.green : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF6B7280),
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _EmptyStockState extends StatelessWidget {
  const _EmptyStockState({
    required this.isSearching,
    required this.isArchivedMode,
  });

  final bool isSearching;
  final bool isArchivedMode;

  @override
  Widget build(BuildContext context) {
    final message = isSearching
        ? 'Aucun produit trouvé pour cette recherche.'
        : isArchivedMode
        ? 'Aucun produit archivé.'
        : 'Aucun produit actif.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _StocksErrorState extends StatelessWidget {
  const _StocksErrorState({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Erreur de chargement des stocks',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}
