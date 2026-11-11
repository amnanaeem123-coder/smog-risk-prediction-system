
import 'dart:async';

import 'package:flutter/material.dart';
import 'login_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _glowController;
  late AnimationController _logoController;
  late Animation<double> _logoAnimation;

  @override
  void initState() {
    super.initState();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _logoAnimation = CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeOutBack,
    );

    _logoController.forward();

    Timer(const Duration(seconds: 4), () {
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => LoginPage(),
        ),
      );
    });
  }

  @override
  void dispose() {
    _glowController.dispose();
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF071525);
    const navy2 = Color(0xFF091A2B);
    const panel = Color(0xFF0D2236);
    const panel2 = Color(0xFF102B43);
    const blue = Color(0xFF1687E8);
    const cyan = Color(0xFF20C4E8);

    return Scaffold(
      backgroundColor: navy,
      body: Stack(
        children: [
          // Dark navy animated background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _glowController,
              builder: (context, child) {
                final glow = _glowController.value;

                return Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(0, -0.2 + glow * 0.15),
                      radius: 1.1,
                      colors: [
                        panel2.withOpacity(0.70 + glow * 0.12),
                        navy2,
                        navy,
                      ],
                      stops: const [0.0, 0.48, 1.0],
                    ),
                  ),
                );
              },
            ),
          ),

          // Subtle cyan glow rings
          Center(
            child: AnimatedBuilder(
              animation: _glowController,
              builder: (context, child) {
                final glow = _glowController.value;

                return Container(
                  width: 250 + glow * 18,
                  height: 250 + glow * 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: cyan.withOpacity(0.10 + glow * 0.12),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: cyan.withOpacity(0.06 + glow * 0.08),
                        blurRadius: 45,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Main content
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated shield logo
                    ScaleTransition(
                      scale: _logoAnimation,
                      child: Container(
                        width: 118,
                        height: 118,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(32),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              cyan,
                              blue,
                              Color(0xFF104B8D),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: cyan.withOpacity(0.28),
                              blurRadius: 35,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.shield_rounded,
                          size: 68,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    const SizedBox(height: 34),

                    // App name
                    ShaderMask(
                      shaderCallback: (bounds) {
                        return const LinearGradient(
                          colors: [
                            Color(0xFFF4F8FC),
                            cyan,
                          ],
                        ).createShader(bounds);
                      },
                      child: const Text(
                        'SMOGGUARD',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3.5,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      'SMOG RISK PREDICTION SYSTEM',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFB6D7EA),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2.0,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Decorative dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildDot(cyan),
                        const SizedBox(width: 9),
                        _buildDot(blue),
                        const SizedBox(width: 9),
                        _buildDot(cyan),
                      ],
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      'MONITORING AIR. PROTECTING LIVES.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF9EB1C5),
                        fontSize: 10,
                        letterSpacing: 1.5,
                      ),
                    ),

                    const SizedBox(height: 58),

                    // Loading bar
                    SizedBox(
                      width: 190,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: const LinearProgressIndicator(
                          minHeight: 4,
                          backgroundColor: Color(0xFF1B3B55),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            cyan,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      'INITIALIZING SAFETY SYSTEM',
                      style: TextStyle(
                        color: Color(0xFF9EB1C5),
                        fontSize: 9,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom tagline
          const Positioned(
            bottom: 22,
            left: 0,
            right: 0,
            child: Text(
              'PREDICT  •  PREVENT  •  PROTECT',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF7897AC),
                fontSize: 10,
                letterSpacing: 2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(Color color) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.6),
            blurRadius: 8,
          ),
        ],
      ),
    );
  }
}
