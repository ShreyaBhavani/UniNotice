import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_app/screens/login/login_screen.dart';
import 'package:my_app/screens/dashboard/admin_dashboard.dart';
import 'package:my_app/screens/dashboard/student_dashboard.dart';
import 'package:my_app/screens/dashboard/staff_dashboard.dart';
import 'package:my_app/services/auth_service.dart';
import 'package:my_app/widgets/floating_icons_background.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _animationController.forward();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Wait for animation
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    Widget destination = const LoginScreen();
    
    try {
      // Wait for Firebase Auth to restore the session
      // Firebase Auth state might not be immediately available on app restart
      User? firebaseUser = FirebaseAuth.instance.currentUser;
      
      // If no user yet, wait a bit for Firebase to restore auth state
      firebaseUser ??= await FirebaseAuth.instance
            .authStateChanges()
            .first
            .timeout(
              const Duration(seconds: 3),
              onTimeout: () => null,
            );

      if (firebaseUser != null && mounted) {
        print('User already logged in: ${firebaseUser.email}');
        final user = await _authService.getCurrentUser().timeout(
          const Duration(seconds: 5),
          onTimeout: () => null,
        );
        if (user != null) {
          print('Navigating to ${user.role} dashboard');
          switch (user.role) {
            case UserRole.admin:
              destination = const AdminDashboard();
              break;
            case UserRole.student:
              destination = const StudentDashboard();
              break;
            case UserRole.staff:
              destination = const StaffDashboard();
              break;
          }
        }
      } else {
        print('No user logged in, showing login screen');
      }
    } catch (e) {
      print('Auth check error: $e');
    }

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => destination,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8EDF5),
      body: FloatingIconsBackground(
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Glowing App Icon
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF00d4ff).withOpacity(0.2),
                          Colors.transparent,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00d4ff).withOpacity(0.3),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(
                          color: const Color(0xFF0088CC),
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0088CC).withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.school_rounded,
                        size: 70,
                        color: Color(0xFF0088CC),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // App Name with gradient
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFF0088CC), Color(0xFF00AADD)],
                    ).createShader(bounds),
                    child: const Text(
                      'UniNotice',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // App Description
                  Text(
                    'Your University Notice Board',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 16,
                      letterSpacing: 1,
                    ),
                  ),

                  const SizedBox(height: 60),

                  // Double ring loading indicator
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: Stack(
                      children: [
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              const Color(0xFF0088CC).withOpacity(0.3),
                            ),
                          ),
                        ),
                        Center(
                          child: SizedBox(
                            width: 28,
                            height: 28,
                            child: const CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF0088CC),
                              ),
                            ),
                          ),
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
    );
  }
}
