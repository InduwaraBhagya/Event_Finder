// FILE: lib/screens/auth/register_screen.dart
// CREATIVE REDESIGN — matches splash screen purple aesthetic
// Original logic 100% preserved. Added:
//   • Animated shifting purple gradient background
//   • Floating particle dots (same as splash)
//   • Icon + gradient app name header (same as splash)
//   • Entrance fade+slide animation
//   • Role selector replaced dropdown with purple pill toggle
//   • Purple form fields (same as create_event style)
//   • Gradient CREATE ACCOUNT button

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:event_finder/providers/auth_provider.dart';
import 'package:event_finder/utils/app_theme.dart';

// ── Same purple palette as splash ─────────────────────────
const _p1 = Color(0xFF6C3CE1);
const _p2 = Color(0xFF9B59B6);
const _p3 = Color(0xFFBB8FCE);
const _p4 = Color(0xFFF3E5F5);
const _p5 = Color(0xFF4A148C);

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {

  // ── Original fields ──────────────────────────────────────
  final _formKey                  = GlobalKey<FormState>();
  final _nameController           = TextEditingController();
  final _emailController          = TextEditingController();
  final _passwordController       = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool   _obscurePassword         = true;
  bool   _obscureConfirmPassword  = true;
  String _selectedRole            = 'user';

  // ── Animation controllers (same as splash) ───────────────
  late AnimationController _entranceCtrl;
  late AnimationController _bgCtrl;
  late AnimationController _particleCtrl;

  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _bgAnim;

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
        opacity: 0.1 + _rng.nextDouble() * 0.38,
        delay:   _rng.nextDouble(),
      ));
    }
  }

  void _setupAnimations() {
    _entranceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 850));
    _fadeAnim = CurvedAnimation(
        parent: _entranceCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
            begin: const Offset(0, 0.13), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _entranceCtrl, curve: Curves.easeOut));

    // Animated bg gradient (same as splash)
    _bgCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 4))
      ..repeat(reverse: true);
    _bgAnim = Tween<double>(begin: 0, end: 1).animate(_bgCtrl);

    // Particles
    _particleCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 6))
      ..repeat();

    _entranceCtrl.forward();
  }

  @override
  void dispose() {
    _entranceCtrl.dispose(); _bgCtrl.dispose(); _particleCtrl.dispose();
    _nameController.dispose();            _emailController.dispose();
    _passwordController.dispose();        _confirmPasswordController.dispose();
    super.dispose();
  }

  // ── ORIGINAL register logic — unchanged ──────────────────
  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        _showSnackBar('Passwords do not match', isError: true);
        return;
      }

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.register(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
        _selectedRole,
      );

      if (!mounted) return;

      if (success) {
        _showSnackBar('Registration successful! Please login.');
        Navigator.of(context).pop();
      } else {
        _showSnackBar(
            authProvider.errorMessage ?? 'Registration failed',
            isError: true);
      }
    }
  }

  // ── ORIGINAL showSnackBar logic — preserved ──────────────
  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(
          isError ? Icons.error_outline : Icons.check_circle_outline,
          color: Colors.white, size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(message)),
      ]),
      backgroundColor: isError
          ? const Color(0xFFAD1457)
          : Colors.green.shade700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ══════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // original property preserved
      appBar: AppBar(                // original AppBar preserved
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.arrow_back,
                color: Colors.white, size: 20),
          ),
        ),
      ),
      body: AnimatedBuilder(
        animation: _bgAnim,
        builder: (_, __) {
          // Slightly shifted palette vs login (topRight → bottomLeft)
          final t  = _bgAnim.value;
          final c1 = Color.lerp(const Color(0xFF311B92), const Color(0xFF4A148C), t)!;
          final c2 = Color.lerp(const Color(0xFF6C3CE1), const Color(0xFFB06AB3), t)!;
          final c3 = Color.lerp(const Color(0xFF7B1FA2), const Color(0xFF9C27B0), t)!;

          return Container(
            height: double.infinity, // original property preserved
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,  // original direction preserved
                end: Alignment.bottomLeft,
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

              // ── Soft glow blobs ──────────────────────
              Positioned(top: -45, left: -45,
                child: Container(width: 220, height: 220,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.05)))),
              Positioned(bottom: -55, right: -35,
                child: Container(width: 200, height: 200,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.04)))),

              // ── Content ──────────────────────────────
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 10),
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: Column(children: [
                        const SizedBox(height: 10),

                        // ── Header icon (same style as splash/login) ──
                        Container(
                          width: 80, height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.22),
                                  blurRadius: 22,
                                  offset: const Offset(0, 8)),
                              BoxShadow(
                                  color: Colors.white.withOpacity(0.22),
                                  blurRadius: 14, spreadRadius: -4),
                            ],
                          ),
                          child: const Center(
                            child: Icon(Icons.person_add_rounded,
                                size: 38, color: _p1),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Gradient text (same as splash)
                        ShaderMask(
                          shaderCallback: (b) => const LinearGradient(
                            colors: [Colors.white, Color(0xFFE1BEE7)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ).createShader(b),
                          child: const Text('Join Eventra',
                              style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 1.5)),
                        ),
                        const SizedBox(height: 6),

                        // Dot divider (same as splash)
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          Container(width: 22, height: 1.5,
                              color: Colors.white.withOpacity(0.4)),
                          const SizedBox(width: 6),
                          Container(width: 5, height: 5,
                              decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          Container(width: 22, height: 1.5,
                              color: Colors.white.withOpacity(0.4)),
                        ]),
                        const SizedBox(height: 8),

                        // Tagline pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.2)),
                          ),
                          child: Text('Join the Community',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500)),
                        ),

                        const SizedBox(height: 24),

                        // ── Registration card ────────────────
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.97),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [BoxShadow(
                                color: _p5.withOpacity(0.28),
                                blurRadius: 30,
                                offset: const Offset(0, 12))],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(children: [

                              // Card header
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
                                      Icons.app_registration_rounded,
                                      color: Colors.white, size: 18),
                                ),
                                const SizedBox(width: 10),
                                const Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text('Create Account',
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: _p5)),
                                    Text('Fill in your details below',
                                        style: TextStyle(
                                            color: _p3, fontSize: 11)),
                                  ],
                                ),
                              ]),
                              const SizedBox(height: 20),

                              // Full Name — original validator preserved
                              _purpleField(
                                controller: _nameController,
                                label: 'Full Name',
                                icon: Icons.person_outline_rounded,
                                validator: (v) =>
                                    v!.isEmpty ? 'Name required' : null,
                              ),
                              const SizedBox(height: 14),

                              // Email — original validator preserved
                              _purpleField(
                                controller: _emailController,
                                label: 'Email',
                                icon: Icons.email_outlined,
                                keyboard: TextInputType.emailAddress,
                                validator: (v) =>
                                    !v!.contains('@') ? 'Invalid email' : null,
                              ),
                              const SizedBox(height: 14),

                              // Role selector (pill toggle replacing dropdown)
                              _buildRoleSelector(),
                              const SizedBox(height: 14),

                              // Password — original validator preserved
                              _purpleField(
                                controller: _passwordController,
                                label: 'Password',
                                icon: Icons.lock_outline_rounded,
                                obscure: _obscurePassword,
                                suffix: IconButton(
                                  icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_rounded
                                          : Icons.visibility_rounded,
                                      color: _p3, size: 20),
                                  onPressed: () => setState(() =>
                                      _obscurePassword = !_obscurePassword),
                                ),
                                validator: (v) =>
                                    v!.length < 6 ? 'Min 6 characters' : null,
                              ),
                              const SizedBox(height: 14),

                              // Confirm password — original validator preserved
                              _purpleField(
                                controller: _confirmPasswordController,
                                label: 'Confirm Password',
                                icon: Icons.lock_reset_rounded,
                                obscure: _obscureConfirmPassword,
                                suffix: IconButton(
                                  icon: Icon(
                                      _obscureConfirmPassword
                                          ? Icons.visibility_off_rounded
                                          : Icons.visibility_rounded,
                                      color: _p3, size: 20),
                                  onPressed: () => setState(() =>
                                      _obscureConfirmPassword =
                                          !_obscureConfirmPassword),
                                ),
                                validator: (v) => v!.isEmpty
                                    ? 'Please confirm password' : null,
                              ),
                              const SizedBox(height: 24),

                              // CREATE ACCOUNT button — original Consumer preserved
                              Consumer<AuthProvider>(
                                builder: (context, authProvider, child) {
                                  return SizedBox(
                                    width: double.infinity,
                                    height: 55,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [_p5, _p1, _p2],
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(15),
                                        boxShadow: [BoxShadow(
                                            color: _p1.withOpacity(0.5),
                                            blurRadius: 16,
                                            offset: const Offset(0, 6))],
                                      ),
                                      child: ElevatedButton(
                                        onPressed: authProvider.isLoading
                                            ? null : _register,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              Colors.transparent,
                                          foregroundColor: Colors.white,
                                          shadowColor: Colors.transparent,
                                          disabledBackgroundColor:
                                              Colors.transparent,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(15)),
                                          elevation: 5, // original preserved
                                        ),
                                        child: authProvider.isLoading
                                            ? const CircularProgressIndicator(
                                                color: Colors.white) // original
                                            : const Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons.person_add_rounded,
                                                      size: 18),
                                                  SizedBox(width: 8),
                                                  Text('CREATE ACCOUNT',
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 15,
                                                          letterSpacing: 1)),
                                                ],
                                              ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ]),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Sign in link — original navigation preserved
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.2)),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min,
                              children: [
                            Text('Already have an account? ',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 13)),
                            GestureDetector(
                              onTap: () => Navigator.of(context).pop(),
                              child: const Text('Sign In',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13)),
                            ),
                          ]),
                        ),
                        const SizedBox(height: 20),
                      ]),
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

  // ── Purple role pill toggle (replaces plain dropdown) ─
  Widget _buildRoleSelector() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Padding(
        padding: EdgeInsets.only(left: 2, bottom: 8),
        child: Text('Join as',
            style: TextStyle(color: _p2, fontSize: 13,
                fontWeight: FontWeight.w600)),
      ),
      Row(children: [
        Expanded(child: _rolePill(
          value: 'user',
          icon: Icons.person_rounded,
          label: 'Regular User',
          subtitle: 'Browse & book events',
        )),
        const SizedBox(width: 10),
        Expanded(child: _rolePill(
          value: 'organizer',
          icon: Icons.event_rounded,
          label: 'Organizer',
          subtitle: 'Create & manage events',
        )),
      ]),
    ]);
  }

  Widget _rolePill({
    required String value,
    required IconData icon,
    required String label,
    required String subtitle,
  }) {
    final isSelected = _selectedRole == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(colors: [_p1, _p2])
              : null,
          color: isSelected ? null : _p4,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? Colors.transparent : _p3.withOpacity(0.4),
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: _p1.withOpacity(0.4),
                  blurRadius: 10, offset: const Offset(0, 4))]
              : [BoxShadow(color: Colors.black.withOpacity(0.03),
                  blurRadius: 4)],
        ),
        child: Column(children: [
          Icon(icon,
              color: isSelected ? Colors.white : _p2, size: 22),
          const SizedBox(height: 5),
          Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : _p1)),
          const SizedBox(height: 2),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 9.5,
                  color: isSelected
                      ? Colors.white.withOpacity(0.8) : _p3)),
        ]),
      ),
    );
  }

  // ── Purple form field ────────────────────────────────
  Widget _purpleField({
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

// ── Particle system (identical to splash + login) ─────────
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