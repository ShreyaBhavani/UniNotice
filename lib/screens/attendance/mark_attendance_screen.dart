import 'package:flutter/material.dart';
import '../../models/attendance_model.dart';
import '../../models/student_model.dart';
import '../../services/database_service.dart';

/// Mark Attendance Screen - CREATE Operation
/// Staff can mark attendance for their lecture
class MarkAttendanceScreen extends StatefulWidget {
  final String courseId;
  final String courseName;
  final String staffId;
  final String staffName;

  const MarkAttendanceScreen({
    super.key,
    required this.courseId,
    required this.courseName,
    required this.staffId,
    required this.staffName,
  });

  @override
  State<MarkAttendanceScreen> createState() => _MarkAttendanceScreenState();
}

class _MarkAttendanceScreenState extends State<MarkAttendanceScreen> {
  final _dbService = DatabaseService();
  
  List<StudentProfile> _students = [];
  final Map<String, bool> _attendance = {};
  String _selectedTime = '09:00 AM';
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;
  bool _isSaving = false;

  final List<String> _timeSlots = [
    '09:00 AM', '10:00 AM', '11:00 AM', '12:00 PM',
    '01:00 PM', '02:00 PM', '03:00 PM', '04:00 PM',
  ];

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);
    try {
      var students = await _dbService.getStudentsByCourse(widget.courseId);
      
      // If no students enrolled, create demo students
      if (students.isEmpty) {
        students = _createDemoStudents();
      }

      setState(() {
        _students = students;
        for (var student in students) {
          _attendance[student.studentId] = true; // Default to present
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Error loading students', Colors.red);
    }
  }

  List<StudentProfile> _createDemoStudents() {
    return [
      StudentProfile(
        studentId: 'demo_1',
        userId: 'user_1',
        fullName: 'John Smith',
        email: 'john@uni.com',
        rollNumber: 'CS2021001',
        departmentId: 'dept_cs',
        departmentName: 'Computer Science',
        currentSemester: 3,
        enrolledCourseIds: [widget.courseId],
        enrollmentDate: DateTime.now(),
      ),
      StudentProfile(
        studentId: 'demo_2',
        userId: 'user_2',
        fullName: 'Jane Doe',
        email: 'jane@uni.com',
        rollNumber: 'CS2021002',
        departmentId: 'dept_cs',
        departmentName: 'Computer Science',
        currentSemester: 3,
        enrolledCourseIds: [widget.courseId],
        enrollmentDate: DateTime.now(),
      ),
      StudentProfile(
        studentId: 'demo_3',
        userId: 'user_3',
        fullName: 'Mike Johnson',
        email: 'mike@uni.com',
        rollNumber: 'CS2021003',
        departmentId: 'dept_cs',
        departmentName: 'Computer Science',
        currentSemester: 3,
        enrolledCourseIds: [widget.courseId],
        enrollmentDate: DateTime.now(),
      ),
      StudentProfile(
        studentId: 'demo_4',
        userId: 'user_4',
        fullName: 'Sarah Williams',
        email: 'sarah@uni.com',
        rollNumber: 'CS2021004',
        departmentId: 'dept_cs',
        departmentName: 'Computer Science',
        currentSemester: 3,
        enrolledCourseIds: [widget.courseId],
        enrollmentDate: DateTime.now(),
      ),
      StudentProfile(
        studentId: 'demo_5',
        userId: 'user_5',
        fullName: 'David Brown',
        email: 'david@uni.com',
        rollNumber: 'CS2021005',
        departmentId: 'dept_cs',
        departmentName: 'Computer Science',
        currentSemester: 3,
        enrolledCourseIds: [widget.courseId],
        enrollmentDate: DateTime.now(),
      ),
    ];
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _markAllPresent() {
    setState(() {
      for (var student in _students) {
        _attendance[student.studentId] = true;
      }
    });
  }

  void _markAllAbsent() {
    setState(() {
      for (var student in _students) {
        _attendance[student.studentId] = false;
      }
    });
  }

  /// CREATE: Save attendance record
  Future<void> _saveAttendance() async {
    if (_students.isEmpty) {
      _showSnackBar('No students to mark attendance', Colors.orange);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final records = _students.map((student) => AttendanceRecord(
        studentId: student.studentId,
        studentName: student.fullName,
        isPresent: _attendance[student.studentId] ?? false,
      )).toList();

      final attendance = AttendanceModel(
        attendanceId: _dbService.generateId(),
        courseId: widget.courseId,
        courseName: widget.courseName,
        staffId: widget.staffId,
        staffName: widget.staffName,
        date: _selectedDate,
        lectureTime: _selectedTime,
        records: records,
        createdAt: DateTime.now(),
      );

      final success = await _dbService.createAttendance(attendance);

      setState(() => _isSaving = false);

      if (success) {
        _showSnackBar('Attendance saved successfully', Colors.green);
        if (mounted) Navigator.pop(context, true);
      } else {
        _showSnackBar('Failed to save attendance', Colors.red);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      _showSnackBar('Error: $e', Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    final presentCount = _attendance.values.where((v) => v).length;
    final absentCount = _attendance.values.where((v) => !v).length;

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
          'Mark Attendance',
          style: TextStyle(color: Color(0xFF2D3748), fontWeight: FontWeight.bold),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Color(0xFF38A169)),
            onSelected: (value) {
              if (value == 'all_present') _markAllPresent();
              if (value == 'all_absent') _markAllAbsent();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all_present', child: Text('Mark All Present')),
              const PopupMenuItem(value: 'all_absent', child: Text('Mark All Absent')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF38A169)))
          : Column(
              children: [
                // Course & Date Info
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.courseName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: _selectDate,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today, size: 18, color: Color(0xFF38A169)),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                      style: const TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedTime,
                                  isExpanded: true,
                                  icon: const Icon(Icons.access_time, color: Color(0xFF38A169)),
                                  items: _timeSlots.map((time) {
                                    return DropdownMenuItem(value: time, child: Text(time));
                                  }).toList(),
                                  onChanged: (value) {
                                    if (value != null) setState(() => _selectedTime = value);
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Summary Row
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: Colors.grey.shade100,
                  child: Row(
                    children: [
                      Text(
                        'Total: ${_students.length}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Present: $presentCount',
                          style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Absent: $absentCount',
                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),

                // Student List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _students.length,
                    itemBuilder: (context, index) {
                      final student = _students[index];
                      final isPresent = _attendance[student.studentId] ?? false;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isPresent
                                ? Colors.green.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                            child: Text(
                              student.fullName[0].toUpperCase(),
                              style: TextStyle(
                                color: isPresent ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            student.fullName,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(student.rollNumber),
                          trailing: Switch(
                            value: isPresent,
                            onChanged: (value) {
                              setState(() => _attendance[student.studentId] = value);
                            },
                            activeThumbColor: Colors.green,
                            inactiveThumbColor: Colors.red,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Save Button
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveAttendance,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF38A169),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              'Save Attendance',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
