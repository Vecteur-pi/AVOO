class RestaurantInfo {
  const RestaurantInfo({
    required this.name,
    required this.address,
    required this.phone,
    this.tablesCount,
    required this.configureTablesLater,
    this.logoUrl,
    this.logoPendingUpload = false,
    this.schedule,
  });

  final String name;
  final String address;
  final String phone;
  final int? tablesCount;
  final bool configureTablesLater;
  final String? logoUrl;
  final bool logoPendingUpload;
  final String? schedule;

  Map<String, dynamic> toJson() => {
    'name': name,
    'address': address,
    'phone': phone,
    'tablesCount': tablesCount,
    'configureTablesLater': configureTablesLater,
    'logoUrl': logoUrl,
    'logoPendingUpload': logoPendingUpload,
    'schedule': schedule,
  };
}
