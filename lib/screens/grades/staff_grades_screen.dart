import 'package:flutter/material.dart';
import '../../models/result_model.dart';
import '../../models/course_model.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';

/// Staff Grades Screen - CRUD Operations for Assignment Grades
class StaffGradesScreen extends StatefulWidget {
  const StaffGradesScreen({super.key});

  @override
  State<StaffGradesScreen> createState() => _StaffGradesScreenState();
}

class _StaffGradesScreenState extends State<StaffGradesScreen> {
  final _dbService = DatabaseService();
  final _authService = AuthService();

  List<CourseModel> _myCourses = [];
  CourseModel? _selectedCourse;
  List<ResultModel> _results = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final user = await _authService.getCurrentUser();
      var courses = await _dbService.getCoursesForStaff(user?.id ?? '');

      setState(() {
        _myCourses = courses;
        if (courses.isNotEmpty) {
          _selectedCourse = courses.first;
          _loadCourseResults(courses.first.courseId);
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadCourseResults(String courseId) async {
    try {
      var results = await _dbService.getResultsForCourse(courseId);
      setState(() => _results = results);
    } catch (e) {
      // Error loading results
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
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
          'Manage Grades',
          style: TextStyle(
            color: Color(0xFF2D3748),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddGradeDialog,
        backgroundColor: const Color(0xFF38A169),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Grade', style: TextStyle(color: Colors.white)),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF38A169)),
            )
          : Column(
              children: [
                // Course Selector
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Course',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<CourseModel>(
                            value: _selectedCourse,
                            isExpanded: true,
                            items: _myCourses.map((course) {
                              return DropdownMenuItem(
                                value: course,
                                child: Text(
                                  '${course.courseName} (${course.courseCode})',
                                ),
                              );
                            }).toList(),
                            onChanged: (course) {
                              if (course != null) {
                                setState(() => _selectedCourse = course);
                                _loadCourseResults(course.courseId);
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Results List
                Expanded(
                  child: _results.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _results.length,
                          itemBuilder: (context, index) =>
                              _buildStudentGradeCard(_results[index]),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.grade_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No grades recorded yet',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap + to add grades',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentGradeCard(ResultModel result) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showEditGradeDialog(result),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFF38A169).withOpacity(0.1),
                    child: Text(
                      result.studentName[0].toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFF38A169),
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
                          result.studentName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                        Text(
                          'Overall: ${result.overallPercentage.toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (result.finalGrade != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF38A169).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        result.finalGrade!,
                        style: const TextStyle(
                          color: Color(0xFF38A169),
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Assignments Summary
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${result.totalAssignmentMarks.toStringAsFixed(0)}/${result.maxAssignmentMarks.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3182CE),
                            ),
                          ),
                          const Text(
                            'Assignments',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF3182CE),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${result.totalExamMarks.toStringAsFixed(0)}/${result.maxExamMarks.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFD69E2E),
                            ),
                          ),
                          const Text(
                            'Exams',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFFD69E2E),
                            ),
                          ),
                        ],
                      ),
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

  /// CREATE Operation - Add new grade
  void _showAddGradeDialog() {
    if (_results.isEmpty) {
      _showSnackBar('No students in this course', Colors.orange);
      return;
    }

    ResultModel? selectedStudent;
    final assignmentNameController = TextEditingController();
    final maxMarksController = TextEditingController(text: '20');
    final obtainedMarksController = TextEditingController();
    String gradeType = 'assignment';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Add Grade'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Student Selector
                const Text(
                  'Select Student',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<ResultModel>(
                      value: selectedStudent,
                      isExpanded: true,
                      hint: const Text('Select student'),
                      items: _results.map((result) {
                        return DropdownMenuItem(
                          value: result,
                          child: Text(result.studentName),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() => selectedStudent = value);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Grade Type
                const Text(
                  'Grade Type',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text(
                          'Assignment',
                          style: TextStyle(fontSize: 14),
                        ),
                        value: 'assignment',
                        groupValue: gradeType,
                        onChanged: (value) {
                          setDialogState(() => gradeType = value!);
                        },
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text(
                          'Exam',
                          style: TextStyle(fontSize: 14),
                        ),
                        value: 'exam',
                        groupValue: gradeType,
                        onChanged: (value) {
                          setDialogState(() => gradeType = value!);
                        },
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Name
                TextField(
                  controller: assignmentNameController,
                  decoration: InputDecoration(
                    labelText: gradeType == 'assignment'
                        ? 'Assignment Name'
                        : 'Exam Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Marks
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: maxMarksController,
                        decoration: InputDecoration(
                          labelText: 'Max Marks',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: obtainedMarksController,
                        decoration: InputDecoration(
                          labelText: 'Obtained',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedStudent == null) {
                  _showSnackBar('Please select a student', Colors.orange);
                  return;
                }
                if (assignmentNameController.text.isEmpty) {
                  _showSnackBar('Please enter a name', Colors.orange);
                  return;
                }

                final maxMarks = double.tryParse(maxMarksController.text) ?? 0;
                final obtainedMarks =
                    double.tryParse(obtainedMarksController.text) ?? 0;

                if (obtainedMarks > maxMarks) {
                  _showSnackBar(
                    'Obtained marks cannot exceed max marks',
                    Colors.orange,
                  );
                  return;
                }

                // Update result with new grade
                final updatedResult = ResultModel(
                  resultId: selectedStudent!.resultId,
                  studentId: selectedStudent!.studentId,
                  studentName: selectedStudent!.studentName,
                  courseId: selectedStudent!.courseId,
                  courseName: selectedStudent!.courseName,
                  courseCode: selectedStudent!.courseCode,
                  semester: selectedStudent!.semester,
                  assignments: [
                    ...selectedStudent!.assignments,
                    if (gradeType == 'assignment')
                      AssignmentGrade(
                        assignmentId: _dbService.generateId(),
                        assignmentName: assignmentNameController.text,
                        maxMarks: maxMarks,
                        obtainedMarks: obtainedMarks,
                        submittedAt: DateTime.now(),
                      ),
                  ],
                  exams: [
                    ...selectedStudent!.exams,
                    if (gradeType == 'exam')
                      ExamResult(
                        examId: _dbService.generateId(),
                        examName: assignmentNameController.text,
                        examType: 'exam',
                        maxMarks: maxMarks,
                        obtainedMarks: obtainedMarks,
                        examDate: DateTime.now(),
                      ),
                  ],
                  updatedAt: DateTime.now(),
                );

                final success = await _dbService.createResult(updatedResult);
                Navigator.pop(context);

                if (success) {
                  _showSnackBar('Grade added successfully', Colors.green);
                  _loadCourseResults(_selectedCourse!.courseId);
                } else {
                  _showSnackBar('Failed to add grade', Colors.red);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF38A169),
              ),
              child: const Text('Add', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  /// UPDATE Operation - Edit grades
  void _showEditGradeDialog(ResultModel result) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
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
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.white,
                        child: Text(
                          result.studentName[0],
                          style: const TextStyle(
                            color: Color(0xFF38A169),
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
                              result.studentName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Overall: ${result.overallPercentage.toStringAsFixed(1)}%',
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  // Assignments
                  const Text(
                    'Assignments',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  if (result.assignments.isEmpty)
                    const Text('No assignments graded yet')
                  else
                    ...result.assignments.map(
                      (a) => _buildGradeItem(
                        a.assignmentName,
                        a.obtainedMarks,
                        a.maxMarks,
                        Colors.blue,
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Exams
                  const Text(
                    'Exams',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  if (result.exams.isEmpty)
                    const Text('No exams graded yet')
                  else
                    ...result.exams.map(
                      (e) => _buildGradeItem(
                        '${e.examName} (${e.examType})',
                        e.obtainedMarks,
                        e.maxMarks,
                        Colors.orange,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradeItem(
    String name,
    double obtained,
    double max,
    Color color,
  ) {
    final percentage = max == 0 ? 0 : (obtained / max) * 100;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${obtained.toStringAsFixed(0)}/${max.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${percentage.toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
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
