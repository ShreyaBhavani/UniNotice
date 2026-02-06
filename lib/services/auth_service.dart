import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// User roles enum
enum UserRole { admin, student, staff }

/// Department enum
enum Department {
  it,
  cs,
  ce,
  aiml,
  unknown;

  String get displayName {
    switch (this) {
      case Department.it:
        return 'Information Technology';
      case Department.cs:
        return 'Computer Science';
      case Department.ce:
        return 'Computer Engineering';
      case Department.aiml:
        return 'AI & Machine Learning';
      case Department.unknown:
        return 'Unknown';
    }
  }

  String get shortName {
    switch (this) {
      case Department.it:
        return 'IT';
      case Department.cs:
        return 'CS';
      case Department.ce:
        return 'CE';
      case Department.aiml:
        return 'AIML';
      case Department.unknown:
        return 'N/A';
    }
  }
}

/// Extract department from email
/// Handles patterns like: 20it006@uni.com, priynkait@uni.com, student_it@uni.com
Department getDepartmentFromEmail(String email) {
  final emailLower = email.toLowerCase();
  final localPart = emailLower.split('@').first; // Get part before @

  // Check for IT department patterns
  if (localPart.contains('it') ||
      emailLower.contains('_it') ||
      emailLower.contains('.it') ||
      emailLower.contains('it@') ||
      emailLower.contains('it_')) {
    return Department.it;
  }
  // Check for CS department patterns
  else if (localPart.contains('cs') ||
      emailLower.contains('_cs') ||
      emailLower.contains('.cs') ||
      emailLower.contains('cs@') ||
      emailLower.contains('cs_')) {
    return Department.cs;
  }
  // Check for CE department patterns (check before 'ce' in 'notice' etc)
  else if (RegExp(r'\d+ce|ce\d+|_ce|ce_|\.ce|ce@').hasMatch(emailLower)) {
    return Department.ce;
  }
  // Check for AIML department patterns
  else if (localPart.contains('aiml') ||
      emailLower.contains('_aiml') ||
      emailLower.contains('.aiml') ||
      emailLower.contains('aiml@') ||
      emailLower.contains('aiml_')) {
    return Department.aiml;
  }
  return Department.unknown;
}

/// Authentication Result class to handle success/error states
class AuthResult {
  final bool success;
  final String? errorMessage;
  final String? userId;
  final UserRole? role;

  AuthResult({
    required this.success,
    this.errorMessage,
    this.userId,
    this.role,
  });
}

/// User model for storing user data
class UserModel {
  final String id;
  final String fullName;
  final String email;
  final UserRole role;
  final Department department;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.createdAt,
    Department? department,
  }) : department = department ?? getDepartmentFromEmail(email);

  Map<String, dynamic> toJson() => {
    'id': id,
    'fullName': fullName,
    'email': email,
    'role': role.name,
    'department': department.name,
    'createdAt': FieldValue.serverTimestamp(),
  };

  /// Convert to JSON for updates (without serverTimestamp)
  Map<String, dynamic> toJsonForUpdate() => {
    'id': id,
    'fullName': fullName,
    'email': email,
    'role': role.name,
    'department': department.name,
  };

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final email = json['email'] ?? '';

    // Handle Firestore Timestamp
    DateTime createdAt;
    if (json['createdAt'] is Timestamp) {
      createdAt = (json['createdAt'] as Timestamp).toDate();
    } else if (json['createdAt'] is String) {
      createdAt = DateTime.parse(json['createdAt']);
    } else {
      createdAt = DateTime.now();
    }

    return UserModel(
      id: json['id'] ?? '',
      fullName: json['fullName'] ?? '',
      email: email,
      role: UserRole.values.firstWhere(
        (r) => r.name == json['role'],
        orElse: () => UserRole.student,
      ),
      department: json['department'] != null
          ? Department.values.firstWhere(
              (d) => d.name == json['department'],
              orElse: () => getDepartmentFromEmail(email),
            )
          : getDepartmentFromEmail(email),
      createdAt: createdAt,
    );
  }

  bool get isAdmin => role == UserRole.admin;
  bool get isStudent => role == UserRole.student;
  bool get isStaff => role == UserRole.staff;
}

