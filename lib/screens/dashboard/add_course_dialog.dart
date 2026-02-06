import 'package:flutter/material.dart';
import '../../models/course_model.dart';
import '../../services/database_service.dart';

/// Add Course Dialog - For admin to create new courses
class AddCourseDialog extends StatefulWidget {
  final VoidCallback onSuccess;

  const AddCourseDialog({
    super.key,
    required this.onSuccess,
  });

  @override
  State<AddCourseDialog> createState() => _AddCourseDialogState();
}

class _AddCourseDialogState extends State<AddCourseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _courseNameController = TextEditingController();
  final _courseCodeController = TextEditingController();
  final _creditsController = TextEditingController();
  final _descriptionController = TextEditingController();

  final _dbService = DatabaseService();
  bool _isLoading = false;

  int _selectedSemester = 1;
  String _selectedDepartment = 'it';
  String? _selectedStaffId;
  List<(String id, String name)> _staffList = [];

  @override
  void initState() {
    super.initState();
    _loadStaff();
  }

  Future<void> _loadStaff() async {
    try {
      final staff = await _dbService.getAllStaff();
      setState(() {
        _staffList = staff.map((s) => (s.staffId, s.fullName)).toList();
        if (_staffList.isNotEmpty) {
          _selectedStaffId = _staffList.first.$1;
        }
      });
    } catch (e) {
      print('Error loading staff: $e');
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final courseId = DateTime.now().millisecondsSinceEpoch.toString();
      final staffName = _staffList
          .firstWhere((s) => s.$1 == _selectedStaffId,
              orElse: () => ('', 'Unassigned'))
          .$2;

      final course = CourseModel(
        courseId: courseId,
        courseName: _courseNameController.text.trim(),
        courseCode: _courseCodeController.text.trim().toUpperCase(),
        semester: _selectedSemester,
        departmentId: _selectedDepartment,
        departmentName: _getDepartmentDisplayName(_selectedDepartment),
        staffId: _selectedStaffId ?? '',
        staffName: staffName,
        credits: int.parse(_creditsController.text),
        description: _descriptionController.text.trim(),
        enrolledStudents: [],
        isActive: true,
        createdAt: DateTime.now(),
      );

      final success = await _dbService.createCourse(course);

      if (mounted) {
        if (success) {
          widget.onSuccess();
          Navigator.pop(context);
          _showSnackBar('Course created successfully!', Colors.green);
        } else {
          _showSnackBar('Failed to create course', Colors.red);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error: ${e.toString()}', Colors.red);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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

  String _getDepartmentDisplayName(String code) {
    switch (code) {
      case 'it':
        return 'Information Technology';
      case 'cs':
        return 'Computer Science';
      case 'ce':
        return 'Computer Engineering';
      case 'aiml':
        return 'AI & Machine Learning';
      default:
        return 'Unknown';
    }
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey.shade600),
      prefixIcon: Icon(icon, color: const Color(0xFF0088CC)),
      filled: true,
      fillColor: const Color(0xFFF7FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF0088CC), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }

  @override
  void dispose() {
    _courseNameController.dispose();
    _courseCodeController.dispose();
    _creditsController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const Icon(Icons.add_circle, color: Color(0xFF0088CC), size: 28),
                  const SizedBox(width: 12),
                  const Text(
                    'Add New Course',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Course Name
              TextFormField(
                controller: _courseNameController,
                decoration: _buildInputDecoration('Course Name', Icons.book),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Enter course name'
                    : null,
              ),
              const SizedBox(height: 16),

              // Course Code
              TextFormField(
                controller: _courseCodeController,
                decoration: _buildInputDecoration('Course Code', Icons.code),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Enter course code'
                    : null,
              ),
              const SizedBox(height: 16),

              // Semester and Credits (Row)
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Semester',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                            color: const Color(0xFFF7FAFC),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: _selectedSemester,
                              isExpanded: true,
                              items: List.generate(
                                8,
                                (i) => DropdownMenuItem(
                                  value: i + 1,
                                  child: Text('Semester ${i + 1}'),
                                ),
                              ),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _selectedSemester = value);
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Credits',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _creditsController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.numbers,
                                color: Color(0xFF0088CC)),
                            filled: true,
                            fillColor: const Color(0xFFF7FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Enter credits';
                            if (int.tryParse(v) == null) return 'Must be a number';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Department
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Department',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                      color: const Color(0xFFF7FAFC),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedDepartment,
                        isExpanded: true,
                        items: [
                          DropdownMenuItem(
                            value: 'it',
                            child: Text(_getDepartmentDisplayName('it')),
                          ),
                          DropdownMenuItem(
                            value: 'cs',
                            child: Text(_getDepartmentDisplayName('cs')),
                          ),
                          DropdownMenuItem(
                            value: 'ce',
                            child: Text(_getDepartmentDisplayName('ce')),
                          ),
                          DropdownMenuItem(
                            value: 'aiml',
                            child: Text(_getDepartmentDisplayName('aiml')),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedDepartment = value);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Staff Assignment
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Assign Staff (Optional)',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _staffList.isEmpty
                      ? Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.amber.shade300),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info, size: 16, color: Colors.amber.shade600),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'No staff members available',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.amber.shade600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                            color: const Color(0xFFF7FAFC),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedStaffId,
                              isExpanded: true,
                              items: [
                                DropdownMenuItem(
                                  value: '',
                                  child: const Text('No staff assigned'),
                                ),
                                ..._staffList.map(
                                  (staff) => DropdownMenuItem(
                                    value: staff.$1,
                                    child: Text(staff.$2),
                                  ),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() => _selectedStaffId = value);
                              },
                            ),
                          ),
                        ),
                ],
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: _buildInputDecoration('Description', Icons.description),
                maxLines: 3,
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Enter description'
                    : null,
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0088CC),
                      disabledBackgroundColor: Colors.grey.shade300,
                    ),
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.add),
                    label: Text(
                      _isLoading ? 'Creating...' : 'Create Course',
                      style: const TextStyle(color: Colors.white),
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
}
