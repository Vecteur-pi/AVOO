import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../auth/user_profile.dart';
import '../incidents/ui/incidents_screen.dart';
import '../menu/ui/menu_screen.dart';
import '../orders/ui/orders_screen.dart';
import '../staff/ui/staff_team_screen.dart';
import '../stocks/ui/stocks_screen.dart';
import '../theme/avoo_theme.dart';
import 'owner_dashboard_repository.dart';
import 'sales_by_hour_chart.dart';

bool _isManagerRole(String role) {
  final normalized = role.toLowerCase().trim();
  return normalized == 'manager' ||
      normalized == 'gerant' ||
      normalized == 'gérant';
}

String _dashboardFilterLabel(DashboardTimeFilter filter) {
  switch (filter) {
    case DashboardTimeFilter.today:
      return "Aujourd'hui";
    case DashboardTimeFilter.yesterday:
      return 'Hier';
    case DashboardTimeFilter.last7Days:
      return '7 jours';
    case DashboardTimeFilter.allTime:
      return 'Tout';
  }
}

DateTime? _chartDateFromFilter(DashboardTimeFilter filter) {
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  switch (filter) {
    case DashboardTimeFilter.today:
      return todayStart;
    case DashboardTimeFilter.yesterday:
      return todayStart.subtract(const Duration(days: 1));
    case DashboardTimeFilter.last7Days:
    case DashboardTimeFilter.allTime:
      return null;
  }
}

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key, required this.profile});

  final UserProfile profile;

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  final OwnerDashboardRepository _repository = OwnerDashboardRepository();
  int _selectedIndex = 0;
  final Set<int> _visitedTabs = <int>{0};
  late Stream<OwnerDashboardData> _dashboardStream;
  DashboardTimeFilter _selectedFilter = DashboardTimeFilter.today;

  void _refreshDashboardStream() {
    _dashboardStream = _repository
        .watch(widget.profile.restaurantId, filter: _selectedFilter)
        .asBroadcastStream();
  }

  void _onFilterSelected(DashboardTimeFilter filter) {
    if (filter == _selectedFilter) {
      return;
    }
    setState(() {
      _selectedFilter = filter;
      _refreshDashboardStream();
    });
  }

  @override
  void initState() {
    super.initState();
    _refreshDashboardStream();
  }

  @override
  void didUpdateWidget(covariant OwnerDashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile.restaurantId != widget.profile.restaurantId) {
      _refreshDashboardStream();
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final media = MediaQuery.of(context);
    final uiScale = (media.size.width / 430).clamp(0.84, 1.0);
    double s(double value) => value * uiScale;

    final tabs = <Widget>[
      Column(
        children: [
          _TopAppBar(profile: profile, topInset: media.padding.top),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(s(16), s(24), s(16), s(24)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _DashboardTitleRow(
                    uiScale: uiScale,
                    selectedFilter: _selectedFilter,
                    onFilterSelected: _onFilterSelected,
                  ),
                  SizedBox(height: s(24)),
                  StreamBuilder<OwnerDashboardData>(
                    stream: _dashboardStream,
                    builder: (context, snapshot) {
                      final data = snapshot.data ?? OwnerDashboardData.empty();
                      return _DashboardContent(
                        data: data,
                        uiScale: uiScale,
                        restaurantId: profile.restaurantId,
                        selectedFilter: _selectedFilter,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      Column(
        children: [
          _TopAppBar(profile: profile, topInset: media.padding.top),
          Expanded(child: OrdersScreen(restaurantId: profile.restaurantId)),
        ],
      ),
      Column(
        children: [
          _TopAppBar(profile: profile, topInset: media.padding.top),
          Expanded(child: MenuScreen(restaurantId: profile.restaurantId)),
        ],
      ),
      Column(
        children: [
          _TopAppBar(profile: profile, topInset: media.padding.top),
          Expanded(child: StocksScreen(restaurantId: profile.restaurantId)),
        ],
      ),
      Column(
        children: [
          _TopAppBar(profile: profile, topInset: media.padding.top),
          const Expanded(child: Center(child: Text('Coming Soon'))),
        ],
      ),
    ];

    final body = IndexedStack(
      index: _selectedIndex,
      children: List<Widget>.generate(tabs.length, (index) {
        if (_visitedTabs.contains(index)) {
          return tabs[index];
        }
        return const SizedBox.shrink();
      }),
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AvooColors.background,
        body: body,
        extendBody: true,
        bottomNavigationBar: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: NavigationBarTheme(
            data: NavigationBarThemeData(
              indicatorShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              labelTextStyle: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  );
                }
                return const TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                );
              }),
              iconTheme: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return const IconThemeData(color: Colors.white);
                }
                return const IconThemeData(color: Color(0xFF9CA3AF));
              }),
            ),
            child: NavigationBar(
              height: 75,
              backgroundColor: AvooColors.navy,
              indicatorColor: AvooColors.green,
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _selectedIndex = index;
                  _visitedTabs.add(index);
                });
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: 'Dashboard',
                ),
                NavigationDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  selectedIcon: Icon(Icons.receipt_long_rounded),
                  label: 'Commandes',
                ),
                NavigationDestination(
                  icon: Icon(Icons.restaurant_menu_outlined),
                  selectedIcon: Icon(Icons.restaurant_menu_rounded),
                  label: 'Menu',
                ),
                NavigationDestination(
                  icon: Icon(Icons.inventory_2_outlined),
                  selectedIcon: Icon(Icons.inventory_2_rounded),
                  label: 'Stocks',
                ),
                NavigationDestination(
                  icon: Icon(Icons.bar_chart_outlined),
                  selectedIcon: Icon(Icons.bar_chart_rounded),
                  label: 'Rapports',
                ),
              ],
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            ),
          ),
        ),
      ),
    );
  }
}

