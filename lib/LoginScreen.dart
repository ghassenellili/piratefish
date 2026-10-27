import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:piratefish/SignUp.dart';
import 'package:piratefish/home.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isPasswordVisible = false;
  bool _isLoading = false;
  final List<OceanBubble> _bubbles = [];

  // Controllers
  late AnimationController _introController;
  late AnimationController _loopController;

  // Intro animations
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoRotateAnimation;
  late Animation<double> _cardSlideAnimation;
  late Animation<double> _cardFadeAnimation;

  @override
  void initState() {
    super.initState();

    // Generate random ocean bubbles
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

    // Intro entrance controller
    _introController = AnimationController(
      duration: const Duration(milliseconds: 1800),
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

    _cardSlideAnimation = Tween<double>(begin: 40.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.35, 0.9, curve: Curves.easeOutCubic),
      ),
    );

    _cardFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.35, 0.85, curve: Curves.easeIn),
      ),
    );

    // Continuous loop controller for alive animations (waves, bubbles, floating)
    _loopController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    _introController.forward();
  }

  @override
  void dispose() {
    _introController.dispose();
    _loopController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
  }

  Future<void> signIn() async {
    FocusManager.instance.primaryFocus?.unfocus();

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showToast(
        "Veuillez remplir tous les champs.",
        isError: true,
      );
      return;
    }

    if (!isValidEmail(email)) {
      _showToast(
        "Veuillez entrer une adresse email valide.",
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => Home(userEmail: email),
          transitionDuration: const Duration(milliseconds: 700),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(
              opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
              child: child,
            );
          },
        ),
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Error: ${e.code} - ${e.message}');
      String errorMessage = "Une erreur s'est produite (${e.code}).";
      if (e.code == 'user-not-found') {
        errorMessage = "Aucun utilisateur trouvé avec cet email.";
      } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        errorMessage = "Email ou mot de passe incorrect.";
      } else if (e.code == 'too-many-requests') {
        errorMessage = "Trop de tentatives. Veuillez réessayer plus tard.";
      } else if (e.code == 'user-disabled') {
        errorMessage = "Ce compte a été désactivé.";
      } else if (e.message != null && e.message!.isNotEmpty) {
        errorMessage = e.message!;
      }

      _showToast(errorMessage, isError: true);
    } catch (e) {
      debugPrint("Login general error: $e");
      _showToast("Erreur: ${e.toString().replaceAll('Exception: ', '')}", isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showToast(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? const Color(0xFFD32F2F) : const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
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
          // 1. Deep Ocean Animated Background Gradient
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

          // 2. Animated Ocean Waves & Bubbles Painter
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

          // 3. Foreground Content with Glassmorphic Card
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 28.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Animated Logo with Floating Effect & Shimmer
                      _buildAnimatedLogo(),

                      const SizedBox(height: 28),

                      // Glassmorphic Card
                      _buildGlassCard(),

                      const SizedBox(height: 24),

                      // Footer Edition Badge
                      _buildFooterBadge(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedLogo() {
    return AnimatedBuilder(
      animation: Listenable.merge([_introController, _loopController]),
      builder: (context, child) {
        // Subtle floating bobbing motion
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
                        width: 170,
                        height: 170,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              const Color(0xFF00E5FF).withOpacity(0.35),
                              const Color(0xFF0091EA).withOpacity(0.18),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.45, 1.0],
                          ),
                        ),
                      ),

                      // Outer glowing halo ring
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.35),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00B0FF).withOpacity(0.4),
                              blurRadius: 25,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),

                      // Inner Glass Circle Container
                      Container(
                        width: 125,
                        height: 125,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.4),
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

  Widget _buildGlassCard() {
    return AnimatedBuilder(
      animation: _introController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _cardSlideAnimation.value),
          child: Opacity(
            opacity: _cardFadeAnimation.value,
            child: child,
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 34),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.92),
                  Colors.white.withOpacity(0.85),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.white.withOpacity(0.6),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF021B38).withOpacity(0.35),
                  blurRadius: 35,
                  offset: const Offset(0, 18),
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: const Color(0xFF00B0FF).withOpacity(0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title & decorative marine accent
                  Center(
                    child: Column(
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [
                              Color(0xFF0A2540),
                              Color(0xFF0277BD),
                            ],
                          ).createShader(bounds),
                          child: const Text(
                            'Connexion',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 48,
                          height: 4,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00B4D8), Color(0xFF0077B6)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Bienvenue sur PirateFish',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF5A7184),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Email input
                  _buildInputField(
                    controller: _emailController,
                    label: 'Email',
                    hint: 'nom@exemple.com',
                    icon: Icons.alternate_email_rounded,
                    keyboardType: TextInputType.emailAddress,
                  ),

                  const SizedBox(height: 18),

                  // Password input
                  _buildInputField(
                    controller: _passwordController,
                    label: 'Mot de passe',
                    hint: '••••••••',
                    icon: Icons.lock_outline_rounded,
                    obscureText: !_isPasswordVisible,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility_rounded
                            : Icons.visibility_off_rounded,
                        color: const Color(0xFF0077B6),
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() => _isPasswordVisible = !_isPasswordVisible);
                      },
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Mot de passe oublié
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        _showToast(
                          "Entrez votre email ci-dessus pour réinitialiser votre mot de passe.",
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF0077B6),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Mot de passe oublié ?',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Connect Button
                  _buildPrimaryButton(
                    text: 'Connexion',
                    onPressed: _isLoading ? null : signIn,
                    isLoading: _isLoading,
                  ),

                  const SizedBox(height: 22),

                  // Register link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Pas encore de compte ? ",
                        style: TextStyle(
                          color: Color(0xFF5A7184),
                          fontSize: 14,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (_, __, ___) => const SignUp(),
                              transitionDuration: const Duration(milliseconds: 500),
                              transitionsBuilder: (_, animation, __, child) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0.08, 0),
                                      end: Offset.zero,
                                    ).animate(CurvedAnimation(
                                      parent: animation,
                                      curve: Curves.easeOutCubic,
                                    )),
                                    child: child,
                                  ),
                                );
                              },
                            ),
                          );
                        },
                        child: const Text(
                          "Inscrivez-vous",
                          style: TextStyle(
                            color: Color(0xFF0077B6),
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            decoration: TextDecoration.underline,
                            decorationColor: Color(0xFF0077B6),
                            decorationThickness: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2C3E50),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 7),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0A2540).withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0A2540),
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade400,
                fontWeight: FontWeight.normal,
              ),
              prefixIcon: Icon(
                icon,
                color: const Color(0xFF0077B6),
                size: 20,
              ),
              suffixIcon: suffixIcon,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade200, width: 1.2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade200, width: 1.2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF0077B6), width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryButton({
    required String text,
    required VoidCallback? onPressed,
    required bool isLoading,
  }) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF00B4D8),
            Color(0xFF0077B6),
            Color(0xFF03045E),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0077B6).withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
            spreadRadius: 1,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.6,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        text,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooterBadge() {
    return AnimatedBuilder(
      animation: _introController,
      builder: (context, child) {
        return Opacity(
          opacity: _cardFadeAnimation.value,
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

// -------------------------------------------------------------
// Ocean Scene Painter (Continuous Waves & Rising Bubbles)
// -------------------------------------------------------------
class OceanBubble {
  double x; // 0.0 to 1.0 (relative width)
  double y; // 0.0 to 1.0 (relative height)
  final double size;
  final double speed;
  final double wobbleSpeed;
  final double opacity;

  OceanBubble({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.wobbleSpeed,
    required this.opacity,
  });
}

class OceanScenePainter extends CustomPainter {
  final double progress;
  final List<OceanBubble> bubbles;

  OceanScenePainter({required this.progress, required this.bubbles});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Paint Continuous Ambient Waves
    _paintFluidWave(
      canvas,
      size,
      color: const Color(0xFF00B4D8).withOpacity(0.08),
      amplitude: 28,
      frequency: 1.4,
      phase: progress * 2 * math.pi,
      baseY: size.height * 0.78,
    );

    _paintFluidWave(
      canvas,
      size,
      color: const Color(0xFF0077B6).withOpacity(0.12),
      amplitude: 22,
      frequency: 2.1,
      phase: -progress * 2 * math.pi * 1.3,
      baseY: size.height * 0.85,
    );

    _paintFluidWave(
      canvas,
      size,
      color: Colors.white.withOpacity(0.05),
      amplitude: 16,
      frequency: 2.8,
      phase: progress * 2 * math.pi * 1.7,
      baseY: size.height * 0.92,
    );

    // 2. Paint Rising Bubbles with gentle sine wobble
    for (var bubble in bubbles) {
      // Advance bubble y upwards
      double currentY = (bubble.y - (progress * bubble.speed * 80)) % 1.0;
      if (currentY < 0) currentY += 1.0;

      // Subtle horizontal wobble
      final wobble = math.sin((progress * 2 * math.pi * bubble.wobbleSpeed) + (bubble.x * 10)) * 14;
      final px = (bubble.x * size.width) + wobble;
      final py = currentY * size.height;

      // Draw bubble glow
      final glowPaint = Paint()
        ..color = const Color(0xFF80D8FF).withOpacity(bubble.opacity * 0.4)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(px, py), bubble.size * 0.7, glowPaint);

      // Draw bubble outline
      final bubblePaint = Paint()
        ..color = Colors.white.withOpacity(bubble.opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      canvas.drawCircle(Offset(px, py), bubble.size * 0.5, bubblePaint);

      // Bubble highlight shine
      final shinePaint = Paint()
        ..color = Colors.white.withOpacity((bubble.opacity * 1.5).clamp(0.0, 0.9))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(px - bubble.size * 0.16, py - bubble.size * 0.16),
        bubble.size * 0.12,
        shinePaint,
      );
    }
  }

  void _paintFluidWave(
    Canvas canvas,
    Size size, {
    required Color color,
    required double amplitude,
    required double frequency,
    required double phase,
    required double baseY,
  }) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()..moveTo(0, baseY);

    for (double x = 0; x <= size.width; x += 4) {
      final y = math.sin((x / size.width * frequency * 2 * math.pi) + phase) * amplitude;
      path.lineTo(x, baseY + y);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant OceanScenePainter oldDelegate) => true;
}