/// Authentication Service with Firebase Auth + Cloud Firestore
class AuthService {
  static const String _keyCurrentUser = 'currentUser';

  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

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
      final snapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: 'admin@uni.com')
          .get();

      if (snapshot.docs.isEmpty) {
        // Create admin in Firebase Auth
        try {
          final userCredential = await _auth.createUserWithEmailAndPassword(
            email: 'admin@uni.com',
            password: 'admin123',
          );

          // Save admin to Firestore
          final adminUser = UserModel(
            id: userCredential.user!.uid,
            fullName: 'Admin',
            email: 'admin@uni.com',
            role: UserRole.admin,
            createdAt: DateTime.now(),
          );

          await _firestore
              .collection('users')
              .doc(userCredential.user!.uid)
              .set(adminUser.toJson());

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
  /// Note: This requires the admin's credentials to re-authenticate after creating user
  Future<AuthResult> registerUser({
    required String fullName,
    required String email,
    required String password,
    required UserRole role,
    String? adminEmail,
    String? adminPassword,
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
      print('Registering new user: $email');

      // Save current admin user before creating new user
      // ignore: unused_local_variable
      final currentAdmin = _auth.currentUser;

      // Create user in Firebase Auth (this will sign in as the new user)
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.toLowerCase(),
        password: password,
      );

      print('User created in Firebase Auth: ${userCredential.user?.uid}');

      // Create user model with department auto-detected from email
      final department = getDepartmentFromEmail(email);

      // Save to Firestore IMMEDIATELY after auth creation
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'id': userCredential.user!.uid,
        'fullName': fullName,
        'email': email.toLowerCase(),
        'role': role.name,
        'department': department.name,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('User saved to Firestore: ${userCredential.user!.uid}');

      final newUserId = userCredential.user!.uid;

      // Sign out the newly created user
      await _auth.signOut();

      // Re-authenticate admin if credentials provided
      if (adminEmail != null && adminPassword != null) {
        try {
          await _auth.signInWithEmailAndPassword(
            email: adminEmail,
            password: adminPassword,
          );
          print('Admin re-authenticated: $adminEmail');
        } catch (e) {
          print('Could not re-authenticate admin: $e');
        }
      }

      return AuthResult(
        success: true,
        userId: newUserId,
        role: role,
      );
    } on FirebaseAuthException catch (e) {
      print(
        'FirebaseAuthException during registration: ${e.code} - ${e.message}',
      );
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

  /// Create user directly in Firestore without Firebase Auth
  /// Used when admin wants to pre-register users
  Future<AuthResult> createUserInFirestore({
    required String fullName,
    required String email,
    required UserRole role,
  }) async {
    try {
      // Check if user already exists
      final existing = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.toLowerCase())
          .get();

      if (existing.docs.isNotEmpty) {
        return AuthResult(
          success: false,
          errorMessage: 'User with this email already exists',
        );
      }

      // Generate a unique ID
      final docRef = _firestore.collection('users').doc();
      final department = getDepartmentFromEmail(email);

      await docRef.set({
        'id': docRef.id,
        'fullName': fullName,
        'email': email.toLowerCase(),
        'role': role.name,
        'department': department.name,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('User created in Firestore: ${docRef.id}');

      // If staff role, also create a staff profile
      if (role == UserRole.staff) {
        await _firestore.collection('staffProfiles').add({
          'staffId': docRef.id,
          'userId': docRef.id,
          'fullName': fullName,
          'email': email.toLowerCase(),
          'employeeId': 'EMP_${docRef.id.substring(0, 8).toUpperCase()}',
          'departmentId': department.name,
          'departmentName': department.displayName,
          'designation': 'Staff',
          'assignedCourseIds': [],
          'joiningDate': DateTime.now().toIso8601String(),
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
        print('Staff profile created for: ${docRef.id}');
      }

      return AuthResult(
        success: true,
        userId: docRef.id,
        role: role,
      );
    } catch (e) {
      print('Error creating user in Firestore: $e');
      return AuthResult(
        success: false,
        errorMessage: 'Failed to create user: ${e.toString()}',
      );
    }
  }

  /// Get all registered users (for admin)
  Future<List<UserModel>> getAllUsers() async {
    try {
      final snapshot = await _firestore.collection('users').get();

      if (snapshot.docs.isEmpty) return [];

      return snapshot.docs.map((doc) {
        return UserModel.fromJson(doc.data());
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
      final snapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.toLowerCase())
          .get();

      if (snapshot.docs.isEmpty) {
        return AuthResult(success: false, errorMessage: 'User not found');
      }

      // Prevent deleting default admin
      if (email.toLowerCase() == 'admin@uni.com') {
        return AuthResult(
          success: false,
          errorMessage: 'Cannot delete default admin',
        );
      }

      // Get user ID and delete from database
      final userId = snapshot.docs.first.id;

      await _firestore.collection('users').doc(userId).delete();

      // Note: We can't delete from Firebase Auth without admin SDK
      // The user will still exist in Auth but not in database

      return AuthResult(success: true);
    } catch (e) {
      return AuthResult(
        success: false,
        errorMessage: 'Failed to delete user: ${e.toString()}',
      );
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

      // Get user data from Firestore
      final snapshot = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      print('Database snapshot exists: ${snapshot.exists}');

      UserModel user;

      // If user doesn't exist in Firestore, create document from Auth data
      if (!snapshot.exists) {
        // Determine role from email pattern
        UserRole role = UserRole.student; // default
        final emailLower = email.toLowerCase();
        if (emailLower.contains('admin')) {
          role = UserRole.admin;
        } else if (emailLower.contains('staff') ||
            emailLower.contains('prof') ||
            emailLower.contains('teacher')) {
          role = UserRole.staff;
        }

        // Create user document in Firestore
        final department = getDepartmentFromEmail(email);
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'id': userCredential.user!.uid,
          'fullName':
              userCredential.user!.displayName ?? email.split('@').first,
          'email': email.toLowerCase(),
          'role': role.name,
          'department': department.name,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Read back the created document
        final newSnapshot = await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();
        user = UserModel.fromJson(newSnapshot.data()!);
        print('Created new Firestore document for: $email');
      } else {
        // READ user data from Firestore
        final userData = snapshot.data()!;
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

  // Google Sign-In instance
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    // Required for Web - Get this from Google Cloud Console > APIs & Credentials > OAuth 2.0 Client IDs > Web client
    clientId: kIsWeb 
        ? '524881463867-hup5jtubm5a90fcam4viqktq7ua34tta.apps.googleusercontent.com'
        : null,
  );

  /// Logout user
  Future<void> logout() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      // Ignore Google sign out errors
    }
    await _auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyCurrentUser);
  }

  /// Sign in with Google
  Future<AuthResult> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        return await _signInWithGoogleWeb();
      }
      print('========================================');
      print('Starting Google Sign-In...');
      print('Platform: ${kIsWeb ? "Web" : "Mobile"}');
      print('========================================');

      GoogleSignInAccount? googleUser;
      
      try {
        // Try silent sign in first (for returning users)
        print('Attempting silent sign-in...');
        googleUser = await _googleSignIn.signInSilently();
        print('Silent sign-in result: ${googleUser?.email ?? "null"}');
      } catch (e) {
        print('Silent sign-in failed: $e');
      }

      // If silent sign-in didn't work, show the sign-in dialog
      if (googleUser == null) {
        print('Calling interactive signIn()...');
        try {
          googleUser = await _googleSignIn.signIn();
          print('Interactive sign-in completed: ${googleUser?.email ?? "null"}');
        } catch (e) {
          print('Interactive sign-in error: $e');
          return AuthResult(
            success: false,
            errorMessage: 'Google sign-in error: ${e.toString()}',
          );
        }
      }

      if (googleUser == null) {
        print('Google user is null - sign-in was cancelled');
        return AuthResult(
          success: false,
          errorMessage: 'Google sign-in was cancelled',
        );
      }

      print('Google user obtained: ${googleUser.email}');

      // Get auth details from Google
      print('Getting authentication tokens...');
      final googleAuth = await googleUser.authentication;
      print('Got tokens - accessToken: ${googleAuth.accessToken != null}, idToken: ${googleAuth.idToken != null}');

      if (googleAuth.idToken == null) {
        return AuthResult(
          success: false,
          errorMessage: 'Failed to get Google ID token. Please try again.',
        );
      }

      // Create Firebase credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with Google credential
      print('Signing in to Firebase...');
      final userCredential = await _auth.signInWithCredential(credential);

      return await _completeGoogleSignIn(userCredential);
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth error: ${e.code} - ${e.message}');
      return AuthResult(
        success: false,
        errorMessage: 'Firebase error: ${e.message}',
      );
    } catch (e, stackTrace) {
      print('Google Sign-In error: $e');
      print('Stack trace: $stackTrace');
      return AuthResult(
        success: false,
        errorMessage: 'Google sign-in failed: ${e.toString()}',
      );
    }
  }

  Future<AuthResult> _signInWithGoogleWeb() async {
    try {
      print('========================================');
      print('Starting Google Sign-In (Web)...');
      print('========================================');

      final provider = GoogleAuthProvider();
      provider.addScope('email');
      provider.addScope('profile');
      provider.addScope('openid');

      final userCredential = await _auth.signInWithPopup(provider);
      return await _completeGoogleSignIn(userCredential);
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth error (Web): ${e.code} - ${e.message}');
      return AuthResult(
        success: false,
        errorMessage: 'Firebase error: ${e.message}',
      );
    } catch (e, stackTrace) {
      print('Google Sign-In Web error: $e');
      print('Stack trace: $stackTrace');
      return AuthResult(
        success: false,
        errorMessage: 'Google sign-in failed: ${e.toString()}',
      );
    }
  }

  Future<AuthResult> _completeGoogleSignIn(UserCredential userCredential) async {
    print('Firebase Auth success: ${userCredential.user?.uid}');

    final email = userCredential.user!.email ?? '';
    final displayName = userCredential.user!.displayName ?? email.split('@').first;

    // First check if user exists by UID
    var snapshot = await _firestore
        .collection('users')
        .doc(userCredential.user!.uid)
        .get();

    UserModel user;

    if (!snapshot.exists) {
      // Check if admin already created a user with this email
      final emailQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.toLowerCase())
          .limit(1)
          .get();

      if (emailQuery.docs.isNotEmpty) {
        // User was pre-registered by admin with this email
        // Update the document ID to match Firebase Auth UID
        final existingData = emailQuery.docs.first.data();
        final oldDocId = emailQuery.docs.first.id;

        // Create new document with correct UID
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          ...existingData,
          'id': userCredential.user!.uid,
          'fullName': existingData['fullName'] ?? displayName,
        });

        // Delete old document with wrong ID
        await _firestore.collection('users').doc(oldDocId).delete();

        print('Migrated pre-registered user to Google UID: $email');

        // Read the updated document
        final newSnapshot = await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();
        user = UserModel.fromJson(newSnapshot.data()!);
      } else {
        // Completely new user - create in Firestore
        // Determine role from email pattern
        UserRole role = UserRole.student; // default for Google users
        final emailLower = email.toLowerCase();
        if (emailLower.contains('admin')) {
          role = UserRole.admin;
        } else if (emailLower.contains('staff') ||
            emailLower.contains('prof') ||
            emailLower.contains('teacher')) {
          role = UserRole.staff;
        }

        final department = getDepartmentFromEmail(email);

        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'id': userCredential.user!.uid,
          'fullName': displayName,
          'email': email.toLowerCase(),
          'role': role.name,
          'department': department.name,
          'createdAt': FieldValue.serverTimestamp(),
        });

        final newSnapshot = await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();
        user = UserModel.fromJson(newSnapshot.data()!);
        print('Created new user from Google: $email');
      }
    } else {
      user = UserModel.fromJson(snapshot.data()!);
    }

    // Save session locally
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCurrentUser, user.id);

    print('Google login successful for role: ${user.role}');
    return AuthResult(success: true, userId: user.id, role: user.role);
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
      final snapshot = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      if (!snapshot.exists) return null;

      final userData = snapshot.data()!;
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