class _TopAppBar extends StatelessWidget {
  const _TopAppBar({required this.profile, required this.topInset});

  final UserProfile profile;
  final double topInset;

  Future<void> _handleProfileMenuAction(
    BuildContext context,
    String value,
  ) async {
    if (value == 'team') {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => StaffTeamScreen(profile: profile)),
      );
      return;
    }

    if (value == 'settings' || value == 'accounting') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fonctionnalité bientôt disponible.')),
      );
      return;
    }

    if (value == 'logout') {
      try {
        await FirebaseAuth.instance.signOut();
      } catch (_) {
        if (!context.mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Déconnexion impossible. Réessayez.')),
        );
      }
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final canAccessAccounting = !_isManagerRole(profile.role);
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AvooColors.navy, // Dark Blue background
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      padding: EdgeInsets.fromLTRB(16, topInset + 12, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Logo Area in Pink
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFFFD1DC), // Light Pink
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: const Text(
              '🥑', // Avocado placeholder emoji
              style: TextStyle(fontSize: 28),
            ),
          ),
          const SizedBox(width: 12),
          // App Name and Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Avo'o",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    fontFamily: 'Serif',
                  ),
                ),
                Flexible(child: _OwnerSubtitle(profile: profile)),
              ],
            ),
          ),
          // Notification Bell
          Stack(
            children: [
              const Icon(
                Icons.notifications_outlined,
                color: Colors.white,
                size: 26,
              ),
              Positioned(
                top: 2,
                right: 2,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AvooColors.error, // Red notification dot
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          // User Avatar
          Theme(
            data: Theme.of(context).copyWith(
              dividerTheme: const DividerThemeData(
                color: Color(0xFFF3F4F6),
                thickness: 1,
                space: 1,
              ),
              popupMenuTheme: PopupMenuThemeData(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: Colors.white,
                surfaceTintColor: Colors.white,
                elevation: 4,
                textStyle: const TextStyle(
                  color: Color(0xFF111827),
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
            child: PopupMenuButton<String>(
              offset: const Offset(0, 50),
              tooltip: 'Menu profil',
              onSelected: (value) async {
                await _handleProfileMenuAction(context, value);
              },
              itemBuilder: (context) => [
                // User Info Header
                PopupMenuItem<String>(
                  enabled: false,
                  height: 80,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        profile.name,
                        style: const TextStyle(
                          color: Color(0xFF111827),
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        profile.email ?? '',
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(height: 1),
                // Settings
                const PopupMenuItem<String>(
                  value: 'settings',
                  height: 48,
                  child: Row(
                    children: [
                      Icon(
                        Icons.settings_outlined,
                        color: Color(0xFF4B5563),
                        size: 20,
                      ),
                      SizedBox(width: 12),
                      Text('Paramètres'),
                    ],
                  ),
                ),
                // Accounting
                if (canAccessAccounting)
                  const PopupMenuItem<String>(
                    value: 'accounting',
                    height: 48,
                    child: Row(
                      children: [
                        Icon(
                          Icons.calculate_outlined,
                          color: Color(0xFF4B5563),
                          size: 20,
                        ),
                        SizedBox(width: 12),
                        Text('Comptabilité'),
                      ],
                    ),
                  ),
                const PopupMenuItem<String>(
                  value: 'team',
                  height: 48,
                  child: Row(
                    children: [
                      Icon(
                        Icons.groups_2_outlined,
                        color: Color(0xFF4B5563),
                        size: 20,
                      ),
                      SizedBox(width: 12),
                      Text('Staff / Équipe'),
                    ],
                  ),
                ),
                const PopupMenuDivider(height: 1),
                const PopupMenuItem<String>(
                  value: 'logout',
                  height: 48,
                  child: Row(
                    children: [
                      Icon(
                        Icons.logout_rounded,
                        color: Color(0xFFB42318),
                        size: 20,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Déconnexion',
                        style: TextStyle(color: Color(0xFFB42318)),
                      ),
                    ],
                  ),
                ),
              ],
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  shape: BoxShape.circle,
                  border: Border.all(color: AvooColors.green, width: 2.0),
                ),
                clipBehavior: Clip.antiAlias,
                alignment: Alignment.center,
                child: profile.photoUrl != null
                    ? Image.network(
                        profile.photoUrl!,
                        fit: BoxFit.cover,
                        width: 40,
                        height: 40,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.person,
                          color: Color(0xFF9CA3AF),
                          size: 24,
                        ),
                      )
                    : const Icon(
                        Icons.person,
                        color: Color(0xFF9CA3AF),
                        size: 24,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardTitleRow extends StatelessWidget {
  const _DashboardTitleRow({
    required this.uiScale,
    required this.selectedFilter,
    required this.onFilterSelected,
  });

  final double uiScale;
  final DashboardTimeFilter selectedFilter;
  final ValueChanged<DashboardTimeFilter> onFilterSelected;

  @override
  Widget build(BuildContext context) {
    double s(double value) => value * uiScale;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Dashboard',
          style: textTheme.headlineMedium?.copyWith(
            color: const Color(0xFF111827),
            fontSize: s(36),
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            fontFamily: 'Serif',
          ),
        ),
        PopupMenuButton<DashboardTimeFilter>(
          padding: EdgeInsets.zero,
          onSelected: onFilterSelected,
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: DashboardTimeFilter.today,
              child: Text("Aujourd'hui"),
            ),
            PopupMenuItem(
              value: DashboardTimeFilter.yesterday,
              child: Text('Hier'),
            ),
            PopupMenuItem(
              value: DashboardTimeFilter.last7Days,
              child: Text('7 jours'),
            ),
            PopupMenuItem(
              value: DashboardTimeFilter.allTime,
              child: Text('Tout'),
            ),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _dashboardFilterLabel(selectedFilter),
                  style: textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF374151),
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: Color(0xFF6B7280),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.data,
    required this.uiScale,
    required this.restaurantId,
    required this.selectedFilter,
  });

  final OwnerDashboardData data;
  final double uiScale;
  final String restaurantId;
  final DashboardTimeFilter selectedFilter;

  @override
  Widget build(BuildContext context) {
    double s(double value) => value * uiScale;
    final textTheme = Theme.of(context).textTheme;
    final chartDate = _chartDateFromFilter(selectedFilter);
    final salesCardTitle = switch (selectedFilter) {
      DashboardTimeFilter.today => 'VENTES DU JOUR',
      DashboardTimeFilter.yesterday => "VENTES D'HIER",
      DashboardTimeFilter.last7Days => 'VENTES (7 JOURS)',
      DashboardTimeFilter.allTime => 'VENTES (TOUT)',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = (constraints.maxWidth - s(16)) / 2;
            return Wrap(
              spacing: s(16),
              runSpacing: s(16),
              children: [
                SizedBox(
                  width: cardWidth,
                  child: _SummaryCard(
                    title: salesCardTitle,
                    headerColor: AvooColors.green,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: _formatInt(data.dailySales.round()),
                                style: textTheme.headlineSmall?.copyWith(
                                  color: AvooColors.green,
                                  fontSize: s(28),
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              TextSpan(
                                text: ' FCFA',
                                style: textTheme.bodySmall?.copyWith(
                                  color: const Color(0xFF9CA3AF),
                                  fontSize: s(13),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: _SummaryCard(
                    title: 'TICKETS',
                    headerColor: AvooColors.navy,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: _formatInt(data.dailyTickets),
                                style: textTheme.headlineSmall?.copyWith(
                                  color: AvooColors.navy,
                                  fontSize: s(28),
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              TextSpan(
                                text: ' tickets',
                                style: textTheme.bodySmall?.copyWith(
                                  color: const Color(0xFF9CA3AF),
                                  fontSize: s(13),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              IncidentsScreen(restaurantId: restaurantId),
                        ),
                      );
                    },
                    child: _SummaryCard(
                      title: 'INCIDENTS',
                      headerColor: AvooColors.navy,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: _formatInt(data.pendingIncidents),
                                  style: textTheme.headlineSmall?.copyWith(
                                    color: AvooColors.navy,
                                    fontSize: s(28),
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                TextSpan(
                                  text: ' à valider',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: const Color(0xFF9CA3AF),
                                    fontSize: s(13),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: _SummaryCard(
                    title: 'ALERTES STOCK',
                    headerColor: AvooColors.warning,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: _formatInt(data.lowStockProducts),
                                style: textTheme.headlineSmall?.copyWith(
                                  color: AvooColors.warning,
                                  fontSize: s(28),
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              TextSpan(
                                text: ' produits',
                                style: textTheme.bodySmall?.copyWith(
                                  color: const Color(0xFF9CA3AF),
                                  fontSize: s(13),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        SizedBox(height: s(24)),
        Container(
          padding: EdgeInsets.all(s(20)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ventes par heure',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: s(18),
                  color: const Color(0xFF111827),
                ),
              ),
              SizedBox(height: s(24)),
              SizedBox(
                height: 240,
                child: SalesByHourChart(
                  fallbackHourlySales: data.hourlySales,
                  date: chartDate,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: s(24)),
      ],
    );
  }

  String _formatInt(int value) {
    final absolute = value.abs().toString();
    final groups = <String>[];
    for (var i = absolute.length; i > 0; i -= 3) {
      final start = math.max(0, i - 3);
      groups.insert(0, absolute.substring(start, i));
    }
    final grouped = groups.join(' ');
    return value < 0 ? '-$grouped' : grouped;
  }

  Widget _buildTopProducts({
    required BuildContext context,
    required List<TopProductData> products,
  }) {
    if (products.isEmpty) {
      return Text(
        'Aucune vente produit pour aujourd’hui.',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: AvooColors.muted,
          fontWeight: FontWeight.w700,
        ),
      );
    }

    return Column(
      children: [
        for (var index = 0; index < products.length; index++) ...[
          _TopProductRow(
            rank: index + 1,
            name: products[index].name,
            details:
                '${_formatInt(products[index].quantity)} ventes • ${_formatInt(products[index].revenue.round())} FCFA',
            growthPercent: products[index].growthPercent,
            isHot: index == 0,
          ),
          if (index < products.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }

  String _formatSignedPercent(double value) {
    final decimals = value.abs() >= 10 ? 0 : 1;
    var formatted = value.toStringAsFixed(decimals);
    if (formatted.endsWith('.0')) {
      formatted = formatted.substring(0, formatted.length - 2);
    }
    if (formatted == '-0') {
      formatted = '0';
    }
    if (value > 0 && !formatted.startsWith('+')) {
      formatted = '+$formatted';
    }
    return '$formatted%';
  }
}

class _OwnerSubtitle extends StatelessWidget {
  const _OwnerSubtitle({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: const Color(0xFFD1D5DB), // Light grey for dark background
      fontWeight: FontWeight.w500,
      fontSize: 13,
    );

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('restaurants')
          .doc(profile.restaurantId)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        final restaurantName = _readString(data, const [
          'name',
          'restaurant_name',
          'restaurantName',
          'title',
        ]);

        // Combine user name and restaurant name if needed, or just restaurant
        // The header already shows "Avo'o", this subtitle usually shows "User — Restaurant"
        final subtitle = restaurantName.isEmpty
            ? '${profile.name}'
            : '${profile.name} — $restaurantName';

        return Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textStyle,
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.headerColor,
    required this.child,
    this.bodyPadding = const EdgeInsets.fromLTRB(16, 16, 16, 16),
  });

  final String title;
  final Color headerColor;
  final Widget child;
  final EdgeInsets bodyPadding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              color: headerColor,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 12.5,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            Padding(padding: bodyPadding, child: child),
          ],
        ),
      ),
    );
  }
}

class _ActionText extends StatelessWidget {
  const _ActionText({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          text,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: color,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 6),
        Icon(Icons.chevron_right_rounded, color: color, size: 20),
      ],
    );
  }
}

class _TopProductRow extends StatelessWidget {
  const _TopProductRow({
    required this.rank,
    required this.name,
    required this.details,
    required this.growthPercent,
    this.isHot = false,
  });

  final int rank;
  final String name;
  final String details;
  final double growthPercent;
  final bool isHot;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isPositive = growthPercent >= 0;
    final growthColor = isPositive ? AvooColors.success : AvooColors.error;
    final growthBackground = isPositive
        ? const Color(0xFFCBE9D1)
        : const Color(0xFFF7D7D2);
    final growthArrow = isPositive ? '↗' : '↘';
    final decimals = growthPercent.abs() >= 10 ? 0 : 1;
    var growthText = growthPercent.toStringAsFixed(decimals);
    if (growthText.endsWith('.0')) {
      growthText = growthText.substring(0, growthText.length - 2);
    }
    if (growthText == '-0') {
      growthText = '0';
    }
    if (isPositive && !growthText.startsWith('+')) {
      growthText = '+$growthText';
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE7EAE4),
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: AvooColors.brandLight,
              borderRadius: BorderRadius.circular(18),
            ),
            alignment: Alignment.center,
            child: Text(
              '$rank',
              style: textTheme.headlineSmall?.copyWith(
                color: AvooColors.green,
                fontWeight: FontWeight.w900,
                fontSize: 30,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  children: [
                    Text(
                      name,
                      style: textTheme.titleLarge?.copyWith(
                        color: const Color(0xFF152038),
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    if (isHot)
                      const Icon(
                        Icons.local_fire_department_rounded,
                        color: Color(0xFFFF6A00),
                        size: 22,
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  details,
                  style: textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF495568),
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: growthBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '$growthArrow $growthText%',
              style: textTheme.titleMedium?.copyWith(
                color: growthColor,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _readString(Map<String, dynamic>? data, List<String> keys) {
  if (data == null) return '';
  for (final key in keys) {
    final value = data[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
  }
  return '';
}
