import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../auth/user_profile.dart';

class OwnerDashboardScreen extends StatelessWidget {
  const OwnerDashboardScreen({super.key, required this.profile});

  final UserProfile profile;

  static const Color _pageBackground = Color(0xFFDCE7D5);
  static const Color _topBackground = Color(0xFF1A4748);
  static const Color _surface = Color(0xFFF5F6F3);
  static const Color _sage = Color(0xFF739760);
  static const Color _ink = Color(0xFF101A2E);
  static const Color _muted = Color(0xFF4A5568);
  static const Color _tealCard = Color(0xFF21494A);
  static const Color _danger = Color(0xFFF10012);
  static const Color _warning = Color(0xFFF55700);
  static const Color _success = Color(0xFF099C3F);

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final uiScale = (media.size.width / 430).clamp(0.84, 1.0);
    double s(double value) => value * uiScale;
    final textTheme = Theme.of(context).textTheme;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: _topBackground,
        drawerScrimColor: const Color(0x7A000000),
        drawer: _OwnerSidebar(profile: profile),
        body: SafeArea(
          top: false,
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: ColoredBox(
                color: _pageBackground,
                child: Column(
                  children: [
                    _DashboardHeader(
                      profile: profile,
                      topInset: media.padding.top,
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                          s(14),
                          s(14),
                          s(14),
                          s(18) + media.padding.bottom,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Vue générale',
                              style: textTheme.headlineMedium?.copyWith(
                                color: _ink,
                                fontSize: s(34),
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: s(12)),
                            _SummaryCard(
                              title: 'VENTES DU JOUR',
                              headerColor: _sage,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    crossAxisAlignment: WrapCrossAlignment.end,
                                    spacing: 10,
                                    children: [
                                      Text(
                                        '325 000',
                                        style: textTheme.headlineSmall
                                            ?.copyWith(
                                              color: const Color(0xFF658F57),
                                              fontSize: s(42),
                                              fontWeight: FontWeight.w900,
                                            ),
                                      ),
                                      Text(
                                        'FCFA',
                                        style: textTheme.headlineSmall
                                            ?.copyWith(
                                              color: _muted,
                                              fontSize: s(21),
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: s(14)),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.trending_up,
                                        color: _success,
                                        size: s(20),
                                      ),
                                      SizedBox(width: s(6)),
                                      Text(
                                        '+15% vs hier',
                                        style: textTheme.titleMedium?.copyWith(
                                          color: _success,
                                          fontWeight: FontWeight.w800,
                                          fontSize: s(15),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: s(12)),
                            _SummaryCard(
                              title: 'TICKETS',
                              headerColor: _tealCard,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    spacing: 8,
                                    children: [
                                      Text(
                                        '78',
                                        style: textTheme.headlineSmall
                                            ?.copyWith(
                                              color: _tealCard,
                                              fontSize: s(42),
                                              fontWeight: FontWeight.w900,
                                            ),
                                      ),
                                      Text(
                                        'tickets',
                                        style: textTheme.headlineSmall
                                            ?.copyWith(
                                              color: _muted,
                                              fontSize: s(21),
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: s(12)),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.receipt_long_rounded,
                                        color: _muted,
                                        size: s(20),
                                      ),
                                      SizedBox(width: s(8)),
                                      Flexible(
                                        child: Text(
                                          'Moyenne: 4 167 FCFA/ticket',
                                          style: textTheme.titleMedium
                                              ?.copyWith(
                                                color: _muted,
                                                fontSize: s(16),
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: s(12)),
                            _SummaryCard(
                              title: 'INCIDENTS',
                              headerColor: _danger,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    spacing: 8,
                                    children: [
                                      Text(
                                        '2',
                                        style: textTheme.headlineSmall
                                            ?.copyWith(
                                              color: _danger,
                                              fontSize: s(42),
                                              fontWeight: FontWeight.w900,
                                            ),
                                      ),
                                      Text(
                                        'à valider',
                                        style: textTheme.headlineSmall
                                            ?.copyWith(
                                              color: _muted,
                                              fontSize: s(21),
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: s(12)),
                                  _ActionText(
                                    text: 'Voir les incidents',
                                    color: _danger,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: s(12)),
                            _SummaryCard(
                              title: 'STOCK BAS',
                              headerColor: _warning,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    spacing: 8,
                                    children: [
                                      Text(
                                        '5',
                                        style: textTheme.headlineSmall
                                            ?.copyWith(
                                              color: _warning,
                                              fontSize: s(42),
                                              fontWeight: FontWeight.w900,
                                            ),
                                      ),
                                      Text(
                                        'produits en alerte',
                                        style: textTheme.headlineSmall
                                            ?.copyWith(
                                              color: _muted,
                                              fontSize: s(21),
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: s(12)),
                                  _ActionText(
                                    text: 'Gérer le stock',
                                    color: _warning,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: s(14)),
                            _SummaryCard(
                              title: 'VENTES PAR HEURE',
                              headerColor: _tealCard,
                              bodyPadding: const EdgeInsets.fromLTRB(
                                8,
                                18,
                                10,
                                12,
                              ),
                              child: const SizedBox(
                                height: 300,
                                child: _SalesByHourChart(),
                              ),
                            ),
                            SizedBox(height: s(12)),
                            _SummaryCard(
                              title: 'TOP PRODUITS',
                              headerColor: _sage,
                              bodyPadding: const EdgeInsets.fromLTRB(
                                16,
                                16,
                                16,
                                18,
                              ),
                              child: Column(
                                children: const [
                                  _TopProductRow(
                                    rank: 1,
                                    name: 'Poulet braisé',
                                    details: '45 ventes • 67 500 FCFA',
                                    growth: '+12%',
                                    isHot: true,
                                  ),
                                  SizedBox(height: 12),
                                  _TopProductRow(
                                    rank: 2,
                                    name: "Burger Avo'o",
                                    details: '38 ventes • 57 000 FCFA',
                                    growth: '+8%',
                                  ),
                                  SizedBox(height: 12),
                                  _TopProductRow(
                                    rank: 3,
                                    name: 'Salade César',
                                    details: '22 ventes • 33 000 FCFA',
                                    growth: '+5%',
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: s(12)),
                            SizedBox(
                              width: double.infinity,
                              height: s(50),
                              child: FilledButton(
                                onPressed: () {},
                                style: FilledButton.styleFrom(
                                  backgroundColor: _sage,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Text(
                                  'Voir tous les produits  ›',
                                  style: textTheme.titleLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: s(15),
                                  ),
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
          ),
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.profile, required this.topInset});

  final UserProfile profile;
  final double topInset;

  static const Color _header = Color(0xFF1A4748);
  static const Color _chip = Color(0xFF7AA265);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(12, topInset + 8, 12, 14),
      decoration: const BoxDecoration(color: _header),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Builder(
            builder: (buttonContext) => IconButton(
              onPressed: () => Scaffold.of(buttonContext).openDrawer(),
              icon: const Icon(Icons.menu_rounded),
              iconSize: 24,
              color: Colors.white,
              tooltip: 'Menu',
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dashboard',
                  style: textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontSize: 40 * 0.75,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                _OwnerSubtitle(profile: profile),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _chip,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "Aujourd'hui",
              style: textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontSize: 16 * 0.75,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OwnerSubtitle extends StatelessWidget {
  const _OwnerSubtitle({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      color: const Color(0xFFCAD5D2),
      fontWeight: FontWeight.w700,
      fontSize: 14,
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
        final subtitle = restaurantName.isEmpty
            ? profile.name
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

class _OwnerSidebar extends StatelessWidget {
  const _OwnerSidebar({required this.profile});

  final UserProfile profile;

  static const Color _drawerBackground = Color(0xFF1A4748);
  static const Color _activeItem = Color(0xFF739760);
  static const Color _inactiveText = Color(0xFFBFCDCA);

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final width = math.min(media.size.width * 0.82, 350.0);
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          width: width,
          margin: const EdgeInsets.fromLTRB(10, 8, 16, 8),
          decoration: BoxDecoration(
            color: _drawerBackground,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
                child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
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
                    final logoUrl = _readString(data, const [
                      'logo_url',
                      'logoUrl',
                      'logo',
                      'image',
                    ]);
                    final title = restaurantName.isEmpty
                        ? 'Restaurant'
                        : restaurantName;

                    return Row(
                      children: [
                        _RestaurantLogo(logoUrl: logoUrl),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 26,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const Divider(color: Color(0x2CFFFFFF), height: 1),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                  children: [
                    _SidebarMenuTile(
                      label: 'Dashboard',
                      icon: Icons.bar_chart_rounded,
                      active: true,
                      activeColor: _activeItem,
                      textColor: _inactiveText,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(height: 8),
                    _SidebarMenuTile(
                      label: 'Commandes',
                      icon: Icons.shopping_cart_outlined,
                      activeColor: _activeItem,
                      textColor: _inactiveText,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    _SidebarMenuTile(
                      label: 'Menus',
                      icon: Icons.restaurant_menu_rounded,
                      activeColor: _activeItem,
                      textColor: _inactiveText,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    _SidebarMenuTile(
                      label: 'Stocks',
                      icon: Icons.inventory_2_outlined,
                      activeColor: _activeItem,
                      textColor: _inactiveText,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    _SidebarMenuTile(
                      label: 'Incidents',
                      icon: Icons.warning_amber_rounded,
                      activeColor: _activeItem,
                      textColor: _inactiveText,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    _SidebarMenuTile(
                      label: 'Comptabilité',
                      icon: Icons.description_outlined,
                      activeColor: _activeItem,
                      textColor: _inactiveText,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    _SidebarMenuTile(
                      label: 'Rapports',
                      icon: Icons.query_stats_rounded,
                      activeColor: _activeItem,
                      textColor: _inactiveText,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    _SidebarMenuTile(
                      label: 'Utilisateurs',
                      icon: Icons.groups_rounded,
                      activeColor: _activeItem,
                      textColor: _inactiveText,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    _SidebarMenuTile(
                      label: 'Paramètres',
                      icon: Icons.settings_outlined,
                      activeColor: _activeItem,
                      textColor: _inactiveText,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(color: Color(0x2CFFFFFF), height: 1),
              _SidebarMenuTile(
                label: 'Déconnexion',
                icon: Icons.logout_rounded,
                activeColor: _activeItem,
                textColor: _inactiveText,
                onTap: () async {
                  Navigator.of(context).pop();
                  await FirebaseAuth.instance.signOut();
                },
              ),
              SizedBox(height: media.padding.bottom > 0 ? 6 : 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _RestaurantLogo extends StatelessWidget {
  const _RestaurantLogo({required this.logoUrl});

  final String logoUrl;

  @override
  Widget build(BuildContext context) {
    final hasLogo = logoUrl.trim().isNotEmpty;
    final radius = BorderRadius.circular(14);

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFF0F3233),
        borderRadius: radius,
      ),
      clipBehavior: Clip.antiAlias,
      child: hasLogo
          ? Image.network(
              logoUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return const Icon(
                  Icons.storefront_rounded,
                  color: Color(0xFFC4D3D0),
                  size: 26,
                );
              },
            )
          : const Icon(
              Icons.storefront_rounded,
              color: Color(0xFFC4D3D0),
              size: 26,
            ),
    );
  }
}

class _SidebarMenuTile extends StatelessWidget {
  const _SidebarMenuTile({
    required this.label,
    required this.icon,
    required this.activeColor,
    required this.textColor,
    required this.onTap,
    this.active = false,
  });

  final String label;
  final IconData icon;
  final Color activeColor;
  final Color textColor;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: active ? activeColor : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        dense: true,
        visualDensity: const VisualDensity(horizontal: -1, vertical: -1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Icon(icon, color: active ? Colors.white : textColor, size: 24),
        title: Text(
          label,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: active ? Colors.white : textColor,
            fontSize: 22,
            fontWeight: active ? FontWeight.w800 : FontWeight.w700,
          ),
        ),
        onTap: onTap,
      ),
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
        color: OwnerDashboardScreen._surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 5),
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
                  fontSize: 14,
                  letterSpacing: 0.6,
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
    required this.growth,
    this.isHot = false,
  });

  final int rank;
  final String name;
  final String details;
  final String growth;
  final bool isHot;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

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
              color: OwnerDashboardScreen._sage,
              borderRadius: BorderRadius.circular(18),
            ),
            alignment: Alignment.center,
            child: Text(
              '$rank',
              style: textTheme.headlineSmall?.copyWith(
                color: Colors.white,
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
              color: const Color(0xFFCBE9D1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '↗ $growth',
              style: textTheme.titleMedium?.copyWith(
                color: const Color(0xFF008639),
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

class _SalesByHourChart extends StatelessWidget {
  const _SalesByHourChart();

  @override
  Widget build(BuildContext context) {
    const labels = [
      '8h',
      '9h',
      '10h',
      '11h',
      '12h',
      '13h',
      '14h',
      '15h',
      '17h',
    ];
    const values = [15.0, 25.0, 18.0, 35.0, 52.0, 48.0, 38.0, 22.0, 44.0];

    return CustomPaint(
      painter: _SalesChartPainter(values: values, labels: labels),
      size: Size.infinite,
    );
  }
}

class _SalesChartPainter extends CustomPainter {
  const _SalesChartPainter({required this.values, required this.labels});

  final List<double> values;
  final List<String> labels;

  static const Color _axisColor = Color(0xFF6B7282);
  static const Color _gridColor = Color(0xFFD4D8D5);
  static const Color _lineColor = Color(0xFF6C945F);

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty || labels.isEmpty || values.length != labels.length) {
      return;
    }

    const maxY = 60.0;
    const yTicks = [0.0, 15.0, 30.0, 45.0, 60.0];
    const leftPadding = 50.0;
    const rightPadding = 14.0;
    const topPadding = 16.0;
    const bottomPadding = 46.0;

    final chartRect = Rect.fromLTRB(
      leftPadding,
      topPadding,
      size.width - rightPadding,
      size.height - bottomPadding,
    );

    final gridPaint = Paint()
      ..color = _gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final axisPaint = Paint()
      ..color = _axisColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final linePaint = Paint()
      ..color = _lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (final tick in yTicks) {
      final y = chartRect.bottom - (tick / maxY) * chartRect.height;
      if (tick > 0) {
        _drawDashedLine(
          canvas,
          Offset(chartRect.left, y),
          Offset(chartRect.right, y),
          gridPaint,
        );
      }
      _drawText(
        canvas,
        '${tick.toInt()}k',
        Offset(4, y - 12),
        const TextStyle(
          color: _axisColor,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      );
    }

    final xStep = labels.length == 1
        ? 0.0
        : chartRect.width / (labels.length - 1);

    for (var i = 0; i < labels.length; i++) {
      final x = chartRect.left + (xStep * i);
      if (i > 0) {
        _drawDashedLine(
          canvas,
          Offset(x, chartRect.top),
          Offset(x, chartRect.bottom),
          gridPaint,
        );
      }
      _drawText(
        canvas,
        labels[i],
        Offset(x - 12, chartRect.bottom + 8),
        const TextStyle(
          color: _axisColor,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      );
    }

    canvas.drawLine(
      Offset(chartRect.left, chartRect.top),
      Offset(chartRect.left, chartRect.bottom),
      axisPaint,
    );
    canvas.drawLine(
      Offset(chartRect.left, chartRect.bottom),
      Offset(chartRect.right, chartRect.bottom),
      axisPaint,
    );

    final points = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final x = chartRect.left + (xStep * i);
      final y = chartRect.bottom - (values[i] / maxY) * chartRect.height;
      points.add(Offset(x, y));
    }

    if (points.length >= 2) {
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (var i = 0; i < points.length - 1; i++) {
        final current = points[i];
        final next = points[i + 1];
        final controlX = (current.dx + next.dx) / 2;
        path.cubicTo(controlX, current.dy, controlX, next.dy, next.dx, next.dy);
      }
      canvas.drawPath(path, linePaint);
    }

    final pointPaint = Paint()
      ..color = _lineColor
      ..style = PaintingStyle.fill;
    for (final point in points) {
      canvas.drawCircle(point, 7.5, pointPaint);
    }
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashLength = 6.0;
    const dashSpace = 6.0;

    final totalDistance = (end - start).distance;
    if (totalDistance <= 0) {
      return;
    }
    final direction = (end - start) / totalDistance;
    var distance = 0.0;

    while (distance < totalDistance) {
      final segmentStart = start + (direction * distance);
      final segmentEnd =
          start + (direction * math.min(distance + dashLength, totalDistance));
      canvas.drawLine(segmentStart, segmentEnd, paint);
      distance += dashLength + dashSpace;
    }
  }

  void _drawText(Canvas canvas, String value, Offset offset, TextStyle style) {
    final textPainter = TextPainter(
      text: TextSpan(text: value, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _SalesChartPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.labels != labels;
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
