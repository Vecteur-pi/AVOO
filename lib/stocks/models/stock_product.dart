class StockCategory {
  final String id;
  final String name;

  const StockCategory({required this.id, required this.name});
}

enum StockStatus {
  normal,
  low,
  critical,
}

class StockProduct {
  final String id;
  final String name;
  final StockCategory category;
  final double quantityRemaining;
  final String unit;
  final StockStatus status;
  
  // Usage indicator
  final double? usageToday;
  final String? usageUnit;
  
  // Timestamp
  final DateTime lastUpdated;

  const StockProduct({
    required this.id,
    required this.name,
    required this.category,
    required this.quantityRemaining,
    required this.unit,
    required this.status,
    this.usageToday,
    this.usageUnit,
    required this.lastUpdated,
  });
}
