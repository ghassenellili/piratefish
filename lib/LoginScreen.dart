import 'dart:math' as math;
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

class _LoginState extends State<Login> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  final List<Particle> _particles = [];

  late AnimationController _animationController;
  late Animation<double> _logoAnimation;
  late Animation<double> _formAnimation;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _backgroundAnimation;

  @override
  void initState() {
    super.initState();

    // Create particles for background animation
    final random = math.Random();
    for (int i = 0; i < 25; i++) {
      _particles.add(Particle(
        x: random.nextDouble() * 400,
        y: random.nextDouble() * 800,
        size: random.nextDouble() * 6 + 2,
        speed: random.nextDouble() * 1.5 + 0.5,
      ));
    }

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    _logoAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    );

    _formAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic),
    );

    // CORRECTION: Garantir que l'animation de shimmer reste dans les limites valides
    _shimmerAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0, // Modifié de 2.0 à 1.0 pour rester dans les limites
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.6, 1.0, curve: Curves.easeInOut),
    ));

    _backgroundAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.linear,
    );

    _animationController.forward();
  }

  bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    return emailRegex.hasMatch(email);
  }

  Future<void> signIn() async {
    // Hide keyboard when sign in is pressed
    FocusManager.instance.primaryFocus?.unfocus();
    
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez remplir tous les champs."),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (!isValidEmail(_emailController.text.trim())) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("L'adresse email est mal formatée."),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Simulate a slight delay for better UX
      await Future.delayed(const Duration(milliseconds: 500));

      // Navigate with a smoother transition
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => 
              Home(userEmail: _emailController.text.trim()),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 0.1);
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
    } on FirebaseAuthException catch (e) {
      String errorMessage = "Une erreur s'est produite. Veuillez réessayer.";
      if (e.code == 'user-not-found') {
        errorMessage = "Aucun utilisateur trouvé avec cet email.";
      } else if (e.code == 'wrong-password') {
        errorMessage = "Mot de passe incorrect.";
      } else if (e.code == 'too-many-requests') {
        errorMessage = "Trop de tentatives. Veuillez réessayer plus tard.";
      } else if (e.code == 'user-disabled') {
        errorMessage = "Ce compte a été désactivé.";
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(child: Text(errorMessage)),
            ],
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(12),
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Une erreur inattendue s'est produite."),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Set system overlay style for status bar
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          // Update particles
          for (var particle in _particles) {
            particle.y -= particle.speed * _backgroundAnimation.value;
            if (particle.y < 0) {
              particle.y = MediaQuery.of(context).size.height;
              particle.x = math.Random().nextDouble() * MediaQuery.of(context).size.width;
            }
          }
          
          return Container(
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0D47A1),  // Deep ocean blue at top
                  Color(0xFF1565C0),  // Deep blue
                  Color(0xFF1E88E5),  // Medium blue
                  Color(0xFF42A5F5),  // Light blue at bottom
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.3, 0.6, 1.0],
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
                    painter: WavePainter(_backgroundAnimation.value),
                  ),
                ),
                
                SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Logo with enhanced animation
                          Transform.scale(
                            scale: _logoAnimation.value,
                            child: Opacity(
                              opacity: _logoAnimation.value.clamp(0.0, 1.0),
                              child: Hero(
                                tag: 'logo',
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Glow effect
                                    Container(
                                      width: 180,
                                      height: 180,
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
                                      width: 160,
                                      height: 160,
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
                                  
                                    // Logo with shimmer effect - CORRECTION
                                    ShaderMask(
                                      shaderCallback: (Rect bounds) {
                                        return LinearGradient(
                                          colors: [
                                            Colors.white.withOpacity(0.2),
                                            Colors.white,
                                            Colors.white.withOpacity(0.2),
                                          ],
                                          stops: [
                                            0.0,
                                            _shimmerAnimation.value,
                                            1.0,
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ).createShader(bounds);
                                      },
                                      blendMode: BlendMode.srcATop,
                                      child: Container(
                                        width: 150,
                                        height: 150,
                                        padding: const EdgeInsets.all(15),
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
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),

                          // Login Form Card with transform animation
                          Transform.translate(
                            offset: Offset(0, 50 * (1 - _formAnimation.value)),
                            child: Opacity(
                              // CORRECTION: Assurons-nous que l'opacité reste dans les limites
                              opacity: _formAnimation.value.clamp(0.0, 1.0),
                              child: Container(
                                padding: const EdgeInsets.all(28),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withOpacity(0.7),
                                      Colors.white.withOpacity(0.9),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(32),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.15),
                                      blurRadius: 30,
                                      offset: const Offset(0, 15),
                                    ),
                                  ],
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.8),
                                    width: 1.5,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    // Title with animated underline
                                    Column(
                                      children: [
                                        ShaderMask(
                                          shaderCallback: (Rect bounds) {
                                            return const LinearGradient(
                                              colors: [
                                                Color(0xFF1A237E),
                                                Color(0xFF1E88E5),
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ).createShader(bounds);
                                          },
                                          blendMode: BlendMode.srcIn,
                                          child: const Text(
                                            'Connexion',
                                            style: TextStyle(
                                              fontSize: 32,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1.5,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          width: 60,
                                          height: 3,
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [
                                                Color(0xFF1A237E),
                                                Color(0xFF1E88E5),
                                              ],
                                              begin: Alignment.centerLeft,
                                              end: Alignment.centerRight,
                                            ),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 40),

                                    // Email Field with improved design
                                    TextFormField(
                                      controller: _emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Color(0xFF0D47A1),
                                        fontWeight: FontWeight.w500,
                                      ),
                                      decoration: InputDecoration(
                                        prefixIcon: Container(
                                          padding: const EdgeInsets.all(12),
                                          margin: const EdgeInsets.only(right: 8),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF1E88E5).withOpacity(0.1),
                                            borderRadius: const BorderRadius.only(
                                              topLeft: Radius.circular(15),
                                              bottomLeft: Radius.circular(15),
                                              topRight: Radius.circular(30),
                                              bottomRight: Radius.circular(30),
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.email_outlined,
                                            color: Color(0xFF1A237E),
                                          ),
                                        ),
                                        labelText: 'Email',
                                        labelStyle: const TextStyle(
                                          color: Color(0xFF607D8B),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        hintText: 'exemple@domaine.com',
                                        hintStyle: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 14,
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(15),
                                          borderSide: BorderSide(color: Colors.grey[300]!),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(15),
                                          borderSide: const BorderSide(color: Color(0xFF1A237E), width: 2),
                                        ),
                                        filled: true,
                                        fillColor: Colors.white,
                                        contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                                      ),
                                    ),
                                    const SizedBox(height: 24),

                                    // Password Field with improved design
                                    TextFormField(
                                      controller: _passwordController,
                                      obscureText: !_isPasswordVisible,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Color(0xFF0D47A1),
                                        fontWeight: FontWeight.w500,
                                      ),
                                      decoration: InputDecoration(
                                        prefixIcon: Container(
                                          padding: const EdgeInsets.all(12),
                                          margin: const EdgeInsets.only(right: 8),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF1E88E5).withOpacity(0.1),
                                            borderRadius: const BorderRadius.only(
                                              topLeft: Radius.circular(15),
                                              bottomLeft: Radius.circular(15),
                                              topRight: Radius.circular(30),
                                              bottomRight: Radius.circular(30),
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.lock_outline,
                                            color: Color(0xFF1A237E),
                                          ),
                                        ),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                                            color: const Color(0xFF607D8B),
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _isPasswordVisible = !_isPasswordVisible;
                                            });
                                          },
                                        ),
                                        labelText: 'Mot de passe',
                                        labelStyle: const TextStyle(
                                          color: Color(0xFF607D8B),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        hintText: '••••••••',
                                        hintStyle: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 14,
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(15),
                                          borderSide: BorderSide(color: Colors.grey[300]!),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(15),
                                          borderSide: const BorderSide(color: Color(0xFF1A237E), width: 2),
                                        ),
                                        filled: true,
                                        fillColor: Colors.white,
                                        contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                                      ),
                                    ),

                                    // Forgot Password
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: () {
                                          // TODO: Implement forgot password
                                        },
                                        style: TextButton.styleFrom(
                                          foregroundColor: const Color(0xFF1A237E),
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                        child: const Text(
                                          'Mot de passe oublié?',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 30),

                                    // Sign In Button with improved design
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF1A237E).withOpacity(0.3),
                                            blurRadius: 15,
                                            offset: const Offset(0, 8),
                                            spreadRadius: -5,
                                          ),
                                        ],
                                      ),
                                      child: ElevatedButton(
                                        onPressed: _isLoading ? null : signIn,
                                        style: ElevatedButton.styleFrom(
                                          foregroundColor: Colors.white,
                                          backgroundColor: const Color(0xFF1A237E),
                                          minimumSize: const Size(double.infinity, 60),
                                          padding: EdgeInsets.zero,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          elevation: 0,
                                        ),
                                        child: Ink(
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [
                                                Color(0xFF1A237E),
                                                Color(0xFF3949AB),
                                                Color(0xFF1565C0),
                                              ],
                                              begin: Alignment.centerLeft,
                                              end: Alignment.centerRight,
                                            ),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Container(
                                            alignment: Alignment.center,
                                            child: _isLoading
                                                ? const SizedBox(
                                                    width: 24,
                                                    height: 24,
                                                    child: CircularProgressIndicator(
                                                      color: Colors.white,
                                                      strokeWidth: 2.5,
                                                    ),
                                                  )
                                                : Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      const Text(
                                                        'Connexion',
                                                        style: TextStyle(
                                                          fontSize: 18,
                                                          fontWeight: FontWeight.w600,
                                                          letterSpacing: 1.0,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Container(
                                                        padding: const EdgeInsets.all(4),
                                                        decoration: BoxDecoration(
                                                          color: Colors.white.withOpacity(0.2),
                                                          shape: BoxShape.circle,
                                                        ),
                                                        child: const Icon(
                                                          Icons.arrow_forward,
                                                          size: 18,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                          ),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 30),

                                    // Sign Up Link with improved design
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Text(
                                          'Pas encore de compte? ',
                                          style: TextStyle(
                                            color: Color(0xFF455A64),
                                            fontSize: 16,
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              PageRouteBuilder(
                                                pageBuilder: (_, __, ___) => const SignUp(),
                                                transitionDuration: const Duration(milliseconds: 400),
                                                transitionsBuilder: (_, animation, __, child) {
                                                  return SlideTransition(
                                                    position: Tween<Offset>(
                                                      begin: const Offset(1, 0),
                                                      end: Offset.zero,
                                                    ).animate(CurvedAnimation(
                                                      parent: animation,
                                                      curve: Curves.easeOutCubic,
                                                    )),
                                                    child: FadeTransition(
                                                      opacity: animation, 
                                                      child: child,
                                                    ),
                                                  );
                                                },
                                              ),
                                            );
                                          },
                                          child: const Text(
                                            'Inscrivez-vous',
                                            style: TextStyle(
                                              color: Color(0xFF1A237E),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              decoration: TextDecoration.underline,
                                              decorationColor: Color(0xFF1A237E),
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

                          // Premium badge at bottom
                          const SizedBox(height: 30),
                          Opacity(
                            // CORRECTION: Assurons-nous que l'opacité reste dans les limites
                            opacity: _formAnimation.value.clamp(0.0, 1.0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.verified,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    "PREMIUM EDITION",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                      letterSpacing: 1.2,
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
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Custom painter for animated wave pattern in background
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
        ..color = Colors.white.withOpacity(0.2 * (particle.size / 10).clamp(0.0, 1.0))
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