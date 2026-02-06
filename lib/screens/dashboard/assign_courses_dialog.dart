import 'package:flutter/material.dart';
import '../../models/staff_model.dart';
import '../../models/course_model.dart';
import '../../services/database_service.dart';

/// Dialog for assigning courses to staff
/// Allows multiple course selection with course details displayed
class AssignCoursesDialog extends StatefulWidget {
  final StaffProfile staff;
  final VoidCallback onSuccess;

  const AssignCoursesDialog({
    super.key,
    required this.staff,
    required this.onSuccess,
  });

  @override
  State<AssignCoursesDialog> createState() => _AssignCoursesDialogState();
}

class _AssignCoursesDialogState extends State<AssignCoursesDialog> {
  final _dbService = DatabaseService();
  List<CourseModel> _availableCourses = [];
  Set<String> _selectedCourseIds = {};
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    try {
      final courses = await _dbService.getAllCourses();
      setState(() {
        _availableCourses = courses;
        _selectedCourseIds = Set.from(widget.staff.assignedCourseIds);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Error loading courses', Colors.red);
    }
  }

  Future<void> _saveCourseAssignments() async {
    setState(() => _isSaving = true);
    try {
      final updatedStaff = widget.staff.copyWith(
        assignedCourseIds: _selectedCourseIds.toList(),
      );
      
      final success = await _dbService.updateStaffProfile(updatedStaff);
      
      if (mounted) {
        setState(() => _isSaving = false);
        if (success) {
          widget.onSuccess();
          if (mounted) {
            Navigator.pop(context);
            _showSnackBar('Courses assigned successfully!', Colors.green);
          }
        } else {
          _showSnackBar('Failed to save assignments', Colors.red);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        _showSnackBar('Error: $e', Colors.red);
      }
    }
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
    if (_isLoading) {
      return AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: const SizedBox(
          height: 100,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.assignment, color: Color(0xFF0088CC)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Assign Courses',
                  style: TextStyle(color: Color(0xFF2D3748), fontSize: 18),
                ),
                Text(
                  'for ${widget.staff.fullName}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: _availableCourses.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey.shade400, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'No courses available',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                itemCount: _availableCourses.length,
                itemBuilder: (context, index) {
                  final course = _availableCourses[index];
                  final isSelected = _selectedCourseIds.contains(course.courseId);

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    elevation: 0,
                    color: isSelected
                        ? const Color(0xFF0088CC).withOpacity(0.1)
                        : Colors.grey.shade50,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected
                            ? const Color(0xFF0088CC)
                            : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      course.courseName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Color(0xFF2D3748),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${course.courseCode} | Sem ${course.semester}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Checkbox(
                                value: isSelected,
                                onChanged: (value) {
                                  setState(() {
                                    if (value == true) {
                                      _selectedCourseIds.add(course.courseId);
                                    } else {
                                      _selectedCourseIds.remove(course.courseId);
                                    }
                                  });
                                },
                                activeColor: const Color(0xFF0088CC),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              _buildTag(
                                Icons.business,
                                course.departmentName,
                                Colors.blue,
                              ),
                              _buildTag(
                                Icons.book,
                                '${course.credits} Credits',
                                Colors.green,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: Text(
            'Skip',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveCourseAssignments,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0088CC),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  'Assign (${_selectedCourseIds.length})',
                  style: const TextStyle(color: Colors.white),
                ),
        ),
      ],
    );
  }

  Widget _buildTag(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
