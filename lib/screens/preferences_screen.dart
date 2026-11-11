import 'dart:async';
import 'package:flutter/material.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen>
    with SingleTickerProviderStateMixin {



  // ============================================================
  // COLORS
  // ============================================================

  static const Color bg = Color(0xFF06111D);
  static const Color surface = Color(0xFF0B1928);
  static const Color surface2 = Color(0xFF0F2133);
  static const Color surface3 = Color(0xFF132A3E);

  static const Color cyan = Color(0xFF28D7E8);
  static const Color green = Color(0xFF39D98A);
  static const Color yellow = Color(0xFFFFC857);
  static const Color red = Color(0xFFFF6376);

  static const Color white = Color(0xFFEAF7FA);
  static const Color muted = Color(0xFF829BAD);
  static const Color muted2 = Color(0xFF587184);
  static const Color line = Color(0xFF1A3144);

  // ============================================================
  // STATE
  // ============================================================

  int selectedSection = 0;

  bool notifications = true;
  bool autoRefresh = true;
  bool visibilityMonitoring = true;
  bool motorwayMonitoring = true;
  bool soundAlerts = true;
  bool predictionConfidence = true;
  bool historicalTrend = true;
  bool airQualityData = true;

  bool routeM2 = true;
  bool routeM3 = true;
  bool routeM4 = true;

  double refreshRate = 30;
  double alertSensitivity = 65;
  double visibilityThreshold = 40;

  String monitoringMode = 'Automatic';
  String riskDisplay = 'Risk + AQI';

  String selectedRoute = 'M-2';

  late AnimationController animationController;

  Timer? _saveTimer;

  @override
  void initState() {
    super.initState();

    animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

  }

  @override
  void dispose() {
    animationController.dispose();
    _saveTimer?.cancel();
    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================


@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: bg,
    body: SafeArea(
      child: Column(
        children: [
          _topBar(),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 650;

                if (isMobile) {
                  return Column(
                    children: [
                      SizedBox(
                        height: 66,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          children: [
                            for (int i = 0; i < 6; i++)
                              Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: _mobileSectionButton(i),
                              ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(14),
                          child: _mainContent(),
                        ),
                      ),

Padding(
  padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
  child: Row(
    children: [
      Expanded(
        child: ElevatedButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.check_rounded, size: 18),
          label: const Text(
            'SAVE SETTINGS',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: cyan,
            foregroundColor: bg,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: OutlinedButton.icon(
          onPressed: _reset,
          icon: const Icon(Icons.restart_alt_rounded, size: 18),
          label: const Text(
            'RESET',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: yellow,
            side: const BorderSide(color: line),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    ],
  ),
),

                    ],
                  );
                }
return Row(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    _settingsSidebar(),
    Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: _mainContent(),
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

Widget _mobileSectionButton(int index) {
  const titles = [
    'General',
    'Monitoring',
    'Alerts',
    'Display',
    'Data & Sync',
    'Privacy',
  ];

  const icons = [
    Icons.dashboard_customize_outlined,
    Icons.radar_outlined,
    Icons.warning_amber_rounded,
    Icons.display_settings_outlined,
    Icons.sync_rounded,
    Icons.lock_outline_rounded,
  ];

  final selected = selectedSection == index;

  return OutlinedButton.icon(
    onPressed: () {
      setState(() {
        selectedSection = index;
      });
    },
    icon: Icon(
      icons[index],
      size: 16,
      color: selected ? cyan : muted,
    ),
    label: Text(titles[index]),
    style: OutlinedButton.styleFrom(
      foregroundColor: selected ? white : muted,
      side: BorderSide(
        color: selected ? cyan : line,
      ),
      backgroundColor: selected ? cyan.withAlpha(18) : surface,
      padding: const EdgeInsets.symmetric(horizontal: 12),
    ),
  );
}

  // ============================================================
  // TOP BAR
  // ============================================================


Widget _topBar() {
  final isMobile = MediaQuery.sizeOf(context).width < 650;

  return Container(
    height: 64,
    padding: EdgeInsets.symmetric(horizontal: isMobile ? 4 : 24),
    decoration: const BoxDecoration(
      color: surface,
      border: Border(
        bottom: BorderSide(color: line),
      ),
    ),
    child: Row(
      children: [
        IconButton(
          tooltip: 'Back to User Dashboard',
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: cyan,
          ),
        ),
        const Icon(
          Icons.tune_rounded,
          color: cyan,
          size: 22,
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PREFERENCES',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: white,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Monitoring Control Center',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: muted,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
        if (!isMobile)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: green.withAlpha(18),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: green.withAlpha(55)),
            ),
            child: Row(
              children: [
                _liveDot(),
                const SizedBox(width: 7),
                const Text(
                  'LIVE MONITORING',
                  style: TextStyle(
                    color: green,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        IconButton(
          tooltip: 'Refresh preferences',
          onPressed: () {
            _showMessage('Preferences refreshed');
          },
          icon: const Icon(
            Icons.refresh_rounded,
            color: muted,
            size: 20,
          ),
        ),
      ],
    ),
  );


  }

  Widget _liveDot() {
    return AnimatedBuilder(
      animation: animationController,
      builder: (context, child) {
        final opacity =
            0.35 + (animationController.value * 0.65);

        return Opacity(
          opacity: opacity,
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: green,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // SETTINGS SIDEBAR
  // ============================================================

  Widget _settingsSidebar() {
    return Container(
      width: 210,
      color: surface,
      padding: const EdgeInsets.fromLTRB(14, 20, 14, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              'SETTINGS',
              style: TextStyle(
                color: muted2,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.3,
              ),
            ),
          ),
          const SizedBox(height: 2),

          _sidebarItem(
            icon: Icons.dashboard_customize_outlined,
            title: 'General',

            index: 0,
          ),

          _sidebarItem(
            icon: Icons.radar_outlined,
            title: 'Monitoring',
            index: 1,
          ),

          _sidebarItem(
            icon: Icons.warning_amber_rounded,
            title: 'Alerts',
            index: 2,
          ),

          _sidebarItem(
            icon: Icons.display_settings_outlined,
            title: 'Display',
            index: 3,
          ),

          _sidebarItem(
            icon: Icons.sync_rounded,
            title: 'Data & Sync',
            index: 4,
          ),

          _sidebarItem(
            icon: Icons.lock_outline_rounded,
            title: 'Privacy',
            index: 5,
          ),

          const Spacer(),

          _systemStatusMini(),

          const SizedBox(height: 15),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(
                Icons.check_rounded,
                size: 16,
              ),
              label: const Text(
                'SAVE SETTINGS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: cyan,
                foregroundColor: bg,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _reset,
              style: OutlinedButton.styleFrom(
                foregroundColor: muted,
                side: const BorderSide(color: line),
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'RESET',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sidebarItem({
    required IconData icon,
    required String title,
    required int index,
  }) {
    final selected = selectedSection == index;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: selected
            ? cyan.withAlpha(18)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selected
              ? cyan.withAlpha(50)
              : Colors.transparent,
        ),
      ),
      child: ListTile(
        dense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10),
        onTap: () {
          setState(() {
            selectedSection = index;
          });
        },
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
        trailing: selected
            ? const Icon(
                Icons.chevron_right_rounded,
                color: cyan,
                size: 16,
              )
            : null,
      ),
    );
  }

  Widget _systemStatusMini() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: surface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: line),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.monitor_heart_outlined,
                color: green,
                size: 15,
              ),
              SizedBox(width: 7),
              Text(
                'SYSTEM HEALTH',
                style: TextStyle(
                  color: muted,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          SizedBox(height: 9),
          Text(
            '98%',
            style: TextStyle(
              color: green,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 3),
          Text(
            'All systems operational',
            style: TextStyle(
              color: muted2,
              fontSize: 8.5,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MAIN CONTENT
  // ============================================================



Widget _mainContent() {
  return Padding(
    padding: const EdgeInsets.all(4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _pageHeader(),
        const SizedBox(height: 20),
        _quickControls(),
        const SizedBox(height: 20),
        _sectionContent(),
        const SizedBox(height: 22),
        _monitoringMap(),
        const SizedBox(height: 20),
        _livePreview(),
        const SizedBox(height: 20),
        _systemConnections(),
        const SizedBox(height: 30),
      ],
    ),
  );
}


  // ============================================================
  // PAGE HEADER
  // ============================================================


Widget _pageHeader() {
  return LayoutBuilder(
    builder: (context, constraints) {
      final isMobile = constraints.maxWidth < 600;

      final heading = const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'System Preferences',
            style: TextStyle(
              color: white,
              fontSize: 25,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Configure monitoring behaviour, alerts, routes and dashboard display.',
            style: TextStyle(
              color: muted,
              fontSize: 11,
            ),
          ),
        ],
      );

      final syncBadge = Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 13,
          vertical: 9,
        ),
        decoration: BoxDecoration(
          color: surface2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: line),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.access_time_rounded,
              color: cyan,
              size: 15,
            ),
            SizedBox(width: 7),
            Text(
              'SYNCED 12 SEC AGO',
              style: TextStyle(
                color: muted,
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );

      if (isMobile) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            heading,
            const SizedBox(height: 12),
            syncBadge,
          ],
        );
      }

      return Row(
        children: [
          Expanded(child: heading),
          const SizedBox(width: 12),
          syncBadge,
        ],
      );
    },
  );
}


  // ============================================================
  // QUICK CONTROLS
  // ============================================================


Widget _quickControls() {
  return LayoutBuilder(
    builder: (context, constraints) {
      final isMobile = constraints.maxWidth < 600;
      final gap = 10.0;
      final itemWidth = isMobile
          ? (constraints.maxWidth - gap) / 2
          : (constraints.maxWidth - gap * 3) / 4;

      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          SizedBox(
            width: itemWidth,
            child: _quickControl(
              icon: Icons.notifications_none_rounded,
              title: 'Notifications',
              subtitle: notifications ? 'Enabled' : 'Disabled',
              value: notifications,
              onChanged: (v) {
                setState(() => notifications = v);
              },
            ),
          ),
          SizedBox(
            width: itemWidth,
            child: _quickControl(
              icon: Icons.autorenew_rounded,
              title: 'Auto Refresh',
              subtitle: autoRefresh
                  ? '${refreshRate.round()} sec'
                  : 'Paused',
              value: autoRefresh,
              onChanged: (v) {
                setState(() => autoRefresh = v);
              },
            ),
          ),
          SizedBox(
            width: itemWidth,
            child: _quickControl(
              icon: Icons.visibility_outlined,
              title: 'Visibility',
              subtitle: visibilityMonitoring
                  ? 'Monitoring'
                  : 'Disabled',
              value: visibilityMonitoring,
              onChanged: (v) {
                setState(() => visibilityMonitoring = v);
              },
            ),
          ),
          SizedBox(
            width: itemWidth,
            child: _quickControl(
              icon: Icons.alt_route_rounded,
              title: 'Motorway Network',
              subtitle: motorwayMonitoring ? 'Active' : 'Disabled',
              value: motorwayMonitoring,
              onChanged: (v) {
                setState(() => motorwayMonitoring = v);
              },
            ),
          ),
        ],
      );
    },
  );
}

  Widget _quickControl({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: value ? cyan.withAlpha(45) : line,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              color: value
                  ? cyan.withAlpha(18)
                  : surface3,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              icon,
              color: value ? cyan : muted,
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
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: value ? green : muted2,
                    fontSize: 8,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: cyan,
            activeTrackColor: cyan.withAlpha(60),
            inactiveThumbColor: muted2,
            inactiveTrackColor: surface3,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION CONTENT
  // ============================================================

  Widget _sectionContent() {
    switch (selectedSection) {
      case 1:
        return _monitoringSettings();

      case 2:
        return _alertSettings();

      case 3:
        return _displaySettings();

      case 4:
        return _dataSettings();

      case 5:
        return _privacySettings();

      default:
        return _generalSettings();
    }
  }

  // ============================================================
  // GENERAL
  // ============================================================

  Widget _generalSettings() {
    return _settingsPanel(
      title: 'General Settings',
      icon: Icons.dashboard_customize_outlined,
      subtitle: 'Basic monitoring behaviour and system operation.',
      child: Column(
        children: [
          _settingRow(
            title: 'Monitoring Mode',
            subtitle:
                'Choose how the prediction system operates.',
            trailing: _segmentedControl(
              options: const [
                'Automatic',
                'Manual',
              ],
              selected: monitoringMode,
              onChanged: (value) {
                setState(() {
                  monitoringMode = value;
                });
              },
            ),
          ),
          const Divider(color: line),
          _switchRow(
            title: 'Notifications',
            subtitle:
                'Receive notifications for important risk changes.',
            value: notifications,
            onChanged: (v) {
              setState(() {
                notifications = v;
              });
            },
          ),
          const Divider(color: line),
          _switchRow(
            title: 'Automatic Refresh',
            subtitle:
                'Automatically refresh latest monitoring data.',
            value: autoRefresh,
            onChanged: (v) {
              setState(() {
                autoRefresh = v;
              });
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MONITORING
  // ============================================================

  Widget _monitoringSettings() {
    return _settingsPanel(
      title: 'Monitoring Configuration',
      icon: Icons.radar_outlined,
      subtitle:
          'Control motorway routes and environmental monitoring.',
      child: Column(
        children: [
          _routeSetting(
            route: 'M-2',
            title: 'Lahore → Islamabad',
            subtitle: 'Primary motorway corridor',
            value: routeM2,
            color: green,
            onChanged: (v) {
              setState(() {
                routeM2 = v;
              });
            },
          ),
          const Divider(color: line),
          _routeSetting(
            route: 'M-3',
            title: 'Lahore → Faisalabad',
            subtitle: 'Central motorway corridor',
            value: routeM3,
            color: yellow,
            onChanged: (v) {
              setState(() {
                routeM3 = v;
              });
            },
          ),
          const Divider(color: line),
          _routeSetting(
            route: 'M-4',
            title: 'Multan Corridor',
            subtitle: 'Southern motorway corridor',
            value: routeM4,
            color: red,
            onChanged: (v) {
              setState(() {
                routeM4 = v;
              });
            },
          ),
          const Divider(color: line),
          _switchRow(
            title: 'Visibility Monitoring',
            subtitle:
                'Monitor visibility conditions along active routes.',
            value: visibilityMonitoring,
            onChanged: (v) {
              setState(() {
                visibilityMonitoring = v;
              });
            },
          ),
          const Divider(color: line),
          _sliderSetting(
            title: 'Visibility Threshold',
            subtitle:
                'Trigger warning when visibility drops below this level.',
            value: visibilityThreshold,
            min: 10,
            max: 100,
            suffix: '%',
            onChanged: (v) {
              setState(() {
                visibilityThreshold = v;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _routeSetting({
    required String route,
    required String title,
    required String subtitle,
    required bool value,
    required Color color,
    required ValueChanged<bool> onChanged,
  }) {
    return InkWell(
      onTap: () {
        setState(() {
          selectedRoute = route;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withAlpha(18),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: color.withAlpha(45),
                ),
              ),
              child: Center(
                child: Text(
                  route,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: muted,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: color,
              activeTrackColor: color.withAlpha(55),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ALERTS
  // ============================================================

  Widget _alertSettings() {
    return _settingsPanel(
      title: 'Risk Alert Settings',
      icon: Icons.warning_amber_rounded,
      subtitle:
          'Configure when and how risk alerts are generated.',
      child: Column(
        children: [
          _sliderSetting(
            title: 'Alert Sensitivity',
            subtitle:
                'Higher sensitivity generates alerts earlier.',
            value: alertSensitivity,
            min: 0,
            max: 100,
            suffix: '%',
            onChanged: (v) {
              setState(() {
                alertSensitivity = v;
              });
            },
          ),
          const Divider(color: line),
          _switchRow(
            title: 'Push Notifications',
            subtitle:
                'Show alerts when risk level changes.',
            value: notifications,
            onChanged: (v) {
              setState(() {
                notifications = v;
              });
            },
          ),
          const Divider(color: line),
          _switchRow(
            title: 'Sound Warning',
            subtitle:
                'Play an audio warning for critical alerts.',
            value: soundAlerts,
            onChanged: (v) {
              setState(() {
                soundAlerts = v;
              });
            },
          ),
          const Divider(color: line),
          _riskLegend(),
        ],
      ),
    );
  }


Widget _riskLegend() {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Wrap(
      spacing: 12,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Text(
          'Risk indicators',
          style: TextStyle(
            color: white,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
        _legendItem(green, 'SAFE'),
        _legendItem(yellow, 'MODERATE'),
        _legendItem(red, 'HIGH'),
      ],
    ),
  );
}


  Widget _legendItem(Color color, String text) {
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
        const SizedBox(width: 5),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 8,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // DISPLAY
  // ============================================================

  Widget _displaySettings() {
    return _settingsPanel(
      title: 'Dashboard Display',
      icon: Icons.display_settings_outlined,
      subtitle:
          'Choose what information is visible on the dashboard.',
      child: Column(
        children: [
          _settingRow(
            title: 'Risk Display',
            subtitle:
                'Select the information shown with risk status.',
            trailing: _segmentedControl(
              options: const [
                'Risk Only',
                'Risk + AQI',
                'Full View',
              ],
              selected: riskDisplay,
              onChanged: (value) {
                setState(() {
                  riskDisplay = value;
                });
              },
            ),
          ),
          const Divider(color: line),
          _switchRow(
            title: 'Prediction Confidence',
            subtitle:
                'Display model confidence percentage.',
            value: predictionConfidence,
            onChanged: (v) {
              setState(() {
                predictionConfidence = v;
              });
            },
          ),
          const Divider(color: line),
          _switchRow(
            title: 'Historical Trend',
            subtitle:
                'Show recent risk trend information.',
            value: historicalTrend,
            onChanged: (v) {
              setState(() {
                historicalTrend = v;
              });
            },
          ),
          const Divider(color: line),
          _switchRow(
            title: 'Air Quality Data',
            subtitle:
                'Display AQI and environmental measurements.',
            value: airQualityData,
            onChanged: (v) {
              setState(() {
                airQualityData = v;
              });
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DATA
  // ============================================================


Widget _dataSettings() {
  return _settingsPanel(
    title: 'Data & Synchronization',
    icon: Icons.sync_rounded,
    subtitle:
        'Manage refresh timing and data synchronization.',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _switchRow(
          title: 'Auto Refresh',
          subtitle:
              'Keep monitoring information updated automatically.',
          value: autoRefresh,
          onChanged: (v) {
            setState(() {
              autoRefresh = v;
            });
          },
        ),
        const Divider(color: line),
        _sliderSetting(
          title: 'Refresh Frequency',
          subtitle:
              'Set the interval for new monitoring data.',
          value: refreshRate,
          min: 10,
          max: 120,
          suffix: ' sec',
          onChanged: (v) {
            setState(() {
              refreshRate = v;
            });
          },
        ),
        const Divider(color: line),
        _connectionStatus(),
      ],
    ),
  );
}


Widget _connectionStatus() {
  return LayoutBuilder(
    builder: (context, constraints) {
      final isMobile = constraints.maxWidth < 450;

      final connectionInfo = const Row(
        children: [
          Icon(
            Icons.cloud_done_outlined,
            color: green,
            size: 20,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Data Connection',
                  style: TextStyle(
                    color: white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Latest data synchronized successfully',
                  style: TextStyle(
                    color: muted,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
        ],
      );

      final statusBadge = Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 9,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: green.withAlpha(18),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'CONNECTED',
          style: TextStyle(
            color: green,
            fontSize: 8,
            fontWeight: FontWeight.w900,
          ),
        ),
      );

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: isMobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  connectionInfo,
                  const SizedBox(height: 12),
                  statusBadge,
                ],
              )
            : Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: green.withAlpha(18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.cloud_done_outlined,
                      color: green,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Data Connection',
                          style: TextStyle(
                            color: white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Latest data synchronized successfully',
                          style: TextStyle(
                            color: muted,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                  statusBadge,
                ],
              ),
      );
    },
  );
}


  // ============================================================
  // PRIVACY
  // ============================================================


Widget _privacySettings() {
  return LayoutBuilder(
    builder: (context, constraints) {
      final isMobile = constraints.maxWidth < 450;

      return _settingsPanel(
        title: 'Privacy & Security',
        icon: Icons.lock_outline_rounded,
        subtitle:
            'Information about system data and local settings.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow(
              Icons.security_outlined,
              'Local Configuration',
              'Your dashboard preferences are managed locally.',
            ),
            const Divider(color: line),
            _infoRow(
              Icons.storage_outlined,
              'Monitoring Data',
              'Risk information is used for system monitoring.',
            ),
            const Divider(color: line),
            _infoRow(
              Icons.admin_panel_settings_outlined,
              'Access Control',
              'System settings are available to authorized users.',
            ),
          ],
        ),
      );
    },
  );
}

  // ============================================================
  // SETTINGS PANEL
  // ============================================================

  Widget _settingsPanel({
    required String title,
    required IconData icon,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: line),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 32,
                decoration: BoxDecoration(
                  color: cyan.withAlpha(18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: cyan,
                  size: 19,
                ),
              ),
              const SizedBox(width: 11),
              Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: white,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: muted,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 17),
          child,
        ],
      ),
    );
  }

  // ============================================================
  // ROW HELPERS
  // ============================================================

  Widget _settingRow({
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: muted,
                    fontSize: 8.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 15),
          trailing,
        ],
      ),
    );
  }

  Widget _switchRow({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: muted,
                    fontSize: 8.5,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: cyan,
            activeTrackColor: cyan.withAlpha(55),
            inactiveThumbColor: muted2,
            inactiveTrackColor: surface3,
          ),
        ],
      ),
    );
  }

  Widget _sliderSetting({
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required String suffix,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: muted,
                        fontSize: 8.5,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${value.round()}$suffix',
                style: const TextStyle(
                  color: cyan,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: cyan,
              inactiveTrackColor: surface3,
              thumbColor: cyan,
              overlayColor: cyan.withAlpha(20),
              trackHeight: 4,
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _segmentedControl({
    required List<String> options,
    required String selected,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: surface2,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: options.map((option) {
          final active = option == selected;

          return GestureDetector(
            onTap: () => onChanged(option),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(
                horizontal: 9,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color: active
                    ? cyan.withAlpha(30)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                option,
                style: TextStyle(
                  color: active ? cyan : muted,
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _infoRow(
    IconData icon,
    String title,
    String subtitle,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          Icon(
            icon,
            color: cyan,
            size: 19,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: muted,
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
  // MONITORING MAP
  // ============================================================


Widget _monitoringMap() {
  return LayoutBuilder(
    builder: (context, outerConstraints) {
      final isMobile = outerConstraints.maxWidth < 600;

      return Container(
        height: isMobile ? 390 : 410,
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: line),
        ),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                isMobile ? 12 : 18,
                15,
                isMobile ? 12 : 18,
                12,
              ),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.map_outlined,
                        color: cyan,
                        size: 19,
                      ),
                      SizedBox(width: 9),
                      Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Motorway Monitoring Map',
                            style: TextStyle(
                              color: white,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Interactive live route coverage',
                            style: TextStyle(
                              color: muted,
                              fontSize: 8.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      _legendItem(green, 'SAFE'),
                      _legendItem(yellow, 'MODERATE'),
                      _legendItem(red, 'HIGH'),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(
              color: line,
              height: 1,
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 400;
                  final width = constraints.maxWidth;
                  final height = constraints.maxHeight;

                  return Stack(
                    clipBehavior: Clip.hardEdge,
                    children: [
                      Positioned.fill(
                        child: AnimatedBuilder(
                          animation: animationController,
                          builder: (context, child) {
                            return CustomPaint(
                              painter: _NetworkPainter(
                                animationValue:
                                    animationController.value,
                                routeM2: routeM2,
                                routeM3: routeM3,
                                routeM4: routeM4,
                                selectedRoute: selectedRoute,
                              ),
                              child: const SizedBox.expand(),
                            );
                          },
                        ),
                      ),

                      _mapNode(
                        left: width * (isNarrow ? 0.04 : 0.16),
                        top: height * 0.54,
                        city: 'Lahore',
                        route: 'M-2 / M-3',
                        color: green,
                        onTap: () {
                          setState(() {
                            selectedRoute =
                                routeM2 ? 'M-2' : 'M-3';
                          });
                        },
                      ),

                      _mapNode(
                        left: width * (isNarrow ? 0.59 : 0.70),
                        top: height * 0.12,
                        city: 'Islamabad',
                        route: 'M-2',
                        color: green,
                        onTap: () {
                          setState(() {
                            selectedRoute = 'M-2';
                          });
                        },
                      ),

                      _mapNode(
                        left: width * (isNarrow ? 0.35 : 0.49),
                        top: height * 0.43,
                        city: 'Faisalabad',
                        route: 'M-3',
                        color: yellow,
                        onTap: () {
                          setState(() {
                            selectedRoute = 'M-3';
                          });
                        },
                      ),

                      _mapNode(
                        left: width * (isNarrow ? 0.61 : 0.72),
                        top: height * 0.65,
                        city: 'Multan',
                        route: 'M-4',
                        color: red,
                        onTap: () {
                          setState(() {
                            selectedRoute = 'M-4';
                          });
                        },
                      ),

                      Positioned(
                        left: 8,
                        bottom: 8,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: width - 16,
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: _mapInfo(),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}

  Widget _mapNode({
    required double left,
    required double top,
    required String city,
    required String route,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            AnimatedBuilder(
              animation: animationController,
              builder: (context, child) {
                final pulse =
                    0.8 +
                    (animationController.value * 0.2);

                return Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withAlpha(28),
                    border: Border.all(
                      color: color.withAlpha(
                        (90 * pulse).round(),
                      ),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withAlpha(35),
                        blurRadius: 14,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 5),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: surface2,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: selectedRoute ==
                          route.split(' / ').first
                      ? cyan
                      : line,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    city,
                    style: const TextStyle(
                      color: white,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    route,
                    style: TextStyle(
                      color: color,
                      fontSize: 7,
                      fontWeight: FontWeight.w800,
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

  Widget _mapInfo() {
    Color routeColor;

    if (selectedRoute == 'M-2') {
      routeColor = green;
    } else if (selectedRoute == 'M-3') {
      routeColor = yellow;
    } else {
      routeColor = red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: surface2.withAlpha(235),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: routeColor.withAlpha(80),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: routeColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 7),
          Text(
            '$selectedRoute SELECTED',
            style: TextStyle(
              color: routeColor,
              fontSize: 8,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Click a node to inspect route',
            style: const TextStyle(
              color: muted,
              fontSize: 8,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LIVE PREVIEW
  // ============================================================


Widget _livePreview() {
  return LayoutBuilder(
    builder: (context, constraints) {
      final isMobile = constraints.maxWidth < 600;

      return Container(
        padding: EdgeInsets.all(isMobile ? 12 : 18),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.preview_outlined,
                      color: cyan,
                      size: 19,
                    ),
                    SizedBox(width: 9),
                    Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Live Dashboard Preview',
                          style: TextStyle(
                            color: white,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Preview changes in real time',
                          style: TextStyle(
                            color: muted,
                            fontSize: 8.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: cyan.withAlpha(15),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: const Text(
                    'LIVE PREVIEW',
                    style: TextStyle(
                      color: cyan,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            if (isMobile) ...[
              Center(child: _healthRing()),
              const SizedBox(height: 18),

              _previewRoute(
                'M-2',
                'Lahore → Islamabad',
                green,
                routeM2,
              ),
              const SizedBox(height: 8),
              _previewRoute(
                'M-3',
                'Lahore → Faisalabad',
                yellow,
                routeM3,
              ),
              const SizedBox(height: 8),
              _previewRoute(
                'M-4',
                'Multan Corridor',
                red,
                routeM4,
              ),

              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: _previewStats(),
              ),
            ] else ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _healthRing(),
                  const SizedBox(width: 20),

                  Expanded(
                    child: Column(
                      children: [
                        _previewRoute(
                          'M-2',
                          'Lahore → Islamabad',
                          green,
                          routeM2,
                        ),
                        const SizedBox(height: 8),
                        _previewRoute(
                          'M-3',
                          'Lahore → Faisalabad',
                          yellow,
                          routeM3,
                        ),
                        const SizedBox(height: 8),
                        _previewRoute(
                          'M-4',
                          'Multan Corridor',
                          red,
                          routeM4,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 20),
                  _previewStats(),
                ],
              ),
            ],
          ],
        ),
      );
    },
  );
}

  Widget _healthRing() {
    return SizedBox(
      width: 105,
      height: 105,
      child: AnimatedBuilder(
        animation: animationController,
        builder: (context, child) {
          return CustomPaint(
            painter: _RingPainter(
              progress: 0.98,
              pulse: animationController.value,
            ),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '98%',
                    style: TextStyle(
                      color: green,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'HEALTH',
                    style: TextStyle(
                      color: muted,
                      fontSize: 7,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _previewRoute(
    String route,
    String name,
    Color color,
    bool enabled,
  ) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedRoute = route;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 11,
          vertical: 9,
        ),
        decoration: BoxDecoration(
          color: enabled
              ? color.withAlpha(10)
              : surface2,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: selectedRoute == route
                ? color.withAlpha(100)
                : line,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: enabled ? color : muted2,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              route,
              style: TextStyle(
                color: enabled ? color : muted2,
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  color: enabled ? white : muted2,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              enabled ? 'ACTIVE' : 'OFF',
              style: TextStyle(
                color: enabled ? color : muted2,
                fontSize: 7,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _previewStats() {
    return Container(
      width: 190,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: surface2,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: line),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'CURRENT CONFIGURATION',
            style: TextStyle(
              color: muted2,
              fontSize: 7.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          _statLine(
            'Mode',
            monitoringMode,
          ),
          _statLine(
            'Refresh',
            autoRefresh
                ? '${refreshRate.round()} sec'
                : 'OFF',
          ),
          _statLine(
            'Alerts',
            notifications ? 'ON' : 'OFF',
          ),
          _statLine(
            'Visibility',
            visibilityMonitoring ? 'ON' : 'OFF',
          ),
          _statLine(
            'Display',
            riskDisplay,
          ),
        ],
      ),
    );
  }

  Widget _statLine(
    String title,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: muted,
              fontSize: 8,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: white,
              fontSize: 8,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SYSTEM CONNECTIONS
  // ============================================================


Widget _systemConnections() {
  return LayoutBuilder(
    builder: (context, constraints) {
      const gap = 12.0;
      const minCardWidth = 180.0;

      final columns = (constraints.maxWidth / (minCardWidth + gap))
          .floor()
          .clamp(1, 4);

      final cardWidth =
          (constraints.maxWidth - (gap * (columns - 1))) / columns;

      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          SizedBox(
            width: cardWidth,
            child: _connectionCard(
              icon: Icons.cloud_done_outlined,
              title: 'DATA API',
              value: '100%',
              subtitle: 'Connected',
              color: green,
            ),
          ),
          SizedBox(
            width: cardWidth,
            child: _connectionCard(
              icon: Icons.psychology_outlined,
              title: 'PREDICTION',
              value: '100%',
              subtitle: 'Operational',
              color: green,
            ),
          ),
          SizedBox(
            width: cardWidth,
            child: _connectionCard(
              icon: Icons.visibility_outlined,
              title: 'VISIBILITY',
              value: '96%',
              subtitle: 'Monitoring',
              color: cyan,
            ),
          ),
          SizedBox(
            width: cardWidth,
            child: _connectionCard(
              icon: Icons.storage_outlined,
              title: 'DATABASE',
              value: '100%',
              subtitle: 'Healthy',
              color: green,
            ),
          ),
        ],
      );
    },
  );
}

  Widget _connectionCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: line),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 21,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: muted,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: muted2,
                    fontSize: 7.5,
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
  // SAVE / RESET
  // ============================================================

  void _save() {
    _saveTimer?.cancel();

    setState(() {});

    _showMessage(
      'Preferences saved successfully',
      color: green,
    );
  }

  void _reset() {
    setState(() {
      selectedSection = 0;

      notifications = true;
      autoRefresh = true;
      visibilityMonitoring = true;
      motorwayMonitoring = true;
      soundAlerts = true;
      predictionConfidence = true;
      historicalTrend = true;
      airQualityData = true;

      routeM2 = true;
      routeM3 = true;
      routeM4 = true;

      refreshRate = 30;
      alertSensitivity = 65;
      visibilityThreshold = 40;

      monitoringMode = 'Automatic';
      riskDisplay = 'Risk + AQI';

      selectedRoute = 'M-2';
    });

    _showMessage(
      'Preferences reset to default',
      color: yellow,
    );
  }

  void _showMessage(
    String message, {
    Color color = cyan,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              color: color,
              size: 18,
            ),
            const SizedBox(width: 9),
            Text(
              message,
              style: const TextStyle(
                color: white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        backgroundColor: surface3,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}

// ================================================================
// NETWORK PAINTER
// ================================================================

class _NetworkPainter extends CustomPainter {
  final double animationValue;

  final bool routeM2;
  final bool routeM3;
  final bool routeM4;

  final String selectedRoute;

  _NetworkPainter({
    required this.animationValue,
    required this.routeM2,
    required this.routeM3,
    required this.routeM4,
    required this.selectedRoute,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    // ------------------------------------------------------------
    // BACKGROUND
    // ------------------------------------------------------------

    final bgPaint = Paint()
      ..color = const Color(0xFF081522);

    canvas.drawRect(
      Offset.zero & size,
      bgPaint,
    );

    // ------------------------------------------------------------
    // GRID
    // ------------------------------------------------------------

    final gridPaint = Paint()
      ..color = const Color(0xFF11283A)
      ..strokeWidth = 0.7;

    const double grid = 28;

    for (double x = 0; x <= size.width; x += grid) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        gridPaint,
      );
    }

    for (double y = 0; y <= size.height; y += grid) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }

    // ------------------------------------------------------------
    // MAP AREA
    // ------------------------------------------------------------

    final lahore = Offset(
      size.width * 0.20,
      size.height * 0.58,
    );

    final islamabad = Offset(
      size.width * 0.73,
      size.height * 0.24,
    );

    final faisalabad = Offset(
      size.width * 0.52,
      size.height * 0.53,
    );

    final multan = Offset(
      size.width * 0.75,
      size.height * 0.76,
    );

    // ------------------------------------------------------------
    // ROUTES
    // ------------------------------------------------------------

    if (routeM2) {
      _drawRoute(
        canvas,
        lahore,
        islamabad,
        const Color(0xFF39D98A),
        selectedRoute == 'M-2',
      );
    }

    if (routeM3) {
      _drawRoute(
        canvas,
        lahore,
        faisalabad,
        const Color(0xFFFFC857),
        selectedRoute == 'M-3',
      );
    }

    if (routeM4) {
      _drawRoute(
        canvas,
        faisalabad,
        multan,
        const Color(0xFFFF6376),
        selectedRoute == 'M-4',
      );
    }

    // ------------------------------------------------------------
    // MOVING LIVE PULSE
    // ------------------------------------------------------------

    if (routeM2 && selectedRoute == 'M-2') {
      _drawPulse(
        canvas,
        lahore,
        islamabad,
        animationValue,
        const Color(0xFF39D98A),
      );
    }

    if (routeM3 && selectedRoute == 'M-3') {
      _drawPulse(
        canvas,
        lahore,
        faisalabad,
        animationValue,
        const Color(0xFFFFC857),
      );
    }

    if (routeM4 && selectedRoute == 'M-4') {
      _drawPulse(
        canvas,
        faisalabad,
        multan,
        animationValue,
        const Color(0xFFFF6376),
      );
    }

    // ------------------------------------------------------------
    // MAP HEADER LABEL
    // ------------------------------------------------------------

    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'LIVE ROUTE COVERAGE',
        style: TextStyle(
          color: Color(0xFF587184),
          fontSize: 8,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.3,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    textPainter.paint(
      canvas,
      const Offset(18, 16),
    );
  }

  void _drawRoute(
    Canvas canvas,
    Offset start,
    Offset end,
    Color color,
    bool selected,
  ) {
    final path = Path();

    path.moveTo(
      start.dx,
      start.dy,
    );

    final control1 = Offset(
      (start.dx + end.dx) / 2,
      start.dy - 35,
    );

    final control2 = Offset(
      (start.dx + end.dx) / 2,
      end.dy + 35,
    );

    path.cubicTo(
      control1.dx,
      control1.dy,
      control2.dx,
      control2.dy,
      end.dx,
      end.dy,
    );

    // glow
    final glowPaint = Paint()
      ..color = color.withAlpha(
        selected ? 35 : 18,
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = selected ? 9 : 5
      ..maskFilter = const MaskFilter.blur(
        BlurStyle.normal,
        7,
      );

    canvas.drawPath(
      path,
      glowPaint,
    );

    // actual route
    final routePaint = Paint()
      ..color = color.withAlpha(
        selected ? 235 : 115,
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = selected ? 2.5 : 1.5;

    canvas.drawPath(
      path,
      routePaint,
    );

    // route dots
    final dotPaint = Paint()
      ..color = color.withAlpha(110)
      ..style = PaintingStyle.fill;

    for (int i = 1; i < 6; i++) {
      final t = i / 6;

      final x = start.dx +
          (end.dx - start.dx) * t;

      final y = start.dy +
          (end.dy - start.dy) * t;

      canvas.drawCircle(
        Offset(x, y),
        2,
        dotPaint,
      );
    }
  }

  void _drawPulse(
    Canvas canvas,
    Offset start,
    Offset end,
    double value,
    Color color,
  ) {
    final t = value;

    final x = start.dx +
        (end.dx - start.dx) * t;

    final y = start.dy +
        (end.dy - start.dy) * t;

    final glow = Paint()
      ..color = color.withAlpha(75)
      ..maskFilter = const MaskFilter.blur(
        BlurStyle.normal,
        10,
      );

    canvas.drawCircle(
      Offset(x, y),
      7,
      glow,
    );

    final dot = Paint()
      ..color = color;

    canvas.drawCircle(
      Offset(x, y),
      3.5,
      dot,
    );
  }

  @override
  bool shouldRepaint(
    covariant _NetworkPainter oldDelegate,
  ) {
    return oldDelegate.animationValue !=
            animationValue ||
        oldDelegate.routeM2 != routeM2 ||
        oldDelegate.routeM3 != routeM3 ||
        oldDelegate.routeM4 != routeM4 ||
        oldDelegate.selectedRoute != selectedRoute;
  }
}

// ================================================================
// HEALTH RING PAINTER
// ================================================================

class _RingPainter extends CustomPainter {
  final double progress;
  final double pulse;

  _RingPainter({
    required this.progress,
    required this.pulse,
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
        (size.width / 2) - 8;

    final backgroundPaint = Paint()
      ..color = const Color(0xFF132A3E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;

    canvas.drawCircle(
      center,
      radius,
      backgroundPaint,
    );

    final progressPaint = Paint()
      ..color = const Color(0xFF39D98A)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 8;

    final rect = Rect.fromCircle(
      center: center,
      radius: radius,
    );

    canvas.drawArc(
      rect,
      -1.5708,
      6.28318 * progress,
      false,
      progressPaint,
    );

    final glowPaint = Paint()
      ..color = const Color(0xFF39D98A)
          .withAlpha(35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..maskFilter = const MaskFilter.blur(
        BlurStyle.normal,
        8,
      );

    canvas.drawArc(
      rect,
      -1.5708,
      6.28318 * progress,
      false,
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(
    covariant _RingPainter oldDelegate,
  ) {
    return oldDelegate.pulse != pulse;
  }
}