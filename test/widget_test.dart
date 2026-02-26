import 'dart:async';

import 'package:avoo/stocks/models/stock_product.dart';
import 'package:avoo/stocks/ui/stocks_repository.dart';
import 'package:avoo/stocks/ui/stocks_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Appui sur + met a jour l\'UI et appelle updateStockQuantity', (
    WidgetTester tester,
  ) async {
    final repository = _FakeStocksRepository([_buildProduct()]);
    addTearDown(repository.dispose);
    await _setTestViewport(tester);

    await tester.pumpWidget(_wrapWithApp(repository));
    await tester.pumpAndSettle();

    expect(find.text('500'), findsOneWidget);

    await tester.tap(find.byKey(const Key('stock_plus_item-1')));
    await tester.pump();

    expect(find.text('510'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    expect(repository.quantityUpdates.length, 1);
    expect(repository.quantityUpdates.single.itemId, 'item-1');
    expect(repository.quantityUpdates.single.quantity, 510);
  });

  testWidgets('Archiver retire l\'item actif et Undo le restaure', (
    WidgetTester tester,
  ) async {
    final repository = _FakeStocksRepository([_buildProduct()]);
    addTearDown(repository.dispose);
    await _setTestViewport(tester);

    await tester.pumpWidget(_wrapWithApp(repository));
    await tester.pumpAndSettle();

    expect(find.text('Mozzarella'), findsOneWidget);

    await tester.tap(find.byKey(const Key('stock_menu_item-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Archiver').last);
    await tester.pumpAndSettle();

    expect(repository.archiveCalls, 1);
    expect(find.text('Mozzarella'), findsNothing);
    expect(find.text('Élément archivé'), findsOneWidget);

    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();

    expect(repository.restoreCalls, 1);
    expect(find.text('Mozzarella'), findsOneWidget);
  });

  testWidgets(
    'Recherche trouve un élément archivé même avec filtre Actifs',
    (WidgetTester tester) async {
      final repository = _FakeStocksRepository([
        _buildProduct(id: 'item-active', name: 'Mozzarella'),
        _buildProduct(
          id: 'item-archived',
          name: 'Poivron',
          isArchived: true,
        ),
      ]);
      addTearDown(repository.dispose);
      await _setTestViewport(tester);

      await tester.pumpWidget(_wrapWithApp(repository));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('stock_menu_item-active')), findsOneWidget);
      expect(find.byKey(const Key('stock_menu_item-archived')), findsNothing);

      await tester.enterText(find.byType(TextField).first, 'Poivron');
      await tester.pump();

      expect(find.byKey(const Key('stock_menu_item-archived')), findsOneWidget);
      expect(find.byKey(const Key('stock_menu_item-active')), findsNothing);
      expect(find.text('Élément archivé'), findsOneWidget);
    },
  );

  testWidgets(
    'Recherche trouve un élément actif même avec filtre Archivés',
    (WidgetTester tester) async {
      final repository = _FakeStocksRepository([
        _buildProduct(id: 'item-active', name: 'Mozzarella'),
        _buildProduct(
          id: 'item-archived',
          name: 'Poivron',
          isArchived: true,
        ),
      ]);
      addTearDown(repository.dispose);
      await _setTestViewport(tester);

      await tester.pumpWidget(_wrapWithApp(repository));
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('Archivés').first);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('stock_menu_item-archived')), findsOneWidget);
      expect(find.byKey(const Key('stock_menu_item-active')), findsNothing);

      await tester.enterText(find.byType(TextField).first, 'Mozzarella');
      await tester.pump();

      expect(find.byKey(const Key('stock_menu_item-active')), findsOneWidget);
      expect(find.byKey(const Key('stock_menu_item-archived')), findsNothing);
      expect(find.text('Élément archivé'), findsNothing);

      await tester.tap(find.byKey(const Key('stock_menu_item-active')));
      await tester.pumpAndSettle();
      expect(find.text('Archiver').last, findsOneWidget);
    },
  );

  testWidgets(
    'Modifier permet de changer les propriétés du produit',
    (WidgetTester tester) async {
      final repository = _FakeStocksRepository([
        _buildProduct(
          id: 'item-1',
          name: 'Ognion',
          quantity: 1,
          unit: 'kg',
          minStock: 5,
        ),
      ]);
      addTearDown(repository.dispose);
      await _setTestViewport(tester);

      await tester.pumpWidget(_wrapWithApp(repository));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('stock_menu_item-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Modifier').last);
      await tester.pumpAndSettle();

      expect(find.text('Modifier le produit'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).at(0), 'Oignon');
      await tester.enterText(find.byType(TextFormField).at(2), '3');
      await tester.enterText(find.byType(TextFormField).at(3), '2');

      await tester.tap(find.text('Enregistrer').last);
      await tester.pumpAndSettle();

      expect(repository.itemUpdates.length, 1);
      expect(repository.itemUpdates.single.itemId, 'item-1');
      expect(repository.itemUpdates.single.name, 'Oignon');
      expect(repository.itemUpdates.single.quantity, 3);
      expect(repository.itemUpdates.single.minStock, 2);

      expect(find.text('Oignon'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('kg restants'), findsOneWidget);
    },
  );
}

