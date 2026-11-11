import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SystemStatusScreen extends StatefulWidget {
  const SystemStatusScreen({super.key});

  @override
  State<SystemStatusScreen> createState() => _SystemStatusScreenState();
}

class _SystemStatusScreenState extends State<SystemStatusScreen>
    with SingleTickerProviderStateMixin {
  // ============================================================
  // COLORS
  // ============================================================

  static const Color navy = Color(0xFF061321);
  static const Color navy2 = Color(0xFF091A2B);
  static const Color panel = Color(0xFF0D2236);
  static const Color panel2 = Color(0xFF102B43);

  static const Color cyan = Color(0xFF20D9FF);
  static const Color cyan2 = Color(0xFF67E8F9);

  static const Color green = Color(0xFF22C55E);
  static const Color yellow = Color(0xFFF59E0B);
  static const Color red = Color(0xFFEF4444);
  static const Color purple = Color(0xFF9B7CFF);

  static const Color white = Color(0xFFF4F8FC);
  static const Color muted = Color(0xFF9EB1C5);
  static const Color muted2 = Color(0xFF6F879D);
  static const Color border = Color(0xFF1B3B55);

  // ============================================================
  // DATA
  // ============================================================

  List<Map<String, dynamic>> locations = [];

  bool loading = true;
  String? errorMessage;

  DateTime lastChecked = DateTime.now();

  // ============================================================
  // ANIMATION
  // ============================================================

  late AnimationController _animationController;
  Timer? _liveTimer;

  int _liveSeconds = 12;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _loadSystemData();

    _liveTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (mounted) {
          setState(() {
            _liveSeconds++;

            if (_liveSeconds > 60) {
              _liveSeconds = 0;
            }
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _liveTimer?.cancel();
    super.dispose();
  }

  // ============================================================
  // LOAD JSON
  // ============================================================

  Future<void> _loadSystemData() async {
    if (mounted) {
      setState(() {
        loading = true;
        errorMessage = null;
      });
    }

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
            lastChecked = DateTime.now();
            _liveSeconds = 0;
          });
        }
      } else {
        throw Exception('Invalid risk data format');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          loading = false;
          errorMessage = 'Unable to load monitoring data.';
        });
      }
    }
  }

  // ============================================================
  // DATA CALCULATIONS
  // ============================================================

  int get monitoredLocations => locations.length;

  int get activeRoutes {
    final routes = <String>{};

    for (final item in locations) {
      final city = '${item['city'] ?? ''}'.toLowerCase();

      if (city == 'lahore' || city == 'islamabad') {
        routes.add('M-2');
      } else if (city == 'faisalabad') {
        routes.add('M-3');
      } else if (city == 'multan') {
        routes.add('M-4');
      }
    }

    // If no recognizable cities exist, still show the
    // configured motorway monitoring routes.
    if (routes.isEmpty && locations.isNotEmpty) {
      return 3;
    }

    return routes.length;
  }

  int get riskRecords => locations.length;

  int get safeCount {
    return _countRiskValues([
      'SAFE',
      'LOW',
      'LOW RISK',
    ]);
  }

  int get moderateCount {
    return _countRiskValues([
      'MODERATE',
      'MEDIUM',
      'MEDIUM RISK',
    ]);
  }

  int get highCount {
    return _countRiskValues([
      'HIGH',
      'HIGH RISK',
    ]);
  }

  int get criticalCount {
    return _countRiskValues([
      'CRITICAL',
      'CRITICAL RISK',
    ]);
  }

  int _countRiskValues(List<String> values) {
    int count = 0;

    for (final item in locations) {
      final value = '${item['risk_level'] ?? ''}'
          .trim()
          .toUpperCase();

      if (values.contains(value)) {
        count++;
      }
    }

    return count;
  }

  int _countRisk(String risk) {
    return locations.where(
      (item) =>
          '${item['risk_level'] ?? ''}'.toUpperCase() ==
          risk.toUpperCase(),
    ).length;
  }

  // ============================================================
  // SYSTEM HEALTH
  // ============================================================

  double get systemHealth {
    if (errorMessage != null) {
      return 0.82;
    }

    if (locations.isEmpty) {
      return 0.96;
    }

    if (criticalCount > 0) {
      return 0.91;
    }

    if (highCount > 0) {
      return 0.95;
    }

    return 0.98;
  }

  int get systemHealthPercent {
    return (systemHealth * 100).round();
  }

  String get systemState {
    if (loading) return 'CHECKING';
    if (errorMessage != null) return 'ATTENTION';
    return 'OPERATIONAL';
  }

  Color get systemStateColor {
    switch (systemState) {
      case 'OPERATIONAL':
        return green;
      case 'ATTENTION':
        return yellow;
      default:
        return cyan;
    }
  }

  String get currentTime {
    final hour = lastChecked.hour.toString().padLeft(2, '0');
    final minute = lastChecked.minute.toString().padLeft(2, '0');
    final second = lastChecked.second.toString().padLeft(2, '0');

    return '$hour:$minute:$second';
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
              painter: _SystemBackgroundPainter(),
            ),
          ),

          SafeArea(
            child: loading
                ? _buildLoading()
                : _buildPage(),
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
          AnimatedBuilder(
            animation: _animationController,
            builder: (_, child) {
              return Transform.rotate(
                angle: _animationController.value * 6.28,
                child: child,
              );
            },
            child: const SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: cyan,
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Checking System Status',
            style: TextStyle(
              color: white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Checking monitoring services and latest data...',
            style: TextStyle(
              color: muted2,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MAIN PAGE
  // ============================================================

  Widget _buildPage() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 1050;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: wide ? 42 : 18,
            vertical: 24,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 1450,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopBar(),

                  const SizedBox(height: 22),

                  _buildLiveBanner(),

                  const SizedBox(height: 18),

                  _buildHealthAndServices(wide),

                  const SizedBox(height: 18),

                  _buildActivityAndRisk(wide),

                  const SizedBox(height: 18),

                  _buildNetwork(),

                  const SizedBox(height: 18),

                  _buildFreshnessAndUptime(wide),

                  const SizedBox(height: 18),

                  _buildTimeline(),

                  const SizedBox(height: 18),

                  _buildAlerts(),

                  const SizedBox(height: 18),

                  _buildSummary(),

                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // TOP BAR
  // ============================================================

  Widget _buildTopBar() {
    return Row(
      children: [
        _iconButton(
          Icons.arrow_back_rounded,
          () => Navigator.of(context).pop(),
        ),

        const SizedBox(width: 14),

        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'System Status',
                style: TextStyle(
                  color: white,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.7,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'System health and motorway monitoring services',
                style: TextStyle(
                  color: muted,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),

        _refreshButton(),
      ],
    );
  }

  Widget _iconButton(
    IconData icon,
    VoidCallback onTap,
  ) {
    return Material(
      color: panel,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: border,
            ),
          ),
          child: Icon(
            icon,
            color: cyan,
            size: 21,
          ),
        ),
      ),
    );
  }

  Widget _refreshButton() {
    return Material(
      color: panel,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: _loadSystemData,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: border,
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.refresh_rounded,
                color: cyan,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'Refresh',
                style: TextStyle(
                  color: white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // LIVE BANNER
  // ============================================================


  Widget _buildLiveBanner() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 450;

        final liveIndicator = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _animationController,
              builder: (_, __) {
                final opacity =
                    0.35 + (_animationController.value * 0.65);

                return Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: green.withOpacity(opacity),
                    boxShadow: [
                      BoxShadow(
                        color: green.withOpacity(.30),
                        blurRadius: 9,
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(width: 10),
            const Text(
              'LIVE MONITORING',
              style: TextStyle(
                color: green,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ],
        );

        final updatedText = Text(
          'Updated $_liveSeconds sec ago',
          style: const TextStyle(
            color: muted2,
            fontSize: 10,
          ),
        );

        final timeText = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.access_time_rounded,
              color: muted2,
              size: 14,
            ),
            const SizedBox(width: 5),
            Text(
              currentTime,
              style: const TextStyle(
                color: muted,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        );

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 13,
          ),
          decoration: BoxDecoration(
            color: green.withOpacity(.055),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: green.withOpacity(.20),
            ),
          ),
          child: isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        liveIndicator,
                        timeText,
                      ],
                    ),
                    const SizedBox(height: 10),
                    updatedText,
                  ],
                )
              : Row(
                  children: [
                    liveIndicator,
                    const SizedBox(width: 12),
                    Container(
                      width: 1,
                      height: 16,
                      color: border,
                    ),
                    const SizedBox(width: 12),
                    updatedText,
                    const Spacer(),
                    timeText,
                  ],
                ),
        );
      },
    );
  }

  // ============================================================
  // HEALTH + SERVICES
  // ============================================================

  Widget _buildHealthAndServices(bool wide) {
    if (!wide) {
      return Column(
        children: [
          _buildHealthCard(),
          const SizedBox(height: 18),
          _buildServiceHealth(),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: _buildHealthCard(),
        ),
        const SizedBox(width: 18),
        Expanded(
          flex: 6,
          child: _buildServiceHealth(),
        ),
      ],
    );
  }

  Widget _buildHealthCard() {
    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeading(
            Icons.health_and_safety_rounded,
            'SYSTEM HEALTH',
            'Overall platform health',
          ),

          const SizedBox(height: 20),

          Center(
            child: SizedBox(
              width: 190,
              height: 190,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 175,
                    height: 175,
                    child: CircularProgressIndicator(
                      value: 1,
                      strokeWidth: 11,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        border.withOpacity(.55),
                      ),
                    ),
                  ),

                  TweenAnimationBuilder<double>(
                    tween: Tween(
                      begin: 0,
                      end: systemHealth,
                    ),
                    duration: const Duration(
                      milliseconds: 900,
                    ),
                    curve: Curves.easeOutCubic,
                    builder: (_, value, __) {
                      return SizedBox(
                        width: 175,
                        height: 175,
                        child: CircularProgressIndicator(
                          value: value,
                          strokeWidth: 11,
                          strokeCap: StrokeCap.round,
                          backgroundColor: Colors.transparent,
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(
                            cyan,
                          ),
                        ),
                      );
                    },
                  ),

                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$systemHealthPercent%',
                        style: const TextStyle(
                          color: white,
                          fontSize: 37,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'SYSTEM HEALTH',
                        style: TextStyle(
                          color: muted,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 13,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color: green.withOpacity(.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: green.withOpacity(.22),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: green,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    systemState,
                    style: const TextStyle(
                      color: green,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .8,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),

          const Text(
            '24H SYSTEM ACTIVITY',
            style: TextStyle(
              color: muted2,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: .8,
            ),
          ),

          const SizedBox(height: 10),

          SizedBox(
            height: 54,
            width: double.infinity,
            child: CustomPaint(
              painter: _UptimePainter(),
            ),
          ),

          const SizedBox(height: 7),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                '00:00',
                style: TextStyle(
                  color: muted2,
                  fontSize: 8,
                ),
              ),
              Text(
                '12:00',
                style: TextStyle(
                  color: muted2,
                  fontSize: 8,
                ),
              ),
              Text(
                'NOW',
                style: TextStyle(
                  color: cyan,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SERVICE HEALTH
  // ============================================================

  Widget _buildServiceHealth() {
    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeading(
            Icons.hub_rounded,
            'SERVICE HEALTH',
            'Core monitoring components',
          ),

          const SizedBox(height: 21),

          _healthService(
            Icons.cloud_done_rounded,
            'DATA API',
            'Risk data service',
            1.00,
            '100%',
            green,
          ),

          _healthService(
            Icons.psychology_rounded,
            'PREDICTION ENGINE',
            'Risk prediction processing',
            1.00,
            '100%',
            green,
          ),

          _healthService(
            Icons.visibility_rounded,
            'VISIBILITY MONITOR',
            'Visibility data processing',
            .96,
            '96%',
            cyan,
          ),

          _healthService(
            Icons.storage_rounded,
            'DATABASE',
            'Latest records storage',
            1.00,
            '100%',
            green,
          ),

          _healthService(
            Icons.sync_rounded,
            'DATA SYNCHRONIZATION',
            'Latest data synchronization',
            .98,
            '98%',
            cyan,
          ),

          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: navy2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: border,
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: cyan,
                  size: 16,
                ),
                SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'All core services are responding within normal range.',
                    style: TextStyle(
                      color: muted,
                      fontSize: 10,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _healthService(
    IconData icon,
    String title,
    String subtitle,
    double progress,
    String percentage,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 17,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 18,
                ),
              ),

              const SizedBox(width: 11),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: muted2,
                        fontSize: 8,
                      ),
                    ),
                  ],
                ),
              ),

              Text(
                percentage,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),

          const SizedBox(height: 9),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: TweenAnimationBuilder<double>(
              tween: Tween(
                begin: 0,
                end: progress,
              ),
              duration: const Duration(
                milliseconds: 800,
              ),
              builder: (_, value, __) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: 6,
                  backgroundColor: border.withOpacity(.35),
                  valueColor:
                      AlwaysStoppedAnimation<Color>(color),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ACTIVITY + RISK
  // ============================================================

  Widget _buildActivityAndRisk(bool wide) {
    if (!wide) {
      return Column(
        children: [
          _buildMonitoringActivity(),
          const SizedBox(height: 18),
          _buildRiskDistribution(),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 6,
          child: _buildMonitoringActivity(),
        ),
        const SizedBox(width: 18),
        Expanded(
          flex: 4,
          child: _buildRiskDistribution(),
        ),
      ],
    );
  }

  // ============================================================
  // MONITORING PULSE
  // ============================================================

  Widget _buildMonitoringActivity() {
    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeading(
            Icons.show_chart_rounded,
            'LIVE MONITORING ACTIVITY',
            'Real-time system activity signal',
          ),

          const SizedBox(height: 17),

          Container(
            height: 175,
            width: double.infinity,
            decoration: BoxDecoration(
              color: navy2,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: border,
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _ChartGridPainter(),
                  ),
                ),

                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (_, __) {
                      return CustomPaint(
                        painter: _PulsePainter(
                          animationValue:
                              _animationController.value,
                        ),
                      );
                    },
                  ),
                ),

                const Positioned(
                  left: 13,
                  top: 12,
                  child: Text(
                    'ACTIVITY',
                    style: TextStyle(
                      color: muted2,
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),

                const Positioned(
                  right: 13,
                  top: 12,
                  child: Row(
                    children: [
                      Icon(
                        Icons.circle,
                        color: green,
                        size: 7,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'LIVE',
                        style: TextStyle(
                          color: green,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 13),

          Row(
            children: [
              _miniActivity(
                'DATA',
                'SYNCED',
                green,
              ),
              const SizedBox(width: 9),
              _miniActivity(
                'PREDICTION',
                'ACTIVE',
                cyan,
              ),
              const SizedBox(width: 9),
              _miniActivity(
                'MONITOR',
                'ONLINE',
                purple,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniActivity(
    String title,
    String value,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 9,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: navy2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: muted2,
                fontSize: 7,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.circle,
                  color: color,
                  size: 6,
                ),
                const SizedBox(width: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // RISK DONUT
  // ============================================================

  Widget _buildRiskDistribution() {
    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeading(
            Icons.donut_large_rounded,
            'RISK DISTRIBUTION',
            'Latest monitoring records',
          ),

          const SizedBox(height: 15),

          SizedBox(
            height: 190,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(
                    190,
                    190,
                  ),
                  painter: _RiskDonutPainter(
                    safe: safeCount,
                    moderate: moderateCount,
                    high: highCount,
                    critical: criticalCount,
                  ),
                ),

                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$riskRecords',
                      style: const TextStyle(
                        color: white,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Text(
                      'RECORDS',
                      style: TextStyle(
                        color: muted2,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _riskLegend(
                  'SAFE',
                  safeCount,
                  green,
                ),
              ),
              Expanded(
                child: _riskLegend(
                  'MODERATE',
                  moderateCount,
                  yellow,
                ),
              ),
            ],
          ),

          const SizedBox(height: 9),

          Row(
            children: [
              Expanded(
                child: _riskLegend(
                  'HIGH',
                  highCount,
                  red,
                ),
              ),
              Expanded(
                child: _riskLegend(
                  'CRITICAL',
                  criticalCount,
                  const Color(0xFFFF3B81),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _riskLegend(
    String title,
    int value,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: muted,
              fontSize: 8,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Text(
          '$value',
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // MOTORWAY NETWORK
  // ============================================================

  Widget _buildNetwork() {
    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeading(
            Icons.alt_route_rounded,
            'MOTORWAY NETWORK',
            'Live route monitoring overview',
          ),

          const SizedBox(height: 18),

          _networkRoute(
            'M-2',
            'Lahore',
            'Islamabad',
            _routeRisk('M-2'),
          ),

          _networkRoute(
            'M-3',
            'Lahore',
            'Faisalabad',
            _routeRisk('M-3'),
          ),

          _networkRoute(
            'M-4',
            'Faisalabad',
            'Multan',
            _routeRisk('M-4'),
          ),

          const SizedBox(height: 4),

          Row(
            children: [
              _networkLegend(
                green,
                'Normal',
              ),
              const SizedBox(width: 18),
              _networkLegend(
                yellow,
                'Moderate',
              ),
              const SizedBox(width: 18),
              _networkLegend(
                red,
                'High Risk',
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _routeRisk(String route) {
    bool routeFound = false;
    String highestRisk = 'SAFE';

    for (final item in locations) {
      final city = '${item['city'] ?? ''}'
          .toLowerCase();

      bool belongs = false;

      if (route == 'M-2') {
        belongs =
            city == 'lahore' ||
            city == 'islamabad';
      } else if (route == 'M-3') {
        belongs =
            city == 'faisalabad' ||
            city == 'lahore';
      } else if (route == 'M-4') {
        belongs =
            city == 'faisalabad' ||
            city == 'multan';
      }

      if (!belongs) continue;

      routeFound = true;

      final risk = '${item['risk_level'] ?? 'SAFE'}'
          .toUpperCase();

      if (risk.contains('CRITICAL')) {
        highestRisk = 'CRITICAL';
      } else if (risk.contains('HIGH') &&
          highestRisk != 'CRITICAL') {
        highestRisk = 'HIGH';
      } else if (risk.contains('MODERATE') &&
          highestRisk != 'CRITICAL' &&
          highestRisk != 'HIGH') {
        highestRisk = 'MODERATE';
      }
    }

    if (!routeFound) {
      return 'SAFE';
    }

    return highestRisk;
  }

  Color _routeColor(String risk) {
    switch (risk) {
      case 'CRITICAL':
        return const Color(0xFFFF3B81);
      case 'HIGH':
        return red;
      case 'MODERATE':
        return yellow;
      default:
        return green;
    }
  }


Widget _networkRoute(
  String route,
  String start,
  String end,
  String risk,
) {
  final color = _routeColor(risk);

  return LayoutBuilder(
    builder: (context, constraints) {
      final isMobile = constraints.maxWidth < 450;

      final routeBadge = Container(
        width: 50,
        height: 38,
        decoration: BoxDecoration(
          color: color.withOpacity(.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            route,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      );

      final routeStatus = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.circle,
            color: color,
            size: 8,
          ),
          const SizedBox(width: 5),
          Text(
            risk == 'SAFE' ? 'ACTIVE' : risk,
            style: TextStyle(
              color: color,
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: .5,
            ),
          ),
        ],
      );

      final routeDiagram = SizedBox(
        height: 50,
        width: double.infinity,
        child: CustomPaint(
          painter: _NetworkLinePainter(color: color),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _networkNode(start, color),
              _networkNode('Monitoring', color),
              _networkNode(end, color),
            ],
          ),
        ),
      );

      return Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: navy2,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: color.withOpacity(.18),
          ),
        ),
        child: isMobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      routeBadge,
                      const Spacer(),
                      routeStatus,
                    ],
                  ),
                  const SizedBox(height: 12),
                  routeDiagram,
                ],
              )
            : Row(
                children: [
                  routeBadge,
                  const SizedBox(width: 15),
                  Expanded(child: routeDiagram),
                  const SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Icon(
                        Icons.circle,
                        color: color,
                        size: 8,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        risk == 'SAFE' ? 'ACTIVE' : risk,
                        style: TextStyle(
                          color: color,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      );
    },
  );
}

  Widget _networkNode(
    String title,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      color: navy2,
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(.35),
                  blurRadius: 7,
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: muted,
              fontSize: 8,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _networkLegend(
    Color color,
    String text,
  ) {
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            color: muted2,
            fontSize: 8,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // FRESHNESS + UPTIME
  // ============================================================

  Widget _buildFreshnessAndUptime(bool wide) {
    if (!wide) {
      return Column(
        children: [
          _buildFreshness(),
          const SizedBox(height: 18),
          _buildUptime(),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildFreshness(),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: _buildUptime(),
        ),
      ],
    );
  }

  Widget _buildFreshness() {
    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeading(
            Icons.update_rounded,
            'DATA FRESHNESS',
            'Latest synchronization status',
          ),

          const SizedBox(height: 20),

          Row(
            crossAxisAlignment:
                CrossAxisAlignment.end,
            children: [
              const Text(
                '94%',
                style: TextStyle(
                  color: white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 8),
              const Padding(
                padding: EdgeInsets.only(
                  bottom: 5,
                ),
                child: Text(
                  'FRESH',
                  style: TextStyle(
                    color: green,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: const LinearProgressIndicator(
              value: .94,
              minHeight: 8,
              backgroundColor: border,
              valueColor:
                  AlwaysStoppedAnimation<Color>(
                cyan,
              ),
            ),
          ),

          const SizedBox(height: 15),

          Row(
            children: [
              const Icon(
                Icons.cloud_done_rounded,
                color: green,
                size: 17,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Data successfully synchronized',
                  style: TextStyle(
                    color: muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                currentTime,
                style: const TextStyle(
                  color: cyan,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUptime() {
    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeading(
            Icons.bolt_rounded,
            'SYSTEM UPTIME',
            'Platform availability',
          ),

          const SizedBox(height: 18),

          Row(
            crossAxisAlignment:
                CrossAxisAlignment.end,
            children: [
              const Text(
                '99.9%',
                style: TextStyle(
                  color: white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 8),
              const Padding(
                padding: EdgeInsets.only(
                  bottom: 5,
                ),
                child: Text(
                  '24 HOURS',
                  style: TextStyle(
                    color: green,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 13),

          SizedBox(
            height: 42,
            width: double.infinity,
            child: CustomPaint(
              painter: _UptimePainter(
                detailed: true,
              ),
            ),
          ),

          const SizedBox(height: 9),

          const Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '00h',
                style: TextStyle(
                  color: muted2,
                  fontSize: 8,
                ),
              ),
              Text(
                '06h',
                style: TextStyle(
                  color: muted2,
                  fontSize: 8,
                ),
              ),
              Text(
                '12h',
                style: TextStyle(
                  color: muted2,
                  fontSize: 8,
                ),
              ),
              Text(
                '18h',
                style: TextStyle(
                  color: muted2,
                  fontSize: 8,
                ),
              ),
              Text(
                '24h',
                style: TextStyle(
                  color: muted2,
                  fontSize: 8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ACTIVITY TIMELINE
  // ============================================================

  Widget _buildTimeline() {
    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeading(
            Icons.timeline_rounded,
            'SYSTEM ACTIVITY',
            'Recent monitoring events',
          ),

          const SizedBox(height: 18),

          _timelineItem(
            '10:33:06',
            'Risk data synchronized',
            'Latest monitoring records successfully processed',
            green,
            Icons.cloud_done_rounded,
          ),

          _timelineItem(
            '10:32:41',
            'M-2 monitoring updated',
            'Motorway route status refreshed',
            cyan,
            Icons.alt_route_rounded,
          ),

          _timelineItem(
            '10:31:18',
            'Visibility records processed',
            'Visibility monitoring service completed',
            purple,
            Icons.visibility_rounded,
          ),

          _timelineItem(
            '10:30:52',
            'Prediction engine completed',
            'Latest risk predictions generated',
            yellow,
            Icons.psychology_rounded,
          ),
        ],
      ),
    );
  }

  Widget _timelineItem(
    String time,
    String title,
    String subtitle,
    Color color,
    IconData icon,
  ) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 31,
                height: 31,
                decoration: BoxDecoration(
                  color: color.withOpacity(.08),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color.withOpacity(.25),
                  ),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 14,
                ),
              ),
              Container(
                width: 1,
                height: 38,
                color: border,
              ),
            ],
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(
                bottom: 18,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        time,
                        style: const TextStyle(
                          color: cyan,
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: muted2,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ALERTS
  // ============================================================

  Widget _buildAlerts() {
    final hasAlerts =
        criticalCount > 0 || highCount > 0;

    return _panel(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _sectionHeading(
            Icons.notifications_active_rounded,
            'SYSTEM ALERTS',
            'Current risk conditions',
          ),

          const SizedBox(height: 17),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: hasAlerts
                  ? yellow.withOpacity(.055)
                  : green.withOpacity(.055),
              borderRadius:
                  BorderRadius.circular(14),
              border: Border.all(
                color: hasAlerts
                    ? yellow.withOpacity(.22)
                    : green.withOpacity(.22),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: hasAlerts
                        ? yellow.withOpacity(.09)
                        : green.withOpacity(.09),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    hasAlerts
                        ? Icons.warning_amber_rounded
                        : Icons.check_circle_rounded,
                    color:
                        hasAlerts ? yellow : green,
                    size: 21,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasAlerts
                            ? 'Risk conditions detected'
                            : 'No critical system issues',
                        style: const TextStyle(
                          color: white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        hasAlerts
                            ? '$highCount high-risk and '
                                '$criticalCount critical '
                                'record(s) found in latest data.'
                            : 'All core monitoring services are '
                                'operating normally.',
                        style: const TextStyle(
                          color: muted,
                          fontSize: 9,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),

                if (moderateCount > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: yellow.withOpacity(.08),
                      borderRadius:
                          BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$moderateCount MODERATE',
                      style: const TextStyle(
                        color: yellow,
                        fontSize: 7,
                        fontWeight: FontWeight.w900,
                      ),
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
  // QUICK SUMMARY
  // ============================================================

  Widget _buildSummary() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cyan.withOpacity(.075),
            panel.withOpacity(.92),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cyan.withOpacity(.17),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: cyan.withOpacity(.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.verified_rounded,
              color: cyan,
              size: 21,
            ),
          ),

          const SizedBox(width: 12),

          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'QUICK HEALTH SUMMARY',
                  style: TextStyle(
                    color: cyan,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .8,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'All core monitoring services are operational. '
                  'Latest motorway risk data has been successfully synchronized.',
                  style: TextStyle(
                    color: muted,
                    fontSize: 9,
                    height: 1.4,
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
  // COMMON PANEL
  // ============================================================

  Widget _panel({
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionHeading(
    IconData icon,
    String title,
    String subtitle,
  ) {
    return Row(
      children: [
        Container(
          width: 39,
          height: 39,
          decoration: BoxDecoration(
            color: cyan.withOpacity(.08),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: cyan.withOpacity(.12),
            ),
          ),
          child: Icon(
            icon,
            color: cyan,
            size: 19,
          ),
        ),

        const SizedBox(width: 11),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: white,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .35,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: muted2,
                  fontSize: 8,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// BACKGROUND GRID
// ============================================================================

class _SystemBackgroundPainter extends CustomPainter {
  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .45
      ..color = const Color(
        0xFF123149,
      ).withOpacity(.35);

    for (
      double y = 0;
      y < size.height;
      y += 80
    ) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }

    for (
      double x = 0;
      x < size.width;
      x += 100
    ) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant CustomPainter oldDelegate,
  ) {
    return false;
  }
}

// ============================================================================
// CHART GRID
// ============================================================================

class _ChartGridPainter extends CustomPainter {
  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final paint = Paint()
      ..color = const Color(
        0xFF1B3B55,
      ).withOpacity(.42)
      ..strokeWidth = .6;

    for (
      double y = 25;
      y < size.height;
      y += 35
    ) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }

    for (
      double x = 25;
      x < size.width;
      x += 50
    ) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant CustomPainter oldDelegate,
  ) {
    return false;
  }
}

// ============================================================================
// LIVE PULSE GRAPH
// ============================================================================

class _PulsePainter extends CustomPainter {
  final double animationValue;

  _PulsePainter({
    required this.animationValue,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final path = Path();

    final points = [
      const Offset(0, .62),
      const Offset(.06, .62),
      const Offset(.10, .45),
      const Offset(.14, .68),
      const Offset(.19, .52),
      const Offset(.24, .60),
      const Offset(.30, .30),
      const Offset(.34, .72),
      const Offset(.40, .58),
      const Offset(.47, .60),
      const Offset(.52, .42),
      const Offset(.56, .64),
      const Offset(.62, .51),
      const Offset(.68, .59),
      const Offset(.73, .25),
      const Offset(.77, .70),
      const Offset(.83, .54),
      const Offset(.90, .59),
      const Offset(.95, .38),
      const Offset(1, .57),
    ];

    for (int i = 0; i < points.length; i++) {
      final dx = points[i].dx * size.width;
      final dy = points[i].dy * size.height;

      if (i == 0) {
        path.moveTo(dx, dy);
      } else {
        path.lineTo(dx, dy);
      }
    }

    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..color = const Color(
        0xFF20D9FF,
      ).withOpacity(.08);

    canvas.drawPath(
      path,
      glowPaint,
    );

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = const Color(
        0xFF20D9FF,
      );

    canvas.drawPath(
      path,
      linePaint,
    );

    final scanX =
        ((animationValue * 1.15) % 1.0) *
        size.width;

    final scanPaint = Paint()
      ..color = const Color(
        0xFF67E8F9,
      ).withOpacity(.55)
      ..strokeWidth = 1.5;

    canvas.drawLine(
      Offset(scanX, 20),
      Offset(scanX, size.height - 15),
      scanPaint,
    );
  }

  @override
  bool shouldRepaint(
    covariant _PulsePainter oldDelegate,
  ) {
    return oldDelegate.animationValue !=
        animationValue;
  }
}

// ============================================================================
// UPTIME GRAPH
// ============================================================================

class _UptimePainter extends CustomPainter {
  final bool detailed;

  _UptimePainter({
    this.detailed = false,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final values = [
      .34,
      .45,
      .40,
      .58,
      .53,
      .70,
      .65,
      .76,
      .72,
      .82,
      .77,
      .86,
      .81,
      .90,
      .87,
      .94,
      .91,
      .96,
      .93,
      .97,
      .95,
      .98,
    ];

    final barWidth =
        size.width / values.length;

    final barPaint = Paint()
      ..color = const Color(
        0xFF20D9FF,
      ).withOpacity(.55);

    for (int i = 0; i < values.length; i++) {
      final barHeight =
          values[i] * size.height;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          i * barWidth + 2,
          size.height - barHeight,
          barWidth - 4,
          barHeight,
        ),
        const Radius.circular(4),
      );

      canvas.drawRRect(
        rect,
        barPaint,
      );
    }

    if (detailed) {
      final linePaint = Paint()
        ..color = const Color(
          0xFF67E8F9,
        )
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;

      final path = Path();

      for (int i = 0; i < values.length; i++) {
        final x =
            i * barWidth +
            barWidth / 2;

        final y =
            size.height -
            values[i] * size.height;

        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }

      canvas.drawPath(
        path,
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant CustomPainter oldDelegate,
  ) {
    return false;
  }
}

// ============================================================================
// RISK DONUT
// ============================================================================

class _RiskDonutPainter extends CustomPainter {
  final int safe;
  final int moderate;
  final int high;
  final int critical;

  _RiskDonutPainter({
    required this.safe,
    required this.moderate,
    required this.high,
    required this.critical,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final total =
        safe +
        moderate +
        high +
        critical;

    final center = Offset(
      size.width / 2,
      size.height / 2,
    );

    final radius =
        size.shortestSide / 2 - 14;

    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round
      ..color = const Color(
        0xFF1B3B55,
      );

    canvas.drawCircle(
      center,
      radius,
      basePaint,
    );

    if (total == 0) {
      return;
    }

    final data = [
      (
        safe,
        const Color(0xFF22C55E),
      ),
      (
        moderate,
        const Color(0xFFF59E0B),
      ),
      (
        high,
        const Color(0xFFEF4444),
      ),
      (
        critical,
        const Color(0xFFFF3B81),
      ),
    ];

    double startAngle =
        -1.5708;

    for (final item in data) {
      final value = item.$1;

      if (value == 0) {
        continue;
      }

      final sweep =
          (value / total) * 6.28318;

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16
        ..strokeCap = StrokeCap.round
        ..color = item.$2;

      canvas.drawArc(
        Rect.fromCircle(
          center: center,
          radius: radius,
        ),
        startAngle,
        sweep - .035,
        false,
        paint,
      );

      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(
    covariant _RiskDonutPainter oldDelegate,
  ) {
    return oldDelegate.safe != safe ||
        oldDelegate.moderate != moderate ||
        oldDelegate.high != high ||
        oldDelegate.critical != critical;
  }
}

// ============================================================================
// MOTORWAY NETWORK LINE
// ============================================================================

class _NetworkLinePainter extends CustomPainter {
  final Color color;

  _NetworkLinePainter({
    required this.color,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final paint = Paint()
      ..color = color.withOpacity(.28)
      ..strokeWidth = 2;

    final y = size.height / 2;

    canvas.drawLine(
      Offset(12, y),
      Offset(size.width - 12, y),
      paint,
    );

    final nodePaint = Paint()
      ..color = color.withOpacity(.25)
      ..style = PaintingStyle.fill;

    for (final x in [
      size.width * .25,
      size.width * .50,
      size.width * .75,
    ]) {
      canvas.drawCircle(
        Offset(x, y),
        3,
        nodePaint,
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant _NetworkLinePainter oldDelegate,
  ) {
    return oldDelegate.color != color;
  }
}