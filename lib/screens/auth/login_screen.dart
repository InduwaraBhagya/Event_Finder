import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:event_finder/providers/auth_provider.dart';
import 'package:event_finder/screens/auth/register_screen.dart';
import 'package:event_finder/screens/user/user_home_screen.dart';
import 'package:event_finder/screens/organizer/organizer_home_screen.dart';
import 'package:event_finder/screens/admin/admin_home_screen.dart';
import 'package:event_finder/utils/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

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
        if (authProvider.isAdmin) {
          homeScreen = const AdminHomeScreen();
        } else if (authProvider.isOrganizer) {
          homeScreen = const OrganizerHomeScreen();
        } else {
          homeScreen = const UserHomeScreen();
        }

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => homeScreen),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'Login failed'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.redAccent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Vibrant Gradient Background
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor,
              AppTheme.primaryColor.withBlue(200),
              Colors.deepPurple.shade400,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Column(
                children: [
                  // Glassmorphism-style Header
                  _buildHeader(),
                  const SizedBox(height: 30),
                  
                  // Login Card
                  Container(
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        )
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            "Login",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor.withOpacity(0.8),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 25),
                          
                          // Email Field
                          _buildTextField(
                            controller: _emailController,
                            label: 'Email Address',
                            icon: Icons.email_rounded,
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Enter your email';
                              if (!value.contains('@')) return 'Invalid email format';
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          
                          // Password Field
                          _buildTextField(
                            controller: _passwordController,
                            label: 'Password',
                            icon: Icons.lock_rounded,
                            isPassword: true,
                            obscureText: _obscurePassword,
                            togglePassword: () => setState(() => _obscurePassword = !_obscurePassword),
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Enter your password';
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),
                          
                          //Align(
                           //// alignment: Alignment.centerRight,
                            //child: TextButton(
                              //onPressed: () {},
                             // child: const Text("Forgot Password?", style: TextStyle(color: Colors.grey)),
                           // ),
                          //),
                          //const SizedBox(height: 20),
                          
                          // Animated Login Button
                          Consumer<AuthProvider>(
                            builder: (context, authProvider, child) {
                              return ElevatedButton(
                                onPressed: authProvider.isLoading ? null : _login,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                  backgroundColor: AppTheme.primaryColor,
                                  elevation: 5,
                                ),
                                child: authProvider.isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                      )
                                    : const Text(
                                        'SIGN IN',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                                      ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Footer Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account? ", style: TextStyle(color: Colors.white70)),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RegisterScreen()));
                        },
                        child: const Text(
                          'Register Now',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, ),
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

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.2),
            border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
          ),
          child: const Icon(Icons.stars_rounded, size: 60, color: Colors.white),
        ),
        const SizedBox(height: 20),
        const Text(
          'Eventra',
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.5),
        ),
        const Text(
          'Your journey starts here',
          style: TextStyle(fontSize: 16, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? togglePassword,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.primaryColor),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                onPressed: togglePassword,
              )
            : null,
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
      ),
    );
  }
}