Future<void> _setTestViewport(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(430, 1200));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

Widget _wrapWithApp(StocksRepositoryBase repository) {
  return MaterialApp(
    home: Scaffold(
      body: StocksScreen(
        restaurantId: 'resto-1',
        userRole: 'owner',
        repository: repository,
      ),
    ),
  );
}

StockProduct _buildProduct({
  String id = 'item-1',
  String name = 'Mozzarella',
  double quantity = 500,
  String category = 'Alimentaire',
  String unit = 'g',
  double minStock = 5,
  bool isArchived = false,
}) {
  return StockProduct(
    id: id,
    name: name,
    category: StockCategory(id: category.toLowerCase(), name: category),
    quantityRemaining: quantity,
    unit: unit,
    status: StockStatus.normal,
    isArchived: isArchived,
    minStock: minStock,
    usageToday: null,
    usageUnit: null,
    lastUpdated: DateTime(2026, 2, 26, 16, 22),
  );
}

class _FakeStocksRepository implements StocksRepositoryBase {
  _FakeStocksRepository(List<StockProduct> seedProducts)
    : _products = List<StockProduct>.from(seedProducts);

  final StreamController<List<StockProduct>> _controller =
      StreamController<List<StockProduct>>.broadcast();

  List<StockProduct> _products;
  final List<_QuantityUpdateCall> quantityUpdates = <_QuantityUpdateCall>[];
  final List<_ItemUpdateCall> itemUpdates = <_ItemUpdateCall>[];
  int archiveCalls = 0;
  int restoreCalls = 0;
  int deleteCalls = 0;

  void dispose() {
    _controller.close();
  }

  @override
  Stream<List<StockProduct>> watchStocks(String restaurantId) async* {
    yield List<StockProduct>.unmodifiable(_products);
    yield* _controller.stream;
  }

  @override
  Future<void> addStockQuantity({
    required String restaurantId,
    required String itemId,
    required double quantityToAdd,
  }) async {}

  @override
  Future<void> archiveStockItem({
    required String restaurantId,
    required String itemId,
  }) async {
    archiveCalls += 1;
    _products = _products
        .map((product) {
          if (product.id != itemId) {
            return product;
          }
          return _copyProduct(product, isArchived: true);
        })
        .toList(growable: false);
    _emit();
  }

  @override
  Future<void> createStockItem({
    required String restaurantId,
    required String name,
    required String category,
    required double initialQuantity,
    required String unit,
    required double minStock,
    String? shortDescription,
    double? purchasePrice,
    String? supplier,
    String? location,
    required bool perishable,
    DateTime? expiresAt,
  }) async {}

