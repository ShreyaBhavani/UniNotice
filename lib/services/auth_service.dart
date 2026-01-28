import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// User roles enum
enum UserRole { admin, student, staff }

/// Authentication Result class to handle success/error states
class AuthResult {
  final bool success;
  final String? errorMessage;
  final String? userId;
  final UserRole? role;

  AuthResult({required this.success, this.errorMessage, this.userId, this.role});
}

/// User model for storing user data
class UserModel {
  final String id;
  final String fullName;
  final String email;
  final UserRole role;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'fullName': fullName,
    'email': email,
    'role': role.name,
    'createdAt': createdAt.toIso8601String(),
  };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'] ?? '',
    fullName: json['fullName'] ?? '',
    email: json['email'] ?? '',
    role: UserRole.values.firstWhere(
      (r) => r.name == json['role'],
      orElse: () => UserRole.student,
    ),
    createdAt: json['createdAt'] != null 
        ? DateTime.parse(json['createdAt']) 
        : DateTime.now(),
  );

  bool get isAdmin => role == UserRole.admin;
  bool get isStudent => role == UserRole.student;
  bool get isStaff => role == UserRole.staff;
}

/// Authentication Service with Firebase Auth + Realtime Database
class AuthService {
  static const String _keyCurrentUser = 'currentUser';
  static const String _databaseUrl = 'https://uninotice-2e07c-default-rtdb.asia-southeast1.firebasedatabase.app';

  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final DatabaseReference _database;

  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal() {
    // Initialize database with explicit URL for regional database
    _database = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: _databaseUrl,
    ).ref();
  }

  // ==================== VALIDATION METHODS ====================

  /// Validate email format
  String? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  /// Validate password
  String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'Password is required';
    }
    if (password.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  /// Validate confirm password
  String? validateConfirmPassword(String? password, String? confirmPassword) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return 'Please confirm your password';
    }
    if (password != confirmPassword) {
      return 'Passwords do not match';
    }
    return null;
  }

  /// Validate full name
  String? validateFullName(String? name) {
    if (name == null || name.isEmpty) {
      return 'Full name is required';
    }
    if (name.length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  // ==================== AUTHENTICATION METHODS ====================

  /// Initialize default admin account if not exists
  Future<void> initializeDefaultAdmin() async {
    try {
      // Check if admin exists in database
      final snapshot = await _database.child('users').orderByChild('email').equalTo('admin@uni.com').get();
      
      if (!snapshot.exists) {
        // Create admin in Firebase Auth
        try {
          final userCredential = await _auth.createUserWithEmailAndPassword(
            email: 'admin@uni.com',
            password: 'admin123',
          );
          
          // Save admin to Realtime Database
          final adminUser = UserModel(
            id: userCredential.user!.uid,
            fullName: 'Admin',
            email: 'admin@uni.com',
            role: UserRole.admin,
            createdAt: DateTime.now(),
          );
          
          await _database.child('users').child(userCredential.user!.uid).set(adminUser.toJson());
          
          // Sign out after creating admin
          await _auth.signOut();
        } on FirebaseAuthException catch (e) {
          // Admin already exists in Auth but not in database, ignore
          if (e.code != 'email-already-in-use') {
            rethrow;
          }
        }
      }
    } catch (e) {
      // Silently fail - admin may already exist
      print('Admin initialization: $e');
    }
  }

  /// Register a new user (Admin only)
  Future<AuthResult> registerUser({
    required String fullName,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    // Validate inputs
    final nameError = validateFullName(fullName);
    if (nameError != null) {
      return AuthResult(success: false, errorMessage: nameError);
    }

    final emailError = validateEmail(email);
    if (emailError != null) {
      return AuthResult(success: false, errorMessage: emailError);
    }

    final passwordError = validatePassword(password);
    if (passwordError != null) {
      return AuthResult(success: false, errorMessage: passwordError);
    }

    try {
      // Store current user to restore session after creating new user
      final currentUser = _auth.currentUser;
      print('Registering new user: $email');
      print('Current admin user: ${currentUser?.email}');
      
      // Create user in Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.toLowerCase(),
        password: password,
      );
      
      print('User created in Firebase Auth: ${userCredential.user?.uid}');

      // Create user model
      final newUser = UserModel(
        id: userCredential.user!.uid,
        fullName: fullName,
        email: email.toLowerCase(),
        role: role,
        createdAt: DateTime.now(),
      );

      // Save to Realtime Database
      await _database.child('users').child(userCredential.user!.uid).set(newUser.toJson());

      // Sign out the newly created user
      await _auth.signOut();
      
      // Re-authenticate the admin if they were logged in
      if (currentUser != null) {
        // Admin needs to re-login - we'll handle this in the UI
      }

      return AuthResult(success: true, userId: newUser.id, role: role);
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException during registration: ${e.code} - ${e.message}');
      String message = 'Registration failed';
      if (e.code == 'email-already-in-use') {
        message = 'An account with this email already exists';
      } else if (e.code == 'weak-password') {
        message = 'Password is too weak';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email address';
      }
      return AuthResult(success: false, errorMessage: message);
    } catch (e) {
      print('General error during registration: $e');
      return AuthResult(
        success: false,
        errorMessage: 'Registration failed: ${e.toString()}',
      );
    }
  }

  /// Get all registered users (for admin)
  Future<List<UserModel>> getAllUsers() async {
    try {
      final snapshot = await _database.child('users').get();
      
      if (!snapshot.exists) return [];
      
      final usersMap = Map<String, dynamic>.from(snapshot.value as Map);
      return usersMap.entries.map((entry) {
        final userData = Map<String, dynamic>.from(entry.value as Map);
        return UserModel.fromJson(userData);
      }).toList();
    } catch (e) {
      print('Error getting users: $e');
      return [];
    }
  }

  /// Delete a user (Admin only)
  Future<AuthResult> deleteUser(String email) async {
    try {
      // Find user by email
      final snapshot = await _database.child('users').orderByChild('email').equalTo(email.toLowerCase()).get();
      
      if (!snapshot.exists) {
        return AuthResult(success: false, errorMessage: 'User not found');
      }

      // Prevent deleting default admin
      if (email.toLowerCase() == 'admin@uni.com') {
        return AuthResult(success: false, errorMessage: 'Cannot delete default admin');
      }

      // Get user ID and delete from database
      final usersMap = Map<String, dynamic>.from(snapshot.value as Map);
      final userId = usersMap.keys.first;
      
      await _database.child('users').child(userId).remove();
      
      // Note: We can't delete from Firebase Auth without admin SDK
      // The user will still exist in Auth but not in database
      
      return AuthResult(success: true);
    } catch (e) {
      return AuthResult(success: false, errorMessage: 'Failed to delete user: ${e.toString()}');
    }
  }

  /// Login user
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    // Validate inputs
    final emailError = validateEmail(email);
    if (emailError != null) {
      return AuthResult(success: false, errorMessage: emailError);
    }

    final passwordError = validatePassword(password);
    if (passwordError != null) {
      return AuthResult(success: false, errorMessage: passwordError);
    }

    try {
      print('Attempting login for: $email');
      
      // Sign in with Firebase Auth
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.toLowerCase(),
        password: password,
      );
      
      print('Firebase Auth success: ${userCredential.user?.uid}');

      // Get user data from Realtime Database
      final snapshot = await _database.child('users').child(userCredential.user!.uid).get();
      
      print('Database snapshot exists: ${snapshot.exists}');
      
      UserModel user;
      if (!snapshot.exists) {
        // Auto-create user data for admin on first login
        final isAdmin = email.toLowerCase() == 'admin@uni.com';
        user = UserModel(
          id: userCredential.user!.uid,
          fullName: isAdmin ? 'Admin' : 'User',
          email: email.toLowerCase(),
          role: isAdmin ? UserRole.admin : UserRole.student,
          createdAt: DateTime.now(),
        );
        await _database.child('users').child(userCredential.user!.uid).set(user.toJson());
      } else {
        final userData = Map<String, dynamic>.from(snapshot.value as Map);
        user = UserModel.fromJson(userData);
      }

      // Save session locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyCurrentUser, user.id);

      print('Login successful for role: ${user.role}');
      return AuthResult(success: true, userId: user.id, role: user.role);
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException: ${e.code} - ${e.message}');
      String message = 'Login failed';
      if (e.code == 'user-not-found') {
        message = 'No account found with this email';
      } else if (e.code == 'wrong-password') {
        message = 'Incorrect password';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email address';
      } else if (e.code == 'user-disabled') {
        message = 'This account has been disabled';
      } else if (e.code == 'invalid-credential') {
        message = 'Invalid email or password';
      }
      return AuthResult(success: false, errorMessage: message);
    } catch (e) {
      print('Login error: $e');
      return AuthResult(
        success: false,
        errorMessage: 'Login failed: ${e.toString()}',
      );
    }
  }

  /// Logout user
  Future<void> logout() async {
    await _auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyCurrentUser);
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    return _auth.currentUser != null;
  }

  /// Get current user
  Future<UserModel?> getCurrentUser() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;

    try {
      final snapshot = await _database.child('users').child(firebaseUser.uid).get();
      
      if (!snapshot.exists) return null;
      
      final userData = Map<String, dynamic>.from(snapshot.value as Map);
      return UserModel.fromJson(userData);
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  /// Clear all data (for testing)
  Future<void> clearAllData() async {
    await _auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
