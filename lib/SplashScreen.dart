import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:piratefish/LoginScreen.dart';

class Splashscreen extends StatefulWidget {
  const Splashscreen({super.key});

  @override
  _SplashscreenState createState() => _SplashscreenState();
}

class _SplashscreenState extends State<Splashscreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoOpacityAnimation;
  late Animation<double> _logoRotateAnimation;
  late Animation<double> _textSlideAnimation;
  late Animation<double> _textOpacityAnimation;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _particleAnimation;
  final math.Random _random = math.Random();

  // Particles for underwater effect
  final List<Particle> _particles = [];

  @override
  void initState() {
    super.initState();

    // Generate random particles
    for (int i = 0; i < 30; i++) {
      _particles.add(Particle(
        x: _random.nextDouble() * 400,
        y: _random.nextDouble() * 800,
        size: _random.nextDouble() * 8 + 2,
        speed: _random.nextDouble() * 2 + 1,
      ));
    }

    // Initialize animation controller with longer duration for smoother animations
    _controller = AnimationController(
      duration: const Duration(milliseconds: 3500),
      vsync: this,
    );

    // Logo scale animation - starts small and grows to full size
    _logoScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    ));

    // Logo opacity animation
    _logoOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
    ));
    
    // Logo subtle rotation animation
    _logoRotateAnimation = Tween<double>(
      begin: -0.1,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    // Text slide animation - slides in from bottom
    _textSlideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 0.7, curve: Curves.easeOut),
    ));

    // Text opacity animation
    _textOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 0.7, curve: Curves.easeIn),
    ));

    // Shimmer effect animation
    _shimmerAnimation = Tween<double>(
      begin: 0.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.7, 1.0, curve: Curves.easeInOut),
    ));
    
    // Particles animation
    _particleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.linear,
    ));

    _controller.forward();

    // Navigate to Login screen after animations complete
    Timer(const Duration(milliseconds: 4500), () {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const Login(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 0.3);
            const end = Offset.zero;
            const curve = Curves.easeOutCubic;
            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            var offsetAnimation = animation.drive(tween);
            
            var fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
                .animate(CurvedAnimation(parent: animation, curve: curve));
            
            return FadeTransition(
              opacity: fadeAnimation,
              child: SlideTransition(position: offsetAnimation, child: child),
            );
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          // Update particles positions
          for (var particle in _particles) {
            particle.y -= particle.speed * _particleAnimation.value;
            if (particle.y < 0) {
              particle.y = MediaQuery.of(context).size.height;
              particle.x = _random.nextDouble() * MediaQuery.of(context).size.width;
            }
          }
          
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: const [
                  Color(0xFF0D47A1),  // Deep ocean blue at top
                  Color(0xFF1565C0),  // Deep blue
                  Color(0xFF1E88E5),  // Medium blue
                  Color(0xFF42A5F5),  // Light blue at bottom
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.3, 0.6, 1.0],
              ),
            ),
            child: Stack(
              children: [
                // Background particles
                CustomPaint(
                  size: Size(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height),
                  painter: ParticlePainter(_particles),
                ),
            
                // Background wave pattern
                Positioned.fill(
                  child: CustomPaint(
                    painter: WavePainter(_controller.value),
                  ),
                ),
                
                // Main content
                Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Animated logo
                        Transform.rotate(
                          angle: _logoRotateAnimation.value,
                          child: Transform.scale(
                            scale: _logoScaleAnimation.value,
                            child: Opacity(
                              opacity: _logoOpacityAnimation.value,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Glow effect
                                  Container(
                                    width: 240,
                                    height: 240,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: [
                                          Colors.white.withOpacity(0.3),
                                          Colors.white.withOpacity(0.1),
                                          Colors.white.withOpacity(0.05),
                                          Colors.transparent,
                                        ],
                                        stops: const [0.0, 0.3, 0.6, 1.0],
                                      ),
                                    ),
                                  ),
                                  
                                  // Inner circle
                                  Container(
                                    width: 210,
                                    height: 210,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withOpacity(0.12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.blue.withOpacity(0.3),
                                          blurRadius: 20,
                                          spreadRadius: 5,
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // Logo with shimmer effect
                                  ShaderMask(
                                    shaderCallback: (Rect bounds) {
                                      return LinearGradient(
                                        colors: [
                                          Colors.white.withOpacity(0.2),
                                          Colors.white,
                                          Colors.white.withOpacity(0.2),
                                        ],
                                        stops: [
                                          _shimmerAnimation.value < 1.0 ? 0.0 : _shimmerAnimation.value - 1.0,
                                          _shimmerAnimation.value < 1.0 ? _shimmerAnimation.value : 1.0,
                                          _shimmerAnimation.value < 0.5 ? 0.5 : 1.0,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ).createShader(bounds);
                                    },
                                    blendMode: BlendMode.srcATop,
                                    child: Container(
                                      width: 200,
                                      height: 200,
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.3),
                                          width: 2,
                                        ),
                                      ),
                                      child: Image.asset(
                                        'images/splash.png',
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                  
                                  // Ripple effect
                                  _buildRippleEffect(),
                                ],
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 40),
                        
                        // Animated title text
                        Transform.translate(
                          offset: Offset(0, _textSlideAnimation.value),
                          child: Opacity(
                            opacity: _textOpacityAnimation.value,
                            child: ShaderMask(
                              shaderCallback: (Rect bounds) {
                                return const LinearGradient(
                                  colors: [
                                    Colors.white,
                                    Color(0xFFE3F2FD),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ).createShader(bounds);
                              },
                              blendMode: BlendMode.srcIn,
                              child: const Text(
                                "Bienvenue sur PirateFish",
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 10.0,
                                      color: Color.fromARGB(150, 0, 0, 100),
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Animated subtitle text
                        Transform.translate(
                          offset: Offset(0, _textSlideAnimation.value),
                          child: Opacity(
                            opacity: _textOpacityAnimation.value,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withOpacity(0.15),
                                    Colors.white.withOpacity(0.25),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    spreadRadius: 0,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: const Text(
                                "Votre compagnon de pêche intelligent",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Animated footer
                Positioned(
                  bottom: 24,
                  left: 0,
                  right: 0,
                  child: Opacity(
                    opacity: _textOpacityAnimation.value,
                    child: Column(
                      children: [
                        // Loading indicator
                        SizedBox(
                          width: 30,
                          height: 30,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.7)),
                            strokeWidth: 2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Version
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.verified,
                              size: 12,
                              color: Colors.white.withOpacity(0.7),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "v1.0.0",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Watermark
                Positioned(
                  top: 40,
                  right: 20,
                  child: Opacity(
                    opacity: _textOpacityAnimation.value * 0.7,
                    child: Row(
                      children: [
                        Icon(
                          Icons.water,
                          color: Colors.white.withOpacity(0.5),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "PREMIUM",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Ripple effect around logo
  Widget _buildRippleEffect() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        if (_controller.value < 0.6) return const SizedBox.shrink();
        
        final rippleSize = 200 + (50 * math.sin((_controller.value - 0.6) * 6));
        final opacity = math.max(0.0, 0.3 - (_controller.value - 0.6) * 0.5);
        
        return Container(
          width: rippleSize,
          height: rippleSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(opacity),
              width: 2,
            ),
          ),
        );
      },
    );
  }
}

// Custom painter for decorative wave pattern in background
class WavePainter extends CustomPainter {
  final double animationValue;
  
  WavePainter(this.animationValue);
  
  @override
  void paint(Canvas canvas, Size size) {
    // First wave (bottom)
    _paintWave(
      canvas, 
      size,
      color: Colors.white.withOpacity(0.05),
      amplitude: size.height * 0.05,
      frequency: 1.5,
      phase: animationValue * 2,
      baseHeight: size.height * 0.75,
    );
    
    // Second wave (middle)
    _paintWave(
      canvas, 
      size,
      color: Colors.white.withOpacity(0.07),
      amplitude: size.height * 0.04,
      frequency: 2.0,
      phase: animationValue * -3,
      baseHeight: size.height * 0.5,
    );
    
    // Third wave (top)
    _paintWave(
      canvas, 
      size,
      color: Colors.white.withOpacity(0.04),
      amplitude: size.height * 0.03,
      frequency: 2.5,
      phase: animationValue * 4,
      baseHeight: size.height * 0.3,
    );
  }
  
  void _paintWave(
    Canvas canvas, 
    Size size, {
    required Color color,
    required double amplitude,
    required double frequency,
    required double phase,
    required double baseHeight,
  }) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    final path = Path();
    
    path.moveTo(0, baseHeight);
    
    for (double x = 0; x <= size.width; x++) {
      double y = math.sin((x / size.width * frequency * math.pi * 2) + phase) * amplitude;
      path.lineTo(x, baseHeight + y);
    }
    
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant WavePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

// Particle class for underwater effect
class Particle {
  double x;
  double y;
  double size;
  double speed;
  
  Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
  });
}

// Painter for underwater particles
class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  
  ParticlePainter(this.particles);
  
  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      final paint = Paint()
        ..color = Colors.white.withOpacity(0.2 * (particle.size / 10))
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        Offset(particle.x, particle.y),
        particle.size * 0.5,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) {
    return true;
  }
}

// Helper extension for Random
extension RandomExtension on math.Random {
  double nextDouble() {
    return math.Random().nextDouble();
  }
}