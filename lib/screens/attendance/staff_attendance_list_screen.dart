import 'package:flutter/material.dart';
import '../../models/attendance_model.dart';
import '../../models/course_model.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import 'mark_attendance_screen.dart';

/// Staff Attendance List Screen - READ & Navigate to CRUD
class StaffAttendanceListScreen extends StatefulWidget {
  final String? staffId;
  
  const StaffAttendanceListScreen({super.key, this.staffId});

  @override
  State<StaffAttendanceListScreen> createState() => _StaffAttendanceListScreenState();
}

class _StaffAttendanceListScreenState extends State<StaffAttendanceListScreen> {
  final _dbService = DatabaseService();
  final _authService = AuthService();

  List<CourseModel> _myCourses = [];
  List<AttendanceModel> _attendanceRecords = [];
  bool _isLoading = true;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final user = await _authService.getCurrentUser();
      final courses = await _dbService.getCoursesForStaff(user?.id ?? '');
      final attendance = await _dbService.getAttendanceByStaff(user?.id ?? '');

      setState(() {
        _currentUserId = user?.id;
        _myCourses = courses;
        _attendanceRecords = attendance;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Error loading data', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8EDF5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF38A169)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Attendance Management',
          style: TextStyle(color: Color(0xFF2D3748), fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCourseSelectionDialog(),
        backgroundColor: const Color(0xFF38A169),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Mark Attendance', style: TextStyle(color: Colors.white)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF38A169)))
          : RefreshIndicator(
              onRefresh: _loadData,
              child: _attendanceRecords.isEmpty
                  ? _buildEmptyState()
                  : _buildAttendanceList(),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.fact_check_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No attendance records yet',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text('Tap + to mark attendance', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildAttendanceList() {
    // Group attendance by date
    Map<String, List<AttendanceModel>> groupedAttendance = {};
    for (var attendance in _attendanceRecords) {
      final dateKey = '${attendance.date.day}/${attendance.date.month}/${attendance.date.year}';
      if (!groupedAttendance.containsKey(dateKey)) {
        groupedAttendance[dateKey] = [];
      }
      groupedAttendance[dateKey]!.add(attendance);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedAttendance.length,
      itemBuilder: (context, index) {
        final dateKey = groupedAttendance.keys.elementAt(index);
        final attendanceList = groupedAttendance[dateKey]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                dateKey,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF718096),
                ),
              ),
            ),
            ...attendanceList.map((attendance) => _buildAttendanceCard(attendance)),
          ],
        );
      },
    );
  }

  Widget _buildAttendanceCard(AttendanceModel attendance) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showAttendanceDetails(attendance),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF38A169).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.fact_check, color: Color(0xFF38A169)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          attendance.courseName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                        Text(
                          attendance.lectureTime,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _statBox('Present', attendance.presentCount.toString(), Colors.green),
                  const SizedBox(width: 8),
                  _statBox('Absent', attendance.absentCount.toString(), Colors.red),
                  const SizedBox(width: 8),
                  _statBox('Total', attendance.records.length.toString(), Colors.blue),
                  const Spacer(),
                  Text(
                    '${attendance.attendancePercentage.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF38A169),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          Text(label, style: TextStyle(fontSize: 10, color: color)),
        ],
      ),
    );
  }

  void _showCourseSelectionDialog() {
    if (_myCourses.isEmpty) {
      // If no courses assigned, use sample courses for demo
      _showSnackBar('No courses assigned. Using demo mode.', Colors.orange);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MarkAttendanceScreen(
            courseId: 'demo_course',
            courseName: 'Demo Course',
            staffId: _currentUserId ?? '',
            staffName: 'Staff',
          ),
        ),
      ).then((_) => _loadData());
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Select Course'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _myCourses.length,
            itemBuilder: (context, index) {
              final course = _myCourses[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF38A169).withOpacity(0.1),
                  child: const Icon(Icons.book, color: Color(0xFF38A169)),
                ),
                title: Text(course.courseName),
                subtitle: Text(course.courseCode),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MarkAttendanceScreen(
                        courseId: course.courseId,
                        courseName: course.courseName,
                        staffId: _currentUserId ?? '',
                        staffName: 'Staff',
                      ),
                    ),
                  ).then((_) => _loadData());
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showAttendanceDetails(AttendanceModel attendance) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF38A169),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    attendance.courseName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${attendance.lectureTime} • ${attendance.date.day}/${attendance.date.month}/${attendance.date.year}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: attendance.records.length,
                itemBuilder: (context, index) {
                  final record = attendance.records[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: record.isPresent
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      child: Icon(
                        record.isPresent ? Icons.check : Icons.close,
                        color: record.isPresent ? Colors.green : Colors.red,
                      ),
                    ),
                    title: Text(record.studentName),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: record.isPresent
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        record.isPresent ? 'Present' : 'Absent',
                        style: TextStyle(
                          color: record.isPresent ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
