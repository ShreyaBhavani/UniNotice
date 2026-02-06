import 'package:flutter/material.dart';
import '../../models/course_model.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../dashboard/add_course_dialog.dart';

/// Student Courses Screen - READ Operation
class StudentCoursesScreen extends StatefulWidget {
  final String? departmentId;
  final int? semester;

  const StudentCoursesScreen({super.key, this.departmentId, this.semester});

  @override
  State<StudentCoursesScreen> createState() => _StudentCoursesScreenState();
}

class _StudentCoursesScreenState extends State<StudentCoursesScreen> {
  final _dbService = DatabaseService();
  final _authService = AuthService();
  List<CourseModel> _courses = [];
  bool _isLoading = true;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _checkAdminStatus();
    await _loadCourses();
  }

  Future<void> _checkAdminStatus() async {
    final user = await _authService.getCurrentUser();
    setState(() {
      _isAdmin = user?.role == UserRole.admin;
    });
  }

  Future<void> _loadCourses() async {
    setState(() => _isLoading = true);
    try {
      List<CourseModel> courses;
      
      // For admin: show all courses
      if (_isAdmin) {
        courses = await _dbService.getAllCourses();
      } else {
        // For students: show courses filtered by department and semester
        final deptId = widget.departmentId ?? '';
        final sem = widget.semester ?? 1;
        courses = await _dbService.getCoursesForStudent(
          departmentId: deptId,
          semester: sem,
        );
      }

      setState(() {
        _courses = courses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate total credits
    int totalCredits = _courses.fold(0, (sum, c) => sum + c.credits);

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context);
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFE8EDF5),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 2,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF3182CE)),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            _isAdmin ? 'Manage Courses' : 'My Courses',
            style: const TextStyle(
              color: Color(0xFF2D3748),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF3182CE)),
              )
            : RefreshIndicator(
                onRefresh: _loadCourses,
                child: _courses.isEmpty
                    ? _buildEmptyState()
                    : _buildCoursesList(totalCredits),
              ),
        floatingActionButton: _isAdmin
            ? FloatingActionButton(
                backgroundColor: const Color(0xFF0088CC),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AddCourseDialog(
                    onSuccess: _loadCourses,
                  ),
                );
              },
              tooltip: 'Add Course',
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.menu_book, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            _isAdmin ? 'No courses created yet' : 'No courses available',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
          if (_isAdmin) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AddCourseDialog(
                    onSuccess: _loadCourses,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0088CC),
              ),
              icon: const Icon(Icons.add),
              label: const Text(
                'Create First Course',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCoursesList(int totalCredits) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary Card
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF805AD5),
                  const Color(0xFF805AD5).withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Semester',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      Text(
                        '${widget.semester}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 50, color: Colors.white30),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Courses',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      Text(
                        '${_courses.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 50, color: Colors.white30),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Credits',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      Text(
                        '$totalCredits',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        const Text(
          'Enrolled Courses',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 12),

        ..._courses.asMap().entries.map(
          (entry) => _buildCourseCard(entry.value, entry.key),
        ),
      ],
    );
  }

  Widget _buildCourseCard(CourseModel course, int index) {
    final colors = [
      const Color(0xFF3182CE),
      const Color(0xFF38A169),
      const Color(0xFFD69E2E),
      const Color(0xFF805AD5),
      const Color(0xFFE53E3E),
    ];
    final color = colors[index % colors.length];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showCourseDetails(course, color),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    course.courseName[0].toUpperCase(),
                    style: TextStyle(
                      color: color,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.courseName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            course.courseCode,
                            style: TextStyle(
                              color: color,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${course.credits} Credits',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.person,
                          size: 14,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          course.staffName,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  void _showCourseDetails(CourseModel course, Color color) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      course.courseName[0].toUpperCase(),
                      style: TextStyle(
                        color: color,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.courseName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                      Text(
                        course.courseCode,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            _detailRow(Icons.school, 'Credits', '${course.credits}'),
            _detailRow(Icons.person, 'Instructor', course.staffName),
            _detailRow(Icons.business, 'Department', course.departmentName),
            const SizedBox(height: 12),
            const Text(
              'Description',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              course.description,
              style: TextStyle(color: Colors.grey.shade700, height: 1.5),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
