import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/avoo_theme.dart';
import '../models/stock_product.dart';
import 'stocks_repository.dart';
import 'widgets/add_stock_item_bottom_sheet.dart';
import 'widgets/stock_product_card.dart';

const List<String> _stockCategoryPresets = <String>[
  'Alimentaire',
  'Boissons',
  'Préparations maison',
  'Emballages',
  'Hygiène & Nettoyage',
  'Consommables',
];

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
  final ScrollController _listScrollController = ScrollController();
  final Map<String, double> _optimisticQuantities = <String, double>{};
  final Map<String, Timer> _pendingQuantitySaves = <String, Timer>{};

  late StocksRepositoryBase _repository;
  late Stream<List<StockProduct>> _stocksStream;

  String? _selectedCategoryId;
  String? _selectedCategoryLabelFilter;
  bool _showAlertsOnly = false;
  bool _showArchived = false;
  bool _isCompactLayout = false;
  double _lastListOffset = 0;
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
    _listScrollController.addListener(_onListScrolled);
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
    _listScrollController
      ..removeListener(_onListScrolled)
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

  void _onListScrolled() {
    if (!_listScrollController.hasClients || !mounted) {
      return;
    }

    final offset = math.max(0.0, _listScrollController.offset);
    final delta = offset - _lastListOffset;
    _lastListOffset = offset;

    var shouldCompact = _isCompactLayout;
    if (offset <= 8) {
      shouldCompact = false;
    } else if (delta > 1.8 && offset > 28) {
      shouldCompact = true;
    } else if (delta < -2.4 && offset < 86) {
      shouldCompact = false;
    }

    if (shouldCompact != _isCompactLayout) {
      setState(() {
        _isCompactLayout = shouldCompact;
      });
    }
  }

  Future<void> _retryLoading() async {
    setState(() {
      _stocksStream = _buildStream();
    });
  }

  Future<void> _openCategoryFilterSheet(
    List<_CategoryOption> categories,
    List<StockProduct> allProducts,
  ) async {
    final categoryCounts = _countActiveProductsPerCategory(allProducts);
    final allCount = allProducts.where((product) => !product.isArchived).length;
    final alertCount = allProducts
        .where(
          (product) =>
              !product.isArchived && product.status != StockStatus.normal,
        )
        .length;
    final options = _buildFilterCategoryOptions(categories, categoryCounts);

    String? draftCategoryId = _selectedCategoryId;
    String? draftCategoryLabel = _selectedCategoryLabelFilter;
    var draftAlertsOnly = _showAlertsOnly;
    if (draftCategoryLabel == null && draftCategoryId != null) {
      final byId = categories.where(
        (category) => category.id == draftCategoryId,
      );
      if (byId.isNotEmpty) {
        draftCategoryLabel = byId.first.label;
      }
    }

    final selection = await showModalBottomSheet<_StockFilterSheetSelection>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          top: false,
          child: StatefulBuilder(
            builder: (context, setModalState) {
              Widget filterChip({
                required String label,
                required bool selected,
                required VoidCallback onTap,
              }) {
                return Material(
                  color: selected ? const Color(0xFF1A2236) : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: onTap,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 13,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: selected
                              ? const Color(0xFF1A2236)
                              : const Color(0xFFD5D9E1),
                        ),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          color: selected
                              ? Colors.white
                              : const Color(0xFF374151),
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                );
              }

              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD6DAE2),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Filtres',
                              style: TextStyle(
                                color: Color(0xFF111827),
                                fontSize: 21,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setModalState(() {
                                draftAlertsOnly = false;
                                draftCategoryId = null;
                                draftCategoryLabel = null;
                              });
                            },
                            child: const Text(
                              'Reset',
                              style: TextStyle(
                                color: Color(0xFF17793A),
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Catégories menu',
                          style: TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.38,
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            filterChip(
                              label: 'Tous ($allCount)',
                              selected:
                                  !draftAlertsOnly &&
                                  draftCategoryLabel == null,
                              onTap: () {
                                setModalState(() {
                                  draftAlertsOnly = false;
                                  draftCategoryId = null;
                                  draftCategoryLabel = null;
                                });
                              },
                            ),
                            filterChip(
                              label: 'Alertes ($alertCount)',
                              selected: draftAlertsOnly,
                              onTap: () {
                                setModalState(() {
                                  draftAlertsOnly = true;
                                  draftCategoryId = null;
                                  draftCategoryLabel = null;
                                });
                              },
                            ),
                            for (final option in options)
                              filterChip(
                                label: '${option.label} (${option.count})',
                                selected:
                                    !draftAlertsOnly &&
                                    draftCategoryLabel != null &&
                                    _normalizeCategoryKey(
                                          draftCategoryLabel!,
                                        ) ==
                                        option.normalizedKey,
                                onTap: () {
                                  setModalState(() {
                                    draftAlertsOnly = false;
                                    draftCategoryId = option.id;
                                    draftCategoryLabel = option.label;
                                  });
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF6B7280),
                                side: const BorderSide(
                                  color: Color(0xFFD5D9E1),
                                ),
                                backgroundColor: const Color(0xFFF4F5F7),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              child: const Text('Annuler'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: () {
                                Navigator.of(context).pop(
                                  _StockFilterSheetSelection(
                                    alertsOnly: draftAlertsOnly,
                                    categoryId: draftAlertsOnly
                                        ? null
                                        : draftCategoryId,
                                    categoryLabel: draftAlertsOnly
                                        ? null
                                        : draftCategoryLabel,
                                  ),
                                );
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF17793A),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              child: const Text('Appliquer'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );

    if (!mounted || selection == null) {
      return;
    }

    setState(() {
      _showAlertsOnly = selection.alertsOnly;
      _selectedCategoryId = selection.categoryId;
      _selectedCategoryLabelFilter = selection.categoryLabel;
      if (_showAlertsOnly) {
        _showArchived = false;
      }
    });
  }

  List<_FilterCategoryOption> _buildFilterCategoryOptions(
    List<_CategoryOption> categories,
    Map<String, int> categoryCounts,
  ) {
    final byNormalized = <String, _CategoryOption>{};
    for (final category in categories) {
      byNormalized[_normalizeCategoryKey(category.label)] = category;
    }

    final options = <_FilterCategoryOption>[];
    final presetKeys = <String>{};

    for (final label in _stockCategoryPresets) {
      final normalized = _normalizeCategoryKey(label);
      presetKeys.add(normalized);
      final dynamicCategory = byNormalized[normalized];
      options.add(
        _FilterCategoryOption(
          id: dynamicCategory?.id,
          label: label,
          normalizedKey: normalized,
          count: categoryCounts[normalized] ?? 0,
        ),
      );
    }

    final extraCategories =
        categories
            .where(
              (category) =>
                  !presetKeys.contains(_normalizeCategoryKey(category.label)),
            )
            .toList(growable: false)
          ..sort(
            (a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()),
          );

    for (final category in extraCategories) {
      final normalized = _normalizeCategoryKey(category.label);
      options.add(
        _FilterCategoryOption(
          id: category.id,
          label: category.label,
          normalizedKey: normalized,
          count: categoryCounts[normalized] ?? 0,
        ),
      );
    }

    return options;
  }

  Map<String, int> _countActiveProductsPerCategory(
    List<StockProduct> products,
  ) {
    final counts = <String, int>{};
    for (final product in products) {
      if (product.isArchived) {
        continue;
      }
      final key = _normalizeCategoryKey(product.category.name);
      counts[key] = (counts[key] ?? 0) + 1;
    }
    return counts;
  }

  String _normalizeCategoryKey(String value) {
    var normalized = value.toLowerCase().trim();
    const replacements = <String, String>{
      'à': 'a',
      'á': 'a',
      'â': 'a',
      'ä': 'a',
      'ã': 'a',
      'å': 'a',
      'ç': 'c',
      'è': 'e',
      'é': 'e',
      'ê': 'e',
      'ë': 'e',
      'ì': 'i',
      'í': 'i',
      'î': 'i',
      'ï': 'i',
      'ñ': 'n',
      'ò': 'o',
      'ó': 'o',
      'ô': 'o',
      'ö': 'o',
      'õ': 'o',
      'ù': 'u',
      'ú': 'u',
      'û': 'u',
      'ü': 'u',
      'ý': 'y',
      'ÿ': 'y',
      '&': ' et ',
    };
    replacements.forEach((from, to) {
      normalized = normalized.replaceAll(from, to);
    });
    normalized = normalized.replaceAll(RegExp(r'[^a-z0-9]+'), ' ');
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ').trim();
    return normalized;
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

    if (_showAlertsOnly) {
      _selectedCategoryId = null;
      _selectedCategoryLabelFilter = null;
    } else if (_selectedCategoryLabelFilter != null) {
      final selectedMatches = categories
          .where(
            (category) =>
                _normalizeCategoryKey(category.label) ==
                _normalizeCategoryKey(_selectedCategoryLabelFilter!),
          )
          .toList(growable: false);
      _selectedCategoryId = selectedMatches.isEmpty
          ? null
          : selectedMatches.first.id;
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
    final compact = _isCompactLayout;
    final controlHeight = compact ? 44.0 : 48.0;
    final controlRadius = compact ? 12.0 : 14.0;

    return ColoredBox(
      color: const Color(0xFFF4F5F8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.fromLTRB(
              16,
              compact ? 10 : 18,
              16,
              compact ? 8 : 12,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Stocks',
                        style: TextStyle(
                          color: const Color(0xFF111827),
                          fontSize: compact ? 24 : 28,
                          fontWeight: FontWeight.w800,
                          height: 1.02,
                        ),
                      ),
                      AnimatedCrossFade(
                        duration: const Duration(milliseconds: 180),
                        sizeCurve: Curves.easeOutCubic,
                        crossFadeState: compact
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        firstChild: const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text(
                            'Gérez vos produits en temps réel',
                            style: TextStyle(
                              color: Color(0xFF697386),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        secondChild: const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
                if (_canManageStocks)
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: compact
                        ? FilledButton(
                            key: const ValueKey('compact-add-btn'),
                            onPressed: _openAddProductSheet,
                            style: FilledButton.styleFrom(
                              backgroundColor: AvooColors.green,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(46, 46),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            child: const Icon(Icons.add_rounded, size: 22),
                          )
                        : FilledButton.icon(
                            key: const ValueKey('default-add-btn'),
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
                  ),
              ],
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 220),
            sizeCurve: Curves.easeOutCubic,
            crossFadeState: compact
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: Padding(
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
            secondChild: const SizedBox.shrink(),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            height: compact ? 8 : 14,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: controlHeight,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(controlRadius),
                      border: Border.all(color: const Color(0xFFE2E6EC)),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Rechercher un produit',
                        hintStyle: const TextStyle(
                          color: Color(0xFF9AA3B1),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: Color(0xFF9AA3B1),
                          size: 22,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          vertical: compact ? 12 : 14,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: controlHeight,
                  child: FilledButton(
                    onPressed: () =>
                        _openCategoryFilterSheet(categories, allProducts),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF146D36),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: compact ? 12 : 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(controlRadius),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.filter_alt_outlined,
                          size: compact ? 18 : 19,
                        ),
                        SizedBox(width: compact ? 5 : 7),
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: compact ? 92 : 110,
                          ),
                          child: Text(
                            _selectedCategoryLabel(categories),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: compact ? 13 : 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: compact ? 18 : 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            height: compact ? 8 : 14,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _ArchiveTab(
              activeCount: activeCount,
              archivedCount: archivedCount,
              showArchived: _showArchived,
              compact: compact,
              onChanged: (showArchived) {
                setState(() {
                  _showArchived = showArchived;
                });
              },
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            height: compact ? 8 : 12,
          ),
          Expanded(
            child: filteredProducts.isEmpty
                ? _EmptyStockState(
                    isSearching: query.isNotEmpty,
                    isArchivedMode: _showArchived,
                  )
                : ListView.separated(
                    controller: _listScrollController,
                    padding: EdgeInsets.fromLTRB(16, compact ? 4 : 8, 16, 104),
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
        _selectedCategoryLabelFilter == null ||
        _normalizeCategoryKey(product.category.name) ==
            _normalizeCategoryKey(_selectedCategoryLabelFilter!) ||
        (_selectedCategoryId != null &&
            product.category.id == _selectedCategoryId);

    final matchesAlertsFilter =
        !_showAlertsOnly ||
        (!product.isArchived && product.status != StockStatus.normal);

    final matchesSearch =
        query.isEmpty ||
        product.name.toLowerCase().contains(query) ||
        product.category.name.toLowerCase().contains(query);

    final matchesArchiveTab = _showAlertsOnly
        ? !product.isArchived
        : query.isNotEmpty ||
              (_showArchived ? product.isArchived : !product.isArchived);

    return matchesCategory &&
        matchesAlertsFilter &&
        matchesSearch &&
        matchesArchiveTab;
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
    if (_showAlertsOnly) {
      return 'Alertes';
    }
    if (_selectedCategoryLabelFilter == null) {
      return 'Filtrer';
    }
    final selected = categories.where(
      (item) =>
          _normalizeCategoryKey(item.label) ==
          _normalizeCategoryKey(_selectedCategoryLabelFilter!),
    );
    if (selected.isEmpty) {
      return _selectedCategoryLabelFilter!;
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

class _FilterCategoryOption {
  const _FilterCategoryOption({
    required this.id,
    required this.label,
    required this.normalizedKey,
    required this.count,
  });

  final String? id;
  final String label;
  final String normalizedKey;
  final int count;
}

class _StockFilterSheetSelection {
  const _StockFilterSheetSelection({
    required this.alertsOnly,
    required this.categoryId,
    required this.categoryLabel,
  });

  final bool alertsOnly;
  final String? categoryId;
  final String? categoryLabel;
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
    this.compact = false,
  });

  final int activeCount;
  final int archivedCount;
  final bool showArchived;
  final ValueChanged<bool> onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEBEDF1),
        borderRadius: BorderRadius.circular(compact ? 16 : 20),
      ),
      padding: EdgeInsets.all(compact ? 4 : 6),
      child: Row(
        children: [
          Expanded(
            child: _TabButton(
              label: 'Actifs ($activeCount)',
              selected: !showArchived,
              compact: compact,
              onTap: () => onChanged(false),
            ),
          ),
          SizedBox(width: compact ? 6 : 8),
          Expanded(
            child: _TabButton(
              label: 'Archivés ($archivedCount)',
              selected: showArchived,
              compact: compact,
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
    this.compact = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: compact ? 40 : 48,
        decoration: BoxDecoration(
          color: selected ? AvooColors.green : Colors.transparent,
          borderRadius: BorderRadius.circular(compact ? 12 : 16),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF6B7280),
            fontSize: compact ? 14 : 16,
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
