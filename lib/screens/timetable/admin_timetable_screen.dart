import 'package:flutter/material.dart';

import '../../models/course_model.dart';
import '../../models/staff_model.dart';
import '../../models/timetable_model.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';

/// Admin Timetable Management Screen
/// Allows admin to create timetable entries for
/// - All students of a particular department + semester
/// - Staff members (based on their assigned courses)
class AdminTimetableScreen extends StatefulWidget {
  const AdminTimetableScreen({super.key});

  @override
  State<AdminTimetableScreen> createState() => _AdminTimetableScreenState();
}

class _AdminTimetableScreenState extends State<AdminTimetableScreen>
    with SingleTickerProviderStateMixin {
  final _dbService = DatabaseService();

  // Department/semester based timetable (student view source)
  Department _selectedDepartment = Department.it;
  int _selectedSemester = 1;
  bool _isLoadingDept = true;
  List<TimetableEntry> _deptEntries = [];

  // Staff based timetable (staff view source)
  bool _isLoadingStaff = true;
  List<StaffProfile> _staffList = [];
  StaffProfile? _selectedStaff;
  List<TimetableEntry> _staffEntries = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadDepartmentTimetable(),
      _loadStaffList(),
    ]);
  }

  Future<void> _loadDepartmentTimetable() async {
    setState(() => _isLoadingDept = true);
    try {
      final entries = await _dbService.getTimetableForStudent(
        departmentId: _selectedDepartment.name,
        semester: _selectedSemester,
      );
      setState(() {
        _deptEntries = entries;
        _isLoadingDept = false;
      });
    } catch (e) {
      setState(() => _isLoadingDept = false);
      _showSnackBar('Error loading timetable', Colors.red);
    }
  }

  Future<void> _loadStaffList() async {
    setState(() => _isLoadingStaff = true);
    try {
      final staff = await _dbService.getAllStaff();
      setState(() {
        _staffList = staff;
        if (_staffList.isNotEmpty) {
          _selectedStaff = _staffList.first;
        }
      });
      await _loadStaffTimetable();
    } catch (e) {
      setState(() => _isLoadingStaff = false);
      _showSnackBar('Error loading staff list', Colors.red);
    }
  }

  Future<void> _loadStaffTimetable() async {
    if (_selectedStaff == null) {
      setState(() {
        _staffEntries = [];
        _isLoadingStaff = false;
      });
      return;
    }

    setState(() => _isLoadingStaff = true);
    try {
      final entries = await _dbService.getTimetableForStaff(_selectedStaff!.staffId);
      setState(() {
        _staffEntries = entries;
        _isLoadingStaff = false;
      });
    } catch (e) {
      setState(() => _isLoadingStaff = false);
      _showSnackBar('Error loading staff timetable', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _showAddEntryDialogForDepartment() async {
    try {
      final courses = await _dbService.getCoursesForStudent(
        departmentId: _selectedDepartment.name,
        semester: _selectedSemester,
      );

      if (!mounted) return;

      if (courses.isEmpty) {
        _showSnackBar('No courses found for selected department & semester', Colors.orange);
        return;
      }

      showDialog(
        context: context,
        builder: (context) => AddTimetableEntryDialog(
          courses: courses,
          onSuccess: () async {
            await _loadDepartmentTimetable();
            await _loadStaffTimetable();
          },
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Error loading courses', Colors.red);
    }
  }

  Future<void> _showAddEntryDialogForStaff() async {
    if (_selectedStaff == null) {
      _showSnackBar('Select a staff member first', Colors.orange);
      return;
    }

    try {
      final courses = await _dbService.getCoursesForStaff(_selectedStaff!.staffId);

      if (!mounted) return;

      if (courses.isEmpty) {
        _showSnackBar(
          'No courses assigned to this staff. Assign courses first.',
          Colors.orange,
        );
        return;
      }

      showDialog(
        context: context,
        builder: (context) => AddTimetableEntryDialog(
          courses: courses,
          onSuccess: () async {
            await _loadStaffTimetable();
            await _loadDepartmentTimetable();
          },
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Error loading staff courses', Colors.red);
    }
  }

  Future<void> _confirmAndDeleteEntry(TimetableEntry entry) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete entry'),
        content: const Text('Are you sure you want to delete this timetable entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _dbService.deleteTimetableEntry(entry.entryId);
      if (!mounted) return;
      if (success) {
        _showSnackBar('Entry deleted', Colors.green);
        await _loadDepartmentTimetable();
        await _loadStaffTimetable();
      } else {
        _showSnackBar('Failed to delete entry', Colors.red);
      }
    }
  }

  String _departmentLabel(Department dept) => dept.displayName;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF0088CC),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Manage Timetable',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Students'),
              Tab(text: 'Staff'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildStudentTab(),
            _buildStaffTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentTab() {
    return RefreshIndicator(
      onRefresh: () async {
        await _loadDepartmentTimetable();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
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
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<Department>(
                          value: _selectedDepartment,
                          isExpanded: true,
                          items: Department.values
                              .where((d) => d != Department.unknown)
                              .map(
                                (d) => DropdownMenuItem(
                                  value: d,
                                  child: Text(_departmentLabel(d)),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedDepartment = value);
                              _loadDepartmentTimetable();
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
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
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
                              _loadDepartmentTimetable();
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _showAddEntryDialogForDepartment,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0088CC),
              ),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Add Entry', style: TextStyle(color: Colors.white)),
            ),
          ),
          const SizedBox(height: 16),
          _isLoadingDept
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: CircularProgressIndicator(color: Color(0xFF0088CC)),
                  ),
                )
              : _deptEntries.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Column(
                        children: [
                          Icon(Icons.event_busy, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text(
                            'No timetable entries yet for this department & semester',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: _deptEntries
                          .map((entry) => _timetableCard(entry))
                          .toList(),
                    ),
        ],
      ),
    );
  }

  Widget _buildStaffTab() {
    return RefreshIndicator(
      onRefresh: () async {
        await _loadStaffList();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Staff Member',
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
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<StaffProfile>(
                value: _selectedStaff,
                isExpanded: true,
                hint: const Text('Select staff member'),
                items: _staffList
                    .map(
                      (s) => DropdownMenuItem(
                        value: s,
                        child: Text(s.fullName),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() => _selectedStaff = value);
                  _loadStaffTimetable();
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _selectedStaff == null ? null : _showAddEntryDialogForStaff,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0088CC),
                disabledBackgroundColor: Colors.grey.shade300,
              ),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Add Entry', style: TextStyle(color: Colors.white)),
            ),
          ),
          const SizedBox(height: 16),
          _isLoadingStaff
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: CircularProgressIndicator(color: Color(0xFF0088CC)),
                  ),
                )
              : _selectedStaff == null
                  ? Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Column(
                        children: [
                          Icon(Icons.person_outline, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text(
                            'Select a staff member to view timetable',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    )
                  : _staffEntries.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.only(top: 40),
                          child: Column(
                            children: [
                              Icon(Icons.event_busy, size: 64, color: Colors.grey.shade300),
                              const SizedBox(height: 12),
                              Text(
                                'No timetable entries yet for this staff member',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          children: _staffEntries
                              .map((entry) => _timetableCard(entry))
                              .toList(),
                        ),
        ],
      ),
    );
  }

  Widget _timetableCard(TimetableEntry entry) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          entry.courseName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('${entry.courseCode} • Sem ${entry.semester}'),
            const SizedBox(height: 2),
            Text('${entry.dayLabel} • ${entry.timeSlot} • Room ${entry.room}'),
            const SizedBox(height: 2),
            Text('Staff: ${entry.staffName}'),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.redAccent),
          onPressed: () => _confirmAndDeleteEntry(entry),
        ),
      ),
    );
  }
}

