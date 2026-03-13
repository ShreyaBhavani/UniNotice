import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/student_model.dart';
import '../../widgets/floating_icons_background.dart';
import '../login/login_screen.dart';
import '../notices/staff_notice_list_screen.dart';
import '../attendance/staff_attendance_list_screen.dart';
import '../grades/staff_grades_screen.dart';
import '../timetable/admin_timetable_screen.dart';
import '../courses/student_courses_screen.dart';
import '../results/student_results_screen.dart';
import 'assign_courses_dialog.dart';
import 'course_management_screen.dart';
import 'staff_management_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final _authService = AuthService();
  final _dbService = DatabaseService();
  UserModel? _currentUser;
  List<UserModel> _allUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = await _authService.getCurrentUser();
    final users = await _authService.getAllUsers();
    if (mounted) {
      setState(() {
        _currentUser = user;
        _allUsers = users;
        _isLoading = false;
      });
    }

    // Ensure staff and student profiles exist for all admin-created users.
    // This runs idempotently on each load so the admin doesn't need to
    // press any extra buttons, keeping behavior professional.
    _autoMigrateProfiles();
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF0088CC)),
        ),
        title: const Text('Logout', style: TextStyle(color: Color(0xFF2D3748))),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: Color(0xFF4A5568)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0088CC),
            ),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.logout();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }

  /// Infer current semester from university batch rules using email pattern.
  ///
  /// Rules based on local-part (before @), for example:
  /// - 22.. and D23.. => 8th sem
  /// - 23.. and D24.. => 6th sem
  /// - 24.. and D25.. => 4th sem
  /// Implementation is dynamic based on the current year so it keeps working
  /// as time passes. If parsing fails it falls back to 1.
  int _inferSemesterFromEmail(String email) {
    final localPart = email.split('@').first.trim().toUpperCase();

    int? computedSem;

    if (localPart.isNotEmpty) {
      final regex = RegExp(r'^(D?)(\d{2})');
      final match = regex.firstMatch(localPart);

      if (match != null) {
        final isDiploma = match.group(1) == 'D';
        final yearSuffixStr = match.group(2);
        final yearSuffix = int.tryParse(yearSuffixStr ?? '');

        if (yearSuffix != null) {
          final baseYear = isDiploma ? (yearSuffix - 1) : yearSuffix;
          final now = DateTime.now();
          final currentYearSuffix = now.year % 100;
          final rawSem = 2 * (currentYearSuffix - baseYear);
          if (rawSem > 0) {
            computedSem = rawSem.clamp(1, 8).toInt();
          }
        }
      }
    }

    return computedSem ?? 1;
  }

  void _showAddUserDialog() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final adminPasswordController = TextEditingController();
    UserRole selectedRole = UserRole.student;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.person_add, color: Color(0xFF0088CC)),
              SizedBox(width: 8),
              Text('Add New User', style: TextStyle(color: Color(0xFF2D3748))),
            ],
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: _inputDecoration('Full Name', Icons.person),
                    validator: (v) => v == null || v.trim().length < 2
                        ? 'Enter valid name'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailController,
                    decoration: _inputDecoration('Email', Icons.email),
                    validator: (v) => v == null || !v.contains('@')
                        ? 'Enter valid email'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: _inputDecoration('Initial Password (set by admin)', Icons.lock),
                    validator: _authService.validatePassword,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: confirmPasswordController,
                    obscureText: true,
                    decoration: _inputDecoration('Confirm Password', Icons.lock_outline),
                    validator: (value) => _authService.validateConfirmPassword(
                      passwordController.text,
                      value,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Admin sets the initial password and shares it with the user.',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: adminPasswordController,
                    obscureText: true,
                    decoration: _inputDecoration('Your admin password (to confirm)', Icons.verified_user),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Enter your admin password to create accounts';
                      }
                      return null;
                    },
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<UserRole>(
                        value: selectedRole,
                        isExpanded: true,
                        items: [
                          DropdownMenuItem(
                            value: UserRole.student,
                            child: _roleItem(UserRole.student),
                          ),
                          DropdownMenuItem(
                            value: UserRole.staff,
                            child: _roleItem(UserRole.staff),
                          ),
                          DropdownMenuItem(
                            value: UserRole.admin,
                            child: _roleItem(UserRole.admin),
                          ),
                        ],
                        onChanged: (role) {
                          if (role != null) {
                            setDialogState(() => selectedRole = role);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final result = await _authService.registerUser(
                    fullName: nameController.text.trim(),
                    email: emailController.text.trim(),
                    password: passwordController.text.trim(),
                    role: selectedRole,
                    // Optional: keep admin logged in by re-authenticating
                    adminEmail: _currentUser?.email,
                    adminPassword: adminPasswordController.text.trim(),
                  );
                  if (mounted) {
                    Navigator.pop(context);
                    if (result.success) {
                      _loadData();
                      _showSnackBar('User created successfully!', Colors.green);

                      // Automatically create a student profile when admin
                      // adds a new student user so other modules (timetable,
                      // attendance, results) can rely on consistent data.
                      if (selectedRole == UserRole.student && result.userId != null) {
                        final email = emailController.text.trim().toLowerCase();
                        final fullName = nameController.text.trim();
                        final department = getDepartmentFromEmail(email);

                        final profile = StudentProfile(
                          studentId: result.userId!,
                          userId: result.userId!,
                          fullName: fullName,
                          email: email,
                          // Use local-part as roll number for now
                          rollNumber: email.split('@').first.toUpperCase(),
                          departmentId: department.name,
                          departmentName: department.displayName,
                          currentSemester: _inferSemesterFromEmail(email),
                          enrolledCourseIds: const [],
                          enrollmentDate: DateTime.now(),
                        );

                        await _dbService.createStudentProfile(profile);
                      }
                      
                      // If staff was created, show course assignment dialog
                      if (selectedRole == UserRole.staff) {
                        Future.delayed(const Duration(milliseconds: 300), () {
                          if (mounted) {
                            _showStaffCourseAssignment(
                              result.userId ?? '',
                              nameController.text.trim(),
                            );
                          }
                        });
                      }
                    } else {
                      _showSnackBar(
                        result.errorMessage ?? 'Failed',
                        Colors.red,
                      );
                    }
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0088CC),
              ),
              child: const Text(
                'Add User',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUserDetails(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: _getRoleColor(user.role),
              child: Text(
                user.fullName[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.fullName,
                    style: const TextStyle(
                      color: Color(0xFF2D3748),
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    _getRoleLabel(user.role),
                    style: TextStyle(
                      color: _getRoleColor(user.role),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow(Icons.email, 'Email', user.email),
            const SizedBox(height: 8),
            _detailRow(
              Icons.business,
              'Department',
              user.department.displayName,
            ),
            const SizedBox(height: 8),
            _detailRow(
              Icons.calendar_today,
              'Created',
              '${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}',
            ),
            const SizedBox(height: 8),
            _detailRow(Icons.badge, 'Role', _getRoleLabel(user.role)),
          ],
        ),
        actions: [
          if (user.email != 'admin@uni.com')
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete User?'),
                    content: Text('Delete ${user.fullName}?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text(
                          'Delete',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await _authService.deleteUser(user.email);
                  _loadData();
                  _showSnackBar('User deleted', Colors.orange);
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0088CC),
            ),
            child: const Text('Close', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF0088CC)),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            color: Color(0xFF4A5568),
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(color: Color(0xFF2D3748))),
        ),
      ],
    );
  }

  Widget _roleItem(UserRole role) {
    return Row(
      children: [
        Icon(_getRoleIcon(role), color: _getRoleColor(role), size: 20),
        const SizedBox(width: 8),
        Text(
          _getRoleLabel(role),
          style: const TextStyle(color: Color(0xFF2D3748)),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF0088CC)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF0088CC), width: 2),
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _showStaffCourseAssignment(String userId, String fullName) async {
    try {
      // Get the staff profile
      final dbService = DatabaseService();
      final staffProfile = await dbService.getStaffProfile(userId);
      
      if (staffProfile != null && mounted) {
        showDialog(
          context: context,
          builder: (context) => AssignCoursesDialog(
            staff: staffProfile,
            onSuccess: () {
              _loadData();
            },
          ),
        );
      }
    } catch (e) {
      print('Error loading staff profile: $e');
    }
  }

  Future<void> _migrateExistingStaff() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Migrate Staff Profiles?'),
        content: const Text(
          'This will create staff profiles for all existing staff users who don\'t have one yet.\n\nContinue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0088CC),
            ),
            child: const Text('Migrate', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final dbService = DatabaseService();
        await dbService.createStaffProfilesForExistingStaff();
        if (mounted) {
          _loadData();
          _showSnackBar('Staff profiles migrated successfully!', Colors.green);
        }
      } catch (e) {
        if (mounted) {
          _showSnackBar('Migration failed: ${e.toString()}', Colors.red);
        }
      }
    }
  }

  Future<void> _autoMigrateProfiles() async {
    try {
      await _dbService.createStaffProfilesForExistingStaff();
      await _dbService.createStudentProfilesForExistingStudents();
    } catch (e) {
      // Log only; avoid disturbing admin UX with migration details
      // in normal usage.
      // ignore: avoid_print
      print('Auto-migration of profiles failed: $e');
    }
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return const Color(0xFFE53E3E);
      case UserRole.staff:
        return const Color(0xFF38A169);
      case UserRole.student:
        return const Color(0xFF3182CE);
    }
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Icons.admin_panel_settings;
      case UserRole.staff:
        return Icons.work;
      case UserRole.student:
        return Icons.school;
    }
  }

  String _getRoleLabel(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Administrator';
      case UserRole.staff:
        return 'Staff';
      case UserRole.student:
        return 'Student';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFE8EDF5),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF0088CC)),
        ),
      );
    }

    final students = _allUsers
        .where((u) => u.role == UserRole.student)
        .toList();
    final staff = _allUsers.where((u) => u.role == UserRole.staff).toList();
    final admins = _allUsers.where((u) => u.role == UserRole.admin).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFE8EDF5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(
            color: Color(0xFF2D3748),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF0088CC)),
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF0088CC)),
            onPressed: _handleLogout,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddUserDialog,
        backgroundColor: const Color(0xFF0088CC),
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('Add User', style: TextStyle(color: Colors.white)),
      ),
      body: FloatingIconsBackground(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF0088CC),
                        const Color(0xFF0088CC).withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0088CC).withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.admin_panel_settings,
                          size: 35,
                          color: const Color(0xFF0088CC),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome, ${_currentUser?.fullName ?? 'Admin'}!',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Administrator Panel',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Stats Cards
                Row(
                  children: [
                    Expanded(
                      child: _statsCard(
                        'Students',
                        students.length,
                        Icons.school,
                        const Color(0xFF3182CE),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _statsCard(
                        'Staff',
                        staff.length,
                        Icons.work,
                        const Color(0xFF38A169),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _statsCard(
                        'Admins',
                        admins.length,
                        Icons.admin_panel_settings,
                        const Color(0xFFE53E3E),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Admin Quick Actions
                const Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
                const SizedBox(height: 12),

                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.0,
                  children: [
                    _actionCard(
                      'Notices',
                      Icons.campaign,
                      const Color(0xFFE53E3E),
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const StaffNoticeListScreen(),
                          ),
                        );
                      },
                    ),
                    _actionCard(
                      'Attendance',
                      Icons.fact_check,
                      const Color(0xFF3182CE),
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const StaffAttendanceListScreen(),
                          ),
                        );
                      },
                    ),
                    _actionCard(
                      'Grades',
                      Icons.grade,
                      const Color(0xFFD69E2E),
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const StaffGradesScreen(),
                          ),
                        );
                      },
                    ),
                    _actionCard(
                      'Schedule',
                      Icons.schedule,
                      const Color(0xFF805AD5),
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminTimetableScreen(),
                          ),
                        );
                      },
                    ),
                    _actionCard(
                      'Courses',
                      Icons.menu_book,
                      const Color(0xFF38A169),
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CourseManagementScreen(),
                          ),
                        );
                      },
                    ),
                    _actionCard(
                      'Manage Staff',
                      Icons.people,
                      const Color(0xFF805AD5),
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const StaffManagementScreen(),
                          ),
                        );
                      },
                    ),
                    _actionCard(
                      'Results',
                      Icons.assessment,
                      const Color(0xFFDD6B20),
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const StudentResultsScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Users List
                const Text(
                  'All Users',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
                const SizedBox(height: 12),

                if (_allUsers.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 48,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'No users yet',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ..._allUsers.map((user) => _userCard(user)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statsCard(String title, int count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(color: Color(0xFF4A5568), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _userCard(UserModel user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: () => _showUserDetails(user),
        leading: CircleAvatar(
          backgroundColor: _getRoleColor(user.role).withOpacity(0.1),
          child: Icon(_getRoleIcon(user.role), color: _getRoleColor(user.role)),
        ),
        title: Text(
          user.fullName,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D3748),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user.email,
              style: const TextStyle(color: Color(0xFF4A5568), fontSize: 12),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getDepartmentColor(
                      user.department,
                    ).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    user.department.shortName,
                    style: TextStyle(
                      color: _getDepartmentColor(user.department),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        isThreeLine: true,
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _getRoleColor(user.role).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _getRoleLabel(user.role),
            style: TextStyle(
              color: _getRoleColor(user.role),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Color _getDepartmentColor(Department dept) {
    switch (dept) {
      case Department.it:
        return const Color(0xFF3182CE);
      case Department.cs:
        return const Color(0xFF38A169);
      case Department.ce:
        return const Color(0xFFD69E2E);
      case Department.aiml:
        return const Color(0xFF805AD5);
      case Department.unknown:
        return Colors.grey;
    }
  }

  Widget _actionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF2D3748),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
