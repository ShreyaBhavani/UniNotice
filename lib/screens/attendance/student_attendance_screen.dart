import 'package:flutter/material.dart';
import '../../models/attendance_model.dart';
import '../../services/database_service.dart';

/// Student Attendance Screen - READ Operation
/// Displays attendance summary for all enrolled courses
class StudentAttendanceScreen extends StatefulWidget {
  final String? studentId;
  final String? studentName;

  const StudentAttendanceScreen({
    super.key,
    this.studentId,
    this.studentName,
  });

  @override
  State<StudentAttendanceScreen> createState() => _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState extends State<StudentAttendanceScreen> {
  final _dbService = DatabaseService();
  List<StudentAttendanceSummary> _attendanceSummary = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    setState(() => _isLoading = true);
    try {
      final studentId = widget.studentId ?? 'demo_student';
      final summary = await _dbService.getStudentAttendanceSummary(studentId);
      setState(() {
        _attendanceSummary = summary;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Error loading attendance', Colors.red);
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
          icon: const Icon(Icons.arrow_back, color: Color(0xFF3182CE)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Attendance',
          style: TextStyle(color: Color(0xFF2D3748), fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF3182CE)))
          : RefreshIndicator(
              onRefresh: _loadAttendance,
              child: _attendanceSummary.isEmpty
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
          Icon(Icons.event_busy, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No attendance records found',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceList() {
    // Calculate overall attendance
    int totalClasses = _attendanceSummary.fold(0, (sum, s) => sum + s.totalClasses);
    int attendedClasses = _attendanceSummary.fold(0, (sum, s) => sum + s.attendedClasses);
    double overallPercentage = totalClasses == 0 ? 0 : (attendedClasses / totalClasses) * 100;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Overall Summary Card
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF3182CE), const Color(0xFF3182CE).withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Text(
                  'Overall Attendance',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      overallPercentage.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text('%', style: TextStyle(color: Colors.white, fontSize: 24)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '$attendedClasses / $totalClasses classes attended',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: overallPercentage / 100,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    overallPercentage >= 75 ? Colors.greenAccent : Colors.orangeAccent,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Course-wise Attendance
        const Text(
          'Course-wise Attendance',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
        ),
        const SizedBox(height: 12),

        ..._attendanceSummary.map((summary) => _buildCourseAttendanceCard(summary)),
      ],
    );
  }

  Widget _buildCourseAttendanceCard(StudentAttendanceSummary summary) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (summary.percentage >= 75) {
      statusColor = Colors.green;
      statusText = 'Good';
      statusIcon = Icons.check_circle;
    } else if (summary.percentage >= 60) {
      statusColor = Colors.orange;
      statusText = 'Warning';
      statusIcon = Icons.warning;
    } else {
      statusColor = Colors.red;
      statusText = 'Critical';
      statusIcon = Icons.error;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    summary.courseName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${summary.attendedClasses} / ${summary.totalClasses}',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
                      ),
                      Text('Classes Attended', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    ],
                  ),
                ),
                SizedBox(
                  width: 80,
                  height: 80,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: summary.percentage / 100,
                        strokeWidth: 8,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                      ),
                      Text(
                        '${summary.percentage.toStringAsFixed(0)}%',
                        style: TextStyle(fontWeight: FontWeight.bold, color: statusColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
