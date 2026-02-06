import 'package:flutter/material.dart';
import '../../models/staff_model.dart';
import '../../models/course_model.dart';
import '../../services/database_service.dart';
import 'assign_courses_dialog.dart';

/// Staff Management Screen - For admin to manage and assign courses to staff
class StaffManagementScreen extends StatefulWidget {
  const StaffManagementScreen({super.key});

  @override
  State<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends State<StaffManagementScreen> {
  final _dbService = DatabaseService();
  List<StaffProfile> _allStaff = [];
  Map<String, List<CourseModel>> _staffCoursesMap = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStaffAndCourses();
  }

  Future<void> _loadStaffAndCourses() async {
    setState(() => _isLoading = true);
    try {
      final staff = await _dbService.getAllStaff();
      
      // Load courses for each staff member
      final coursesMap = <String, List<CourseModel>>{};
      for (var s in staff) {
        final courses = await _dbService.getCoursesForStaff(s.staffId);
        coursesMap[s.staffId] = courses;
      }

      setState(() {
        _allStaff = staff;
        _staffCoursesMap = coursesMap;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading staff: $e');
      setState(() => _isLoading = false);
      _showSnackBar('Error loading staff', Colors.red);
    }
  }

  void _showAssignCoursesDialog(StaffProfile staff) {
    showDialog(
      context: context,
      builder: (context) => AssignCoursesDialog(
        staff: staff,
        onSuccess: _loadStaffAndCourses,
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0088CC),
        elevation: 0,
        title: const Text(
          'Manage Staff',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _allStaff.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'No staff members yet',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _allStaff.length,
                  itemBuilder: (context, index) {
                    final staff = _allStaff[index];
                    final assignedCourses = _staffCoursesMap[staff.staffId] ?? [];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Staff Header
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: const Color(0xFF0088CC),
                                  radius: 28,
                                  child: Text(
                                    staff.fullName[0].toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        staff.fullName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Color(0xFF2D3748),
                                        ),
                                      ),
                                      Text(
                                        staff.email,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.business,
                                            size: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            staff.departmentName,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Assigned Courses Section
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Assigned Courses (${assignedCourses.length})',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Color(0xFF2D3748),
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () => _showAssignCoursesDialog(staff),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0088CC),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                  ),
                                  icon: const Icon(Icons.edit, size: 16),
                                  label: const Text(
                                    'Assign',
                                    style: TextStyle(fontSize: 12, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (assignedCourses.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      size: 16,
                                      color: Colors.grey.shade600,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'No courses assigned yet',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: assignedCourses.map((course) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0088CC).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xFF0088CC).withOpacity(0.3),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          course.courseName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                            color: Color(0xFF0088CC),
                                          ),
                                        ),
                                        Text(
                                          'Sem ${course.semester} • ${course.departmentName}',
                                          style: TextStyle(
                                            fontSize: 9,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0088CC),
        onPressed: _loadStaffAndCourses,
        tooltip: 'Refresh',
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }
}
