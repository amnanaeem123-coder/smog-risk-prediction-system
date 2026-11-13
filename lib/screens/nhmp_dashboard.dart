import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'login_page.dart';

import 'user_dashboard.dart';
class NHMPDashboard extends StatefulWidget {
  final bool isOpenedFromAdmin;

  const NHMPDashboard({
    super.key,
    this.isOpenedFromAdmin = false,
  });

  @override
  State<NHMPDashboard> createState() => _NHMPDashboardState();
}


class _NHMPDashboardState extends State<NHMPDashboard>
    with TickerProviderStateMixin {
  // ============================================================
  // DATA
  // ============================================================

  List<dynamic> riskData = [];

  bool isLoading = true;
  String? errorMessage;

  int selectedMenu = 0;
  DateTime? lastUpdated;

  // LIVE SERVER (same as User Dashboard)
  static const String _liveUrl = 'http://localhost:5000/latest';
  String _dataSource = 'Offline file';
  Timer? _autoRefreshTimer;

  // ============================================================
  // SCROLL / SECTION KEYS
  // ============================================================

  final ScrollController _scrollController = ScrollController();

  final GlobalKey overviewKey = GlobalKey();
  final GlobalKey locationsKey = GlobalKey();
  final GlobalKey alertsKey = GlobalKey();
  final GlobalKey analysisKey = GlobalKey();

  // ============================================================
  // ANIMATIONS
  // ============================================================

  late AnimationController _pageController;
  late AnimationController _chartController;
  late AnimationController _refreshController;
  late AnimationController _pulseController;

  // ============================================================
  // PROFESSIONAL NHMP THEME
  // ============================================================

  static const Color background = Color(0xff06111F);
  static const Color background2 = Color(0xff091827);
  static const Color sidebarColor = Color(0xff071522);

  static const Color cardColor = Color(0xff0C1D2E);


  static const Color cyan = Color(0xff25C7E8);
  static const Color blue = Color(0xff238BE8);

  static const Color safeColor = Color(0xff32C66B);
  static const Color lowColor = Color(0xff8CC63F);
  static const Color moderateColor = Color(0xffF5B82E);
  static const Color highColor = Color(0xffFF922E);
  static const Color criticalColor = Color(0xffF04B4B);

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _pageController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _chartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _refreshController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat(reverse: true);

    loadRiskData();

    // Ask the live server again every 5 minutes.
    _autoRefreshTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => loadRiskData(),
    );
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _scrollController.dispose();
    _pageController.dispose();
    _chartController.dispose();
    _refreshController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOAD BACKEND / JSON DATA
  // ============================================================

  Future<void> loadRiskData() async {
    // Full loading screen only the first time.
    // Later refreshes update the data quietly.
    final firstLoad = riskData.isEmpty;

    if (mounted && firstLoad) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }

    _refreshController.forward(from: 0);

    List<dynamic> list = [];
    String source = 'Offline file';

    // 1. Try the live server first.
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
      // Server is off. Use the saved file below.
    }

    // 2. If the server did not answer, use the saved file.
    if (list.isEmpty) {
      try {
        final jsonString = await rootBundle.loadString(
          'assets/data/latest_risk.json',
        );
        final decoded = json.decode(jsonString);
        list = decoded is List ? decoded : [];
      } catch (_) {
        list = [];
      }
    }

    if (!mounted) return;

    if (list.isNotEmpty) {
      setState(() {
        riskData = list;
        _dataSource = source;
        isLoading = false;
        errorMessage = null;
        lastUpdated = DateTime.now();
      });

      if (firstLoad) {
        _pageController.forward(from: 0);
        _chartController.forward(from: 0);
      }
    } else if (firstLoad) {
      setState(() {
        riskData = [];
        isLoading = false;
        errorMessage = "Unable to load risk data.";
      });
    }
  }

  // ============================================================
  // SAFE DATA HELPERS
  // ============================================================

  String valueOf(
    dynamic item,
    List<String> keys, [
    String fallback = "--",
  ]) {
    if (item is! Map) return fallback;

    for (final key in keys) {
      final value = item[key];

      if (value != null &&
          value.toString().trim().isNotEmpty &&
          value.toString() != "null") {
        return value.toString();
      }
    }

    return fallback;
  }

  double numberOf(
    dynamic item,
    List<String> keys, [
    double fallback = 0,
  ]) {
    final text = valueOf(item, keys, "");

    if (text.isEmpty) return fallback;

    return double.tryParse(
          text.replaceAll(RegExp(r'[^0-9.\-]'), ''),
        ) ??
        fallback;
  }

  String cityOf(dynamic item) {
    return valueOf(
      item,
      ['city', 'location', 'name'],
      'Unknown Location',
    );
  }

  String riskOf(dynamic item) {
    return valueOf(
      item,
      ['risk_level', 'risk', 'riskLevel'],
      'SAFE',
    ).toUpperCase();
  }

  double visibilityOf(dynamic item) {
    return numberOf(
      item,
      ['visibility_km', 'visibility', 'visibilityKm'],
    );
  }

  String recommendationOf(dynamic item) {
    return valueOf(
      item,
      ['recommendation', 'action', 'advice'],
      'No recommendation available.',
    );
  }

  // ============================================================
  // RISK HELPERS
  // ============================================================

  Color riskColor(String risk) {
    switch (risk.toUpperCase()) {
      case "CRITICAL":
        return criticalColor;
      case "HIGH":
        return highColor;
      case "MODERATE":
        return moderateColor;
      case "LOW":
        return lowColor;
      case "SAFE":
      default:
        return safeColor;
    }
  }

  IconData riskIcon(String risk) {
    switch (risk.toUpperCase()) {
      case "CRITICAL":
        return Icons.gpp_maybe_rounded;
      case "HIGH":
        return Icons.warning_rounded;
      case "MODERATE":
        return Icons.warning_amber_rounded;
      case "LOW":
        return Icons.remove_circle_outline_rounded;
      case "SAFE":
      default:
        return Icons.verified_rounded;
    }
  }

  // ============================================================
  // COUNTS
  // ============================================================

  int get safeCount {
    return riskData.where(
      (item) => riskOf(item) == "SAFE",
    ).length;
  }

  int get lowCount {
    return riskData.where(
      (item) => riskOf(item) == "LOW",
    ).length;
  }

  int get moderateCount {
    return riskData.where(
      (item) => riskOf(item) == "MODERATE",
    ).length;
  }

  int get highCount {
    return riskData.where(
      (item) => riskOf(item) == "HIGH",
    ).length;
  }

  int get criticalCount {
    return riskData.where(
      (item) => riskOf(item) == "CRITICAL",
    ).length;
  }

  int get alertCount => highCount + criticalCount;

  int get attentionCount =>
      moderateCount + highCount + criticalCount;

  double get averageVisibility {
    if (riskData.isEmpty) return 0;

    double total = 0;

    for (final item in riskData) {
      total += visibilityOf(item);
    }

    return total / riskData.length;
  }

  double get safeCoverage {
    if (riskData.isEmpty) return 0;

    return (safeCount / riskData.length) * 100;
  }

  dynamic get lowestVisibilityItem {
    if (riskData.isEmpty) return null;

    dynamic lowest = riskData.first;

    for (final item in riskData.skip(1)) {
      if (visibilityOf(item) < visibilityOf(lowest)) {
        lowest = item;
      }
    }

    return lowest;
  }

  dynamic get highestVisibilityItem {
    if (riskData.isEmpty) return null;

    dynamic highest = riskData.first;

    for (final item in riskData.skip(1)) {
      if (visibilityOf(item) > visibilityOf(highest)) {
        highest = item;
      }
    }

    return highest;
  }

  List<dynamic> get alertItems {
    return riskData.where((item) {
      final risk = riskOf(item);

      return risk == "HIGH" || risk == "CRITICAL";
    }).toList();
  }

  String get overallStatus {
    if (criticalCount > 0) return "CRITICAL";
    if (highCount > 0) return "HIGH";
    if (moderateCount > 0) return "MODERATE";

    return "NORMAL";
  }

  Color get overallStatusColor {
    switch (overallStatus) {
      case "CRITICAL":
        return criticalColor;
      case "HIGH":
        return highColor;
      case "MODERATE":
        return moderateColor;
      default:
        return safeColor;
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: isLoading
          ? buildLoading()
          : errorMessage != null
              ? buildError()
              : LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 900) {
                      return buildMobileDashboard();
                    }

                    return buildDesktopDashboard();
                  },
                ),
    );
  }

  // ============================================================
  // LOADING SCREEN
  // ============================================================

  Widget buildLoading() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            background,
            background2,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cyan.withAlpha(15),
                border: Border.all(
                  color: cyan.withAlpha(60),
                ),
                boxShadow: [
                  BoxShadow(
                    color: cyan.withAlpha(35),
                    blurRadius: 35,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: cyan,
                ),
              ),
            ),
            const SizedBox(height: 25),
            const Text(
              "NHMP CONTROL CENTER",
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Loading motorway risk intelligence...",
              style: TextStyle(
                color: Colors.white.withAlpha(100),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ERROR SCREEN
  // ============================================================

  Widget buildError() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            background,
            background2,
          ],
        ),
      ),
      child: Center(
        child: Container(
          width: 430,
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: criticalColor.withAlpha(45),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: criticalColor.withAlpha(15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.cloud_off_rounded,
                  color: criticalColor,
                  size: 32,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                "Monitoring Data Unavailable",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                errorMessage ??
                    "Unable to load monitoring data.",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: loadRiskData,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text("Retry"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ANIMATED SECTION
  // ============================================================

  Widget animatedSection({
    required Widget child,
    double begin = 25,
  }) {
    return AnimatedBuilder(
      animation: _pageController,
      builder: (context, _) {
        final progress =
            Curves.easeOutCubic.transform(
          _pageController.value,
        );

        return Opacity(
          opacity: progress.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(
              0,
              begin * (1 - progress),
            ),
            child: child,
          ),
        );
      },
    );
  }

  // ============================================================
  // SCROLL NAVIGATION
  // ============================================================

  void scrollToSection(
  GlobalKey key,
  int index,
) {
  setState(() {
    selectedMenu = index;
  });

  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) return;

    final targetContext = key.currentContext;

    if (targetContext == null) return;

    Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
      alignment: 0.04,
    );
  });
}

  // ============================================================
  // DESKTOP DASHBOARD
  // ============================================================

  Widget buildDesktopDashboard() {
    return Row(
      children: [
        buildSidebar(),
        Expanded(
          child: SafeArea(
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                30,
                24,
                30,
                50,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [

KeyedSubtree(
  key: overviewKey,
  child: animatedSection(
    child: buildTopHeader(),
  ),
),
const SizedBox(height: 14),

// OPEN USER DASHBOARD BUTTON
Align(
  alignment: Alignment.centerLeft,
  child: OutlinedButton.icon(
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const UserDashboard(
            isOpenedFromNHMP: true,
          ),
        ),
      );
    },
    icon: const Icon(
      Icons.person_outline_rounded,
      color: cyan,
    ),
    label: const Text(
      'Open User Dashboard',
      style: TextStyle(
        color: cyan,
        fontWeight: FontWeight.w700,
      ),
    ),
    style: OutlinedButton.styleFrom(
      side: BorderSide(
        color: cyan.withAlpha(90),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 14,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
),

const SizedBox(height: 18),
animatedSection(
  begin: 20,
  child: buildSystemStatusBanner(),
),

                  const SizedBox(height: 16),
                  animatedSection(
                    begin: 25,
                    child: buildSummaryCards(),
                  ),
                  const SizedBox(height: 20),
                  animatedSection(
                    begin: 30,
                    child: buildHeroInsight(),
                  ),
                  const SizedBox(height: 20),
                  animatedSection(
                    begin: 35,
                    child: buildMainAnalytics(),
                  ),
                  const SizedBox(height: 20),
                  KeyedSubtree(
                    key: locationsKey,
                    child: animatedSection(
                      begin: 40,
                      child: buildLocationMonitoring(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  KeyedSubtree(
                    key: alertsKey,
                    child: animatedSection(
                      begin: 45,
                      child: buildAlertSection(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  KeyedSubtree(
                    key: analysisKey,
                    child: animatedSection(
                      begin: 50,
                      child: buildOperationalAnalysis(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  animatedSection(
                    begin: 55,
                    child: buildThresholds(),
                  ),
                  const SizedBox(height: 24),
                  buildFooter(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SIDEBAR
  // ============================================================

  Widget buildSidebar() {
    return Container(
      width: 255,
      decoration: BoxDecoration(
        color: sidebarColor,
        border: Border(
          right: BorderSide(
            color: Colors.white.withAlpha(12),
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            19,
            22,
            19,
            18,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 47,
                    height: 47,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          cyan.withAlpha(40),
                          blue.withAlpha(20),
                        ],
                      ),
                      borderRadius:
                          BorderRadius.circular(13),
                      border: Border.all(
                        color: cyan.withAlpha(55),
                      ),
                    ),
                    child: const Icon(
                      Icons.cloud_outlined,
                      color: cyan,
                      size: 25,
                    ),
                  ),
                  const SizedBox(width: 11),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          "SMOG RISK",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          "PREDICTION SYSTEM",
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 7,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 38),
              const Text(
                "NHMP OPERATIONS",
                style: TextStyle(
                  color: Colors.white30,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              sidebarItem(
                Icons.dashboard_rounded,
                "Overview",
                0,
                overviewKey,
              ),
              sidebarItem(
                Icons.route_rounded,
                "Motorway Monitoring",
                1,
                locationsKey,
              ),
              sidebarItem(
                Icons.notifications_active_outlined,
                "Risk Alerts",
                2,
                alertsKey,
              ),
              sidebarItem(
                Icons.analytics_outlined,
                "Risk Analysis",
                3,
                analysisKey,
              ),
              const SizedBox(height: 14),
              Container(
                height: 1,
                color: Colors.white.withAlpha(10),
              ),
              const SizedBox(height: 16),
              buildSidebarNetworkStatus(),
              const Spacer(),
              buildOfficerCard(),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SIDEBAR ITEM
  // ============================================================

  Widget sidebarItem(
    IconData icon,
    String title,
    int index,
    GlobalKey targetKey,
  ) {
    final selected = selectedMenu == index;

    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          borderRadius: BorderRadius.circular(11),
          onTap: () {
            scrollToSection(
              targetKey,
              index,
            );
          },
          hoverColor: cyan.withAlpha(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.symmetric(
              horizontal: 11,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: selected
                  ? cyan.withAlpha(20)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color: selected
                    ? cyan.withAlpha(35)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration:
                      const Duration(milliseconds: 220),
                  width: 3,
                  height: selected ? 19 : 0,
                  decoration: BoxDecoration(
                    color: cyan,
                    borderRadius:
                        BorderRadius.circular(5),
                  ),
                ),
                if (selected)
                  const SizedBox(width: 8),
                Icon(
                  icon,
                  size: 18,
                  color: selected
                      ? cyan
                      : Colors.white38,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: selected
                          ? Colors.white
                          : Colors.white54,
                      fontSize: 10,
                      fontWeight: selected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ),
                if (selected)
                  Container(
                    width: 5,
                    height: 5,
                    decoration:
                        const BoxDecoration(
                      color: cyan,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SIDEBAR NETWORK STATUS
  // ============================================================

  Widget buildSidebarNetworkStatus() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: safeColor.withAlpha(7),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: safeColor.withAlpha(23),
        ),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final size =
                  9 + (_pulseController.value * 2);

              return Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: safeColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: safeColor.withAlpha(
                        45 +
                            (_pulseController.value * 45)
                                .round(),
                      ),
                      blurRadius: 8,
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  "SYSTEM ONLINE",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  "Source: $_dataSource",
                  style: TextStyle(
                    color: _dataSource == 'Live server'
                        ? safeColor
                        : moderateColor,
                    fontSize: 8,
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
  // OFFICER CARD
  // ============================================================

  Widget buildOfficerCard() {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: Colors.white.withAlpha(12),
        ),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: Color(0xff173A55),
            child: Icon(
              Icons.shield_outlined,
              color: cyan,
              size: 18,
            ),
          ),
          SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  "NHMP Officer",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  "Control Center",
                  style: TextStyle(
                    color: Colors.white30,
                    fontSize: 8,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.verified_rounded,
            color: safeColor,
            size: 15,
          ),
        ],
      ),
    );
  }
    // ============================================================
  // TOP HEADER
  // ============================================================

  Widget buildTopHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      "Motorway Safety Intelligence",
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 27,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  buildLiveBadge(),
                ],
              ),
              const SizedBox(height: 7),
              Text(
                "NHMP operational dashboard for motorway visibility and smog-risk monitoring",
                style: TextStyle(
                  color: Colors.white.withAlpha(105),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        buildLastSync(),
        const SizedBox(width: 10),
        buildRefreshButton(),
        const SizedBox(width: 10),
        buildHeaderOfficer(),
      ],
    );
  }

  Widget buildLiveBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: safeColor.withAlpha(13),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: safeColor.withAlpha(35),
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.circle,
            color: safeColor,
            size: 6,
          ),
          SizedBox(width: 5),
          Text(
            "LIVE",
            style: TextStyle(
              color: safeColor,
              fontSize: 7,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildLastSync() {
    final time = lastUpdated == null
        ? "--:--"
        : _formatTime(lastUpdated!);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withAlpha(14),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.sync_rounded,
            color: Colors.white38,
            size: 15,
          ),
          const SizedBox(width: 7),
          Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                "LAST SYNC",
                style: TextStyle(
                  color: Colors.white30,
                  fontSize: 6,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .8,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                time,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour == 0
        ? 12
        : dateTime.hour > 12
            ? dateTime.hour - 12
            : dateTime.hour;

    final minute =
        dateTime.minute.toString().padLeft(2, '0');

    final period =
        dateTime.hour >= 12 ? "PM" : "AM";

    return "$hour:$minute $period";
  }

  Widget buildRefreshButton() {
    return AnimatedBuilder(
      animation: _refreshController,
      builder: (context, child) {
        return Transform.rotate(
          angle:
              _refreshController.value * 6.283185,
          child: child,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.white.withAlpha(16),
          ),
        ),
        child: IconButton(
          tooltip: "Refresh data",
          onPressed: loadRiskData,
          icon: const Icon(
            Icons.refresh_rounded,
            color: cyan,
            size: 19,
          ),
        ),
      ),
    );
  }

  Widget buildHeaderOfficer() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withAlpha(16),
        ),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: Color(0xff173A55),
            child: Icon(
              Icons.shield_outlined,
              color: cyan,
              size: 16,
            ),
          ),
          SizedBox(width: 8),
          Text(
            "NHMP Officer",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SYSTEM STATUS
  // ============================================================

  Widget buildSystemStatusBanner() {
    final hasAlerts = alertCount > 0;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 17,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cardColor,
            overallStatusColor.withAlpha(10),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: overallStatusColor.withAlpha(32),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color:
                  overallStatusColor.withAlpha(17),
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasAlerts
                  ? Icons.warning_amber_rounded
                  : Icons.verified_rounded,
              color: overallStatusColor,
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
                  hasAlerts
                      ? "Operational Attention Required"
                      : "Monitoring Network Operating Normally",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  hasAlerts
                      ? "$alertCount high/critical location(s) require operational review."
                      : "All monitored locations are currently being tracked by the system.",
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 8,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 11,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color:
                  overallStatusColor.withAlpha(14),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                color:
                    overallStatusColor.withAlpha(24),
              ),
            ),
            child: Text(
              overallStatus,
              style: TextStyle(
                color: overallStatusColor,
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: .6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SUMMARY CARDS
  // ============================================================

  Widget buildSummaryCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width =
            (constraints.maxWidth - 48) / 4;

        return Row(
          children: [
            SizedBox(
              width: width,
              child: kpiCard(
                title: "MONITORED LOCATIONS",
                value: riskData.length.toString(),
                subtitle: "Active monitoring points",
                icon: Icons.radar_rounded,
                color: cyan,
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: width,
              child: kpiCard(
                title: "ACTIVE ALERTS",
                value: alertCount.toString(),
                subtitle: "High / critical risk",
                icon:
                    Icons.notifications_active_outlined,
                color: alertCount > 0
                    ? criticalColor
                    : safeColor,
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: width,
              child: kpiCard(
                title: "AVG VISIBILITY",
                value:
                    "${averageVisibility.toStringAsFixed(1)} km",
                subtitle: "Across all locations",
                icon: Icons.visibility_outlined,
                color: cyan,
                isDecimal: true,
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: width,
              child: kpiCard(
                title: "SAFE COVERAGE",
                value:
                    "${safeCoverage.toStringAsFixed(0)}%",
                subtitle: "$safeCount safe locations",
                icon: Icons.verified_rounded,
                color: safeColor,
                isDecimal: true,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget kpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    bool isDecimal = false,
  }) {
    return HoverCard(
      color: cardColor,
      borderColor: color.withAlpha(32),
      radius: 15,
      child: Container(
        height: 160,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 37,
                  height: 37,
                  decoration: BoxDecoration(
                    color: color.withAlpha(17),
                    borderRadius:
                        BorderRadius.circular(9),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 18,
                  ),
                ),
                const Spacer(),
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white30,
                fontSize: 7,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.end,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(
                    begin: 0,
                    end: isDecimal
                        ? _numericValue(value)
                        : double.tryParse(value) ?? 0,
                  ),
                  duration: const Duration(
                    milliseconds: 1000,
                  ),
                  curve: Curves.easeOutCubic,
                  builder:
                      (context, animated, _) {
                    String display;

                    if (value.contains("%")) {
                      display =
                          "${animated.round()}%";
                    } else if (value.contains("km")) {
                      display =
                          "${animated.toStringAsFixed(1)} km";
                    } else {
                      display =
                          animated.round().toString();
                    }

                    return Text(
                      display,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.6,
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                color: Colors.white30,
                fontSize: 7,
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _numericValue(String value) {
    return double.tryParse(
          value.replaceAll(
            RegExp(r'[^0-9.]'),
            '',
          ),
        ) ??
        0;
  }

  // ============================================================
  // HERO INSIGHT
  // ============================================================

  Widget buildHeroInsight() {
    final lowest = lowestVisibilityItem;
    final highest = highestVisibilityItem;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xff0B2134),
            Color(0xff0B1928),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cyan.withAlpha(22),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: cyan.withAlpha(13),
              borderRadius:
                  BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.insights_rounded,
              color: cyan,
              size: 21,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  "OPERATIONAL SNAPSHOT",
                  style: TextStyle(
                    color: cyan,
                    fontSize: 7,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  alertCount == 0
                      ? "All monitored motorway points are currently within the active observation range."
                      : "$attentionCount location(s) are outside the normal safe operating category and require monitoring.",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (lowest != null) ...[
            const SizedBox(width: 25),
            buildSnapshotMetric(
              "LOWEST VISIBILITY",
              "${visibilityOf(lowest).toStringAsFixed(1)} km",
              cityOf(lowest),
              criticalColor,
            ),
          ],
          const SizedBox(width: 25),
          if (highest != null)
            buildSnapshotMetric(
              "BEST VISIBILITY",
              "${visibilityOf(highest).toStringAsFixed(1)} km",
              cityOf(highest),
              safeColor,
            ),
        ],
      ),
    );
  }

  Widget buildSnapshotMetric(
    String label,
    String value,
    String location,
    Color color,
  ) {
    return Container(
      constraints: const BoxConstraints(
        minWidth: 135,
      ),
      padding:
          const EdgeInsets.only(left: 18),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: Colors.white.withAlpha(12),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white30,
              fontSize: 6,
              fontWeight: FontWeight.w900,
              letterSpacing: .8,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            location,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 7,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MAIN ANALYTICS
  // ============================================================

  Widget buildMainAnalytics() {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 6,
          child: buildVisibilityChart(),
        ),
        const SizedBox(width: 18),
        Expanded(
          flex: 4,
          child: buildRiskOverview(),
        ),
      ],
    );
  }

  // ============================================================
  // VISIBILITY CHART
  // ============================================================

  Widget buildVisibilityChart() {
    return HoverCard(
      color: cardColor,
      borderColor: cyan.withAlpha(25),
      radius: 17,
      child: Container(
        height: 365,
        padding: const EdgeInsets.fromLTRB(
          20,
          18,
          20,
          15,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                buildSectionIcon(
                  Icons.bar_chart_rounded,
                  cyan,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Visibility Intelligence",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        "Current visibility by monitored location",
                        style: TextStyle(
                          color: Colors.white30,
                          fontSize: 8,
                        ),
                      ),
                    ],
                  ),
                ),
                buildMiniMetric(
                  Icons.visibility_outlined,
                  "${averageVisibility.toStringAsFixed(1)} km",
                  cyan,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                buildLegendDot(
                  safeColor,
                  "Safe",
                ),
                const SizedBox(width: 12),
                buildLegendDot(
                  moderateColor,
                  "Moderate",
                ),
                const SizedBox(width: 12),
                buildLegendDot(
                  highColor,
                  "High",
                ),
                const SizedBox(width: 12),
                buildLegendDot(
                  criticalColor,
                  "Critical",
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: riskData.isEmpty
                  ? const Center(
                      child: Text(
                        "No visibility data available",
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 10,
                        ),
                      ),
                    )
                  : AnimatedBuilder(
                      animation: _chartController,
                      builder: (context, _) {
                        return CustomPaint(
                          painter:
                              VisibilityChartPainter(
                            data: riskData,
                            animationValue:
                                Curves.easeOutCubic
                                    .transform(
                              _chartController.value,
                            ),
                          ),
                          child:
                              const SizedBox.expand(),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSectionIcon(
    IconData icon,
    Color color,
  ) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: color.withAlpha(14),
        borderRadius:
            BorderRadius.circular(9),
      ),
      child: Icon(
        icon,
        color: color,
        size: 18,
      ),
    );
  }

  Widget buildMiniMetric(
    IconData icon,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(13),
        borderRadius:
            BorderRadius.circular(8),
        border: Border.all(
          color: color.withAlpha(22),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 13,
          ),
          const SizedBox(width: 5),
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
    );
  }

  Widget buildLegendDot(
    Color color,
    String label,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 7,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // RISK OVERVIEW
  // ============================================================

  Widget buildRiskOverview() {
    return HoverCard(
      color: cardColor,
      borderColor: criticalColor.withAlpha(23),
      radius: 17,
      child: Container(
        height: 365,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                buildSectionIcon(
                  Icons.donut_large_rounded,
                  criticalColor,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Risk Distribution",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        "Current classification profile",
                        style: TextStyle(
                          color: Colors.white30,
                          fontSize: 8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

Expanded(
  child: LayoutBuilder(
    builder: (context, constraints) {
      final chartSize =
          (constraints.maxWidth * 0.42).clamp(100.0, 145.0);

      return Row(
        children: [
          SizedBox(
            width: chartSize,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: Size(chartSize, chartSize),
                  painter: RiskDonutPainter(
                    safe: safeCount,
                    low: lowCount,
                    moderate: moderateCount,
                    high: highCount,
                    critical: criticalCount,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      riskData.length.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Text(
                      "LOCATIONS",
                      style: TextStyle(
                        color: Colors.white30,
                        fontSize: 6,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .8,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                riskProgress("SAFE", safeCount, safeColor),
                riskProgress("LOW", lowCount, lowColor),
                riskProgress("MODERATE", moderateCount, moderateColor),
                riskProgress("HIGH", highCount, highColor),
                riskProgress("CRITICAL", criticalCount, criticalColor),
              ],
            ),
          ),
        ],
      );
    },

  ),
),

          ],
        ),
      ),
    );
  }

  // ============================================================
  // RISK PROGRESS
  // ============================================================

  Widget riskProgress(
    String label,
    int count,
    Color color,
  ) {
    final total =
        riskData.isEmpty ? 1 : riskData.length;

    final percentage = count / total;

    return Padding(
      padding:
          const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 7,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child:
                TweenAnimationBuilder<double>(
              tween: Tween<double>(
                begin: 0,
                end: percentage,
              ),
              duration: const Duration(
                milliseconds: 1100,
              ),
              curve: Curves.easeOutCubic,
              builder:
                  (context, value, _) {
                return ClipRRect(
                  borderRadius:
                      BorderRadius.circular(20),
                  child:
                      LinearProgressIndicator(
                    value: value,
                    minHeight: 6,
                    backgroundColor:
                        Colors.white.withAlpha(9),
                    valueColor:
                        AlwaysStoppedAnimation<
                            Color>(
                      color,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 22,
            child: Text(
              count.toString(),
              textAlign: TextAlign.right,
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
    // ============================================================
  // LOCATION MONITORING
  // ============================================================

  Widget buildLocationMonitoring() {
    return HoverCard(
      color: cardColor,
      borderColor: blue.withAlpha(25),
      radius: 17,
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            buildLocationHeader(),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(5),
                borderRadius:
                    BorderRadius.circular(9),
              ),
              child: const Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      "LOCATION",
                      style: TextStyle(
                        color: Colors.white30,
                        fontSize: 7,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      "RISK STATUS",
                      style: TextStyle(
                        color: Colors.white30,
                        fontSize: 7,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      "VISIBILITY",
                      style: TextStyle(
                        color: Colors.white30,
                        fontSize: 7,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Text(
                      "RECOMMENDATION",
                      style: TextStyle(
                        color: Colors.white30,
                        fontSize: 7,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 55,
                    child: Text(
                      "VIEW",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white30,
                        fontSize: 7,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 5),
            ...riskData.map(
              (item) => buildLocationRow(item),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildLocationHeader() {
    return Row(
      children: [
        buildSectionIcon(
          Icons.route_rounded,
          blue,
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                "Motorway Location Monitoring",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 3),
              Text(
                "Live visibility and risk status across monitored points",
                style: TextStyle(
                  color: Colors.white30,
                  fontSize: 8,
                ),
              ),
            ],
          ),
        ),
        buildMiniMetric(
          Icons.radar_rounded,
          "${riskData.length} MONITORED",
          safeColor,
        ),
      ],
    );
  }

  // ============================================================
  // LOCATION ROW
  // ============================================================

  Widget buildLocationRow(dynamic item) {
    final city = cityOf(item);
    final risk = riskOf(item);
    final visibility = visibilityOf(item);
    final recommendation =
        recommendationOf(item);
    final color = riskColor(risk);

    return Padding(
      padding:
          const EdgeInsets.only(top: 5),
      child: HoverCard(
        color: Colors.white.withAlpha(3),
        borderColor: color.withAlpha(28),
        radius: 11,
        child: InkWell(
          borderRadius:
              BorderRadius.circular(11),
          onTap: () =>
              showLocationDetails(item),
          child: Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 11,
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color:
                              color.withAlpha(17),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.location_on_outlined,
                          color: color,
                          size: 17,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          city,
                          style:
                              const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight:
                                FontWeight.w700,
                          ),
                          overflow:
                              TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child:
                      buildRiskBadge(risk),
                ),
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      const Icon(
                        Icons
                            .visibility_outlined,
                        color:
                            Colors.white30,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "${visibility.toStringAsFixed(1)} km",
                        style:
                            const TextStyle(
                          color:
                              Colors.white70,
                          fontSize: 9,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Text(
                    recommendation,
                    style:
                        const TextStyle(
                      color:
                          Colors.white54,
                      fontSize: 8,
                      height: 1.35,
                    ),
                    maxLines: 2,
                    overflow:
                        TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(
                  width: 55,
                  child: Center(
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration:
                          BoxDecoration(
                        color:
                            cyan.withAlpha(10),
                        borderRadius:
                            BorderRadius.circular(
                          8,
                        ),
                        border: Border.all(
                          color:
                              cyan.withAlpha(18),
                        ),
                      ),
                      child: const Icon(
                        Icons
                            .arrow_forward_rounded,
                        color: cyan,
                        size: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildRiskBadge(String risk) {
    final color = riskColor(risk);

    return Row(
      children: [
        Icon(
          riskIcon(risk),
          color: color,
          size: 15,
        ),
        const SizedBox(width: 7),
        Container(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 7,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: color.withAlpha(15),
            borderRadius:
                BorderRadius.circular(5),
          ),
          child: Text(
            risk,
            style: TextStyle(
              color: color,
              fontSize: 7,
              fontWeight:
                  FontWeight.w900,
              letterSpacing: .3,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // LOCATION DETAILS
  // ============================================================

  void showLocationDetails(
    dynamic item,
  ) {
    final city = cityOf(item);
    final risk = riskOf(item);
    final visibility =
        visibilityOf(item);
    final recommendation =
        recommendationOf(item);
    final color = riskColor(risk);

    final pm25 = valueOf(
      item,
      [
        'pm25',
        'pm2_5',
        'PM2.5',
        'PM25',
      ],
    );

    final pm10 = valueOf(
      item,
      [
        'pm10',
        'PM10',
      ],
    );

    final temperature = valueOf(
      item,
      [
        'temperature',
        'temp',
        'temperature_c',
      ],
    );

    final humidity = valueOf(
      item,
      [
        'humidity',
        'humidity_percent',
      ],
    );

    final wind = valueOf(
      item,
      [
        'wind',
        'wind_speed',
        'wind_speed_kmh',
      ],
    );

    final hasExtraData =
        pm25 != "--" ||
        pm10 != "--" ||
        temperature != "--" ||
        humidity != "--" ||
        wind != "--";

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor:
              Colors.transparent,
          insetPadding:
              const EdgeInsets.all(20),
          child: Container(
            width: 560,
            constraints:
                const BoxConstraints(
              maxHeight: 650,
            ),
            padding:
                const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color:
                  const Color(0xff0B1D2E),
              borderRadius:
                  BorderRadius.circular(20),
              border: Border.all(
                color: color.withAlpha(40),
              ),
              boxShadow: [
                BoxShadow(
                  color:
                      Colors.black.withAlpha(
                    90,
                  ),
                  blurRadius: 35,
                ),
              ],
            ),
            child:
                SingleChildScrollView(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration:
                            BoxDecoration(
                          color:
                              color.withAlpha(
                            18,
                          ),
                          borderRadius:
                              BorderRadius
                                  .circular(
                            12,
                          ),
                        ),
                        child: Icon(
                          riskIcon(risk),
                          color: color,
                          size: 23,
                        ),
                      ),
                      const SizedBox(
                        width: 12,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            const Text(
                              "LOCATION INTELLIGENCE",
                              style:
                                  TextStyle(
                                color:
                                    cyan,
                                fontSize: 7,
                                fontWeight:
                                    FontWeight
                                        .w900,
                                letterSpacing:
                                    1.2,
                              ),
                            ),
                            const SizedBox(
                              height: 4,
                            ),
                            Text(
                              city,
                              style:
                                  const TextStyle(
                                color:
                                    Colors
                                        .white,
                                fontSize: 19,
                                fontWeight:
                                    FontWeight
                                        .w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () =>
                            Navigator.pop(
                          dialogContext,
                        ),
                        icon:
                            const Icon(
                          Icons.close_rounded,
                          color:
                              Colors.white54,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child:
                            detailMetric(
                          "RISK LEVEL",
                          risk,
                          riskIcon(risk),
                          color,
                        ),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        child:
                            detailMetric(
                          "VISIBILITY",
                          "${visibility.toStringAsFixed(1)} km",
                          Icons
                              .visibility_outlined,
                          cyan,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                  if (hasExtraData)
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        if (pm25 != "--")
                          smallDataTile(
                            "PM2.5",
                            pm25,
                            Icons.air_rounded,
                          ),
                        if (pm10 != "--")
                          smallDataTile(
                            "PM10",
                            pm10,
                            Icons.blur_on_rounded,
                          ),
                        if (temperature !=
                            "--")
                          smallDataTile(
                            "TEMPERATURE",
                            temperature,
                            Icons
                                .thermostat_outlined,
                          ),
                        if (humidity != "--")
                          smallDataTile(
                            "HUMIDITY",
                            humidity,
                            Icons
                                .water_drop_outlined,
                          ),
                        if (wind != "--")
                          smallDataTile(
                            "WIND",
                            wind,
                            Icons.air_rounded,
                          ),
                      ],
                    ),
                  const SizedBox(
                    height: 15,
                  ),
                  Container(
                    width:
                        double.infinity,
                    padding:
                        const EdgeInsets.all(
                      16,
                    ),
                    decoration:
                        BoxDecoration(
                      color:
                          color.withAlpha(8),
                      borderRadius:
                          BorderRadius.circular(
                        13,
                      ),
                      border: Border.all(
                        color:
                            color.withAlpha(
                          20,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons
                                  .assignment_outlined,
                              color: color,
                              size: 17,
                            ),
                            const SizedBox(
                              width: 8,
                            ),
                            const Text(
                              "OPERATIONAL RECOMMENDATION",
                              style:
                                  TextStyle(
                                color:
                                    Colors
                                        .white54,
                                fontSize: 7,
                                fontWeight:
                                    FontWeight
                                        .w900,
                                letterSpacing:
                                    .8,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 9,
                        ),
                        Text(
                          recommendation,
                          style:
                              const TextStyle(
                            color:
                                Colors.white70,
                            fontSize: 10,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 18,
                  ),
                  SizedBox(
                    width:
                        double.infinity,
                    child:
                        ElevatedButton.icon(
                      onPressed: () =>
                          Navigator.pop(
                        dialogContext,
                      ),
                      icon: const Icon(
                        Icons.check_rounded,
                        size: 16,
                      ),
                      label: const Text(
                        "Close Details",
                      ),
                      style:
                          ElevatedButton
                              .styleFrom(
                        backgroundColor:
                            color,
                        foregroundColor:
                            Colors.white,
                        elevation: 0,
                        padding:
                            const EdgeInsets
                                .symmetric(
                          vertical: 13,
                        ),
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            10,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget detailMetric(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(5),
        borderRadius:
            BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withAlpha(10),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 19,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style:
                      const TextStyle(
                    color:
                        Colors.white30,
                    fontSize: 6,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  overflow:
                      TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget smallDataTile(
    String title,
    String value,
    IconData icon,
  ) {
    return Container(
      width: 155,
      padding:
          const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(4),
        borderRadius:
            BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withAlpha(9),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: cyan,
            size: 15,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style:
                      const TextStyle(
                    color:
                        Colors.white30,
                    fontSize: 6,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    color:
                        Colors.white70,
                    fontSize: 9,
                    fontWeight:
                        FontWeight.w700,
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
  // ALERT SECTION
  // ============================================================

  Widget buildAlertSection() {
    return HoverCard(
      color: cardColor,
      borderColor:
          criticalColor.withAlpha(24),
      radius: 17,
      child: Container(
        padding:
            const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                buildSectionIcon(
                  Icons
                      .notifications_active_outlined,
                  criticalColor,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        "Risk Alerts",
                        style: TextStyle(
                          color:
                              Colors.white,
                          fontSize: 14,
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        "Locations requiring operational attention",
                        style: TextStyle(
                          color:
                              Colors.white30,
                          fontSize: 8,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  "$alertCount ACTIVE",
                  style: TextStyle(
                    color: alertCount > 0
                        ? criticalColor
                        : safeColor,
                    fontSize: 8,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (alertItems.isEmpty)
              buildNoAlerts()
            else
              ...alertItems.map(
                (item) =>
                    buildAlertRow(item),
              ),
          ],
        ),
      ),
    );
  }

  Widget buildNoAlerts() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: safeColor.withAlpha(7),
        borderRadius:
            BorderRadius.circular(12),
        border: Border.all(
          color: safeColor.withAlpha(20),
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            color: safeColor,
            size: 21,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              "No high or critical risk alerts are currently active.",
              style: TextStyle(
                color: Colors.white60,
                fontSize: 9,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildAlertRow(
    dynamic item,
  ) {
    final risk = riskOf(item);
    final city = cityOf(item);
    final visibility =
        visibilityOf(item);
    final color = riskColor(risk);

    return Padding(
      padding:
          const EdgeInsets.only(bottom: 7),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () =>
              showLocationDetails(item),
          borderRadius:
              BorderRadius.circular(11),
          child: Container(
            padding:
                const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withAlpha(6),
              borderRadius:
                  BorderRadius.circular(11),
              border: Border.all(
                color: color.withAlpha(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color:
                        color.withAlpha(16),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    riskIcon(risk),
                    color: color,
                    size: 17,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        city,
                        style:
                            const TextStyle(
                          color:
                              Colors.white,
                          fontSize: 10,
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                      const SizedBox(
                          height: 3),
                      Text(
                        "Visibility ${visibility.toStringAsFixed(1)} km",
                        style:
                            const TextStyle(
                          color:
                              Colors.white38,
                          fontSize: 8,
                        ),
                      ),
                    ],
                  ),
                ),
                buildRiskBadge(risk),
                const SizedBox(width: 10),
                const Icon(
                  Icons
                      .chevron_right_rounded,
                  color:
                      Colors.white30,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
    // ============================================================
  // OPERATIONAL ANALYSIS
  // ============================================================

  Widget buildOperationalAnalysis() {
    final lowest = lowestVisibilityItem;
    final highest = highestVisibilityItem;

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              "Operational Analysis",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 9),
            Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 7,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: cyan.withAlpha(12),
                borderRadius:
                    BorderRadius.circular(5),
              ),
              child: const Text(
                "LIVE SUMMARY",
                style: TextStyle(
                  color: cyan,
                  fontSize: 6,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .8,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Expanded(
              child: buildAnalysisCard(
                Icons.visibility_outlined,
                "AVERAGE VISIBILITY",
                "${averageVisibility.toStringAsFixed(1)} km",
                "Network-wide average",
                cyan,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: buildAnalysisCard(
                Icons.warning_amber_rounded,
                "ATTENTION NEEDED",
                attentionCount.toString(),
                "Moderate and above",
                moderateColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: buildAnalysisCard(
                Icons.low_priority_rounded,
                "LOWEST VISIBILITY",
                lowest == null
                    ? "--"
                    : "${visibilityOf(lowest).toStringAsFixed(1)} km",
                lowest == null
                    ? "No data"
                    : cityOf(lowest),
                criticalColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: buildAnalysisCard(
                Icons.verified_outlined,
                "BEST VISIBILITY",
                highest == null
                    ? "--"
                    : "${visibilityOf(highest).toStringAsFixed(1)} km",
                highest == null
                    ? "No data"
                    : cityOf(highest),
                safeColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget buildAnalysisCard(
    IconData icon,
    String title,
    String value,
    String subtitle,
    Color color,
  ) {
    return HoverCard(
      color: cardColor,
      borderColor: color.withAlpha(20),
      radius: 13,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withAlpha(14),
                borderRadius:
                    BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: color,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white30,
                      fontSize: 6,
                      fontWeight:
                          FontWeight.w900,
                      letterSpacing: .7,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontSize: 16,
                      fontWeight:
                          FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white30,
                      fontSize: 7,
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

  // ============================================================
  // THRESHOLDS
  // ============================================================

  Widget buildThresholds() {
    return HoverCard(
      color: cardColor,
      borderColor: cyan.withAlpha(20),
      radius: 17,
      child: Container(
        padding:
            const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                buildSectionIcon(
                  Icons.tune_rounded,
                  cyan,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        "Risk Classification Thresholds",
                        style: TextStyle(
                          color:
                              Colors.white,
                          fontSize: 14,
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        "Visibility-based classification used by the monitoring system",
                        style: TextStyle(
                          color:
                              Colors.white30,
                          fontSize: 8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 9,
              runSpacing: 9,
              children: [
                thresholdChip(
                  "SAFE",
                  "> 10.0 km",
                  safeColor,
                ),
                thresholdChip(
                  "LOW",
                  "< 10.0 km",
                  lowColor,
                ),
                thresholdChip(
                  "MODERATE",
                  "< 5.0 km",
                  moderateColor,
                ),
                thresholdChip(
                  "HIGH",
                  "< 2.0 km",
                  highColor,
                ),
                thresholdChip(
                  "CRITICAL",
                  "< 0.5 km",
                  criticalColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget thresholdChip(
    String label,
    String range,
    Color color,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(10),
        borderRadius:
            BorderRadius.circular(10),
        border: Border.all(
          color: color.withAlpha(30),
        ),
      ),
      child: Row(
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
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 8,
              fontWeight:
                  FontWeight.w900,
            ),
          ),
          const SizedBox(width: 7),
          Text(
            range,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 8,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FOOTER
  // ============================================================

  Widget buildFooter() {
    return Row(
      children: [
        const Icon(
          Icons.shield_outlined,
          color: Colors.white24,
          size: 14,
        ),
        const SizedBox(width: 7),
        const Text(
          "NHMP • Smog Risk Prediction System",
          style: TextStyle(
            color: Colors.white24,
            fontSize: 7,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        Text(
          "${riskData.length} monitoring points • System online",
          style: const TextStyle(
            color: Colors.white24,
            fontSize: 7,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // MOBILE DASHBOARD
  // ============================================================

  Widget buildMobileDashboard() {
    return SafeArea(
      child: RefreshIndicator(
        color: cyan,
        backgroundColor: cardColor,
        onRefresh: loadRiskData,
        child: SingleChildScrollView(
          physics:
              const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding:
              const EdgeInsets.fromLTRB(
            15,
            15,
            15,
            35,
          ),
          child: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [


KeyedSubtree(
  key: overviewKey,
  child: animatedSection(
    child: buildMobileHeader(),
  ),
),
const SizedBox(height: 10),

buildOfficerCard(),

const SizedBox(height: 12),

// OPEN USER DASHBOARD BUTTON
SizedBox(
  width: double.infinity,
  child: OutlinedButton.icon(
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const UserDashboard(
            isOpenedFromNHMP: true,
          ),
        ),
      );
    },
    icon: const Icon(
      Icons.person_outline_rounded,
      color: cyan,
    ),
    label: const Text(
      'Open User Dashboard',
      style: TextStyle(
        color: cyan,
        fontWeight: FontWeight.w700,
      ),
    ),
    style: OutlinedButton.styleFrom(
      side: BorderSide(
        color: cyan.withAlpha(90),
      ),
      padding: const EdgeInsets.symmetric(
        vertical: 13,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
),

const SizedBox(height: 14),


  Container(
    padding: const EdgeInsets.all(6),
    decoration: BoxDecoration(
      color: cardColor,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: Colors.white.withAlpha(15),
      ),
    ),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [

          _mobileMenuItem(Icons.dashboard_rounded, 'Overview', 0, overviewKey),
          _mobileMenuItem(Icons.route_rounded, 'Motorway', 1, locationsKey),
          _mobileMenuItem(Icons.notifications_active_outlined, 'Alerts', 2, alertsKey),
          _mobileMenuItem(Icons.analytics_outlined, 'Analysis', 3, analysisKey),
        ],
      ),
    ),
  ),

  const SizedBox(height: 16),
  animatedSection(
    begin: 15,
    child: buildMobileStatus(),
  ),

              const SizedBox(height: 18),
              animatedSection(
                begin: 20,
                child: buildMobileHero(),
              ),
              const SizedBox(height: 15),
              animatedSection(
                begin: 25,
                child: buildMobileSummary(),
              ),
              const SizedBox(height: 15),
              animatedSection(
                begin: 30,
                child: buildVisibilityChart(),
              ),
              const SizedBox(height: 15),
              animatedSection(
                begin: 35,
                child: buildRiskOverview(),
              ),
              const SizedBox(height: 15),
              KeyedSubtree(
  key: locationsKey,
  child: animatedSection(
    begin: 40,
    child: buildMobileLocations(),
  ),
),
              const SizedBox(height: 15),

KeyedSubtree(
  key: alertsKey,
  child: animatedSection(
    begin: 45,
    child: buildAlertSection(),
  ),
),

              const SizedBox(height: 15),

KeyedSubtree(
  key: analysisKey,
  child: animatedSection(
    begin: 50,
    child: buildMobileOperational(),
  ),
),

              const SizedBox(height: 15),
              animatedSection(
                begin: 55,
                child: buildThresholds(),
              ),
                            const SizedBox(height: 20),
              buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // MOBILE HEADER
  // ============================================================



Widget buildMobileHeader() {
  return Row(
    children: [
      IconButton(
        onPressed: () {
          if (widget.isOpenedFromAdmin) {
            Navigator.pop(context);
          } else {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => LoginPage(),
              ),
              (route) => false,
            );
          }
        },
        icon: const Icon(
          Icons.arrow_back_rounded,
          color: Colors.white,
          size: 22,
        ),
        tooltip: 'Go back',
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(
          minWidth: 32,
          minHeight: 40,
        ),
      ),
      const SizedBox(width: 5),

      Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: cyan.withAlpha(18),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: cyan.withAlpha(40),
          ),
        ),
        child: const Icon(
          Icons.cloud_outlined,
          color: cyan,
          size: 22,
        ),
      ),

      const SizedBox(width: 8),

      const Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "NHMP OPERATIONS",
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: .8,
              ),
            ),
            SizedBox(height: 3),
            Text(
              "Motorway Safety Intelligence",
              style: TextStyle(
                color: Colors.white30,
                fontSize: 8,
              ),
            ),
          ],
        ),
      ),

      buildRefreshButton(),
    ],
  );
}

  // ============================================================
  // MOBILE STATUS
  // ============================================================

Widget _mobileMenuItem(
  IconData icon,
  String title,
  int index,
  GlobalKey targetKey,
) {
  final selected = selectedMenu == index;

  return Padding(
    padding: const EdgeInsets.only(right: 6),
    child: Material(
      color: selected
          ? cyan.withAlpha(22)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          scrollToSection(targetKey, index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 11,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? cyan.withAlpha(65)
                  : Colors.white.withAlpha(12),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? cyan : Colors.white54,
              ),
              const SizedBox(width: 7),
              Text(
                title,
                style: TextStyle(
                  color: selected
                      ? Colors.white
                      : Colors.white60,
                  fontSize: 11,
                  fontWeight: selected
                      ? FontWeight.w700
                      : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}



Widget buildMobileStatus() {
  final bool isOnline = true;

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(
      horizontal: 12,
      vertical: 13,
    ),
    decoration: BoxDecoration(
      color: cardColor,
      borderRadius: BorderRadius.circular(13),
      border: Border.all(
        color: (isOnline ? safeColor : criticalColor)
            .withAlpha(45),
      ),
    ),
    child: Row(
      children: [
        Icon(
          isOnline
              ? Icons.wifi_rounded
              : Icons.wifi_off_rounded,
          color: isOnline ? safeColor : criticalColor,
          size: 19,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isOnline ? 'SYSTEM ONLINE' : 'SYSTEM OFFLINE',
                style: TextStyle(
                  color: isOnline ? safeColor : criticalColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                overallStatus == 'NORMAL'
                    ? 'System operating normally'
                    : '$overallStatus risk detected',
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 9,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Source: $_dataSource',
                style: TextStyle(
                  color: _dataSource == 'Live server'
                      ? safeColor
                      : moderateColor,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            '$alertCount alerts',
            textAlign: TextAlign.end,
            style: TextStyle(
              color: overallStatusColor,
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );
}

  // ============================================================
  // MOBILE HERO
  // ============================================================

  Widget buildMobileHero() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(17),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xff0B2337),
            cardColor,
          ],
        ),
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: cyan.withAlpha(22),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 37,
                height: 37,
                decoration: BoxDecoration(
                  color: cyan.withAlpha(14),
                  borderRadius:
                      BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.insights_rounded,
                  color: cyan,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  "Motorway Safety Intelligence",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            alertCount == 0
                ? "All monitored locations are currently being tracked."
                : "$attentionCount location(s) require closer operational monitoring.",
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 9,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MOBILE SUMMARY
  // ============================================================

  Widget buildMobileSummary() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 9,
      mainAxisSpacing: 9,
      childAspectRatio: 1.05,
      shrinkWrap: true,
      physics:
          const NeverScrollableScrollPhysics(),
      children: [
        kpiCard(
          title: "LOCATIONS",
          value: riskData.length.toString(),
          subtitle: "Monitored",
          icon: Icons.radar_rounded,
          color: cyan,
        ),
        kpiCard(
          title: "ALERTS",
          value: alertCount.toString(),
          subtitle: "High / critical",
          icon:
              Icons.notifications_active_outlined,
          color: alertCount > 0
              ? criticalColor
              : safeColor,
        ),
        kpiCard(
          title: "VISIBILITY",
          value:
              "${averageVisibility.toStringAsFixed(1)} km",
          subtitle: "Network average",
          icon: Icons.visibility_outlined,
          color: cyan,
          isDecimal: true,
        ),
        kpiCard(
          title: "SAFE COVERAGE",
          value:
              "${safeCoverage.toStringAsFixed(0)}%",
          subtitle: "Safe locations",
          icon: Icons.verified_rounded,
          color: safeColor,
          isDecimal: true,
        ),
      ],
    );
  }

  // ============================================================
  // MOBILE LOCATIONS
  // ============================================================

  Widget buildMobileLocations() {
    return HoverCard(
      color: cardColor,
      borderColor: blue.withAlpha(20),
      radius: 16,
      child: Container(
        padding:
            const EdgeInsets.all(16),

child: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [


            Row(
              children: [
                buildSectionIcon(
                  Icons.route_rounded,
                  blue,
                ),
                const SizedBox(width: 9),
                const Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Motorway Locations",
                        style: TextStyle(
                          color:
                              Colors.white,
                          fontSize: 14,
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        "Current monitoring status",
                        style: TextStyle(
                          color:
                              Colors.white30,
                          fontSize: 8,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  "${riskData.length}",
                  style: const TextStyle(
                    color: cyan,
                    fontSize: 15,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...riskData.map(
              (item) =>
                  buildMobileLocationCard(
                item,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MOBILE LOCATION CARD
  // ============================================================

  Widget buildMobileLocationCard(
    dynamic item,
  ) {
    final city = cityOf(item);
    final risk = riskOf(item);
    final visibility =
        visibilityOf(item);
    final recommendation =
        recommendationOf(item);
    final color = riskColor(risk);

    return Padding(
      padding:
          const EdgeInsets.only(bottom: 9),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius:
              BorderRadius.circular(13),
          onTap: () =>
              showLocationDetails(item),
          child: Container(
            padding:
                const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(4),
              borderRadius:
                  BorderRadius.circular(13),
              border: Border.all(
                color: color.withAlpha(25),
              ),
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration:
                          BoxDecoration(
                        color:
                            color.withAlpha(18),
                        shape:
                            BoxShape.circle,
                      ),
                      child: Icon(
                        riskIcon(risk),
                        color: color,
                        size: 19,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        city,
                        style:
                            const TextStyle(
                          color:
                              Colors.white,
                          fontSize: 12,
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                    ),
                    buildRiskBadge(risk),
                  ],
                ),
                const SizedBox(height: 11),
                Container(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 9,
                    vertical: 9,
                  ),
                  decoration:
                      BoxDecoration(
                    color: Colors.white
                        .withAlpha(4),
                    borderRadius:
                        BorderRadius.circular(
                      8,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons
                            .visibility_outlined,
                        color:
                            Colors.white30,
                        size: 14,
                      ),
                      const SizedBox(
                        width: 6,
                      ),
                      const Text(
                        "Visibility",
                        style:
                            TextStyle(
                          color:
                              Colors.white38,
                          fontSize: 8,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        "${visibility.toStringAsFixed(1)} km",
                        style:
                            const TextStyle(
                          color:
                              Colors.white70,
                          fontSize: 9,
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                      const SizedBox(
                        width: 6,
                      ),
                      const Icon(
                        Icons
                            .arrow_forward_ios_rounded,
                        color:
                            Colors.white24,
                        size: 9,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  recommendation,
                  style:
                      const TextStyle(
                    color:
                        Colors.white38,
                    fontSize: 8,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow:
                      TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // MOBILE OPERATIONAL
  // ============================================================

  Widget buildMobileOperational() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          "Operational Analysis",
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        buildAnalysisCard(
          Icons.visibility_outlined,
          "AVERAGE VISIBILITY",
          "${averageVisibility.toStringAsFixed(1)} km",
          "Network-wide average",
          cyan,
        ),
        const SizedBox(height: 9),
        buildAnalysisCard(
          Icons.warning_amber_rounded,
          "ATTENTION NEEDED",
          attentionCount.toString(),
          "Moderate and above",
          moderateColor,
        ),
        const SizedBox(height: 9),
        buildAnalysisCard(
          Icons.gpp_maybe_rounded,
          "CRITICAL",
          criticalCount.toString(),
          "Immediate attention",
          criticalColor,
        ),
      ],
    );
  }
}
 // =================================================================
 // HOVER CARD
 // =================================================================

class HoverCard extends StatefulWidget {
  final Widget child;
  final Color color;
  final Color borderColor;
  final double radius;

  const HoverCard({
    super.key,
    required this.child,
    required this.color,
    required this.borderColor,
    this.radius = 18,
  });

  @override
  State<HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<HoverCard> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.basic,
      onEnter: (_) {
        setState(() {
          isHovered = true;
        });
      },
      onExit: (_) {
        setState(() {
          isHovered = false;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        transform: isHovered
            ? Matrix4.translationValues(0, -2, 0)
            : Matrix4.identity(),
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(
            widget.radius,
          ),
          border: Border.all(
            color: isHovered
                ? widget.borderColor.withAlpha(70)
                : widget.borderColor.withAlpha(32),
          ),
          boxShadow: isHovered
              ? [
                  BoxShadow(
                    color: widget.borderColor.withAlpha(17),
                    blurRadius: 22,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
        child: widget.child,
      ),
    );
  }
}

// =================================================================
// VISIBILITY CHART PAINTER
// =================================================================

class VisibilityChartPainter extends CustomPainter {
  final List<dynamic> data;
  final double animationValue;

  VisibilityChartPainter({
    required this.data,
    required this.animationValue,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    if (data.isEmpty) return;

    const double left = 42;
    const double right = 12;
    const double top = 16;
    const double bottom = 40;

    final chartWidth =
        size.width - left - right;

    final chartHeight =
        size.height - top - bottom;

    if (chartWidth <= 0 || chartHeight <= 0) {
      return;
    }

    double maxVisibility = 20;

    for (final item in data) {
      final rawValue = item is Map
          ? (item['visibility_km'] ??
              item['visibility'] ??
              item['visibilityKm'])
          : null;

      final value = double.tryParse(
            rawValue?.toString() ?? '',
          ) ??
          0;

      if (value > maxVisibility) {
        maxVisibility = value;
      }
    }

    // ============================================================
    // GRID
    // ============================================================

    final gridPaint = Paint()
      ..color = Colors.white.withAlpha(11)
      ..strokeWidth = 1;

    for (int i = 0; i <= 4; i++) {
      final y =
          top + (chartHeight / 4) * i;

      canvas.drawLine(
        Offset(left, y),
        Offset(
          size.width - right,
          y,
        ),
        gridPaint,
      );

      final value =
          maxVisibility -
          (maxVisibility / 4) * i;

      final textPainter = TextPainter(
        text: TextSpan(
          text: value.toStringAsFixed(0),
          style: const TextStyle(
            color: Colors.white30,
            fontSize: 8,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();

      textPainter.paint(
        canvas,
        Offset(0, y - 5),
      );
    }

    // ============================================================
    // SAFE THRESHOLD LINE
    // ============================================================

    if (maxVisibility >= 10) {
      final thresholdY =
          top +
          chartHeight -
          (10 / maxVisibility) *
              chartHeight;

      final thresholdPaint = Paint()
        ..color = const Color(0x1932C66B)
        ..strokeWidth = 1.2;

      canvas.drawLine(
        Offset(left, thresholdY),
        Offset(
          size.width - right,
          thresholdY,
        ),
        thresholdPaint,
      );
    }

    // ============================================================
    // BARS
    // ============================================================

    final count = data.length;

    double gap;

    if (count <= 4) {
      gap = 12;
    } else if (count <= 7) {
      gap = 9;
    } else {
      gap = 7;
    }

    double barWidth;

    if (count <= 4) {
      barWidth =
          (chartWidth -
                  gap * (count - 1)) /
              count;
    } else {
      barWidth =
          ((chartWidth -
                      gap * (count - 1)) /
                  count)
              .clamp(25.0, 50.0);
    }

    for (int i = 0; i < count; i++) {
      final item = data[i];

      final rawValue = item is Map
          ? (item['visibility_km'] ??
              item['visibility'] ??
              item['visibilityKm'])
          : null;

      final value = double.tryParse(
            rawValue?.toString() ?? '',
          ) ??
          0;

      final rawRisk = item is Map
          ? (item['risk_level'] ??
              item['risk'] ??
              item['riskLevel'])
          : null;

      final risk =
          (rawRisk ?? "SAFE")
              .toString()
              .toUpperCase();

      final color = _riskColor(risk);

      final targetHeight =
          (value / maxVisibility) *
              chartHeight;

      final barHeight =
          targetHeight *
          animationValue.clamp(0.0, 1.0);

      final x =
          left +
          i * (barWidth + gap);

      final y =
          top +
          chartHeight -
          barHeight;

      // ----------------------------------------------------------
      // SHADOW
      // ----------------------------------------------------------

      final shadowPaint = Paint()
        ..color = color.withAlpha(18)
        ..maskFilter =
            const MaskFilter.blur(
          BlurStyle.normal,
          7,
        );

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            x,
            y,
            barWidth,
            barHeight,
          ),
          const Radius.circular(7),
        ),
        shadowPaint,
      );

      // ----------------------------------------------------------
      // BAR
      // ----------------------------------------------------------

      final barPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withAlpha(235),
            color.withAlpha(105),
          ],
        ).createShader(
          Rect.fromLTWH(
            x,
            y,
            barWidth,
            barHeight,
          ),
        );

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            x,
            y,
            barWidth,
            barHeight,
          ),
          const Radius.circular(7),
        ),
        barPaint,
      );

      // ----------------------------------------------------------
      // TOP HIGHLIGHT
      // ----------------------------------------------------------

      if (barWidth > 4) {
        final highlightPaint = Paint()
          ..color =
              Colors.white.withAlpha(35);

        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              x + 2,
              y + 2,
              barWidth - 4,
              2,
            ),
            const Radius.circular(3),
          ),
          highlightPaint,
        );
      }

      // ----------------------------------------------------------
      // VALUE
      // ----------------------------------------------------------

      if (animationValue > 0.65) {
        final valuePainter = TextPainter(
          text: TextSpan(
            text:
                value.toStringAsFixed(1),
            style: TextStyle(
              color: color,
              fontSize: 8,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
          textDirection:
              TextDirection.ltr,
        );

        valuePainter.layout();

        valuePainter.paint(
          canvas,
          Offset(
            x +
                barWidth / 2 -
                valuePainter.width / 2,
            y - 14,
          ),
        );
      }

      // ----------------------------------------------------------
      // CITY
      // ----------------------------------------------------------

      final rawCity = item is Map
          ? (item['city'] ??
              item['location'] ??
              item['name'])
          : null;

      final city =
          (rawCity ?? "").toString();

      String shortCity = city;

      if (city.length > 9) {
        shortCity =
            "${city.substring(0, 8)}.";
      }

      final cityPainter = TextPainter(
        text: TextSpan(
          text: shortCity,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 8,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      cityPainter.layout(
        maxWidth: barWidth + 15,
      );

      cityPainter.paint(
        canvas,
        Offset(
          x +
              barWidth / 2 -
              cityPainter.width / 2,
          top +
              chartHeight +
              10,
        ),
      );
    }
  }

  Color _riskColor(String risk) {
    switch (risk.toUpperCase()) {
      case "CRITICAL":
        return const Color(0xffF04444);

      case "HIGH":
        return const Color(0xffFF922E);

      case "MODERATE":
        return const Color(0xffF5B82E);

      case "LOW":
        return const Color(0xff8CC63F);

      case "SAFE":
      default:
        return const Color(0xff32C66B);
    }
  }

  @override
  bool shouldRepaint(
    covariant VisibilityChartPainter oldDelegate,
  ) {
    return oldDelegate.data != data ||
        oldDelegate.animationValue !=
            animationValue;
  }
}

// =================================================================
// RISK DONUT PAINTER
// =================================================================

class RiskDonutPainter extends CustomPainter {
  final int safe;
  final int low;
  final int moderate;
  final int high;
  final int critical;

  RiskDonutPainter({
    required this.safe,
    required this.low,
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
        low +
        moderate +
        high +
        critical;

    final center = Offset(
      size.width / 2,
      size.height / 2,
    );

    final radius =
        (size.shortestSide / 2) - 13;

    final backgroundPaint = Paint()
      ..style =
          PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.butt
      ..color =
          Colors.white.withAlpha(8);

    canvas.drawCircle(
      center,
      radius,
      backgroundPaint,
    );

    if (total == 0) return;

    final values = [
      safe,
      low,
      moderate,
      high,
      critical,
    ];

    final colors = [
      const Color(0xff32C66B),
      const Color(0xff8CC63F),
      const Color(0xffF5B82E),
      const Color(0xffFF922E),
      const Color(0xffF04B4B),
    ];

    double startAngle = -1.5708;

    for (int i = 0;
        i < values.length;
        i++) {
      if (values[i] == 0) {
        continue;
      }

      final sweep =
          (values[i] / total) *
              6.283185;

      final paint = Paint()
        ..style =
            PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap =
            StrokeCap.butt
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

    final innerPaint = Paint()
      ..color =
          const Color(0xff0C1D2E);

    canvas.drawCircle(
      center,
      radius - 8,
      innerPaint,
    );
  }

  @override
  bool shouldRepaint(
    covariant RiskDonutPainter oldDelegate,
  ) {
    return oldDelegate.safe != safe ||
        oldDelegate.low != low ||
        oldDelegate.moderate != moderate ||
        oldDelegate.high != high ||
        oldDelegate.critical !=
            critical;
  }
}

