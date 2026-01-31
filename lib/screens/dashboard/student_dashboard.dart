import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../widgets/floating_icons_background.dart';
import '../login/login_screen.dart';
import '../notices/student_notice_list_screen.dart';
import '../timetable/student_timetable_screen.dart';
import '../results/student_results_screen.dart';
import '../courses/student_courses_screen.dart';
import '../attendance/student_attendance_screen.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final _authService = AuthService();
  UserModel? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = await _authService.getCurrentUser();
    if (mounted) {
      setState(() {
        _currentUser = user;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF3182CE)),
        ),
        title: const Text('Logout', style: TextStyle(color: Color(0xFF2D3748))),
        content: const Text('Are you sure you want to logout?', style: TextStyle(color: Color(0xFF4A5568))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3182CE)),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.logout();
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      }
    }
  }

  void _showFeatureMessage(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature - Coming soon!'),
        backgroundColor: const Color(0xFF3182CE),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFE8EDF5),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF3182CE))),
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
        child: SingleChildScrollView(
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
                          Text('Welcome, ${_currentUser?.fullName ?? 'Student'}!', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
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
              ),
              const SizedBox(height: 24),

              // Quick Actions
              const Text('Quick Actions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2D3748))),
              const SizedBox(height: 12),
              
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.2,
                children: [
                  _actionCard('Notices', Icons.notifications, const Color(0xFFE53E3E), () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => StudentNoticeListScreen(
                        departmentId: _currentUser?.department.name,
                        departmentName: _currentUser?.department.displayName,
                      ),
                    ));
                  }),
                  _actionCard('Timetable', Icons.calendar_today, const Color(0xFF38A169), () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => StudentTimetableScreen(
                        departmentId: _currentUser?.department.name,
                      ),
                    ));
                  }),
                  _actionCard('Results', Icons.assessment, const Color(0xFFD69E2E), () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => StudentResultsScreen(
                        studentId: _currentUser?.id,
                      ),
                    ));
                  }),
                  _actionCard('Courses', Icons.menu_book, const Color(0xFF805AD5), () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => StudentCoursesScreen(
                        departmentId: _currentUser?.department.name,
                      ),
                    ));
                  }),
                  _actionCard('Attendance', Icons.fact_check, const Color(0xFF3182CE), () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => StudentAttendanceScreen(
                        studentId: _currentUser?.id,
                        studentName: _currentUser?.fullName,
                      ),
                    ));
                  }),
                ],
              ),
              const SizedBox(height: 24),

              // Department Info Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Your Department', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2D3748))),
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
              ),
            ],
          ),
        ),
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
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(color: Color(0xFF2D3748), fontWeight: FontWeight.w600, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
