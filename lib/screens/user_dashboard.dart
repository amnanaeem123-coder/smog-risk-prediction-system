import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'login_page.dart';
import 'motorway_network_screen.dart';
import 'risk_alerts_screen.dart';
import 'system_status_screen.dart';
import 'preferences_screen.dart';
class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard>
    with TickerProviderStateMixin {
  // ============================================================
  // PROFESSIONAL FYP COLOR SYSTEM
  // ============================================================

  static const Color navy = Color(0xFF061321);
  static const Color navy2 = Color(0xFF091A2B);
  static const Color panel = Color(0xFF0D2236);
  static const Color panel2 = Color(0xFF102B43);

  static const Color cyan = Color(0xFF20D9FF);
  static const Color cyan2 = Color(0xFF67E8F9);
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

  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Map<String, dynamic>> _locations = [];
  bool _loading = true;
  String _search = '';
  String _filter = 'ALL';

  late AnimationController _backgroundController;
  late AnimationController _entryController;
  late AnimationController _pulseController;
  late AnimationController _refreshController;

  Timer? _clockTimer;
  DateTime _now = DateTime.now();

  bool _refreshing = false;

  // LIVE DATA: address of the small Python (Flask) server.
  static const String _liveUrl = 'http://localhost:5000/latest';

  // LIVE DATA: shows where the current data came from.
  String _dataSource = 'Offline file';

  // LIVE DATA: asks the server for new data every 5 minutes.
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();

    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _refreshController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });

    _loadData();

    _autoRefreshTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (mounted) _loadData();
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _autoRefreshTimer?.cancel();
    _backgroundController.dispose();
    _entryController.dispose();
    _pulseController.dispose();
    _refreshController.dispose();
    super.dispose();
  }

  // LIVE DATA: try the Python server first.
  // If the server is not running, use the bundled JSON file instead,
  // so the app never shows an empty screen during a demo.
  Future<void> _loadData() async {
    final firstLoad = _locations.isEmpty;

    List<dynamic> list = [];
    String source = 'Offline file';

    try {
      final response = await http
          .get(Uri.parse(_liveUrl))
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List && decoded.isNotEmpty) {
          list = decoded;
          source = 'Live server';
        }
      }
    } catch (_) {
      // Server not reachable. Fall back to the bundled file below.
    }

    if (list.isEmpty) {
      try {
        final raw =
            await rootBundle.loadString('assets/data/latest_risk.json');
        final decoded = jsonDecode(raw);
        list = decoded is List ? decoded : [];
      } catch (_) {
        list = [];
      }
    }

    final data = list
        .map<Map<String, dynamic>>(
          (e) => Map<String, dynamic>.from(e as Map),
        )
        .toList();

    if (!mounted) return;

    setState(() {
      _locations = data;
      _dataSource = source;
      _loading = false;
    });

    // Play the entry animation only on the first load,
    // not on every auto refresh.
    if (firstLoad) {
      _entryController.forward(from: 0);
    }
  }

  Future<void> _refreshData() async {
    if (_refreshing) return;

    setState(() {
      _refreshing = true;
    });

    _refreshController.repeat();

    await Future.delayed(const Duration(milliseconds: 700));
    await _loadData();

    if (!mounted) return;

    _refreshController.stop();
    setState(() {
      _refreshing = false;
    });
  }

  Future<void> _logout() async {
    await _auth.signOut();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const LoginPage(),
      ),
      (route) => false,
    );
  }

  String get _email =>
      _auth.currentUser?.email ?? 'motorway.user@smogsystem.pk';

  // CHANGE 1: sort by risk first, then by lowest visibility,
  // so ties go to the location with the worst visibility.
  Map<String, dynamic>? get _highestRiskLocation {
    if (_locations.isEmpty) return null;

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
        default:
          return 1;
      }
    }

    final copy = List<Map<String, dynamic>>.from(_locations);

    copy.sort((a, b) {
      final byRisk = score(
        b['risk_level'].toString(),
      ).compareTo(
        score(a['risk_level'].toString()),
      );

      if (byRisk != 0) return byRisk;

      final visA =
          double.tryParse(a['visibility_km'].toString()) ?? double.infinity;
      final visB =
          double.tryParse(b['visibility_km'].toString()) ?? double.infinity;

      return visA.compareTo(visB);
    });

    return copy.first;
  }

  // CHANGE 1: true when every location is SAFE
  bool get _allClear {
    if (_locations.isEmpty) return false;

    return _locations.every(
      (e) => e['risk_level'].toString().toUpperCase() == 'SAFE',
    );
  }

  // CHANGE 3: newest data timestamp from the JSON file
  String get _lastDataTime {
    if (_locations.isEmpty) return 'No data loaded';

    final times = _locations
        .map((e) => e['datetime']?.toString() ?? '')
        .where((t) => t.isNotEmpty && t != 'null')
        .toList();

    if (times.isEmpty) return 'Unknown';

    times.sort();
    return times.last;
  }

  int _countRisk(String risk) {
    return _locations.where(
      (e) => e['risk_level'].toString().toUpperCase() == risk,
    ).length;
  }

  double get _averageVisibility {
    if (_locations.isEmpty) return 0;

    double total = 0;

    for (final item in _locations) {
      total += double.tryParse(
            item['visibility_km'].toString(),
          ) ??
          0;
    }

    return total / _locations.length;
  }

  Color _riskColor(String risk) {
    switch (risk.toUpperCase()) {
      case 'CRITICAL':
        return critical;
      case 'HIGH':
        return high;
      case 'MODERATE':
        return moderate;
      case 'LOW':
        return low;
      default:
        return safe;
    }
  }

  IconData _riskIcon(String risk) {
    switch (risk.toUpperCase()) {
      case 'CRITICAL':
        return Icons.warning_rounded;
      case 'HIGH':
        return Icons.priority_high_rounded;
      case 'MODERATE':
        return Icons.visibility_off_rounded;
      case 'LOW':
        return Icons.info_outline_rounded;
      default:
        return Icons.check_circle_outline_rounded;
    }
  }

  String _routeForCity(String city) {
    switch (city.toLowerCase()) {
      case 'lahore':
      case 'islamabad':
        return 'M-2';
      case 'faisalabad':
        return 'M-3';
      case 'multan':
        return 'M-4';
      default:
        return 'Motorway';
    }
  }

  Map<String, dynamic>? _locationForCity(String city) {
    for (final item in _locations) {
      if (item['city'].toString().toLowerCase() == city.toLowerCase()) {
        return item;
      }
    }

    return null;
  }

  List<Map<String, dynamic>> get _filteredLocations {
    return _locations.where((item) {
      final city = item['city'].toString().toLowerCase();
      final risk = item['risk_level'].toString().toUpperCase();

      final searchMatch =
          _search.trim().isEmpty || city.contains(_search.toLowerCase());

      final filterMatch = _filter == 'ALL' || risk == _filter;

      return searchMatch && filterMatch;
    }).toList();
  }

  String _timeText() {
    final hour = _now.hour.toString().padLeft(2, '0');
    final minute = _now.minute.toString().padLeft(2, '0');
    final second = _now.second.toString().padLeft(2, '0');

    return '$hour:$minute:$second';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: navy,
      body: Stack(
        children: [
          Positioned.fill(
            child: _AnimatedAtmosphere(
              controller: _backgroundController,
            ),
          ),

          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    navy.withAlpha(245),
                    navy2.withAlpha(235),
                    const Color(0xFF061827).withAlpha(250),
                  ],
                ),
              ),
            ),
          ),

          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 820) {
                return _buildMobileLayout();
              }

              return _buildDesktopLayout(constraints);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BoxConstraints constraints) {
    return Row(
      children: [
        _buildSidebar(),

        Expanded(
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 40),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 1500,
                  ),
                  child: _buildDashboardContent(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return SafeArea(
      child: Column(
        children: [
          _buildMobileHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 30),
              child: _buildDashboardContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 218,
      decoration: BoxDecoration(
        color: navy2.withAlpha(245),
        border: Border(
          right: BorderSide(
            color: border.withAlpha(180),
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==================================================
              // LOGO
              // ==================================================

              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          cyan,
                          teal,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(13),
                      boxShadow: [
                        BoxShadow(
                          color: cyan.withAlpha(45),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.cloud_queue_rounded,
                      color: navy,
                      size: 23,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'SMOG\nRISK SYSTEM',
                      style: TextStyle(
                        color: white,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                        letterSpacing: .7,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // ==================================================
              // FIXED MONITORING MENU
              // ==================================================

              _sidebarSection('MONITORING'),

              // OVERVIEW
              _sidebarItem(
                icon: Icons.dashboard_rounded,
                title: 'Overview',
                selected: true,
              ),

              // MOTORWAY NETWORK
              _sidebarItem(
                icon: Icons.route_rounded,
                title: 'Motorway Network',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const MotorwayNetworkScreen(),
                    ),
                  );
                },
              ),

              // RISK ALERTS
              _sidebarItem(
                icon: Icons.warning_amber_rounded,
                title: 'Risk Alerts',
                badge: (_countRisk('MODERATE') +
                        _countRisk('HIGH') +
                        _countRisk('CRITICAL'))
                    .toString(),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const RiskAlertsScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 8),

              // ==================================================
              // SYSTEM
              // ==================================================

              _sidebarSection('SYSTEM'),

              _sidebarItem(
                icon: Icons.info_outline_rounded,
                title: 'System Status',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SystemStatusScreen(),
                    ),
                  );
                },
              ),
              _sidebarItem(
                icon: Icons.settings_outlined,
                title: 'Preferences',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PreferencesScreen(),
                    ),
                  );
                },
              ),

              const Spacer(),

              // ==================================================
              // SYSTEM ONLINE
              // ==================================================

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: panel.withAlpha(210),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: border.withAlpha(180),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (_, __) {
                            final opacity =
                                .45 + (_pulseController.value * .55);

                            return Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: safe.withOpacity(opacity),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: safe.withOpacity(
                                      opacity * .45,
                                    ),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 7),
                        const Text(
                          'SYSTEM ONLINE',
                          style: TextStyle(
                            color: safe,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: .8,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _timeText(),
                      style: const TextStyle(
                        color: white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // CHANGE 3: show when the data was last updated
                    const Text(
                      'Last prediction data',
                      style: TextStyle(
                        color: muted2,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _lastDataTime,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: muted,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // LIVE DATA: where the data came from
                    Text(
                      'Source: $_dataSource',
                      style: TextStyle(
                        color: _dataSource == 'Live server' ? safe : moderate,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // ==================================================
              // SIGN OUT
              // ==================================================

              InkWell(
                onTap: _logout,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 10,
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.logout_rounded,
                        color: muted,
                        size: 18,
                      ),
                      SizedBox(width: 9),
                      Text(
                        'Sign Out',
                        style: TextStyle(
                          color: muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
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
    );
  }

  Widget _sidebarSection(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 10,
        bottom: 8,
      ),
      child: Text(
        title,
        style: const TextStyle(
          color: muted2,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _sidebarItem({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
    bool selected = false,
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
          horizontal: 10,
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
            fontWeight: selected
                ? FontWeight.w800
                : FontWeight.w600,
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
                  color: moderate.withAlpha(22),
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

  Widget _buildMobileHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 12, 15, 12),
      decoration: BoxDecoration(
        color: navy2.withAlpha(245),
        border: Border(
          bottom: BorderSide(
            color: border.withAlpha(170),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  cyan,
                  teal,
                ],
              ),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.cloud_queue_rounded,
              color: navy,
              size: 21,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'SMOG RISK\nPREDICTION SYSTEM',
              style: TextStyle(
                color: white,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                height: 1.05,
              ),
            ),
          ),
          IconButton(
            onPressed: _refreshData,
            icon: RotationTransition(
              turns: _refreshController,
              child: const Icon(
                Icons.refresh_rounded,
                color: cyan,
              ),
            ),
          ),
          IconButton(
            onPressed: _logout,
            icon: const Icon(
              Icons.logout_rounded,
              color: muted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTopHeader(),
        const SizedBox(height: 18),

        if (_loading)
          const SizedBox(
            height: 500,
            child: Center(
              child: CircularProgressIndicator(
                color: cyan,
              ),
            ),
          )
        else if (_locations.isEmpty)
          _buildEmptyState()
        else
          _buildAnimatedDashboard(),
      ],
    );
  }

  Widget _buildTopHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Motorway Safety Command',
                style: TextStyle(
                  color: white,
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.5,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Real-time visibility and smog-risk overview for Punjab motorway routes',
                style: TextStyle(
                  color: muted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),

        if (MediaQuery.of(context).size.width > 900) ...[
          // LIVE DATA: manual refresh button for desktop
          Tooltip(
            message: 'Refresh data',
            child: IconButton(
              onPressed: _refreshData,
              icon: RotationTransition(
                turns: _refreshController,
                child: const Icon(
                  Icons.refresh_rounded,
                  color: cyan,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _buildUserChip(),
        ],
      ],
    );
  }

  Widget _buildUserChip() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: panel.withAlpha(210),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 31,
            height: 31,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  cyan,
                  teal,
                ],
              ),
            ),
            child: const Icon(
              Icons.person_rounded,
              size: 17,
              color: navy,
            ),
          ),
          const SizedBox(width: 9),
          ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 190,
            ),
            child: Text(
              _email,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.verified_rounded,
            color: cyan,
            size: 15,
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedDashboard() {
    return AnimatedBuilder(
      animation: _entryController,
      builder: (context, child) {
        return Column(
          children: [
            _AnimatedSection(
              animation: _entryController,
              interval: const Interval(
                0.00,
                .25,
                curve: Curves.easeOutCubic,
              ),
              child: _buildHeroSection(),
            ),

            const SizedBox(height: 16),

            _AnimatedSection(
              animation: _entryController,
              interval: const Interval(
                .10,
                .38,
                curve: Curves.easeOutCubic,
              ),
              child: _buildStatsRow(),
            ),

            const SizedBox(height: 16),

            _AnimatedSection(
              animation: _entryController,
              interval: const Interval(
                .20,
                .50,
                curve: Curves.easeOutCubic,
              ),
              child: _buildAnalyticsRow(),
            ),

            const SizedBox(height: 16),

            _AnimatedSection(
              animation: _entryController,
              interval: const Interval(
                .30,
                .62,
                curve: Curves.easeOutCubic,
              ),
              child: _buildNetworkPanel(),
            ),

            const SizedBox(height: 16),

            _AnimatedSection(
              animation: _entryController,
              interval: const Interval(
                .42,
                .75,
                curve: Curves.easeOutCubic,
              ),
              child: _buildAdvisoryPanel(),
            ),

            const SizedBox(height: 16),

            _AnimatedSection(
              animation: _entryController,
              interval: const Interval(
                .52,
                .90,
                curve: Curves.easeOutCubic,
              ),
              child: _buildLocationsPanel(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeroSection() {
    final highest = _highestRiskLocation;

    final risk = highest?['risk_level']?.toString() ?? 'SAFE';
    final city = highest?['city']?.toString() ?? 'Unknown';
    final visibility =
        double.tryParse(highest?['visibility_km']?.toString() ?? '') ?? 0;

    final riskColor = _riskColor(risk);

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(
        minHeight: 220,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            panel2,
            panel.withAlpha(245),
            const Color(0xFF0A1D30),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: riskColor.withAlpha(80),
        ),
        boxShadow: [
          BoxShadow(
            color: riskColor.withAlpha(18),
            blurRadius: 35,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -50,
            top: -80,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (_, __) {
                final scale = 1 + (_pulseController.value * .08);

                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          riskColor.withAlpha(35),
                          riskColor.withAlpha(0),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(22),
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 650) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeroTitle(
                        city,
                        risk,
                        visibility,
                        riskColor,
                      ),
                      const SizedBox(height: 20),
                      _buildRiskGauge(
                        risk,
                        riskColor,
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(
                      child: _buildHeroTitle(
                        city,
                        risk,
                        visibility,
                        riskColor,
                      ),
                    ),
                    const SizedBox(width: 24),
                    _buildRiskGauge(
                      risk,
                      riskColor,
                    ),
                  ],
                );
              },
            ),
          ),

          Positioned(
            right: 20,
            bottom: 17,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (_, __) {
                    return Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: safe.withAlpha(
                          (130 + (_pulseController.value * 125)).round(),
                        ),
                        shape: BoxShape.circle,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 7),
                const Text(
                  'LIVE MONITORING',
                  style: TextStyle(
                    color: muted,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroTitle(
    String city,
    String risk,
    double visibility,
    Color riskColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 9,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: riskColor.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: riskColor.withAlpha(65),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _riskIcon(risk),
                    color: riskColor,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  // CHANGE 1: different label when everything is safe
                  Text(
                    _allClear
                        ? 'ALL CLEAR  •  LOWEST VISIBILITY'
                        : 'CURRENT HIGHEST RISK',
                    style: TextStyle(
                      color: riskColor,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .8,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Text(
          city,
          style: const TextStyle(
            color: white,
            fontSize: 31,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          '${_routeForCity(city)}  •  Motorway Risk Zone',
          style: const TextStyle(
            color: cyan2,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 17),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.visibility_rounded,
              color: muted,
              size: 18,
            ),
            const SizedBox(width: 7),
            Text(
              '${visibility.toStringAsFixed(2)} km visibility',
              style: const TextStyle(
                color: white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 650,
          ),
          child: Text(
            _locationForCity(city)?['recommendation']?.toString() ??
                'Normal Operations',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: muted,
              fontSize: 11,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRiskGauge(
    String risk,
    Color riskColor,
  ) {
    double progress;

    switch (risk.toUpperCase()) {
      case 'CRITICAL':
        progress = .96;
        break;
      case 'HIGH':
        progress = .78;
        break;
      case 'MODERATE':
        progress = .58;
        break;
      case 'LOW':
        progress = .35;
        break;
      default:
        progress = .16;
    }

    return SizedBox(
      width: 170,
      height: 170,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(170, 170),
            painter: _RiskGaugePainter(
              progress: progress,
              color: riskColor,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'RISK LEVEL',
                style: TextStyle(
                  color: muted,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                risk,
                style: TextStyle(
                  color: riskColor,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'location status',
                style: TextStyle(
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

  Widget _buildStatsRow() {
    final stats = [
      _StatData(
        title: 'MONITORED',
        value: _locations.length.toString(),
        subtitle: 'locations',
        icon: Icons.location_on_rounded,
        accent: cyan,
      ),
      _StatData(
        title: 'SAFE',
        value: _countRisk('SAFE').toString(),
        subtitle: 'normal operation',
        icon: Icons.check_circle_rounded,
        accent: safe,
      ),
      _StatData(
        title: 'ATTENTION',
        value: (_countRisk('MODERATE') +
                _countRisk('HIGH') +
                _countRisk('CRITICAL'))
            .toString(),
        subtitle: 'need attention',
        icon: Icons.warning_rounded,
        accent: moderate,
      ),
      _StatData(
        title: 'AVG VISIBILITY',
        value: _averageVisibility.toStringAsFixed(1),
        subtitle: 'kilometres',
        icon: Icons.visibility_rounded,
        accent: cyan2,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 700 ? 2 : 4;
        const spacing = 10.0;
        final itemWidth =
            (constraints.maxWidth - ((columns - 1) * spacing)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: stats.map(
            (stat) {
              return SizedBox(
                width: itemWidth,
                child: _HoverCard(
                  child: _buildStatCard(stat),
                ),
              );
            },
          ).toList(),
        );
      },
    );
  }

  Widget _buildStatCard(_StatData stat) {
    return Container(
      height: 100,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: panel.withAlpha(230),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: stat.accent.withAlpha(45),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 39,
            height: 39,
            decoration: BoxDecoration(
              color: stat.accent.withAlpha(17),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color: stat.accent.withAlpha(38),
              ),
            ),
            child: Icon(
              stat.icon,
              color: stat.accent,
              size: 19,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // CHANGE 4: slightly larger, more readable
                Text(
                  stat.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: muted,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .8,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  stat.value,
                  style: const TextStyle(
                    color: white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  stat.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: muted,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 850) {
          return Column(
            children: [
              _buildVisibilityPanel(),
              const SizedBox(height: 12),
              _buildRiskDistributionPanel(),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 6,
              child: _buildVisibilityPanel(),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 4,
              child: _buildRiskDistributionPanel(),
            ),
          ],
        );
      },
    );
  }

  // CHANGE 2: bar chart with y-axis and value labels
  Widget _buildVisibilityPanel() {
    final values = _locations
        .map(
          (e) => double.tryParse(e['visibility_km'].toString()) ?? 0,
        )
        .toList();

    final barColors = _locations
        .map(
          (e) => _riskColor(e['risk_level'].toString()),
        )
        .toList();

    return _panelContainer(
      title: 'VISIBILITY ANALYSIS',
      subtitle: 'Current visibility (km) across monitored locations',
      icon: Icons.bar_chart_rounded,
      accent: cyan,
      child: Column(
        children: [
          SizedBox(
            height: 155,
            width: double.infinity,
            child: CustomPaint(
              painter: _VisibilityChartPainter(
                values: values,
                barColors: barColors,
                gridColor: border,
                labelColor: muted,
                valueColor: white,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(
              left: _VisibilityChartPainter.leftPad,
            ),
            child: Row(
              children: _locations.map((location) {
                final city = location['city'].toString();

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 3,
                    ),
                    child: Text(
                      city,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: muted,
                        fontSize: 10,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskDistributionPanel() {
    final counts = {
      'SAFE': _countRisk('SAFE'),
      'LOW': _countRisk('LOW'),
      'MODERATE': _countRisk('MODERATE'),
      'HIGH': _countRisk('HIGH'),
      'CRITICAL': _countRisk('CRITICAL'),
    };

    return _panelContainer(
      title: 'RISK DISTRIBUTION',
      subtitle: 'Current status by risk category',
      icon: Icons.donut_large_rounded,
      accent: teal,
      child: Column(
        children: [
          SizedBox(
            height: 150,
            child: Center(
              child: SizedBox(
                width: 145,
                height: 145,
                child: CustomPaint(
                  painter: _DonutPainter(
                    values: counts.values.toList(),
                    colors: const [
                      safe,
                      low,
                      moderate,
                      high,
                      critical,
                    ],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _locations.length.toString(),
                          style: const TextStyle(
                            color: white,
                            fontSize: 25,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Text(
                          'LOCATIONS',
                          style: TextStyle(
                            color: muted,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: .8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 7,
            children: counts.entries.map(
              (entry) {
                final color = _riskColor(entry.key);

                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    // CHANGE 4: larger legend text
                    Text(
                      '${entry.key} ${entry.value}',
                      style: const TextStyle(
                        color: muted,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                );
              },
            ).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkPanel() {
    final routes = [
      const _RouteInfo(
        route: 'M-2',
        name: 'Lahore — Islamabad',
        cities: ['Lahore', 'Islamabad'],
      ),
      const _RouteInfo(
        route: 'M-3',
        name: 'Lahore — Faisalabad',
        cities: ['Lahore', 'Faisalabad'],
      ),
      const _RouteInfo(
        route: 'M-4',
        name: 'Faisalabad — Multan',
        cities: ['Faisalabad', 'Multan'],
      ),
    ];

    return _panelContainer(
      title: 'MOTORWAY NETWORK',
      subtitle: 'Monitored Punjab motorway corridors',
      icon: Icons.route_rounded,
      accent: cyan,
      trailing: _buildNetworkLegend(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;

          if (width < 720) {
            return Column(
              children: routes
                  .map(
                    (route) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildRouteCard(route),
                    ),
                  )
                  .toList(),
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: routes.map(
              (route) {
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: route == routes.last ? 0 : 10,
                    ),
                    child: _buildRouteCard(route),
                  ),
                );
              },
            ).toList(),
          );
        },
      ),
    );
  }

  Widget _buildNetworkLegend() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            color: safe,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        const Text(
          'MONITORED',
          style: TextStyle(
            color: muted,
            fontSize: 8,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildRouteCard(_RouteInfo route) {
    final first = _locationForCity(route.cities.first);
    final second = _locationForCity(route.cities.last);

    final firstRisk = first?['risk_level']?.toString() ?? 'SAFE';
    final secondRisk = second?['risk_level']?.toString() ?? 'SAFE';

    final routeRisk = _routeRisk(firstRisk, secondRisk);
    final routeColor = _riskColor(routeRisk);

    return _HoverCard(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: navy2.withAlpha(220),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: routeColor.withAlpha(42),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: cyan.withAlpha(14),
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                      color: cyan.withAlpha(30),
                    ),
                  ),
                  child: Text(
                    route.route,
                    style: const TextStyle(
                      color: cyan,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    route.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 17),
            _buildRouteLine(
              route.cities.first,
              firstRisk,
              first?['visibility_km'],
              routeColor,
            ),
            Padding(
              padding: const EdgeInsets.only(
                left: 7,
              ),
              child: Container(
                width: 2,
                height: 19,
                color: border,
              ),
            ),
            _buildRouteLine(
              route.cities.last,
              secondRisk,
              second?['visibility_km'],
              routeColor,
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 9,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color: routeColor.withAlpha(10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.shield_outlined,
                    color: routeColor,
                    size: 13,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Route status: $routeRisk',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: routeColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _routeRisk(String a, String b) {
    final scores = {
      'SAFE': 1,
      'LOW': 2,
      'MODERATE': 3,
      'HIGH': 4,
      'CRITICAL': 5,
    };

    final scoreA = scores[a.toUpperCase()] ?? 1;
    final scoreB = scores[b.toUpperCase()] ?? 1;

    final score = math.max(scoreA, scoreB);

    if (score >= 5) return 'CRITICAL';
    if (score == 4) return 'HIGH';
    if (score == 3) return 'MODERATE';
    if (score == 2) return 'LOW';

    return 'SAFE';
  }

  Widget _buildRouteLine(
    String city,
    String risk,
    dynamic visibility,
    Color routeColor,
  ) {
    final visibilityValue =
        double.tryParse(visibility?.toString() ?? '') ?? 0;

    return Row(
      children: [
        Container(
          width: 15,
          height: 15,
          decoration: BoxDecoration(
            color: navy,
            shape: BoxShape.circle,
            border: Border.all(
              color: routeColor,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: routeColor.withAlpha(55),
                blurRadius: 8,
              ),
            ],
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            city,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          '${visibilityValue.toStringAsFixed(1)} km',
          style: const TextStyle(
            color: muted,
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 7),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 6,
            vertical: 3,
          ),
          decoration: BoxDecoration(
            color: _riskColor(risk).withAlpha(18),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text(
            risk,
            style: TextStyle(
              color: _riskColor(risk),
              fontSize: 7,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdvisoryPanel() {
    final alerts = _locations.where((item) {
      final risk = item['risk_level'].toString().toUpperCase();
      return risk != 'SAFE' && risk != 'LOW';
    }).toList();

    if (alerts.isEmpty) {
      return _panelContainer(
        title: 'TRAVEL ADVISORY',
        subtitle: 'Current system recommendation',
        icon: Icons.shield_rounded,
        accent: safe,
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: safe.withAlpha(10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: safe.withAlpha(35),
            ),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: safe,
                size: 25,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'No active travel advisory is currently indicated by the monitored risk data.',
                  style: TextStyle(
                    color: white,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return _panelContainer(
      title: 'TRAVEL ADVISORY',
      subtitle: 'Locations requiring additional attention',
      icon: Icons.warning_amber_rounded,
      accent: moderate,
      child: Column(
        children: alerts.map(
          (item) {
            final city = item['city'].toString();
            final risk = item['risk_level'].toString();
            final recommendation = item['recommendation'].toString();

            final color = _riskColor(risk);

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withAlpha(9),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                    color: color.withAlpha(32),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: color.withAlpha(17),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(
                        _riskIcon(risk),
                        color: color,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '$city  •  ${_routeForCity(city)}',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                risk,
                                style: TextStyle(
                                  color: color,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            recommendation,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: muted,
                              fontSize: 9.5,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ).toList(),
      ),
    );
  }

  Widget _buildLocationsPanel() {
    return _panelContainer(
      title: 'MONITORED LOCATIONS',
      subtitle: 'Location-level motorway condition monitoring',
      icon: Icons.location_searching_rounded,
      accent: cyan,
      // All risk levels now have a filter button.
      // Wrap lets the buttons move to a second line on small screens.
      trailing: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Wrap(
          alignment: WrapAlignment.end,
          spacing: 5,
          runSpacing: 5,
          children: [
            _buildFilterButton('ALL'),
            _buildFilterButton('SAFE'),
            _buildFilterButton('LOW'),
            _buildFilterButton('MODERATE'),
            _buildFilterButton('HIGH'),
            _buildFilterButton('CRITICAL'),
          ],
        ),
      ),
      child: Column(
        children: [
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: navy.withAlpha(180),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: border,
              ),
            ),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _search = value;
                });
              },
              style: const TextStyle(
                color: white,
                fontSize: 11,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: muted2,
                  size: 18,
                ),
                hintText: 'Search city...',
                hintStyle: TextStyle(
                  color: muted2,
                  fontSize: 10,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final list = _filteredLocations;

              if (list.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(25),
                  child: Text(
                    'No location matches this filter or search.',
                    style: TextStyle(
                      color: muted,
                      fontSize: 11,
                    ),
                  ),
                );
              }

              final columns = constraints.maxWidth < 700 ? 1 : 2;
              const spacing = 10.0;
              final itemWidth = columns == 1
                  ? constraints.maxWidth
                  : (constraints.maxWidth - spacing) / 2;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: list.map(
                  (item) {
                    return SizedBox(
                      width: itemWidth,
                      child: _LocationCard(
                        item: item,
                        route: _routeForCity(
                          item['city'].toString(),
                        ),
                        riskColor: _riskColor(
                          item['risk_level'].toString(),
                        ),
                        onDetails: () {
                          _showLocationDetails(item);
                        },
                      ),
                    );
                  },
                ).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String value) {
    final selected = _filter == value;

    return InkWell(
      onTap: () {
        setState(() {
          _filter = value;
        });
      },
      borderRadius: BorderRadius.circular(7),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 7,
          vertical: 5,
        ),
        decoration: BoxDecoration(
          color: selected ? cyan.withAlpha(18) : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color: selected ? cyan.withAlpha(55) : border,
          ),
        ),
        child: Text(
          value,
          style: TextStyle(
            color: selected ? cyan : muted2,
            fontSize: 7,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _panelContainer({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accent,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: panel.withAlpha(230),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: border.withAlpha(190),
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withAlpha(8),
            blurRadius: 22,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: accent.withAlpha(13),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: accent.withAlpha(30),
                  ),
                ),
                child: Icon(
                  icon,
                  color: accent,
                  size: 16,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: white,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .7,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // CHANGE 4: larger, more readable subtitle
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: muted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      height: 420,
      decoration: BoxDecoration(
        color: panel.withAlpha(230),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: border,
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              color: muted2,
              size: 45,
            ),
            SizedBox(height: 14),
            Text(
              'No monitoring data available',
              style: TextStyle(
                color: white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Please check the latest risk data file.',
              style: TextStyle(
                color: muted,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLocationDetails(Map<String, dynamic> item) {
    final city = item['city'].toString();
    final risk = item['risk_level'].toString();
    final visibility =
        double.tryParse(item['visibility_km'].toString()) ?? 0;
    final recommendation = item['recommendation'].toString();
    final datetime = item['datetime'].toString();

    final color = _riskColor(risk);

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: 500,
            ),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: navy2,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: color.withAlpha(60),
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withAlpha(20),
                  blurRadius: 35,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 43,
                      height: 43,
                      decoration: BoxDecoration(
                        color: color.withAlpha(17),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _riskIcon(risk),
                        color: color,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            city,
                            style: const TextStyle(
                              color: white,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            '${_routeForCity(city)} • Location Details',
                            style: const TextStyle(
                              color: cyan,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: muted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _detailMetric(
                        'RISK',
                        risk,
                        color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _detailMetric(
                        'VISIBILITY',
                        '${visibility.toStringAsFixed(2)} km',
                        cyan,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _detailMetric(
                  'DATA TIMESTAMP',
                  datetime,
                  muted,
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: panel,
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(
                      color: border,
                    ),
                  ),
                  child: Text(
                    recommendation,
                    style: const TextStyle(
                      color: muted,
                      fontSize: 10.5,
                      height: 1.45,
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

  Widget _detailMetric(
    String label,
    String value,
    Color color,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: muted2,
              fontSize: 7.5,
              fontWeight: FontWeight.w900,
              letterSpacing: .8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// LOCATION CARD
// ============================================================

class _LocationCard extends StatefulWidget {
  final Map<String, dynamic> item;
  final String route;
  final Color riskColor;
  final VoidCallback onDetails;

  const _LocationCard({
    required this.item,
    required this.route,
    required this.riskColor,
    required this.onDetails,
  });

  @override
  State<_LocationCard> createState() => _LocationCardState();
}

class _LocationCardState extends State<_LocationCard> {
  bool _hovered = false;

  // Colors needed by this separate State class
  static const Color _white = Color(0xFFF4F8FC);
  static const Color _muted = Color(0xFF9EB1C5);
  static const Color _muted2 = Color(0xFF6F879D);
  static const Color _cyan = Color(0xFF20D9FF);
  static const Color _border = Color(0xFF1B3B55);

  @override
  Widget build(BuildContext context) {
    final city = widget.item['city'].toString();
    final risk = widget.item['risk_level'].toString();

    final visibility = double.tryParse(
          widget.item['visibility_km'].toString(),
        ) ??
        0;

    return MouseRegion(
      onEnter: (_) {
        setState(() {
          _hovered = true;
        });
      },
      onExit: (_) {
        setState(() {
          _hovered = false;
        });
      },
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        transform: Matrix4.translationValues(
          0,
          _hovered ? -3 : 0,
          0,
        ),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: _hovered
              ? const Color(0xFF112B43)
              : const Color(0xFF0B2034),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: widget.riskColor.withAlpha(
              _hovered ? 75 : 38,
            ),
          ),
          boxShadow: [
            if (_hovered)
              BoxShadow(
                color: widget.riskColor.withAlpha(18),
                blurRadius: 20,
              ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: widget.riskColor.withAlpha(15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: widget.riskColor.withAlpha(35),
                ),
              ),
              child: Icon(
                Icons.location_on_rounded,
                color: widget.riskColor,
                size: 18,
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          city,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _white,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),

                      const SizedBox(width: 7),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: widget.riskColor.withAlpha(17),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          risk,
                          style: TextStyle(
                            color: widget.riskColor,
                            fontSize: 7,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 3),

                  Text(
                    '${widget.route}  •  monitored location',
                    style: const TextStyle(
                      color: _muted2,
                      fontSize: 8.5,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      const Icon(
                        Icons.visibility_outlined,
                        color: _muted,
                        size: 13,
                      ),

                      const SizedBox(width: 5),

                      Text(
                        '${visibility.toStringAsFixed(2)} km',
                        style: const TextStyle(
                          color: _white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(width: 13),

                      Expanded(
                        child: _visibilityBar(
                          visibility,
                          widget.riskColor,
                        ),
                      ),

                      const SizedBox(width: 9),

                      InkWell(
                        onTap: widget.onDetails,
                        borderRadius: BorderRadius.circular(7),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: _cyan.withAlpha(12),
                            borderRadius: BorderRadius.circular(7),
                            border: Border.all(
                              color: _cyan.withAlpha(30),
                            ),
                          ),
                          child: const Text(
                            'DETAILS',
                            style: TextStyle(
                              color: _cyan,
                              fontSize: 7,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _visibilityBar(
    double visibility,
    Color color,
  ) {
    final progress = (visibility / 20).clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: LinearProgressIndicator(
        value: progress,
        minHeight: 4,
        backgroundColor: _border,
        valueColor: AlwaysStoppedAnimation<Color>(
          color,
        ),
      ),
    );
  }
}

// ============================================================
// HOVER CARD
// ============================================================

class _HoverCard extends StatefulWidget {
  final Widget child;

  const _HoverCard({
    required this.child,
  });

  @override
  State<_HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<_HoverCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() {
          _hovered = true;
        });
      },
      onExit: (_) {
        setState(() {
          _hovered = false;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        transform: Matrix4.translationValues(
          0,
          _hovered ? -2 : 0,
          0,
        ),
        child: widget.child,
      ),
    );
  }
}

// ============================================================
// ANIMATED SECTION
// ============================================================

class _AnimatedSection extends StatelessWidget {
  final Animation<double> animation;
  final Interval interval;
  final Widget child;

  const _AnimatedSection({
    required this.animation,
    required this.interval,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: interval,
    );

    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, .045),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}

// ============================================================
// BACKGROUND ATMOSPHERE
// ============================================================

class _AnimatedAtmosphere extends StatelessWidget {
  final Animation<double> controller;

  const _AnimatedAtmosphere({
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        return CustomPaint(
          painter: _AtmospherePainter(
            progress: controller.value,
          ),
        );
      },
    );
  }
}

class _AtmospherePainter extends CustomPainter {
  final double progress;

  _AtmospherePainter({
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    final blobs = [
      (
        Offset(
          size.width * (.08 + progress * .03),
          size.height * .13,
        ),
        190.0,
        const Color(0xFF20D9FF),
      ),
      (
        Offset(
          size.width * (.88 - progress * .04),
          size.height * .28,
        ),
        230.0,
        const Color(0xFF0EA5A4),
      ),
      (
        Offset(
          size.width * .50,
          size.height * (.92 - progress * .03),
        ),
        280.0,
        const Color(0xFF075985),
      ),
    ];

    for (final blob in blobs) {
      paint.shader = RadialGradient(
        colors: [
          blob.$3.withAlpha(20),
          blob.$3.withAlpha(0),
        ],
      ).createShader(
        Rect.fromCircle(
          center: blob.$1,
          radius: blob.$2,
        ),
      );

      canvas.drawCircle(
        blob.$1,
        blob.$2,
        paint,
      );
    }

    paint.shader = null;

    // Very subtle atmospheric lines.
    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0xFF20D9FF).withAlpha(7);

    for (int i = 0; i < 8; i++) {
      final y = size.height * (i / 8) +
          math.sin(progress * math.pi * 2 + i) * 9;

      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AtmospherePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// ============================================================
// RISK GAUGE PAINTER
// ============================================================

class _RiskGaugePainter extends CustomPainter {
  final double progress;
  final Color color;

  _RiskGaugePainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(
      size.width / 2,
      size.height / 2,
    );

    final radius = size.width / 2 - 13;

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF1B3449);

    canvas.drawArc(
      Rect.fromCircle(
        center: center,
        radius: radius,
      ),
      math.pi * .75,
      math.pi * 1.5,
      false,
      track,
    );

    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round
      ..color = color;

    canvas.drawArc(
      Rect.fromCircle(
        center: center,
        radius: radius,
      ),
      math.pi * .75,
      math.pi * 1.5 * progress,
      false,
      progressPaint,
    );

    final dotAngle = math.pi * .75 + (math.pi * 1.5 * progress);

    final dot = Offset(
      center.dx + radius * math.cos(dotAngle),
      center.dy + radius * math.sin(dotAngle),
    );

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      dot,
      5,
      dotPaint,
    );

    final glowPaint = Paint()
      ..color = color.withAlpha(45)
      ..maskFilter = const MaskFilter.blur(
        BlurStyle.normal,
        10,
      );

    canvas.drawCircle(
      dot,
      8,
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RiskGaugePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color;
  }
}

// ============================================================
// VISIBILITY CHART (CHANGE 2: bars + y-axis + value labels)
// ============================================================

class _VisibilityChartPainter extends CustomPainter {
  final List<double> values;
  final List<Color> barColors;
  final Color gridColor;
  final Color labelColor;
  final Color valueColor;

  // Space on the left for y-axis numbers.
  // The city label row uses the same padding so it lines up.
  static const double leftPad = 28;

  _VisibilityChartPainter({
    required this.values,
    required this.barColors,
    required this.gridColor,
    required this.labelColor,
    required this.valueColor,
  });

  void _drawText(
    Canvas canvas,
    String text,
    TextStyle style,
    Offset Function(Size textSize) position,
  ) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(canvas, position(tp.size));
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    const topPad = 18.0;
    final chartHeight = size.height - topPad;
    final chartWidth = size.width - leftPad;
    final baseY = topPad + chartHeight;

    final maxValue = math.max(
      20.0,
      values.reduce((a, b) => math.max(a, b)),
    );
    final axisMax = (maxValue / 5).ceil() * 5.0;

    // Grid lines and y-axis labels
    final gridPaint = Paint()
      ..color = gridColor.withAlpha(80)
      ..strokeWidth = 1;

    final axisStyle = TextStyle(
      color: labelColor,
      fontSize: 9,
    );

    const steps = 5;
    for (int i = 0; i <= steps; i++) {
      final value = axisMax * i / steps;
      final y = baseY - (chartHeight * i / steps);

      canvas.drawLine(
        Offset(leftPad, y),
        Offset(size.width, y),
        gridPaint,
      );

      _drawText(
        canvas,
        value.toStringAsFixed(0),
        axisStyle,
        (s) => Offset(leftPad - 6 - s.width, y - s.height / 2),
      );
    }

    // Bars
    final slot = chartWidth / values.length;
    final barWidth = math.min(slot * .45, 46.0);

    final valueStyle = TextStyle(
      color: valueColor,
      fontSize: 10,
      fontWeight: FontWeight.w700,
    );

    for (int i = 0; i < values.length; i++) {
      final v = values[i];
      final centerX = leftPad + slot * i + slot / 2;
      final barHeight = chartHeight * (v / axisMax).clamp(0.0, 1.0);
      final top = baseY - barHeight;

      final color =
          i < barColors.length ? barColors[i] : const Color(0xFF20D9FF);

      final rect = RRect.fromRectAndCorners(
        Rect.fromLTRB(
          centerX - barWidth / 2,
          top,
          centerX + barWidth / 2,
          baseY,
        ),
        topLeft: const Radius.circular(6),
        topRight: const Radius.circular(6),
      );

      final barPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withAlpha(230),
            color.withAlpha(90),
          ],
        ).createShader(rect.outerRect);

      canvas.drawRRect(rect, barPaint);

      _drawText(
        canvas,
        '${v.toStringAsFixed(1)} km',
        valueStyle,
        (s) => Offset(centerX - s.width / 2, top - s.height - 3),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _VisibilityChartPainter oldDelegate) {
    return true;
  }
}

// ============================================================
// DONUT CHART
// ============================================================

class _DonutPainter extends CustomPainter {
  final List<int> values;
  final List<Color> colors;

  _DonutPainter({
    required this.values,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold<int>(
      0,
      (sum, value) => sum + value,
    );

    if (total == 0) return;

    final center = Offset(
      size.width / 2,
      size.height / 2,
    );

    final radius = size.width / 2 - 10;

    double startAngle = -math.pi / 2;

    for (int i = 0; i < values.length; i++) {
      if (values[i] == 0) continue;

      final sweep = (values[i] / total) * math.pi * 2;

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 17
        ..strokeCap = StrokeCap.butt
        ..color = colors[i];

      canvas.drawArc(
        Rect.fromCircle(
          center: center,
          radius: radius,
        ),
        startAngle,
        sweep,
        false,
        paint,
      );

      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return true;
  }
}

// ============================================================
// DATA CLASSES
// ============================================================

class _StatData {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accent;

  const _StatData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.accent,
  });
}

class _RouteInfo {
  final String route;
  final String name;
  final List<String> cities;

  const _RouteInfo({
    required this.route,
    required this.name,
    required this.cities,
  });
}