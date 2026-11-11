import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'risk_alerts_screen.dart';

class MotorwayNetworkScreen extends StatefulWidget {
  const MotorwayNetworkScreen({super.key});

  @override
  State<MotorwayNetworkScreen> createState() => _MotorwayNetworkScreenState();
}

class _MotorwayNetworkScreenState extends State<MotorwayNetworkScreen>
    with TickerProviderStateMixin {
  // ============================================================
  // THEME
  // ============================================================

  static const Color navy = Color(0xFF061321);
  static const Color navy2 = Color(0xFF091A2B);
  static const Color panel = Color(0xFF0D2236);
  static const Color panel2 = Color(0xFF102B43);

  static const Color cyan = Color(0xFF20D9FF);
  static const Color cyan2 = Color(0xFF67E8F9);
  static const Color purple = Color(0xFF9B7CFF);
  static const Color teal = Color(0xFF14B8A6);

  static const Color white = Color(0xFFF4F8FC);
  static const Color muted = Color(0xFF9EB1C5);
  static const Color muted2 = Color(0xFF6F879D);
  static const Color border = Color(0xFF1B3B55);

  static const Color safe = Color(0xFF22C55E);
  static const Color low = Color(0xFF84CC16);
  static const Color moderate = Color(0xFFF59E0B);
  static const Color high = Color(0xFFF97316);
  static const Color critical = Color(0xFFEF4444);

  // ============================================================
  // STATE
  // ============================================================

  List<Map<String, dynamic>> locations = [];
  bool loading = true;
  String selectedRoute = 'ALL';
  String searchQuery = '';

  late AnimationController _pageController;
  late AnimationController _pulseController;
  late AnimationController _networkController;

  double get pulse => _pulseController.value;

  @override
  void initState() {
    super.initState();

    _pageController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _networkController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();

    _loadData();

    Timer(const Duration(milliseconds: 150), () {
      if (mounted) {
        _pageController.forward();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _pulseController.dispose();
    _networkController.dispose();
    super.dispose();
  }

  // ============================================================
  // DATA
  // ============================================================

  Future<void> _loadData() async {
    try {
      final raw = await rootBundle.loadString(
        'assets/data/latest_risk.json',
      );

      final decoded = jsonDecode(raw);

      if (decoded is List) {
        final parsed = decoded
            .whereType<Map>()
            .map(
              (item) => Map<String, dynamic>.from(item),
            )
            .toList();

        if (mounted) {
          setState(() {
            locations = parsed;
            loading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            loading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  // ============================================================
  // ROUTE HELPERS
  // ============================================================

  String routeForCity(String city) {
    switch (city.toLowerCase()) {
      case 'lahore':
        return 'M-2';
      case 'islamabad':
        return 'M-2';
      case 'faisalabad':
        return 'M-3';
      case 'multan':
        return 'M-4';
      default:
        return 'N/A';
    }
  }

  Color riskColor(String risk) {
    switch (risk.toUpperCase()) {
      case 'SAFE':
        return safe;
      case 'LOW':
        return low;
      case 'MODERATE':
        return moderate;
      case 'HIGH':
        return high;
      case 'CRITICAL':
        return critical;
      default:
        return muted;
    }
  }

  IconData riskIcon(String risk) {
    switch (risk.toUpperCase()) {
      case 'SAFE':
        return Icons.check_circle_rounded;
      case 'LOW':
        return Icons.shield_outlined;
      case 'MODERATE':
        return Icons.warning_amber_rounded;
      case 'HIGH':
        return Icons.warning_rounded;
      case 'CRITICAL':
        return Icons.dangerous_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  List<Map<String, dynamic>> get filteredLocations {
    return locations.where((item) {
      final city = '${item['city'] ?? ''}'.toLowerCase();
      final route = routeForCity(city);

      final routeMatch =
          selectedRoute == 'ALL' || route == selectedRoute;

      final searchMatch =
          searchQuery.isEmpty ||
          city.contains(searchQuery.toLowerCase()) ||
          route.toLowerCase().contains(searchQuery.toLowerCase());

      return routeMatch && searchMatch;
    }).toList();
  }

  Map<String, dynamic>? get highestRiskLocation {
    if (locations.isEmpty) return null;

    int score(String risk) {
      switch (risk.toUpperCase()) {
        case 'CRITICAL':
          return 5;
        case 'HIGH':
          return 4;
        case 'MODERATE':
          return 3;
        case 'LOW':
          return 2;
        case 'SAFE':
          return 1;
        default:
          return 0;
      }
    }

    final list = [...locations];

    list.sort(
      (a, b) => score(
        '${b['risk_level'] ?? ''}',
      ).compareTo(
        score('${a['risk_level'] ?? ''}'),
      ),
    );

    return list.first;
  }

  double visibilityValue(Map<String, dynamic> item) {
    final value = item['visibility_km'];

    if (value is num) return value.toDouble();

    return double.tryParse('$value') ?? 0;
  }

  double get averageVisibility {
    if (locations.isEmpty) return 0;

    double total = 0;

    for (final item in locations) {
      total += visibilityValue(item);
    }

    return total / locations.length;
  }

  int riskCount(String risk) {
    return locations.where(
      (item) =>
          '${item['risk_level'] ?? ''}'.toUpperCase() ==
          risk.toUpperCase(),
    ).length;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: navy,
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _NetworkBackgroundPainter(
                animation: _networkController,
              ),
            ),
          ),

          SafeArea(
            child: loading
                ? _buildLoading()
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final desktop = constraints.maxWidth >= 950;

                      if (desktop) {
                        return _buildDesktop();
                      }

                      return _buildMobile();
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LOADING
  // ============================================================

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 55,
            height: 55,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: cyan,
              backgroundColor: border,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Loading Motorway Network',
            style: TextStyle(
              color: white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Reading latest risk information...',
            style: TextStyle(
              color: muted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DESKTOP
  // ============================================================

  Widget _buildDesktop() {
    // Motorway Network is a secondary screen, so it opens
    // without the main dashboard sidebar and uses the full width.
    return _buildMainContent();
  }

  // ============================================================
  // SIDEBAR
  // ============================================================

  Widget _buildSidebar() {
    return Container(
      width: 235,
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: navy2.withAlpha(245),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(60),
            blurRadius: 25,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 39,
                height: 39,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [cyan, teal],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: cyan.withAlpha(60),
                      blurRadius: 15,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.route_rounded,
                  color: navy,
                  size: 21,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'SMOG RISK\nSYSTEM',
                  style: TextStyle(
                    color: white,
                    fontSize: 11,
                    height: 1.15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .6,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),

          _sideItem(
            Icons.dashboard_rounded,
            'Overview',
            false,
            () => Navigator.pop(context),
          ),

          _sideItem(
            Icons.route_rounded,
            'Motorway Network',
            true,
            null,
          ),

       _sideItem(
  Icons.warning_amber_rounded,
  'Risk Alerts',
  false,
  () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const RiskAlertsScreen(),
      ),
    );
  },
  badge:
      '${riskCount('MODERATE') + riskCount('HIGH') + riskCount('CRITICAL')}',
),
          _sideItem(
            Icons.visibility_rounded,
            'Visibility Analysis',
            false,
            null,
          ),

          _sideItem(
            Icons.analytics_rounded,
            'Risk Analysis',
            false,
            null,
          ),

          const Spacer(),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cyan.withAlpha(10),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: cyan.withAlpha(30),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: safe,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: safe.withAlpha(120),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'SYSTEM ONLINE',
                      style: TextStyle(
                        color: safe,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                const Text(
                  'Latest backend data loaded',
                  style: TextStyle(
                    color: muted2,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sideItem(
    IconData icon,
    String title,
    bool selected,
    VoidCallback? onTap, {
    String? badge,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      decoration: BoxDecoration(
        color: selected ? cyan.withAlpha(18) : Colors.transparent,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: selected ? cyan.withAlpha(55) : Colors.transparent,
        ),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 9,
        ),
        onTap: onTap,
        leading: Icon(
          icon,
          size: 18,
          color: selected ? cyan : muted,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: selected ? white : muted,
            fontSize: 11.5,
            fontWeight:
                selected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
        trailing: badge == null
            ? null
            : Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: moderate.withAlpha(20),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: moderate,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
      ),
    );
  }

  // ============================================================
  // MAIN CONTENT
  // ============================================================

  Widget _buildMainContent() {
    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: AnimatedBuilder(
        animation: _pageController,
        builder: (context, child) {
          final value = Curves.easeOutCubic.transform(
            _pageController.value,
          );

          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 25 * (1 - value)),
              child: child,
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopBar(),
            const SizedBox(height: 16),
            _buildHero(),
            const SizedBox(height: 14),
            _buildStats(),
            const SizedBox(height: 14),
            _buildNetworkPanel(),
            const SizedBox(height: 14),
            _buildRoutes(),
            const SizedBox(height: 14),
            _buildLocations(),
          ],
        ),
      ),
      ),
    );
  }

  // ============================================================
  // TOP BAR
  // ============================================================

  Widget _buildTopBar() {
    return Row(
      children: [
        // Back to the main Overview dashboard.
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: panel,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: border),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: white,
                size: 20,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'MOTORWAY NETWORK',
                style: TextStyle(
                  color: cyan,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Punjab Motorway Risk Monitoring',
                style: TextStyle(
                  color: white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),

        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 9,
          ),
          decoration: BoxDecoration(
            color: panel,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: safe,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: safe.withAlpha(130),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'LIVE MONITORING',
                style: TextStyle(
                  color: white,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .7,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // HERO
  // ============================================================

  Widget _buildHero() {
    final item = highestRiskLocation;

    if (item == null) {
      return _emptyCard(
        'No motorway data available',
        'The latest risk dataset could not be loaded.',
      );
    }

    final risk = '${item['risk_level'] ?? 'UNKNOWN'}';
    final city = '${item['city'] ?? 'Unknown'}';
    final visibility = visibilityValue(item);
    final recommendation =
        '${item['recommendation'] ?? 'No recommendation available.'}';

    final color = riskColor(risk);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            panel2,
            panel.withAlpha(230),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withAlpha(75),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(18),
            blurRadius: 30,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      color: cyan,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$city • ${routeForCity(city)}',
                      style: const TextStyle(
                        color: muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  'CURRENT NETWORK STATUS',
                  style: TextStyle(
                    color: muted2,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      risk,
                      style: TextStyle(
                        color: color,
                        fontSize: 31,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      riskIcon(risk),
                      color: color,
                      size: 27,
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                SizedBox(
                  width: 560,
                  child: Text(
                    recommendation,
                    style: const TextStyle(
                      color: muted,
                      fontSize: 11,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 25),

          _VisibilityGauge(
            visibility: visibility,
            color: color,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STATS
  // ============================================================

  Widget _buildStats() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 720;

        final cards = [
          _statCard(
            'MONITORED LOCATIONS',
            '${locations.length}',
            Icons.location_on_rounded,
            cyan,
            'Latest records',
          ),
          _statCard(
            'AVERAGE VISIBILITY',
            '${averageVisibility.toStringAsFixed(1)} km',
            Icons.visibility_rounded,
            teal,
            'Across locations',
          ),
          _statCard(
            'MODERATE+ RISKS',
            '${riskCount('MODERATE') + riskCount('HIGH') + riskCount('CRITICAL')}',
            Icons.warning_amber_rounded,
            moderate,
            'Requires attention',
          ),
          _statCard(
            'ACTIVE ROUTES',
            '3',
            Icons.alt_route_rounded,
            purple,
            'M-2 • M-3 • M-4',
          ),
        ];

        if (narrow) {
          return Column(
            children: cards
                .map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: e,
                  ),
                )
                .toList(),
          );
        }

        return Row(
          children: [
            for (int i = 0; i < cards.length; i++) ...[
              Expanded(child: cards[i]),
              if (i != cards.length - 1)
                const SizedBox(width: 10),
            ],
          ],
        );
      },
    );
  }

  Widget _statCard(
    String label,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: panel.withAlpha(245),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withAlpha(16),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: color.withAlpha(45),
              ),
            ),
            child: Icon(
              icon,
              color: color,
              size: 19,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: muted2,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color: white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: muted2,
                    fontSize: 8.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // NETWORK PANEL
  // ============================================================

  Widget _buildNetworkPanel() {
    return Container(
      decoration: BoxDecoration(
        color: panel.withAlpha(245),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              17,
              16,
              17,
              12,
            ),
            child: Row(
              children: [
                Container(
                  width: 35,
                  height: 35,
                  decoration: BoxDecoration(
                    color: cyan.withAlpha(15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.map_rounded,
                    color: cyan,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MOTORWAY NETWORK',
                        style: TextStyle(
                          color: white,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Operational route overview',
                        style: TextStyle(
                          color: muted2,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
                _networkLegend(
                  'Safe',
                  safe,
                ),
                const SizedBox(width: 12),
                _networkLegend(
                  'Moderate',
                  moderate,
                ),
                const SizedBox(width: 12),
                _networkLegend(
                  'High',
                  high,
                ),
              ],
            ),
          ),

          Container(
            height: 300,
            margin: const EdgeInsets.fromLTRB(
              10,
              0,
              10,
              10,
            ),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: navy,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: border,
              ),
            ),
            child: AnimatedBuilder(
              animation: _networkController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _MotorwayNetworkPainter(
                    locations: locations,
                    animation:
                        _networkController.value,
                  ),
                  child: const SizedBox.expand(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _networkLegend(String title, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          title,
          style: const TextStyle(
            color: muted2,
            fontSize: 8,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ROUTES
  // ============================================================

  Widget _buildRoutes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'MOTORWAY CORRIDORS',
          style: TextStyle(
            color: white,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Risk condition across monitored motorway corridors',
          style: TextStyle(
            color: muted2,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 750;

            final cards = [
              _routeCard(
                'M-2',
                'Lahore',
                'Islamabad',
                [
                  'Lahore',
                  'Islamabad',
                ],
                cyan,
              ),
              _routeCard(
                'M-3',
                'Lahore',
                'Faisalabad',
                [
                  'Faisalabad',
                ],
                purple,
              ),
              _routeCard(
                'M-4',
                'Faisalabad',
                'Multan',
                [
                  'Faisalabad',
                  'Multan',
                ],
                teal,
              ),
            ];

            if (narrow) {
              return Column(
                children: cards
                    .map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(
                          bottom: 10,
                        ),
                        child: e,
                      ),
                    )
                    .toList(),
              );
            }

            return Row(
              children: [
                for (int i = 0; i < cards.length; i++) ...[
                  Expanded(child: cards[i]),
                  if (i != cards.length - 1)
                    const SizedBox(width: 10),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _routeCard(
    String route,
    String start,
    String end,
    List<String> cities,
    Color accent,
  ) {
    final routeLocations = locations.where((item) {
      return routeForCity('${item['city']}') == route;
    }).toList();

    String routeRisk = 'SAFE';

    if (routeLocations.isNotEmpty) {
      final risks = routeLocations.map(
        (e) => '${e['risk_level'] ?? 'SAFE'}',
      );

      routeRisk = _highestRisk(risks);
    }

    final color = riskColor(routeRisk);

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accent.withAlpha(40),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: accent.withAlpha(17),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  route,
                  style: TextStyle(
                    color: accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: color.withAlpha(16),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  routeRisk,
                  style: TextStyle(
                    color: color,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              _routePoint(start, accent),
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      height: 2,
                      color: border,
                    ),
                    Container(
                      height: 2,
                      width: 45,
                      color: accent.withAlpha(150),
                    ),
                  ],
                ),
              ),
              _routePoint(end, color),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                color: muted2,
                size: 13,
              ),
              const SizedBox(width: 5),
              Text(
                '${routeLocations.length} monitored location${routeLocations.length == 1 ? '' : 's'}',
                style: const TextStyle(
                  color: muted2,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _routePoint(String title, Color color) {
    return Column(
      children: [
        Container(
          width: 11,
          height: 11,
          decoration: BoxDecoration(
            color: navy,
            shape: BoxShape.circle,
            border: Border.all(
              color: color,
              width: 2,
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          title,
          style: const TextStyle(
            color: muted,
            fontSize: 8,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  String _highestRisk(Iterable<String> risks) {
    const order = [
      'SAFE',
      'LOW',
      'MODERATE',
      'HIGH',
      'CRITICAL',
    ];

    String result = 'SAFE';

    for (final risk in risks) {
      final current = risk.toUpperCase();

      if (order.indexOf(current) > order.indexOf(result)) {
        result = current;
      }
    }

    return result;
  }

  // ============================================================
  // LOCATIONS
  // ============================================================


Widget _buildLocations() {
  final data = filteredLocations;

  return LayoutBuilder(
    builder: (context, constraints) {
      final isMobile = constraints.maxWidth < 500;

      final heading = const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MONITORED LOCATIONS',
            style: TextStyle(
              color: white,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Latest backend records by city',
            style: TextStyle(
              color: muted2,
              fontSize: 10,
            ),
          ),
        ],
      );

      final searchBox = SizedBox(
        width: isMobile ? double.infinity : 210,
        height: 40,
        child: TextField(
          onChanged: (value) {
            setState(() {
              searchQuery = value;
            });
          },
          style: const TextStyle(
            color: white,
            fontSize: 12,
          ),
          decoration: InputDecoration(
            hintText: 'Search city or route...',
            hintStyle: const TextStyle(
              color: muted2,
              fontSize: 11,
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: muted2,
              size: 18,
            ),
            filled: true,
            fillColor: panel,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 8,
              horizontal: 10,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: cyan),
            ),
          ),
        ),
      );

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isMobile) ...[
            heading,
            const SizedBox(height: 12),
            searchBox,
          ] else
            Row(
              children: [
                Expanded(child: heading),
                const SizedBox(width: 12),
                searchBox,
              ],
            ),

          const SizedBox(height: 12),

          _buildFilters(),

          const SizedBox(height: 10),

          if (data.isEmpty)
            _emptyCard(
              'No locations found',
              'Try another route or search term.',
            )
          else
            ...data.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: _locationCard(item),
              ),
            ),
        ],
      );
    },
  );
}

  Widget _buildFilters() {
    final filters = [
      'ALL',
      'M-2',
      'M-3',
      'M-4',
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final selected = selectedRoute == filter;

          return Padding(
            padding: const EdgeInsets.only(right: 7),
            child: InkWell(
              onTap: () {
                setState(() {
                  selectedRoute = filter;
                });
              },
              borderRadius: BorderRadius.circular(9),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? cyan.withAlpha(20)
                      : panel,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: selected
                        ? cyan.withAlpha(100)
                        : border,
                  ),
                ),
                child: Text(
                  filter,
                  style: TextStyle(
                    color: selected ? cyan : muted,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }


Widget _locationCard(Map<String, dynamic> item) {
  final city = '${item['city'] ?? 'Unknown'}';
  final route = routeForCity(city);
  final risk = '${item['risk_level'] ?? 'UNKNOWN'}';
  final visibility = visibilityValue(item);
  final dateTime = '${item['datetime'] ?? 'N/A'}';
  final recommendation =
      '${item['recommendation'] ?? 'No recommendation available.'}';

  final color = riskColor(risk);

  return LayoutBuilder(
    builder: (context, constraints) {
      final isMobile = constraints.maxWidth < 550;

      final locationIcon = Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: color.withAlpha(45)),
        ),
        child: Icon(riskIcon(risk), color: color, size: 20),
      );

      final cityInfo = Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 7,
              runSpacing: 5,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  city,
                  style: const TextStyle(
                    color: white,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: cyan.withAlpha(13),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    route,
                    style: const TextStyle(
                      color: cyan,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              dateTime,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: muted2,
                fontSize: 9,
              ),
            ),
          ],
        ),
      );

      final riskBadge = Container(
        constraints: const BoxConstraints(minWidth: 76),
        padding: const EdgeInsets.symmetric(
          horizontal: 9,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: color.withAlpha(13),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: color.withAlpha(35)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              risk,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 3),
            const Text(
              'RISK LEVEL',
              style: TextStyle(
                color: muted2,
                fontSize: 7,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );

      final visibilityInfo = _miniMetric(
        Icons.visibility_rounded,
        '${visibility.toStringAsFixed(2)} km',
        'VISIBILITY',
      );

      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showDetails(item),
          borderRadius: BorderRadius.circular(15),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(isMobile ? 12 : 15),
            decoration: BoxDecoration(
              color: panel,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: border),
            ),
            child: isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          locationIcon,
                          const SizedBox(width: 10),
                          cityInfo,
                          const SizedBox(width: 8),
                          riskBadge,
                        ],
                      ),
                      const SizedBox(height: 14),
                      Container(height: 1, color: border),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: visibilityInfo),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.open_in_new_rounded,
                            color: muted2,
                            size: 16,
                          ),
                        ],
                      ),
                    ],
                  )
                : Row(
                    children: [
                      locationIcon,
                      const SizedBox(width: 12),
                      cityInfo,
                      const SizedBox(width: 16),
                      visibilityInfo,
                      const SizedBox(width: 18),
                      Container(
                        width: 1,
                        height: 35,
                        color: border,
                      ),
                      const SizedBox(width: 18),
                      riskBadge,
                      const SizedBox(width: 10),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: muted2,
                        size: 20,
                      ),
                    ],
                  ),
          ),
        ),
      );
    },
  );
}

  Widget _miniMetric(
    IconData icon,
    String value,
    String label,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: cyan,
              size: 13,
            ),
            const SizedBox(width: 5),
            Text(
              value,
              style: const TextStyle(
                color: white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(
            color: muted2,
            fontSize: 7,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // DETAILS
  // ============================================================

  void _showDetails(Map<String, dynamic> item) {
    final city = '${item['city'] ?? 'Unknown'}';
    final route = routeForCity(city);
    final risk = '${item['risk_level'] ?? 'UNKNOWN'}';
    final visibility = visibilityValue(item);
    final datetime = '${item['datetime'] ?? 'N/A'}';
    final recommendation =
        '${item['recommendation'] ?? 'No recommendation available.'}';

    final color = riskColor(risk);

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 520,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: navy2,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: color.withAlpha(70),
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withAlpha(18),
                  blurRadius: 35,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        color: color.withAlpha(18),
                        borderRadius:
                            BorderRadius.circular(12),
                      ),
                      child: Icon(
                        riskIcon(risk),
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            city,
                            style: const TextStyle(
                              color: white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '$route Motorway Corridor',
                            style: const TextStyle(
                              color: muted2,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () =>
                          Navigator.pop(context),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: muted,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                Row(
                  children: [
                    Expanded(
                      child: _dialogMetric(
                        'RISK LEVEL',
                        risk,
                        color,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _dialogMetric(
                        'VISIBILITY',
                        '${visibility.toStringAsFixed(2)} km',
                        cyan,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: panel,
                    borderRadius:
                        BorderRadius.circular(12),
                    border: Border.all(
                      color: border,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        color: muted2,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          datetime,
                          style: const TextStyle(
                            color: muted,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: color.withAlpha(10),
                    borderRadius:
                        BorderRadius.circular(12),
                    border: Border.all(
                      color: color.withAlpha(35),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: color,
                            size: 16,
                          ),
                          const SizedBox(width: 7),
                          const Text(
                            'TRAVEL ADVISORY',
                            style: TextStyle(
                              color: white,
                              fontSize: 9,
                              fontWeight:
                                  FontWeight.w900,
                              letterSpacing: .7,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        recommendation,
                        style: const TextStyle(
                          color: muted,
                          fontSize: 10,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        Navigator.pop(context),
                    icon: const Icon(
                      Icons.check_rounded,
                      size: 17,
                    ),
                    label: const Text(
                      'Close Details',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cyan,
                      foregroundColor: navy,
                      elevation: 0,
                      padding:
                          const EdgeInsets.symmetric(
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(10),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _dialogMetric(
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: muted2,
              fontSize: 8,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MOBILE
  // ============================================================

  Widget _buildMobile() {
    return Column(
      children: [
        _buildMobileHeader(),
        Expanded(
          child: Scrollbar(
            thumbVisibility: true,
            child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                _buildHero(),
                const SizedBox(height: 12),
                _buildStats(),
                const SizedBox(height: 12),
                _buildNetworkPanel(),
                const SizedBox(height: 12),
                _buildRoutes(),
                const SizedBox(height: 12),
                _buildLocations(),
              ],
            ),
          ),
          ),
        ),
      ],
    );
  }


Widget _buildMobileHeader() {
  return Container(
    width: double.infinity,
    margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
    padding: const EdgeInsets.symmetric(
      horizontal: 8,
      vertical: 8,
    ),
    decoration: BoxDecoration(
      color: panel,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: border),
    ),
    child: Row(
      children: [
        IconButton(
          tooltip: 'Back to User Dashboard',
          constraints: const BoxConstraints(
            minWidth: 40,
            minHeight: 40,
          ),
          padding: EdgeInsets.zero,
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: cyan,
            size: 21,
          ),
        ),
        const SizedBox(width: 6),
        const Icon(
          Icons.alt_route_rounded,
          color: cyan,
          size: 20,
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MOTORWAY NETWORK',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: white,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Punjab Risk Monitoring',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: muted2,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: safe,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
      ],
    ),
  );
}

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _emptyCard(
    String title,
    String subtitle,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            color: muted2,
            size: 32,
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: muted2,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}

// ==================================================================
// VISIBILITY GAUGE
// ==================================================================

class _VisibilityGauge extends StatelessWidget {
  final double visibility;
  final Color color;

  const _VisibilityGauge({
    required this.visibility,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final normalized =
        (visibility / 20).clamp(0.0, 1.0);

    return SizedBox(
      width: 135,
      height: 135,
      child: CustomPaint(
        painter: _CircularProgressPainter(
          progress: normalized,
          color: color,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                visibility.toStringAsFixed(1),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Text(
                'KM VISIBILITY',
                style: TextStyle(
                  color: Color(0xFF6F879D),
                  fontSize: 7,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .7,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================================================================
// CIRCULAR PROGRESS PAINTER
// ==================================================================

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;

  const _CircularProgressPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final center = Offset(
      size.width / 2,
      size.height / 2,
    );

    final radius =
        math.min(size.width, size.height) / 2 - 10;

    final backgroundPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF1B3B55);

    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round
      ..color = color;

    canvas.drawCircle(
      center,
      radius,
      backgroundPaint,
    );

    canvas.drawArc(
      Rect.fromCircle(
        center: center,
        radius: radius,
      ),
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(
    covariant _CircularProgressPainter oldDelegate,
  ) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color;
  }
}

// ==================================================================
// NETWORK BACKGROUND
// ==================================================================

class _NetworkBackgroundPainter extends CustomPainter {
  final Animation<double> animation;

  _NetworkBackgroundPainter({
    required this.animation,
  }) : super(repaint: animation);

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final paint = Paint()
      ..color = const Color(0xFF20D9FF).withAlpha(5)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 18; i++) {
      final x =
          (i * 137.0 + animation.value * 80) %
              size.width;

      final y =
          (i * 79.0) % size.height;

      final radius =
          1.5 + (i % 3) * .7;

      canvas.drawCircle(
        Offset(x, y),
        radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant _NetworkBackgroundPainter oldDelegate,
  ) {
    return true;
  }
}

// ==================================================================
// MOTORWAY NETWORK PAINTER
// ==================================================================

class _MotorwayNetworkPainter extends CustomPainter {
  final List<Map<String, dynamic>> locations;
  final double animation;

  // IMPORTANT:
  // Colors are declared INSIDE this painter.
  // This fixes all "getter cyan/safe/moderate..." errors.

  static const Color navy =
      Color(0xFF061321);

  static const Color border =
      Color(0xFF1B3B55);

  static const Color cyan =
      Color(0xFF20D9FF);

  static const Color purple =
      Color(0xFF9B7CFF);

  static const Color teal =
      Color(0xFF14B8A6);

  static const Color safe =
      Color(0xFF22C55E);

  static const Color low =
      Color(0xFF84CC16);

  static const Color moderate =
      Color(0xFFF59E0B);

  static const Color high =
      Color(0xFFF97316);

  static const Color critical =
      Color(0xFFEF4444);

  const _MotorwayNetworkPainter({
    required this.locations,
    required this.animation,
  });

  Color riskColor(String risk) {
    switch (risk.toUpperCase()) {
      case 'SAFE':
        return safe;
      case 'LOW':
        return low;
      case 'MODERATE':
        return moderate;
      case 'HIGH':
        return high;
      case 'CRITICAL':
        return critical;
      default:
        return cyan;
    }
  }

  String routeForCity(String city) {
    switch (city.toLowerCase()) {
      case 'lahore':
      case 'islamabad':
        return 'M-2';
      case 'faisalabad':
        return 'M-3';
      case 'multan':
        return 'M-4';
      default:
        return '';
    }
  }

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final w = size.width;
    final h = size.height;

    final gridPaint = Paint()
      ..color = border.withAlpha(28)
      ..strokeWidth = 1;

    for (double x = 0; x < w; x += 40) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, h),
        gridPaint,
      );
    }

    for (double y = 0; y < h; y += 40) {
      canvas.drawLine(
        Offset(0, y),
        Offset(w, y),
        gridPaint,
      );
    }

    // --------------------------------------------------------------
    // Decorative central network glow
    // --------------------------------------------------------------

    final glowPaint = Paint()
      ..color = cyan.withAlpha(9)
      ..maskFilter = const MaskFilter.blur(
        BlurStyle.normal,
        25,
      );

    canvas.drawCircle(
      Offset(w * .50, h * .52),
      75,
      glowPaint,
    );

    // --------------------------------------------------------------
    // Fixed network positions
    // --------------------------------------------------------------

    final lahore = Offset(
      w * .18,
      h * .67,
    );

    final islamabad = Offset(
      w * .76,
      h * .19,
    );

    final faisalabad = Offset(
      w * .48,
      h * .48,
    );

    final multan = Offset(
      w * .77,
      h * .76,
    );

    // --------------------------------------------------------------
    // Draw routes
    // --------------------------------------------------------------

    _drawRoute(
      canvas,
      lahore,
      islamabad,
      cyan,
      'M-2',
    );

    _drawRoute(
      canvas,
      lahore,
      faisalabad,
      purple,
      'M-3',
    );

    _drawRoute(
      canvas,
      faisalabad,
      multan,
      teal,
      'M-4',
    );

    // --------------------------------------------------------------
    // Draw cities
    // --------------------------------------------------------------

    _drawCity(
      canvas,
      lahore,
      'Lahore',
      _riskForCity('Lahore'),
    );

    _drawCity(
      canvas,
      islamabad,
      'Islamabad',
      _riskForCity('Islamabad'),
    );

    _drawCity(
      canvas,
      faisalabad,
      'Faisalabad',
      _riskForCity('Faisalabad'),
    );

    _drawCity(
      canvas,
      multan,
      'Multan',
      _riskForCity('Multan'),
    );

    // --------------------------------------------------------------
    // Header
    // --------------------------------------------------------------

    _drawLabel(
      canvas,
      Offset(18, 18),
      'PUNJAB MOTORWAY NETWORK',
      cyan,
      10,
    );

    _drawLabel(
      canvas,
      Offset(18, 35),
      'LIVE RISK TOPOLOGY',
      border,
      7,
    );
  }

  String _riskForCity(String city) {
    for (final item in locations) {
      if ('${item['city']}'.toLowerCase() ==
          city.toLowerCase()) {
        return '${item['risk_level'] ?? 'SAFE'}';
      }
    }

    return 'SAFE';
  }

  void _drawRoute(
    Canvas canvas,
    Offset start,
    Offset end,
    Color color,
    String label,
  ) {
    final path = Path();

    path.moveTo(start.dx, start.dy);

    final middleX =
        (start.dx + end.dx) / 2;

    path.cubicTo(
      middleX,
      start.dy,
      middleX,
      end.dy,
      end.dx,
      end.dy,
    );

    final shadow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..color = color.withAlpha(10)
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, shadow);

    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = color.withAlpha(150)
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, line);

    // Animated moving point
    final metric =
        path.computeMetrics().first;

    final distance =
        metric.length * animation;

    final tangent =
        metric.getTangentForOffset(distance);

    if (tangent != null) {
      final dotPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        tangent.position,
        3.5,
        dotPaint,
      );
    }

    final labelPoint = Offset(
      (start.dx + end.dx) / 2,
      (start.dy + end.dy) / 2 - 10,
    );

    _drawLabel(
      canvas,
      labelPoint,
      label,
      color,
      8,
    );
  }

  void _drawCity(
    Canvas canvas,
    Offset point,
    String city,
    String risk,
  ) {
    final color = riskColor(risk);

    final glow = Paint()
      ..color = color.withAlpha(25)
      ..maskFilter = const MaskFilter.blur(
        BlurStyle.normal,
        12,
      );

    canvas.drawCircle(
      point,
      13,
      glow,
    );

    final outer = Paint()
      ..style = PaintingStyle.fill
      ..color = navy;

    canvas.drawCircle(
      point,
      9,
      outer,
    );

    final inner = Paint()
      ..style = PaintingStyle.fill
      ..color = color;

    canvas.drawCircle(
      point,
      5,
      inner,
    );

    final textPainter = TextPainter(
      text: TextSpan(
        text: city,
        style: const TextStyle(
          color: Color(0xFFF4F8FC),
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    textPainter.paint(
      canvas,
      Offset(
        point.dx - textPainter.width / 2,
        point.dy + 14,
      ),
    );

    final riskPainter = TextPainter(
      text: TextSpan(
        text: risk,
        style: TextStyle(
          color: color,
          fontSize: 6.5,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    riskPainter.layout();

    riskPainter.paint(
      canvas,
      Offset(
        point.dx - riskPainter.width / 2,
        point.dy + 26,
      ),
    );
  }

  void _drawLabel(
    Canvas canvas,
    Offset point,
    String text,
    Color color,
    double size,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: FontWeight.w800,
          letterSpacing: .6,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    painter.layout();

    painter.paint(
      canvas,
      point,
    );
  }

  @override
  bool shouldRepaint(
    covariant _MotorwayNetworkPainter oldDelegate,
  ) {
    return oldDelegate.animation != animation ||
        oldDelegate.locations != locations;
  }
}