// FILE: lib/screens/splash_screen.dart
// CREATIVE SPLASH:
//   - Animated gradient background (purple shifting)
//   - Floating particle dots that drift upward
//   - Logo bounces in with scale + fade animation
//   - App name types in letter by letter
//   - Tagline fades in below
//   - Pulsing ring around logo
//   - Shimmer loading bar at bottom

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:event_finder/providers/auth_provider.dart';
import 'package:event_finder/screens/auth/login_screen.dart';
import 'package:event_finder/screens/user/user_home_screen.dart';
import 'package:event_finder/screens/organizer/organizer_home_screen.dart';
import 'package:event_finder/screens/admin/admin_home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  // ── Animation controllers ─────────────────────────────
  late AnimationController _logoCtrl;      // logo bounce-in
  late AnimationController _pulseCtrl;     // pulsing ring
  late AnimationController _textCtrl;      // text fade-in
  late AnimationController _particleCtrl;  // floating particles
  late AnimationController _shimmerCtrl;   // loading shimmer
  late AnimationController _bgCtrl;        // background gradient shift

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _pulseScale;
  late Animation<double> _pulseOpacity;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;
  late Animation<double> _taglineOpacity;
  late Animation<double> _shimmer;
  late Animation<double> _bgAnim;

  // Particles
  final List<_Particle> _particles = [];
  final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _generateParticles();
    _startSequence();
  }

  void _generateParticles() {
    for (int i = 0; i < 18; i++) {
      _particles.add(_Particle(
        x:      _rng.nextDouble(),
        y:      _rng.nextDouble(),
        size:   2 + _rng.nextDouble() * 5,
        speed:  0.003 + _rng.nextDouble() * 0.004,
        opacity: 0.15 + _rng.nextDouble() * 0.45,
        delay:  _rng.nextDouble(),
      ));
    }
  }

  void _setupAnimations() {
    // Logo
    _logoCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _logoScale = Tween<double>(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut));
    _logoOpacity = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _logoCtrl,
            curve: const Interval(0, 0.5, curve: Curves.easeIn)));

    // Pulse ring
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat();
    _pulseScale = Tween<double>(begin: 1.0, end: 1.6).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut));
    _pulseOpacity = Tween<double>(begin: 0.5, end: 0).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut));

    // Text
    _textCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _textOpacity = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut));
    _textSlide = Tween<Offset>(
            begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut));
    _taglineOpacity = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _textCtrl,
            curve: const Interval(0.4, 1.0, curve: Curves.easeOut)));

    // Particles
    _particleCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 6))
      ..repeat();

    // Shimmer
    _shimmerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat();
    _shimmer = Tween<double>(begin: -1.5, end: 2.5).animate(
        CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut));

    // Background gradient
    _bgCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 4))
      ..repeat(reverse: true);
    _bgAnim = Tween<double>(begin: 0, end: 1).animate(_bgCtrl);
  }

  Future<void> _startSequence() async {
    // Logo bounces in after short delay
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    _logoCtrl.forward();

    // Text slides up after logo
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    _textCtrl.forward();

    // Init auth + navigate
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.init();
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;
    _navigate(authProvider);
  }

  void _navigate(AuthProvider authProvider) {
    Widget home;
    if (authProvider.isLoggedIn) {
      if (authProvider.isAdmin)         home = const AdminHomeScreen();
      else if (authProvider.isOrganizer) home = const OrganizerHomeScreen();
      else                               home = const UserHomeScreen();
    } else {
      home = const LoginScreen();
    }
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, anim, __) => home,
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _pulseCtrl.dispose();
    _textCtrl.dispose();
    _particleCtrl.dispose();
    _shimmerCtrl.dispose();
    _bgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _bgAnim,
        builder: (_, __) {
          // Smoothly shift between two purple gradients
          final t = _bgAnim.value;
          final c1 = Color.lerp(
              const Color(0xFF4A148C), const Color(0xFF6C3CE1), t)!;
          final c2 = Color.lerp(
              const Color(0xFF6C3CE1), const Color(0xFFB06AB3), t)!;
          final c3 = Color.lerp(
              const Color(0xFF311B92), const Color(0xFF7B1FA2), t)!;

          return Container(
            width: double.infinity, height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [c1, c2, c3],
              ),
            ),
            child: Stack(children: [

              // ── Floating particles ───────────────────
              AnimatedBuilder(
                animation: _particleCtrl,
                builder: (_, __) {
                  return CustomPaint(
                    size: size,
                    painter: _ParticlePainter(
                        _particles, _particleCtrl.value),
                  );
                },
              ),

              // ── Big soft glow circles ───────────────
              Positioned(
                top: -60, right: -60,
                child: Container(
                  width: 280, height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
              ),
              Positioned(
                bottom: -80, left: -40,
                child: Container(
                  width: 240, height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.04),
                  ),
                ),
              ),
              Positioned(
                top: size.height * 0.35, left: -30,
                child: Container(
                  width: 120, height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.06),
                  ),
                ),
              ),

              // ── Main content ─────────────────────────
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [

                    // Pulsing ring + logo
                    Stack(alignment: Alignment.center, children: [

                      // Outer pulse ring 2
                      AnimatedBuilder(
                        animation: _pulseCtrl,
                        builder: (_, __) => Transform.scale(
                          scale: _pulseScale.value * 1.2,
                          child: Opacity(
                            opacity: _pulseOpacity.value * 0.4,
                            child: Container(
                              width: 140, height: 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white, width: 1.5),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Inner pulse ring
                      AnimatedBuilder(
                        animation: _pulseCtrl,
                        builder: (_, __) => Transform.scale(
                          scale: _pulseScale.value,
                          child: Opacity(
                            opacity: _pulseOpacity.value,
                            child: Container(
                              width: 140, height: 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Logo
                      AnimatedBuilder(
                        animation: _logoCtrl,
                        builder: (_, __) => Transform.scale(
                          scale: _logoScale.value,
                          child: Opacity(
                            opacity: _logoOpacity.value,
                            child: Container(
                              width: 120, height: 120,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.25),
                                    blurRadius: 30,
                                    offset: const Offset(0, 10),
                                  ),
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.3),
                                    blurRadius: 20,
                                    spreadRadius: -5,
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.stars_rounded,
                                  size: 56,
                                  color: Color(0xFF6C3CE1),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ]),

                    const SizedBox(height: 36),

                    // App name + tagline
                    FadeTransition(
                      opacity: _textOpacity,
                      child: SlideTransition(
                        position: _textSlide,
                        child: Column(children: [

                          // App name with letter-spaced style
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [Colors.white, Color(0xFFE1BEE7)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ).createShader(bounds),
                            child: const Text(
                              'Eventra',
                              style: TextStyle(
                                fontSize: 46,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 2,
                                height: 1,
                              ),
                            ),
                          ),

                          const SizedBox(height: 4),

                          // Divider line
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                  width: 30, height: 1.5,
                                  color: Colors.white.withOpacity(0.4)),
                              const SizedBox(width: 8),
                              Container(
                                width: 6, height: 6,
                                decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                  width: 30, height: 1.5,
                                  color: Colors.white.withOpacity(0.4)),
                            ],
                          ),

                          const SizedBox(height: 10),

                          // Tagline
                          FadeTransition(
                            opacity: _taglineOpacity,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.2)),
                              ),
                              child: Text(
                                '✨  Discover Amazing Events',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ]),
                      ),
                    ),

                    const SizedBox(height: 80),

                    // Shimmer loading bar
                    AnimatedBuilder(
                      animation: _shimmer,
                      builder: (_, __) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            width: 160, height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Stack(children: [
                              Positioned.fill(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      stops: [
                                        (_shimmer.value - 0.3).clamp(0, 1),
                                        _shimmer.value.clamp(0, 1),
                                        (_shimmer.value + 0.3).clamp(0, 1),
                                      ],
                                      colors: [
                                        Colors.white.withOpacity(0),
                                        Colors.white.withOpacity(0.85),
                                        Colors.white.withOpacity(0),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ]),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 12),

                    Text(
                      'Loading...',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.45),
                        fontSize: 11,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Version tag bottom ───────────────────
              Positioned(
                bottom: 32, left: 0, right: 0,
                child: Center(
                  child: Text(
                    'v1.0.0',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.25),
                      fontSize: 11,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ]),
          );
        },
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
// PARTICLE DATA
// ══════════════════════════════════════════════════════════
class _Particle {
  double x, y, size, speed, opacity, delay;
  _Particle({
    required this.x, required this.y,
    required this.size, required this.speed,
    required this.opacity, required this.delay,
  });
}

// ══════════════════════════════════════════════════════════
// PARTICLE PAINTER — draws drifting circles
// ══════════════════════════════════════════════════════════
class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ParticlePainter(this.particles, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      // Each particle drifts upward with its own speed + delay offset
      final t = (progress + p.delay) % 1.0;
      final y  = (p.y - t * p.speed * 40) % 1.0;
      final x  = p.x + sin(t * 2 * pi + p.delay * 10) * 0.02;

      // Fade in from bottom, fade out at top
      final fade = t < 0.1 ? t / 0.1 : t > 0.85 ? (1 - t) / 0.15 : 1.0;

      final paint = Paint()
        ..color = Colors.white.withOpacity(p.opacity * fade)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(x * size.width, y * size.height),
        p.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}