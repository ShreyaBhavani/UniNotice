import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/student_model.dart';
import '../../models/timetable_model.dart';
import '../../widgets/floating_icons_background.dart';
import '../../widgets/animated_widgets.dart';
import '../login/login_screen.dart';
import '../notices/student_notice_list_screen.dart';
import '../timetable/student_timetable_screen.dart';
import '../results/student_results_screen.dart';
import '../courses/student_courses_screen.dart';
import '../attendance/student_attendance_screen.dart';
import '../../services/notification_service.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> with TickerProviderStateMixin {
  final _authService = AuthService();
  final _dbService = DatabaseService();
  UserModel? _currentUser;
  StudentProfile? _studentProfile;
  bool _isLoading = true;
  int _todayClasses = 0;
  
  // Animation controllers
  late AnimationController _welcomeController;
  late AnimationController _cardsController;
  late Animation<double> _welcomeFade;
  late Animation<Offset> _welcomeSlide;
  late List<Animation<double>> _cardAnimations;

  /// Compute current semester dynamically from batch rules.
  ///
  /// Rules (for year suffixes, e.g. 22, 23, 24, 25 when current year is 2026):
  /// - Normal batch (e.g. "22", "23") uses that number directly.
  /// - Diploma-to-degree batch (e.g. "D23", "D24") maps to previous year
  ///   so that 22 and D23 are both treated as 8th sem in 2026.
  ///
  /// We first try rollNumber; if not available, we fall back to the email
  /// local-part (e.g. "23IT009" from 23IT009@chausat.edu.in).
  /// The result is clamped between 1 and 8. If parsing fails, we fall back
  /// to the stored currentSemester or 1 so existing behavior is preserved.
  int _computeCurrentSemester(StudentProfile? profile) {
    // Prefer rollNumber if present, else fall back to email local-part.
    String? source;
    if (profile != null && profile.rollNumber.trim().isNotEmpty) {
      source = profile.rollNumber.trim();
    } else if (_currentUser?.email != null && _currentUser!.email.isNotEmpty) {
      source = _currentUser!.email.split('@').first.trim();
    }

    int? computedSem;

    if (source != null && source.isNotEmpty) {
      // Extract a batch code like "22" or "D23" from the start.
      final regex = RegExp(r'^(D?)(\d{2})');
      final match = regex.firstMatch(source);

      if (match != null) {
        final isDiploma = match.group(1) == 'D';
        final yearSuffixStr = match.group(2);
        final yearSuffix = int.tryParse(yearSuffixStr ?? '');

        if (yearSuffix != null) {
          // Map diploma batches to previous year (D23 -> baseYear 22, etc.)
          final baseYear = isDiploma ? (yearSuffix - 1) : yearSuffix;

          // Use last two digits of current year (e.g. 2026 -> 26)
          final now = DateTime.now();
          final currentYearSuffix = now.year % 100;

          final rawSem = 2 * (currentYearSuffix - baseYear);
          if (rawSem > 0) {
            // Clamp between 1 and 8
            computedSem = rawSem.clamp(1, 8);
          }
        }
      }
    }

    if (computedSem != null) {
      return computedSem;
    }

    if (profile != null) {
      return profile.currentSemester;
    }

    return 1;
  }

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadUserData();
  }

  void _setupAnimations() {
    // Welcome card animation
    _welcomeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _welcomeFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _welcomeController, curve: Curves.easeOut),
    );
    _welcomeSlide = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _welcomeController, curve: Curves.elasticOut));

    // Cards stagger animation
    _cardsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    _cardAnimations = List.generate(5, (index) {
      final start = index * 0.15;
      final end = start + 0.4;
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _cardsController,
          curve: Interval(start, end.clamp(0.0, 1.0), curve: Curves.elasticOut),
        ),
      );
    });
  }

  @override
  void dispose() {
    _welcomeController.dispose();
    _cardsController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = await _authService.getCurrentUser();
    StudentProfile? studentProfile;

    // If logged-in user is a student, load their profile to get current semester
    if (user != null && user.isStudent) {
      studentProfile = await _dbService.getStudentProfile(user.id);
    }

    if (mounted) {
      setState(() {
        _currentUser = user;
        _studentProfile = studentProfile;
        _isLoading = false;
      });
      // Load today's classes summary after basic data is ready
      _loadTodayClasses();
      // Start animations after data loads
      _welcomeController.forward();
      Future.delayed(const Duration(milliseconds: 300), () {
        _cardsController.forward();
      });

      // Schedule a daily reminder for students to check timetable/attendance
      if (user != null && user.isStudent) {
        await NotificationService().scheduleDailyTimetableReminder();
      }
    }
  }

  Future<void> _loadTodayClasses() async {
    final user = _currentUser;
    if (user == null || !user.isStudent) return;

    try {
      final deptId = user.department.name;
      final sem = _computeCurrentSemester(_studentProfile);

      final entries = await _dbService.getTimetableForStudent(
        departmentId: deptId,
        semester: sem,
      );

      // Map DateTime weekday (1=Mon..7=Sun) to DayOfWeek enum
      final weekday = DateTime.now().weekday;
      DayOfWeek? todayEnum;
      switch (weekday) {
        case DateTime.monday:
          todayEnum = DayOfWeek.monday;
          break;
        case DateTime.tuesday:
          todayEnum = DayOfWeek.tuesday;
          break;
        case DateTime.wednesday:
          todayEnum = DayOfWeek.wednesday;
          break;
        case DateTime.thursday:
          todayEnum = DayOfWeek.thursday;
          break;
        case DateTime.friday:
          todayEnum = DayOfWeek.friday;
          break;
        case DateTime.saturday:
          todayEnum = DayOfWeek.saturday;
          break;
        case DateTime.sunday:
          todayEnum = DayOfWeek.sunday;
          break;
      }

      if (todayEnum == null) return;

      final todayCount = entries.where((e) => e.day == todayEnum).length;

      if (!mounted) return;
      setState(() {
        _todayClasses = todayCount;
      });
    } catch (_) {
      // Ignore errors for summary; main functionality remains unaffected
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.logout, color: const Color(0xFF3182CE)),
            const SizedBox(width: 12),
            const Text('Logout', style: TextStyle(color: Color(0xFF2D3748))),
          ],
        ),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: Color(0xFF4A5568)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3182CE),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.logout();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context, 
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false, // Remove all previous routes
        );
      }
    }
  }

  void _showFeatureMessage(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature - Coming soon!'),
        backgroundColor: const Color(0xFF3182CE),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFE8EDF5),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const BouncingDotsLoader(
                color: Color(0xFF3182CE),
                dotSize: 14,
              ),
              const SizedBox(height: 16),
              Text(
                'Loading...',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFE8EDF5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        title: const Text('Student Portal', style: TextStyle(color: Color(0xFF2D3748), fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Color(0xFF3182CE)),
            onPressed: () => _showFeatureMessage('Notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF3182CE)),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: FloatingIconsBackground(
        child: RefreshIndicator(
          onRefresh: _loadUserData,
          color: const Color(0xFF3182CE),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Animated Welcome Card
                SlideTransition(
                  position: _welcomeSlide,
                  child: FadeTransition(
                    opacity: _welcomeFade,
                    child: _buildWelcomeCard(),
                  ),
                ),
                const SizedBox(height: 16),

                // Today's classes summary
                _buildTodaySummaryCard(),

                const SizedBox(height: 24),

                // Quick Actions with stagger animation
                FadeTransition(
                  opacity: _welcomeFade,
                  child: const Text(
                    'Quick Actions', 
                    style: TextStyle(
                      fontSize: 20, 
                      fontWeight: FontWeight.bold, 
                      color: Color(0xFF2D3748),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                _buildAnimatedGrid(),
                const SizedBox(height: 24),

                // Department Info Section with animation
                AnimatedBuilder(
                  animation: _cardAnimations.last,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _cardAnimations.last.value,
                      child: Opacity(
                        opacity: _cardAnimations.last.value.clamp(0.0, 1.0),
                        child: _buildDepartmentInfo(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF3182CE), const Color(0xFF3182CE).withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: const Color(0xFF3182CE).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: Text(
              _currentUser?.fullName.isNotEmpty == true ? _currentUser!.fullName[0].toUpperCase() : 'S',
              style: const TextStyle(color: Color(0xFF3182CE), fontSize: 28, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, ${_currentUser?.fullName ?? 'Student'}!',
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                      child: const Text('Student', style: TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), borderRadius: BorderRadius.circular(12)),
                      child: Text(
                        _currentUser?.department.shortName ?? 'N/A',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedGrid() {
    final actions = [
      {'title': 'Notices', 'icon': Icons.notifications, 'color': const Color(0xFFE53E3E), 'index': 0},
      {'title': 'Timetable', 'icon': Icons.calendar_today, 'color': const Color(0xFF38A169), 'index': 1},
      {'title': 'Results', 'icon': Icons.assessment, 'color': const Color(0xFFD69E2E), 'index': 2},
      {'title': 'Courses', 'icon': Icons.menu_book, 'color': const Color(0xFF805AD5), 'index': 3},
      {'title': 'Attendance', 'icon': Icons.fact_check, 'color': const Color(0xFF3182CE), 'index': 4},
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: actions.map((action) {
        final index = action['index'] as int;
        return AnimatedBuilder(
          animation: _cardAnimations[index],
          builder: (context, child) {
            return Transform.scale(
              scale: _cardAnimations[index].value,
              child: Opacity(
                opacity: _cardAnimations[index].value.clamp(0.0, 1.0),
                child: _actionCard(
                  action['title'] as String,
                  action['icon'] as IconData,
                  action['color'] as Color,
                  () => _handleCardTap(action['title'] as String),
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }

  Widget _buildTodaySummaryCard() {
    // Only relevant for students
    if (!(_currentUser?.isStudent ?? false)) {
      return const SizedBox.shrink();
    }

    final label = _todayClasses == 1 ? 'class today' : 'classes today';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF38A169).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.today, color: Color(0xFF38A169)),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Today's Classes",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$_todayClasses $label',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleCardTap(String title) {
    Widget? screen;
    // Compute semester dynamically for timetable/courses based on rollNumber rules.
    final effectiveSemester = _computeCurrentSemester(_studentProfile);
    switch (title) {
      case 'Notices':
        screen = StudentNoticeListScreen(
          departmentId: _currentUser?.department.name,
          departmentName: _currentUser?.department.displayName,
        );
        break;
      case 'Timetable':
        screen = StudentTimetableScreen(
          departmentId: _currentUser?.department.name,
          semester: effectiveSemester,
        );
        break;
      case 'Results':
        screen = StudentResultsScreen(
          studentId: _currentUser?.id,
        );
        break;
      case 'Courses':
        screen = StudentCoursesScreen(
          departmentId: _currentUser?.department.name,
          semester: effectiveSemester,
        );
        break;
      case 'Attendance':
        screen = StudentAttendanceScreen(
          // Use the student profile's ID so attendance
          // records (which store studentId) match correctly.
          studentId: _studentProfile?.studentId ?? _currentUser?.id,
          studentName: _currentUser?.fullName,
        );
        break;
    }
    if (screen != null) {
      Navigator.push(context, SlidePageRoute(page: screen));
    }
  }

  Widget _buildDepartmentInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Department',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.school, color: Color(0xFF3182CE)),
              const SizedBox(width: 8),
              Text(
                _currentUser?.department.displayName ?? 'Not Assigned',
                style: const TextStyle(color: Color(0xFF4A5568), fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'All notices, results, and attendance will be shown based on your department.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _actionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF2D3748),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
