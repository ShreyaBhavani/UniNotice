import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../widgets/floating_icons_background.dart';
import '../../widgets/animated_tech_border.dart';
import '../dashboard/admin_dashboard.dart';
import '../dashboard/student_dashboard.dart';
import '../dashboard/staff_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAdmin();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  Future<void> _initializeAdmin() async {
    // Skip - admin already created in Firebase
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result = await _authService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => AuthResult(success: false, errorMessage: 'Login timeout. Check your internet.'),
      );

      if (result.success && mounted) {
        final user = await _authService.getCurrentUser().timeout(
          const Duration(seconds: 10),
          onTimeout: () => null,
        );
        if (user != null) {
          _navigateToRoleDashboard(user.role);
        } else if (result.role != null) {
          _navigateToRoleDashboard(result.role!);
        }
      } else if (mounted) {
        _showError(result.errorMessage ?? 'Login failed');
      }
    } catch (e) {
      if (mounted) _showError('An error occurred');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateToRoleDashboard(UserRole role) {
    Widget dashboard;
    switch (role) {
      case UserRole.admin:
        dashboard = const AdminDashboard();
        break;
      case UserRole.student:
        dashboard = const StudentDashboard();
        break;
      case UserRole.staff:
        dashboard = const StaffDashboard();
        break;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => dashboard),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      print('Login screen: Starting Google sign-in...');
      // Remove timeout - Google Sign-In manages its own popup/redirect timing
      final result = await _authService.signInWithGoogle();
      print('Login screen: Got result - success: ${result.success}');

      if (result.success && mounted) {
        // Use the role from the result directly - it's already set
        if (result.role != null) {
          _navigateToRoleDashboard(result.role!);
        } else {
          // Fallback: try to get current user
          final user = await _authService.getCurrentUser();
          if (user != null && mounted) {
            _navigateToRoleDashboard(user.role);
          } else if (mounted) {
            // Default to student if no role found
            _navigateToRoleDashboard(UserRole.student);
          }
        }
      } else if (mounted) {
        _showError(result.errorMessage ?? 'Google sign-in failed');
      }
    } catch (e) {
      print('Login screen: Exception - $e');
      if (mounted) _showError('An error occurred during Google sign-in: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _buildInputDecoration(String label, IconData icon,
      {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey.shade600),
      prefixIcon: Icon(icon, color: const Color(0xFF0088CC)),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF7FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF0088CC), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8EDF5),
      body: FloatingIconsBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 40),
                      AnimatedTechBorder(
                        borderRadius: 20,
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0088CC).withOpacity(0.1),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  style: const TextStyle(color: Color(0xFF2D3748)),
                                  decoration: _buildInputDecoration('Email', Icons.email_outlined),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) return 'Please enter email';
                                    if (!value.contains('@') || !value.contains('.')) return 'Please enter a valid email';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  style: const TextStyle(color: Color(0xFF2D3748)),
                                  decoration: _buildInputDecoration(
                                    'Password',
                                    Icons.lock_outline,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                        color: Colors.grey.shade600,
                                      ),
                                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) return 'Please enter password';
                                    if (value.length < 6) return 'Password must be at least 6 characters';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _submit,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0088CC),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      elevation: 4,
                                      shadowColor: const Color(0xFF0088CC).withOpacity(0.3),
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                                          )
                                        : const Text('LOGIN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2)),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(child: Divider(color: Colors.grey.shade300)),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      child: Text('OR', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                                    ),
                                    Expanded(child: Divider(color: Colors.grey.shade300)),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: OutlinedButton.icon(
                                    onPressed: _isLoading ? null : _signInWithGoogle,
                                    icon: Image.network(
                                      'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                                      height: 24,
                                      width: 24,
                                      errorBuilder: (context, error, stackTrace) => 
                                        const Icon(Icons.g_mobiledata, size: 24, color: Colors.red),
                                    ),
                                    label: const Text(
                                      'Continue with Google',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF2D3748),
                                      side: BorderSide(color: Colors.grey.shade300),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF0088CC).withOpacity(0.3)),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.info_outline, color: Color(0xFF0088CC), size: 24),
                            const SizedBox(height: 8),
                            Text(
                              'Students & Staff: Contact admin for credentials',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Admin: admin@uni.com / admin123',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
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
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [BoxShadow(color: const Color(0xFF0088CC).withOpacity(0.2), blurRadius: 20, spreadRadius: 5)],
          ),
          child: const Center(child: Icon(Icons.school, size: 50, color: Color(0xFF0088CC))),
        ),
        const SizedBox(height: 24),
        const Text('UniNotice', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFF2D3748), letterSpacing: 2)),
        const SizedBox(height: 8),
        Text('Sign in to continue', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
      ],
    );
  }
}