/// Dialog to create a new timetable entry based on available courses.
/// The entry will use department, semester and staff details from
/// the selected course so that:
/// - Students see timetable by department + semester
/// - Staff see timetable for their own courses
class AddTimetableEntryDialog extends StatefulWidget {
  final List<CourseModel> courses;
  final VoidCallback onSuccess;

  const AddTimetableEntryDialog({
    super.key,
    required this.courses,
    required this.onSuccess,
  });

  @override
  State<AddTimetableEntryDialog> createState() => _AddTimetableEntryDialogState();
}

class _AddTimetableEntryDialogState extends State<AddTimetableEntryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();
  final _roomController = TextEditingController();

  final _dbService = DatabaseService();
  CourseModel? _selectedCourse;
  DayOfWeek _selectedDay = DayOfWeek.monday;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.courses.isNotEmpty) {
      _selectedCourse = widget.courses.first;
    }
  }

  @override
  void dispose() {
    _startTimeController.dispose();
    _endTimeController.dispose();
    _roomController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCourse == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a course first')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final course = _selectedCourse!;
      final entry = TimetableEntry(
        entryId: 'tt_${DateTime.now().millisecondsSinceEpoch}',
        courseId: course.courseId,
        courseName: course.courseName,
        courseCode: course.courseCode,
        day: _selectedDay,
        startTime: _startTimeController.text.trim(),
        endTime: _endTimeController.text.trim(),
        room: _roomController.text.trim(),
        staffId: course.staffId,
        staffName: course.staffName,
        departmentId: course.departmentId,
        semester: course.semester,
      );

      final success = await _dbService.createTimetableEntry(entry);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Timetable entry created'), backgroundColor: Colors.green),
        );
        widget.onSuccess();
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create entry'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _dayLabel(DayOfWeek day) {
    switch (day) {
      case DayOfWeek.monday:
        return 'Monday';
      case DayOfWeek.tuesday:
        return 'Tuesday';
      case DayOfWeek.wednesday:
        return 'Wednesday';
      case DayOfWeek.thursday:
        return 'Thursday';
      case DayOfWeek.friday:
        return 'Friday';
      case DayOfWeek.saturday:
        return 'Saturday';
      case DayOfWeek.sunday:
        return 'Sunday';
    }
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
              Row(
                children: const [
                  Icon(Icons.schedule, color: Color(0xFF0088CC)),
                  SizedBox(width: 8),
                  Text(
                    'Add Timetable Entry',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Course',
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
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<CourseModel>(
                    value: _selectedCourse,
                    isExpanded: true,
                    items: widget.courses
                        .map(
                          (c) => DropdownMenuItem(
                            value: c,
                            child: Text('${c.courseName} (${c.courseCode})'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() => _selectedCourse = value);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Day',
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
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<DayOfWeek>(
                    value: _selectedDay,
                    isExpanded: true,
                    items: DayOfWeek.values
                        .map(
                          (d) => DropdownMenuItem(
                            value: d,
                            child: Text(_dayLabel(d)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedDay = value);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _startTimeController,
                decoration: InputDecoration(
                  labelText: 'Start Time (e.g. 09:00)',
                  prefixIcon:
                      const Icon(Icons.access_time, color: Color(0xFF0088CC)),
                  filled: true,
                  fillColor: const Color(0xFFF7FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Enter start time'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _endTimeController,
                decoration: InputDecoration(
                  labelText: 'End Time (e.g. 10:00)',
                  prefixIcon:
                      const Icon(Icons.access_time, color: Color(0xFF0088CC)),
                  filled: true,
                  fillColor: const Color(0xFFF7FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Enter end time'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _roomController,
                decoration: InputDecoration(
                  labelText: 'Room (e.g. 101)',
                  prefixIcon:
                      const Icon(Icons.location_on, color: Color(0xFF0088CC)),
                  filled: true,
                  fillColor: const Color(0xFFF7FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Enter room'
                    : null,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0088CC),
                      disabledBackgroundColor: Colors.grey.shade300,
                    ),
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.check, color: Colors.white),
                    label: Text(
                      _isSaving ? 'Saving...' : 'Save Entry',
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