  @override
  Future<void> restoreStockItem({
    required String restaurantId,
    required String itemId,
  }) async {
    restoreCalls += 1;
    _products = _products
        .map((product) {
          if (product.id != itemId) {
            return product;
          }
          return _copyProduct(product, isArchived: false);
        })
        .toList(growable: false);
    _emit();
  }

  @override
  Future<void> updateStockQuantity({
    required String restaurantId,
    required String itemId,
    required double quantity,
  }) async {
    quantityUpdates.add(
      _QuantityUpdateCall(itemId: itemId, quantity: quantity),
    );
    _products = _products
        .map((product) {
          if (product.id != itemId) {
            return product;
          }
          return _copyProduct(product, quantityRemaining: quantity);
        })
        .toList(growable: false);
    _emit();
  }

  @override
  Future<void> updateStockItem({
    required String restaurantId,
    required String itemId,
    required String name,
    required double quantity,
    required String category,
    required String unit,
    required double minStock,
    String? shortDescription,
    double? purchasePrice,
    String? supplier,
    String? location,
    required bool perishable,
    DateTime? expiresAt,
  }) async {
    itemUpdates.add(
      _ItemUpdateCall(
        itemId: itemId,
        name: name,
        quantity: quantity,
        category: category,
        unit: unit,
        minStock: minStock,
      ),
    );
    _products = _products
        .map((product) {
          if (product.id != itemId) {
            return product;
          }
          return _copyProduct(
            product,
            name: name,
            category: StockCategory(id: category.toLowerCase(), name: category),
            quantityRemaining: quantity,
            unit: unit,
            minStock: minStock,
            status: _statusFor(quantity, minStock),
            description: shortDescription ?? '',
            purchasePrice: purchasePrice,
            supplier: supplier ?? '',
            location: location ?? '',
            perishable: perishable,
            expiresAt: expiresAt,
          );
        })
        .toList(growable: false);
    _emit();
  }

  @override
  Future<void> deleteStockItem({
    required String restaurantId,
    required String itemId,
  }) async {
    deleteCalls += 1;
    _products = _products
        .where((product) => product.id != itemId)
        .toList(growable: false);
    _emit();
  }

  void _emit() {
    _controller.add(List<StockProduct>.unmodifiable(_products));
  }

  StockProduct _copyProduct(
    StockProduct source, {
    String? name,
    StockCategory? category,
    double? quantityRemaining,
    String? unit,
    StockStatus? status,
    bool? isArchived,
    double? minStock,
    String? description,
    double? purchasePrice,
    String? supplier,
    String? location,
    bool? perishable,
    DateTime? expiresAt,
  }) {
    return StockProduct(
      id: source.id,
      name: name ?? source.name,
      category: category ?? source.category,
      quantityRemaining: quantityRemaining ?? source.quantityRemaining,
      unit: unit ?? source.unit,
      status: status ?? source.status,
      isArchived: isArchived ?? source.isArchived,
      minStock: minStock ?? source.minStock,
      usageToday: source.usageToday,
      usageUnit: source.usageUnit,
      description: description ?? source.description,
      purchasePrice: purchasePrice ?? source.purchasePrice,
      supplier: supplier ?? source.supplier,
      location: location ?? source.location,
      perishable: perishable ?? source.perishable,
      expiresAt: expiresAt ?? source.expiresAt,
      lastUpdated: source.lastUpdated,
    );
  }

  StockStatus _statusFor(double quantity, double minStock) {
    if (quantity <= 0) {
      return StockStatus.critical;
    }
    if (quantity <= minStock) {
      return StockStatus.low;
    }
    return StockStatus.normal;
  }
}

class _QuantityUpdateCall {
  const _QuantityUpdateCall({required this.itemId, required this.quantity});

  final String itemId;
  final double quantity;
}

class _ItemUpdateCall {
  const _ItemUpdateCall({
    required this.itemId,
    required this.name,
    required this.quantity,
    required this.category,
    required this.unit,
    required this.minStock,
  });

  final String itemId;
  final String name;
  final double quantity;
  final String category;
  final String unit;
  final double minStock;
}
