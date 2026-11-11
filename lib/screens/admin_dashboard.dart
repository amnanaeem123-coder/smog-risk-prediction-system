import 'package:flutter/material.dart';

import '../widgets/aqi_chart.dart';
import '../widgets/alert_table.dart';
import '../widgets/motorway_monitor.dart';
import '../widgets/ai_prediction.dart';
import '../widgets/risk_chart.dart';
import 'user_dashboard.dart';
import 'nhmp_dashboard.dart';
import 'users_screen.dart';
import 'air_quality_screen.dart';
import 'alert_screen.dart';
import 'nhmp_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';
import 'login_page.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedTab = 0;

  // ============================================================
  // COLORS
  // ============================================================

  static const Color backgroundColor = Color(0xff081426);
  static const Color sidebarColor = Color(0xff102A43);
  static const Color cardColor = Color(0xff102A43);

  static const Color cyanColor = Colors.cyanAccent;
  static const Color blueColor = Color(0xff3B82F6);
  static const Color redColor = Colors.redAccent;

  static const Color whiteColor = Colors.white;
  static const Color secondaryColor = Colors.white70;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final isMobile = width < 700;
        final isTablet = width >= 700 && width < 1100;

        return Scaffold(
          backgroundColor: backgroundColor,

          // ======================================================
          // MOBILE DRAWER
          // ======================================================

          drawer: isMobile
              ? Drawer(
                  backgroundColor: sidebarColor,
                  child: SafeArea(
                    child: _buildSidebar(
                      context,
                      false,
                    ),
                  ),
                )
              : null,

          bottomNavigationBar: _buildBottomNavigationBar(),

          body: SafeArea(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isMobile)
                  _buildSidebar(
                    context,
                    isTablet,
                  ),

                Expanded(
                  child: _selectedTab == 0
                      ? SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      isMobile
                          ? 14
                          : isTablet
                              ? 20
                              : 28,
                      isMobile
                          ? 14
                          : isTablet
                              ? 20
                              : 24,
                      isMobile
                          ? 14
                          : isTablet
                              ? 20
                              : 28,
                      35,
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        // HEADER
                        _buildHeader(
                          context,
                          isMobile,
                          isTablet,
                        ),

                        SizedBox(
                          height: isMobile ? 18 : 25,
                        ),

                        // OVERVIEW
                        _buildSectionHeading(
                          "Dashboard Overview",
                          "Real-time system performance at a glance",
                          isMobile: isMobile,
                        ),

                        const SizedBox(height: 15),

                        // CARDS
                        _buildDashboardCards(
                          context,
                          isMobile,
                          isTablet,
                        ),

                        SizedBox(
                          height: isMobile ? 20 : 28,
                        ),

                        // LIVE STATUS
                        _buildLiveStatusPanel(
                          isMobile || isTablet,
                        ),

                        SizedBox(
                          height: isMobile ? 20 : 28,
                        ),

                        // ANALYTICS
                        _buildSectionHeading(
                          "Air Quality Analytics",
                          "AQI trends and smog risk distribution",
                          isMobile: isMobile,
                        ),

                        const SizedBox(height: 15),

                        _buildCharts(
                          context,
                          isMobile,
                          isTablet,
                        ),

                        SizedBox(
                          height: isMobile ? 20 : 28,
                        ),

                        // RECENT ALERTS
                        _buildDashboardSection(
                          title: "Recent Smog Alerts",
                          subtitle:
                              "Latest alerts generated by the monitoring system",
                          icon: Icons.warning_amber_rounded,
                          color: redColor,
                          buttonText: "View All",
                          isMobile: isMobile,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const AlertScreen(),
                              ),
                            );
                          },
                          child: const AlertTable(),
                        ),

                        SizedBox(
                          height: isMobile ? 20 : 28,
                        ),

                        // MOTORWAY
                        _buildDashboardSection(
                          title: "Motorway Monitoring",
                          subtitle:
                              "Current NHMP motorway monitoring status",
                          icon: Icons.route_rounded,
                          color: blueColor,
                          buttonText: "View Stations",
                          isMobile: isMobile,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const NHMPScreen(),
                              ),
                            );
                          },
                          child: const MotorwayMonitor(),
                        ),

                        SizedBox(
                          height: isMobile ? 20 : 28,
                        ),

                        // AI PREDICTION
                        _buildDashboardSection(
                          title: "AI Risk Prediction",
                          subtitle:
                              "AI-powered smog risk analysis and forecasting",
                          icon: Icons.psychology_rounded,
                          color: cyanColor,
                          buttonText: "View Reports",
                          isMobile: isMobile,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const ReportsScreen(),
                              ),
                            );
                          },
                          child: const AIPrediction(),
                        ),

                        const SizedBox(height: 30),
                      ],
                    ),
                  )
                      : _selectedTabContent(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _selectedTabContent() {
    switch (_selectedTab) {
      case 1:
        return const UsersScreen();
      case 2:
        return const NHMPScreen();
      case 3:
        return const SettingsScreen();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: sidebarColor,
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: BottomNavigationBar(
          currentIndex: _selectedTab,


onTap: (index) {
  if (index == 0) {
    setState(() {
      _selectedTab = 0;
    });
  } else if (index == 1) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const UserDashboard(
          isOpenedFromAdmin: true,
        ),
      ),
    );
  } else if (index == 2) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const NHMPDashboard(
          isOpenedFromAdmin: true,
        ),
      ),
    );
  } else if (index == 3) {
    setState(() {
      _selectedTab = 3;
    });
  }
},

          type: BottomNavigationBarType.fixed,
          backgroundColor: sidebarColor,
          selectedItemColor: cyanColor,
          unselectedItemColor: Colors.white60,
          showUnselectedLabels: true,
          selectedFontSize: 11,
          unselectedFontSize: 10,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_rounded),
              label: 'Users',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shield_rounded),
              label: 'NHMP',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_rounded),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SIDEBAR
  // ============================================================

  Widget _buildSidebar(
    BuildContext context,
    bool isTablet,
  ) {
    return Container(
      width: isTablet ? 225 : 260,
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: sidebarColor,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 25,
            offset: const Offset(5, 0),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 28),

            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: cyanColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(17),
                border: Border.all(
                  color: cyanColor.withValues(alpha: 0.25),
                ),
              ),
              child: const Icon(
                Icons.cloud_rounded,
                color: cyanColor,
                size: 31,
              ),
            ),

            const SizedBox(height: 12),

            const Text(
              "Smog AI",
              style: TextStyle(
                color: whiteColor,
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 5),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 15),
              child: Text(
                "Risk Prediction System",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: secondaryColor,
                  fontSize: 11.5,
                ),
              ),
            ),

            const SizedBox(height: 25),

            _divider(),

            const SizedBox(height: 18),

            _sidebarItem(
              context,
              Icons.dashboard_rounded,
              "Dashboard",
              active: true,
            ),

            _sidebarItem(
              context,
              Icons.people_rounded,
              "Users",
            ),

            _sidebarItem(
              context,
              Icons.route_rounded,
              "NHMP Stations",
            ),

            _sidebarItem(
              context,
              Icons.air_rounded,
              "Air Quality",
            ),

            _sidebarItem(
              context,
              Icons.warning_rounded,
              "Alerts",
            ),

            _sidebarItem(
              context,
              Icons.bar_chart_rounded,
              "Reports",
            ),

            _sidebarItem(
              context,
              Icons.settings_rounded,
              "Settings",
            ),

            _sidebarItem(
              context,
              Icons.person_rounded,
              "Profile",
            ),

            const SizedBox(height: 20),

            _divider(),

            const SizedBox(height: 15),

            _sidebarItem(
              context,
              Icons.logout_rounded,
              "Logout",
              logout: true,
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _divider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      color: Colors.white.withValues(alpha: 0.08),
    );
  }

  // ============================================================
  // SIDEBAR ITEM
  // ============================================================

  Widget _sidebarItem(
    BuildContext context,
    IconData icon,
    String title, {
    bool active = false,
    bool logout = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 3,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (MediaQuery.of(context).size.width < 700) {
              Navigator.pop(context);
            }

            _navigate(context, title);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: active
                  ? cyanColor.withValues(alpha: 0.13)
                  : logout
                      ? redColor.withValues(alpha: 0.04)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: active
                    ? cyanColor.withValues(alpha: 0.18)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: active
                        ? cyanColor.withValues(alpha: 0.13)
                        : logout
                            ? redColor.withValues(alpha: 0.08)
                            : Colors.white.withValues(alpha: 0.045),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 21,
                    color: active
                        ? cyanColor
                        : logout
                            ? redColor
                            : Colors.white70,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: active
                          ? cyanColor
                          : logout
                              ? redColor
                              : whiteColor,
                      fontSize: 14,
                      fontWeight: active
                          ? FontWeight.bold
                          : FontWeight.w500,
                    ),
                  ),
                ),

                if (active)
                  Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: cyanColor,
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
  // NAVIGATION
  // ============================================================

  void _navigate(
    BuildContext context,
    String title,
  ) {
    switch (title) {
      case "Dashboard":
        break;

      case "Users":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const UsersScreen(),
          ),
        );
        break;

      case "NHMP Stations":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const NHMPScreen(),
          ),
        );
        break;

      case "Air Quality":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AirQualityScreen(),
          ),
        );
        break;

      case "Alerts":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AlertScreen(),
          ),
        );
        break;

      case "Reports":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const ReportsScreen(),
          ),
        );
        break;

      case "Settings":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const SettingsScreen(),
          ),
        );
        break;

      case "Profile":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const ProfileScreen(),
          ),
        );
        break;

      case "Logout":
        _showLogoutDialog(context);
        break;
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  void _showLogoutDialog(
    BuildContext context,
  ) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: sidebarColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.logout_rounded,
                color: redColor,
              ),
              SizedBox(width: 12),
              Text(
                "Logout",
                style: TextStyle(
                  color: whiteColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: const Text(
            "Are you sure you want to logout?",
            style: TextStyle(
              color: secondaryColor,
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text(
                "Cancel",
                style: TextStyle(
                  color: secondaryColor,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LoginPage(),
                  ),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: redColor,
                foregroundColor: whiteColor,
              ),
              child: const Text(
                "Logout",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(
    BuildContext context,
    bool isMobile,
    bool isTablet,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        isMobile ? 14 : 22,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xff102A43),
            Color(0xff163B5C),
          ],
        ),
        borderRadius: BorderRadius.circular(
          isMobile ? 18 : 24,
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.09),
        ),
      ),
      child: Row(
        children: [

 // MOBILE BACK ARROW + MENU
if (isMobile) ...[
  IconButton(
    tooltip: 'Back to Login',
    onPressed: () {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const LoginPage(),
        ),
        (route) => false,
      );
    },
    icon: const Icon(
      Icons.arrow_back_rounded,
      color: cyanColor,
      size: 24,
    ),
    padding: EdgeInsets.zero,
    constraints: const BoxConstraints(
      minWidth: 32,
      minHeight: 40,
    ),
  ),
  const SizedBox(width: 4),
  Builder(
    builder: (drawerContext) {
      return GestureDetector(
        onTap: () {
          Scaffold.of(drawerContext).openDrawer();
        },
        child: _headerButton(
          icon: Icons.menu_rounded,
          small: true,
        ),
      );
    },
  ),
  const SizedBox(width: 10),
],


          // ADMIN ICON
          Container(
            width: isMobile ? 46 : 56,
            height: isMobile ? 46 : 56,
            decoration: BoxDecoration(
              color: cyanColor.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(17),
              border: Border.all(
                color: cyanColor.withValues(alpha: 0.20),
              ),
            ),
            child: Icon(
              Icons.admin_panel_settings_rounded,
              color: cyanColor,
              size: isMobile ? 24 : 30,
            ),
          ),

          SizedBox(
            width: isMobile ? 10 : 15,
          ),

          // WELCOME
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMobile
                      ? "Welcome, Admin 👋"
                      : "Welcome back, Admin 👋",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: whiteColor,
                    fontSize: isMobile ? 16 : 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (!isMobile) ...[
                  const SizedBox(height: 5),
                  const Text(
                    "Monitor air quality, predictions and alerts",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: secondaryColor,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // NOTIFICATIONS
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const NotificationsScreen(),
                ),
              );
            },
            child: _headerButton(
              icon: Icons.notifications_none_rounded,
              badge: "3",
              small: isMobile,
            ),
          ),

          // ADMIN DROPDOWN
          if (!isMobile) ...[
            const SizedBox(width: 10),

            PopupMenuButton<String>(
              tooltip: "Admin menu",
              color: sidebarColor,
              offset: const Offset(0, 55),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              onSelected: (value) {
                switch (value) {
                  case "profile":
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const ProfileScreen(),
                      ),
                    );
                    break;

                  case "notifications":
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const NotificationsScreen(),
                      ),
                    );
                    break;

                  case "settings":
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const SettingsScreen(),
                      ),
                    );
                    break;

                  case "logout":
                    _showLogoutDialog(context);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem<String>(
                  value: "profile",
                  child: Row(
                    children: [
                      Icon(
                        Icons.person_rounded,
                        color: cyanColor,
                      ),
                      SizedBox(width: 12),
                      Text(
                        "Profile",
                        style: TextStyle(
                          color: whiteColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: "notifications",
                  child: Row(
                    children: [
                      Icon(
                        Icons.notifications_rounded,
                        color: cyanColor,
                      ),
                      SizedBox(width: 12),
                      Text(
                        "Notifications",
                        style: TextStyle(
                          color: whiteColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: "settings",
                  child: Row(
                    children: [
                      Icon(
                        Icons.settings_rounded,
                        color: cyanColor,
                      ),
                      SizedBox(width: 12),
                      Text(
                        "Settings",
                        style: TextStyle(
                          color: whiteColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem<String>(
                  value: "logout",
                  child: Row(
                    children: [
                      Icon(
                        Icons.logout_rounded,
                        color: redColor,
                      ),
                      SizedBox(width: 12),
                      Text(
                        "Logout",
                        style: TextStyle(
                          color: redColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color:
                      Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color:
                        Colors.white.withValues(alpha: 0.06),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 19,
                      backgroundColor: cyanColor,
                      child: Icon(
                        Icons.person,
                        color: backgroundColor,
                        size: 21,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      "Admin",
                      style: TextStyle(
                        color: whiteColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.white60,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // HEADER BUTTON
  // ============================================================

  Widget _headerButton({
    required IconData icon,
    String? badge,
    bool small = false,
  }) {
    return Container(
      width: small ? 42 : 45,
      height: small ? 42 : 45,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.07),
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: Icon(
              icon,
              color: whiteColor,
              size: small ? 21 : 23,
            ),
          ),
          if (badge != null)
            Positioned(
              right: 6,
              top: 5,
              child: Container(
                width: 14,
                height: 14,
                decoration: const BoxDecoration(
                  color: redColor,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: whiteColor,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION HEADING
  // ============================================================

  Widget _buildSectionHeading(
    String title,
    String subtitle, {
    bool isMobile = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 4,
          height: 34,
          decoration: BoxDecoration(
            color: cyanColor,
            borderRadius: BorderRadius.circular(10),
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
                style: TextStyle(
                  color: whiteColor,
                  fontSize: isMobile ? 16 : 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: isMobile ? 2 : 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: secondaryColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // DASHBOARD CARDS
  // ============================================================

  Widget _buildDashboardCards(
    BuildContext context,
    bool isMobile,
    bool isTablet,
  ) {
    final cards = [
      _DashboardCardData(
        title: "Total Users",
        value: "12,450",
        status: "+12.5%",
        icon: Icons.people_rounded,
        color: cyanColor,
        page: const UsersScreen(),
      ),
      _DashboardCardData(
        title: "NHMP Stations",
        value: "35",
        status: "Active",
        icon: Icons.route_rounded,
        color: blueColor,
        page: const NHMPScreen(),
      ),
      _DashboardCardData(
        title: "Predictions",
        value: "560",
        status: "Today",
        icon: Icons.analytics_rounded,
        color: cyanColor,
        page: const ReportsScreen(),
      ),
      _DashboardCardData(
        title: "Alerts",
        value: "18",
        status: "Active",
        icon: Icons.warning_rounded,
        color: redColor,
        page: const AlertScreen(),
      ),
    ];

    if (isMobile) {
      return Column(
        children: [
          for (int i = 0; i < cards.length; i++) ...[
            _dashboardCard(
              context,
              cards[i],
            ),
            if (i != cards.length - 1)
              const SizedBox(height: 12),
          ],
        ],
      );
    }

    if (isTablet) {
      return GridView.builder(
        shrinkWrap: true,
        physics:
            const NeverScrollableScrollPhysics(),
        itemCount: cards.length,
        gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          mainAxisExtent: 190,
        ),
        itemBuilder: (context, index) {
          return _dashboardCard(
            context,
            cards[index],
          );
        },
      );
    }

    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: List.generate(
        cards.length,
        (index) {
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right:
                    index == cards.length - 1
                        ? 0
                        : 14,
              ),
              child: _dashboardCard(
                context,
                cards[index],
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // SINGLE DASHBOARD CARD
  // ============================================================

  Widget _dashboardCard(
    BuildContext context,
    _DashboardCardData data,
  ) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => data.page,
            ),
          );
        },
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(
            minHeight: 175,
          ),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.09),
                Colors.white.withValues(alpha: 0.035),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color:
                  Colors.white.withValues(alpha: 0.09),
            ),
            boxShadow: [
              BoxShadow(
                color:
                    Colors.black.withValues(alpha: 0.12),
                blurRadius: 18,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 47,
                    height: 47,
                    decoration: BoxDecoration(
                      color: data.color
                          .withValues(alpha: 0.12),
                      borderRadius:
                          BorderRadius.circular(14),
                    ),
                    child: Icon(
                      data.icon,
                      color: data.color,
                      size: 25,
                    ),
                  ),

                  const Spacer(),

                  Container(
                    constraints:
                        const BoxConstraints(
                      maxWidth: 70,
                    ),
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: data.color
                          .withValues(alpha: 0.08),
                      borderRadius:
                          BorderRadius.circular(8),
                    ),
                    child: Text(
                      data.status,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: TextStyle(
                        color: data.color,
                        fontSize: 9,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              Text(
                data.title,
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
                style: const TextStyle(
                  color: secondaryColor,
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 5),

              Row(
                children: [
                  Text(
                    data.value,
                    style: const TextStyle(
                      color: whiteColor,
                      fontSize: 23,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: data.color
                        .withValues(alpha: 0.65),
                    size: 18,
                  ),
                ],
              ),

              const SizedBox(height: 7),

              const Text(
                "View details",
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // LIVE STATUS
  // ============================================================

  Widget _buildLiveStatusPanel(
    bool isSmall,
  ) {
    final content = [
      _liveItem(
        Icons.cloud_rounded,
        "Air Quality System",
        "Operational",
        Colors.greenAccent,
      ),
      _liveItem(
        Icons.route_rounded,
        "NHMP Monitoring",
        "35 Stations Online",
        cyanColor,
      ),
      _liveItem(
        Icons.psychology_rounded,
        "AI Prediction Engine",
        "Running",
        blueColor,
      ),
      _liveItem(
        Icons.notifications_active_rounded,
        "Alert Service",
        "18 Active Alerts",
        Colors.orangeAccent,
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xff0D2139),
            Color(0xff102A43),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color:
                      cyanColor.withValues(alpha: 0.10),
                  borderRadius:
                      BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.monitor_heart_rounded,
                  color: cyanColor,
                  size: 20,
                ),
              ),

              const SizedBox(width: 11),

              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Live System Status",
                      style: TextStyle(
                        color: whiteColor,
                        fontSize: 15,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      "Current platform health",
                      style: TextStyle(
                        color: secondaryColor,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),

              if (!isSmall)
                _statusBadge(),
            ],
          ),

          if (isSmall)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text(
                "●  All Systems Normal",
                style: TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

          const SizedBox(height: 18),

          if (isSmall)
            Column(
              children: [
                for (int i = 0;
                    i < content.length;
                    i++) ...[
                  content[i],
                  if (i != content.length - 1)
                    const SizedBox(height: 10),
                ],
              ],
            )
          else
            Row(
              children: [
                for (int i = 0;
                    i < content.length;
                    i++)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right:
                            i == content.length - 1
                                ? 0
                                : 10,
                      ),
                      child: content[i],
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _statusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.greenAccent
            .withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.circle,
            color: Colors.greenAccent,
            size: 7,
          ),
          SizedBox(width: 6),
          Text(
            "All Systems Normal",
            style: TextStyle(
              color: Colors.greenAccent,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _liveItem(
    IconData icon,
    String title,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color:
            Colors.white.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color:
              Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              color:
                  color.withValues(alpha: 0.10),
              borderRadius:
                  BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 18,
            ),
          ),

          const SizedBox(width: 9),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight:
                        FontWeight.w600,
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
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        value,
                        overflow:
                            TextOverflow.ellipsis,
                        style: TextStyle(
                          color: color,
                          fontSize: 9,
                          fontWeight:
                              FontWeight.bold,
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
    );
  }

  // ============================================================
  // CHARTS
  // ============================================================

  Widget _buildCharts(
    BuildContext context,
    bool isMobile,
    bool isTablet,
  ) {
    if (isMobile) {
      return Column(
        children: [
          _chartContainer(
            const AQIChart(),
            290,
          ),
          const SizedBox(height: 16),
          _chartContainer(
            const RiskChart(),
            290,
          ),
        ],
      );
    }

    if (isTablet) {
      return Column(
        children: [
          _chartContainer(
            const AQIChart(),
            320,
          ),
          const SizedBox(height: 18),
          _chartContainer(
            const RiskChart(),
            320,
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: _chartContainer(
            const AQIChart(),
            350,
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          flex: 2,
          child: _chartContainer(
            const RiskChart(),
            350,
          ),
        ),
      ],
    );
  }

  Widget _chartContainer(
    Widget child,
    double height,
  ) {
    return Container(
      height: height,
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            Colors.white.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: child,
      ),
    );
  }

  // ============================================================
  // DASHBOARD SECTION
  // ============================================================

  Widget _buildDashboardSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Widget child,
    required bool isMobile,
    String? buttonText,
    VoidCallback? onPressed,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color:
              Colors.white.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              14,
            ),
            child: isMobile
                ? Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: color.withValues(
                                alpha: 0.12,
                              ),
                              borderRadius:
                                  BorderRadius.circular(
                                13,
                              ),
                            ),
                            child: Icon(
                              icon,
                              color: color,
                              size: 21,
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
                                  style:
                                      const TextStyle(
                                    color:
                                        whiteColor,
                                    fontSize: 15,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(
                                    height: 4),
                                Text(
                                  subtitle,
                                  maxLines: 3,
                                  overflow:
                                      TextOverflow
                                          .ellipsis,
                                  style:
                                      const TextStyle(
                                    color:
                                        secondaryColor,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (buttonText != null &&
                          onPressed != null)
                        Padding(
                          padding:
                              const EdgeInsets.only(
                            top: 12,
                          ),
                          child: SizedBox(
                            width: double.infinity,
                            child:
                                OutlinedButton.icon(
                              onPressed: onPressed,
                              icon: const Icon(
                                Icons
                                    .arrow_forward_rounded,
                                size: 14,
                              ),
                              label:
                                  Text(buttonText),
                              style:
                                  OutlinedButton
                                      .styleFrom(
                                foregroundColor:
                                    color,
                                side: BorderSide(
                                  color: color
                                      .withValues(
                                    alpha: 0.30,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  )
                : Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: color.withValues(
                            alpha: 0.12,
                          ),
                          borderRadius:
                              BorderRadius.circular(
                            13,
                          ),
                        ),
                        child: Icon(
                          icon,
                          color: color,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style:
                                  const TextStyle(
                                color: whiteColor,
                                fontSize: 16,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              maxLines: 2,
                              overflow:
                                  TextOverflow.ellipsis,
                              style:
                                  const TextStyle(
                                color:
                                    secondaryColor,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (buttonText != null &&
                          onPressed != null)
                        OutlinedButton.icon(
                          onPressed: onPressed,
                          icon: const Icon(
                            Icons
                                .arrow_forward_rounded,
                            size: 14,
                          ),
                          label: Text(buttonText),
                          style:
                              OutlinedButton.styleFrom(
                            foregroundColor: color,
                            side: BorderSide(
                              color: color
                                  .withValues(
                                alpha: 0.30,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),

          Container(
            height: 1,
            color:
                Colors.white.withValues(alpha: 0.06),
          ),

          Padding(
            padding: const EdgeInsets.all(10),
            child: child,
          ),
        ],
      ),
    );
  }
}

// ================================================================
// DASHBOARD CARD DATA
// ================================================================

class _DashboardCardData {
  final String title;
  final String value;
  final String status;
  final IconData icon;
  final Color color;
  final Widget page;

  const _DashboardCardData({
    required this.title,
    required this.value,
    required this.status,
    required this.icon,
    required this.color,
    required this.page,
  });
}
