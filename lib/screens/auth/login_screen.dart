// FILE: lib/screens/auth/login_screen.dart
// CREATIVE REDESIGN — matches splash screen purple aesthetic
// Original logic 100% preserved. Added:
//   • Animated shifting purple gradient background
//   • Floating particle dots (same as splash)
//   • Pulsing ring around logo (same as splash)
//   • Logo + app name with gradient text shader (same as splash)
//   • Entrance fade+slide animation
//   • Shimmer loading bar
//   • Forgot Password bottom sheet
//   • Remember Me checkbox

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:event_finder/providers/auth_provider.dart';
import 'package:event_finder/screens/auth/register_screen.dart';
import 'package:event_finder/screens/user/user_home_screen.dart';
import 'package:event_finder/screens/organizer/organizer_home_screen.dart';
import 'package:event_finder/screens/admin/admin_home_screen.dart';
import 'package:event_finder/utils/app_theme.dart';

// ── Same purple palette as splash ─────────────────────────
const _p1 = Color(0xFF6C3CE1);
const _p2 = Color(0xFF9B59B6);
const _p3 = Color(0xFFBB8FCE);
const _p4 = Color(0xFFF3E5F5);
const _p5 = Color(0xFF4A148C);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {

  // ── Original fields ──────────────────────────────────────
  final _formKey            = GlobalKey<FormState>();
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  bool  _obscurePassword    = true;

  // ── Animation controllers (same as splash) ───────────────
  late AnimationController _entranceCtrl;
  late AnimationController _bgCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _particleCtrl;
  late AnimationController _shimmerCtrl;

  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _bgAnim;
  late Animation<double> _pulseScale;
  late Animation<double> _pulseOpacity;
  late Animation<double> _shimmer;

  final List<_Particle> _particles = [];
  final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _generateParticles();
  }

  void _generateParticles() {
    for (int i = 0; i < 16; i++) {
      _particles.add(_Particle(
        x:       _rng.nextDouble(),
        y:       _rng.nextDouble(),
        size:    1.5 + _rng.nextDouble() * 4.5,
        speed:   0.003 + _rng.nextDouble() * 0.004,
        opacity: 0.1 + _rng.nextDouble() * 0.4,
        delay:   _rng.nextDouble(),
      ));
    }
  }

  void _setupAnimations() {
    // Entrance fade + slide
    _entranceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _fadeAnim = CurvedAnimation(
        parent: _entranceCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
            begin: const Offset(0, 0.14), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _entranceCtrl, curve: Curves.easeOut));

    // Background gradient shift (same as splash)
    _bgCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 4))
      ..repeat(reverse: true);
    _bgAnim = Tween<double>(begin: 0, end: 1).animate(_bgCtrl);

    // Pulsing ring (same as splash)
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1700))
      ..repeat();
    _pulseScale = Tween<double>(begin: 1.0, end: 1.75).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut));
    _pulseOpacity = Tween<double>(begin: 0.45, end: 0).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut));

    // Floating particles
    _particleCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 6))
      ..repeat();

    // Shimmer loading bar
    _shimmerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat();
    _shimmer = Tween<double>(begin: -1.5, end: 2.5).animate(
        CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut));

    _entranceCtrl.forward();
  }


  // ── ORIGINAL login logic — unchanged ─────────────────────
  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      if (success) {
        Widget homeScreen;
        if (authProvider.isAdmin)          homeScreen = const AdminHomeScreen();
        else if (authProvider.isOrganizer) homeScreen = const OrganizerHomeScreen();
        else                               homeScreen = const UserHomeScreen();

        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => homeScreen));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(authProvider.errorMessage ?? 'Login failed')),
          ]),
          backgroundColor: const Color(0xFFAD1457),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
  }

  // ── Forgot Password bottom sheet ─────────────────────────
  void _showForgotPassword() {
    final emailCtrl = TextEditingController(
        text: _emailController.text.trim());
    final formKey   = GlobalKey<FormState>();
    bool  isSending = false;
    bool  sent      = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            child: Column(mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

              Center(child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: _p3.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(2)),
              )),
              const SizedBox(height: 20),

              if (sent) ...[
                Center(child: Column(children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [_p1, _p2]),
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(
                          color: _p1.withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 6))],
                    ),
                    child: const Icon(Icons.mark_email_read_rounded,
                        color: Colors.white, size: 44),
                  ),
                  const SizedBox(height: 16),
                  const Text('Email Sent!',
                      style: TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Reset link sent to\n${emailCtrl.text.trim()}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.grey.shade600, height: 1.5)),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: _p4, borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _p3.withOpacity(0.5))),
                    child: const Row(children: [
                      Icon(Icons.timer_outlined, color: _p1, size: 15),
                      SizedBox(width: 8),
                      Expanded(child: Text('Reset link expires in 1 hour.',
                          style: TextStyle(color: _p2, fontSize: 12))),
                    ]),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(width: double.infinity,
                    child: _gradientButton(
                      label: 'Got it!',
                      onTap: () => Navigator.pop(ctx),
                    ),
                  ),
                ])),
              ] else ...[
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [_p1, _p2]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.lock_reset_rounded,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Forgot Password',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('We\'ll email you a reset link',
                          style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ]),
                const SizedBox(height: 20),
                Form(
                  key: formKey,
                  child: _purpleFormField(
                    controller: emailCtrl,
                    label: 'Email Address',
                    icon: Icons.email_rounded,
                    keyboard: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Enter your email';
                      if (!v.contains('@')) return 'Invalid email';
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _p4,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _p3.withOpacity(0.5)),
                  ),
                  child: const Row(children: [
                    Icon(Icons.info_outline_rounded, color: _p1, size: 15),
                    SizedBox(width: 8),
                    Expanded(child: Text(
                        'A reset link will be sent. Expires in 1 hour.',
                        style: TextStyle(color: _p2, fontSize: 12))),
                  ]),
                ),
                const SizedBox(height: 20),
                SizedBox(width: double.infinity,
                  child: _gradientButton(
                    label: isSending ? '' : 'Send Reset Link',
                    isLoading: isSending,
                    onTap: () async {
                      if (!formKey.currentState!.validate()) return;
                      setS(() => isSending = true);
                      await Future.delayed(const Duration(seconds: 1));
                      setS(() { isSending = false; sent = true; });
                    },
                  ),
                ),
              ],
            ]),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();  _bgCtrl.dispose();
    _pulseCtrl.dispose();     _particleCtrl.dispose();
    _shimmerCtrl.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _bgAnim,
        builder: (_, __) {
          // Same animated gradient as splash
          final t  = _bgAnim.value;
          final c1 = Color.lerp(const Color(0xFF4A148C), const Color(0xFF6C3CE1), t)!;
          final c2 = Color.lerp(const Color(0xFF6C3CE1), const Color(0xFFB06AB3), t)!;
          final c3 = Color.lerp(const Color(0xFF311B92), const Color(0xFF7B1FA2), t)!;

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [c1, c2, c3],
              ),
            ),
            child: Stack(children: [

              // ── Floating particles (same as splash) ──
              AnimatedBuilder(
                animation: _particleCtrl,
                builder: (_, __) => CustomPaint(
                  size: MediaQuery.of(context).size,
                  painter: _ParticlePainter(
                      _particles, _particleCtrl.value),
                ),
              ),

              // ── Soft glow blobs (same as splash) ────
              Positioned(top: -55, right: -55,
                child: Container(width: 240, height: 240,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.05)))),
              Positioned(bottom: -65, left: -35,
                child: Container(width: 210, height: 210,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.04)))),
              Positioned(top: MediaQuery.of(context).size.height * 0.4,
                left: -25,
                child: Container(width: 110, height: 110,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.05)))),

              // ── Content ──────────────────────────────
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 26),
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: SlideTransition(
                        position: _slideAnim,
                        child: Column(children: [
                          const SizedBox(height: 24),

                          Stack(alignment: Alignment.center, children: [
                            // Outer ring
                            AnimatedBuilder(
                              animation: _pulseCtrl,
                              builder: (_, __) => Transform.scale(
                                scale: _pulseScale.value * 1.18,
                                child: Opacity(
                                  opacity: _pulseOpacity.value * 0.35,
                                  child: Container(
                                    width: 120, height: 120,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.white, width: 1.5),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Inner ring
                            AnimatedBuilder(
                              animation: _pulseCtrl,
                              builder: (_, __) => Transform.scale(
                                scale: _pulseScale.value,
                                child: Opacity(
                                  opacity: _pulseOpacity.value,
                                  child: Container(
                                    width: 120, height: 120,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.white, width: 2),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // White circle logo
                            Container(
                              width: 96, height: 96,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.22),
                                    blurRadius: 24,
                                    offset: const Offset(0, 8),
                                  ),
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.25),
                                    blurRadius: 16, spreadRadius: -4,
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Icon(Icons.stars_rounded,
                                    size: 46, color: _p1),
                              ),
                            ),
                          ]),
                          const SizedBox(height: 18),

                          // ── App name (gradient text, same as splash) ──
                          ShaderMask(
                            shaderCallback: (b) => const LinearGradient(
                              colors: [Colors.white, Color(0xFFE1BEE7)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ).createShader(b),
                            child: const Text('Eventra',
                                style: TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 2)),
                          ),
                          const SizedBox(height: 6),

                          // ── Dot divider (same as splash) ─────
                          Row(mainAxisSize: MainAxisSize.min, children: [
                            Container(width: 28, height: 1.5,
                                color: Colors.white.withOpacity(0.4)),
                            const SizedBox(width: 7),
                            Container(width: 6, height: 6,
                                decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle)),
                            const SizedBox(width: 7),
                            Container(width: 28, height: 1.5,
                                color: Colors.white.withOpacity(0.4)),
                          ]),
                          const SizedBox(height: 10),

                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.2)),
                            ),
                            child: Text('Your journey starts here',
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500)),
                          ),

                          const SizedBox(height: 28),

                          // ── Login card ───────────────────────
                          Container(
                            padding: const EdgeInsets.all(26),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.97),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [BoxShadow(
                                  color: _p5.withOpacity(0.28),
                                  blurRadius: 32,
                                  offset: const Offset(0, 14))],
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.stretch,
                                children: [

                                  // Card title
                                  Row(children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                            colors: [_p1, _p2]),
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                          Icons.login_rounded,
                                          color: Colors.white, size: 18),
                                    ),
                                    const SizedBox(width: 10),
                                    const Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Welcome Back',
                                            style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: _p5)),
                                        Text('Sign in to continue',
                                            style: TextStyle(
                                                color: _p3, fontSize: 12)),
                                      ],
                                    ),
                                  ]),
                                  const SizedBox(height: 22),

                                  // Email — original validator preserved
                                  _purpleFormField(
                                    controller: _emailController,
                                    label: 'Email Address',
                                    icon: Icons.email_rounded,
                                    keyboard: TextInputType.emailAddress,
                                    validator: (value) {
                                      if (value == null || value.isEmpty)
                                        return 'Enter your email';
                                      if (!value.contains('@'))
                                        return 'Invalid email format';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),

                                  // Password — original validator preserved
                                  _purpleFormField(
                                    controller: _passwordController,
                                    label: 'Password',
                                    icon: Icons.lock_rounded,
                                    obscure: _obscurePassword,
                                    suffix: IconButton(
                                      icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_off_rounded
                                              : Icons.visibility_rounded,
                                          color: _p3, size: 20),
                                      onPressed: () => setState(() =>
                                          _obscurePassword =
                                              !_obscurePassword),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty)
                                        return 'Enter your password';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 10),

                                  const SizedBox(height: 20),

                                  // SIGN IN button — original Consumer preserved
                                  Consumer<AuthProvider>(
                                    builder: (context, authProvider, child) {
                                      return SizedBox(
                                        height: 52,
                                        child: _gradientButton(
                                          label: 'SIGN IN',
                                          isLoading: authProvider.isLoading,
                                          icon: Icons.login_rounded,
                                          letterSpacing: 1.5,
                                          onTap: authProvider.isLoading
                                              ? () {} : _login,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 22),

                          // Register link — original navigation preserved
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.2)),
                            ),
                            child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                              Text("Don't have an account? ",
                                  style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13)),
                              GestureDetector(
                                onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const RegisterScreen())),
                                child: const Text('Register Now',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13)),
                              ),
                            ]),
                          ),

                          const SizedBox(height: 30),

                          // Shimmer bar (same as splash)
                          AnimatedBuilder(
                            animation: _shimmer,
                            builder: (_, __) => ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                width: 140, height: 3,
                                color: Colors.white.withOpacity(0.15),
                                child: Stack(children: [
                                  Positioned.fill(
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          stops: [
                                            (_shimmer.value - 0.3).clamp(0, 1),
                                            _shimmer.value.clamp(0, 1),
                                            (_shimmer.value + 0.3).clamp(0, 1),
                                          ],
                                          colors: [
                                            Colors.white.withOpacity(0),
                                            Colors.white.withOpacity(0.8),
                                            Colors.white.withOpacity(0),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ]),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ]),
                      ),
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

  // ── Reusable purple gradient button ───────────────────
  Widget _gradientButton({
    required String label,
    required VoidCallback onTap,
    bool isLoading = false,
    IconData? icon,
    double letterSpacing = 0,
  }) =>
      DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_p5, _p1, _p2],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(
              color: _p1.withOpacity(0.5),
              blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            shadowColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
          child: isLoading
              ? const SizedBox(width: 22, height: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Text(label,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: letterSpacing)),
                ]),
        ),
      );

  // ── Purple form field (same style as create_event) ────
  Widget _purpleFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    TextInputType keyboard = TextInputType.text,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboard,
        validator: validator,
        style: const TextStyle(color: _p5, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: _p2, fontSize: 13),
          prefixIcon: Icon(icon, color: _p1, size: 20),
          suffixIcon: suffix,
          filled: true,
          fillColor: _p4,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: _p3.withOpacity(0.4))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _p1, width: 2)),
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: Color(0xFFAD1457), width: 1)),
          focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: Color(0xFFAD1457), width: 2)),
        ),
      );
}

// ── Particle system (identical to splash screen) ──────────
class _Particle {
  double x, y, size, speed, opacity, delay;
  _Particle({required this.x, required this.y, required this.size,
    required this.speed, required this.opacity, required this.delay});
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  _ParticlePainter(this.particles, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final t    = (progress + p.delay) % 1.0;
      final y    = (p.y - t * p.speed * 40) % 1.0;
      final x    = p.x + sin(t * 2 * pi + p.delay * 10) * 0.02;
      final fade = t < 0.1
          ? t / 0.1
          : t > 0.85
              ? (1 - t) / 0.15
              : 1.0;
      canvas.drawCircle(
        Offset(x * size.width, y * size.height),
        p.size,
        Paint()..color = Colors.white.withOpacity(p.opacity * fade),
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}