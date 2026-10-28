// ignore_for_file: deprecated_member_use
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:piratefish/LoginScreen.dart';

class Splashscreen extends StatefulWidget {
  const Splashscreen({super.key});

  @override
  State<Splashscreen> createState() => _SplashscreenState();
}

class _SplashscreenState extends State<Splashscreen> with TickerProviderStateMixin {
  final List<OceanBubble> _bubbles = [];

  // Controllers matching LoginScreen
  late AnimationController _introController;
  late AnimationController _loopController;

  // Intro animations
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoRotateAnimation;
  late Animation<double> _contentSlideAnimation;
  late Animation<double> _contentFadeAnimation;
  late Animation<double> _progressAnimation;

  Timer? _navTimer;

  @override
  void initState() {
    super.initState();

    // 1. Generate random ocean bubbles (same as LoginScreen)
    final random = math.Random();
    for (int i = 0; i < 35; i++) {
      _bubbles.add(
        OceanBubble(
          x: random.nextDouble(),
          y: random.nextDouble(),
          size: random.nextDouble() * 10 + 4,
          speed: random.nextDouble() * 0.0015 + 0.0008,
          wobbleSpeed: random.nextDouble() * 3 + 1,
          opacity: random.nextDouble() * 0.35 + 0.1,
        ),
      );
    }

    // 2. Intro entrance controller
    _introController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _logoScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.0, 0.65, curve: Curves.elasticOut),
      ),
    );

    _logoRotateAnimation = Tween<double>(begin: -0.15, end: 0.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _contentSlideAnimation = Tween<double>(begin: 35.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.35, 0.9, curve: Curves.easeOutCubic),
      ),
    );

    _contentFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.35, 0.85, curve: Curves.easeIn),
      ),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.2, 0.95, curve: Curves.easeInOut),
      ),
    );

    // 3. Continuous loop controller for alive animations (waves, bubbles, bobbing, shimmer)
    _loopController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    _introController.forward();

    // 4. Smooth transition to Login screen after animation sequence
    _navTimer = Timer(const Duration(milliseconds: 3200), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const Login(),
          transitionDuration: const Duration(milliseconds: 800),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              ),
              child: child,
            );
          },
        ),
      );
    });
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _introController.dispose();
    _loopController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Deep Ocean Animated Background Gradient (identical to LoginScreen)
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF041426), // Deep abyssal navy
                  Color(0xFF092A52), // Ocean deep
                  Color(0xFF0D47A1), // Royal navy blue
                  Color(0xFF0277BD), // Vibrant marine blue
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.35, 0.7, 1.0],
              ),
            ),
          ),

          // 2. Animated Ocean Waves & Bubbles Painter (identical to LoginScreen)
          AnimatedBuilder(
            animation: _loopController,
            builder: (context, _) {
              return CustomPaint(
                size: Size(size.width, size.height),
                painter: OceanScenePainter(
                  progress: _loopController.value,
                  bubbles: _bubbles,
                ),
              );
            },
          ),

          // 3. Ambient Top Light Glow Accent
          Positioned(
            top: -100,
            left: size.width * 0.2,
            right: size.width * 0.2,
            child: Container(
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF00E5FF).withOpacity(0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // 4. Center Content: Animated Logo + Brand Typography + Loading Bar
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Animated Floating Logo matching LoginScreen exactly
                      _buildAnimatedLogo(),

                      const SizedBox(height: 36),

                      // Brand Titles with Slide & Fade Animation
                      _buildAnimatedTypography(),

                      const SizedBox(height: 40),

                      // Refined Glassmorphic Loading Indicator
                      _buildLoadingIndicator(),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 5. Footer Badge (identical to LoginScreen)
          Positioned(
            bottom: 28,
            left: 0,
            right: 0,
            child: Center(
              child: _buildFooterBadge(),
            ),
          ),
        ],
      ),
    );
  }

  /// Logo identical in style and animation to LoginScreen with Hero integration
  Widget _buildAnimatedLogo() {
    return AnimatedBuilder(
      animation: Listenable.merge([_introController, _loopController]),
      builder: (context, child) {
        // Continuous bobbing float motion (identical to LoginScreen)
        final floatOffset = math.sin(_loopController.value * 2 * math.pi) * 6;
        final shimmerValue = (_loopController.value * 2) % 2.0;

        return Transform.translate(
          offset: Offset(0, floatOffset),
          child: Transform.rotate(
            angle: _logoRotateAnimation.value,
            child: Transform.scale(
              scale: _logoScaleAnimation.value,
              child: Opacity(
                opacity: _introController.value.clamp(0.0, 1.0),
                child: Hero(
                  tag: 'piratefish_logo',
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Ambient Radial Glow
                      Container(
                        width: 190,
                        height: 190,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              const Color(0xFF00E5FF).withOpacity(0.40),
                              const Color(0xFF0091EA).withOpacity(0.20),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.45, 1.0],
                          ),
                        ),
                      ),

                      // Outer glowing halo ring
                      Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.4),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00B0FF).withOpacity(0.45),
                              blurRadius: 28,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                      ),

                      // Inner Glass Circle Container
                      Container(
                        width: 132,
                        height: 132,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.45),
                            width: 1.5,
                          ),
                        ),
                        child: ShaderMask(
                          shaderCallback: (Rect bounds) {
                            return LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.7),
                                Colors.white,
                                Colors.white.withOpacity(0.7),
                              ],
                              stops: [
                                (shimmerValue - 0.3).clamp(0.0, 1.0),
                                shimmerValue.clamp(0.0, 1.0),
                                (shimmerValue + 0.3).clamp(0.0, 1.0),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ).createShader(bounds);
                          },
                          blendMode: BlendMode.srcATop,
                          child: Image.asset(
                            'images/splash.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Title & Subtitle with smooth slide-up and fade-in matching Login card animation
  Widget _buildAnimatedTypography() {
    return AnimatedBuilder(
      animation: _introController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _contentSlideAnimation.value),
          child: Opacity(
            opacity: _contentFadeAnimation.value,
            child: child,
          ),
        );
      },
      child: Column(
        children: [
          // Main Brand Title
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [
                Colors.white,
                Color(0xFFE0F7FA),
                Color(0xFF80D8FF),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ).createShader(bounds),
            child: const Text(
              "PIRATEFISH",
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 4.5,
                shadows: [
                  Shadow(
                    color: Color(0x8000E5FF),
                    blurRadius: 18,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Glassmorphic Tagline Pill
          ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.22),
                    width: 1,
                  ),
                ),
                child: const Text(
                  "Votre compagnon de pêche intelligent",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFFE1F5FE),
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Elegant oceanic loading bar with glowing progress
  Widget _buildLoadingIndicator() {
    return AnimatedBuilder(
      animation: _introController,
      builder: (context, child) {
        return Opacity(
          opacity: _contentFadeAnimation.value,
          child: Column(
            children: [
              // Progress Bar Track
              Container(
                width: 160,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 160 * _progressAnimation.value,
                    height: 4,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF00B0FF),
                          Color(0xFF00E5FF),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00E5FF).withOpacity(0.6),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Status text
              Text(
                "Initialisation du système...",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.65),
                  fontSize: 12,
                  letterSpacing: 1.0,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Footer badge matching LoginScreen exactly
  Widget _buildFooterBadge() {
    return AnimatedBuilder(
      animation: _introController,
      builder: (context, child) {
        return Opacity(
          opacity: _contentFadeAnimation.value,
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: Colors.white.withOpacity(0.25),
            width: 1,
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.shield_outlined,
              color: Color(0xFF80D8FF),
              size: 15,
            ),
            SizedBox(width: 8),
            Text(
              "PIRATEFISH SECURE SYSTEM",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 11,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}