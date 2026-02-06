import 'package:flutter/material.dart';
import '../../models/notice_model.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';

/// Add/Edit Notice Screen - CREATE & UPDATE Operations
/// Supports multi-audience selection with department-wise staff/student grouping
class AddEditNoticeScreen extends StatefulWidget {
  final NoticeModel? notice; // null for create, populated for edit

  const AddEditNoticeScreen({super.key, this.notice});

  @override
  State<AddEditNoticeScreen> createState() => _AddEditNoticeScreenState();
}

class _AddEditNoticeScreenState extends State<AddEditNoticeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dbService = DatabaseService();
  final _authService = AuthService();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  NoticeType _selectedType = NoticeType.departmentLevel;
  Set<TargetAudience> _selectedAudiences = {}; // Changed to Set for multi-selection
  Department? _selectedDepartment;
  List<String> _selectedStaffIds = [];
  List<String> _selectedStudentIds = [];

  // Available departments for selection
  final List<Department> _availableDepartments = [
    Department.it,
    Department.cs,
    Department.ce,
    Department.aiml,
  ];

  List<UserModel> _allStaff = [];  // Staff users from users collection
  List<UserModel> _allStudents = [];  // Student users from users collection

  bool _isLoading = false;
  bool _isEditing = false;
  String? _currentUserId;
  String? _currentUserName;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.notice != null;
    if (_isEditing) {
      _titleController.text = widget.notice!.title;
      _descriptionController.text = widget.notice!.description;
      _selectedType = widget.notice!.type;
      _selectedAudiences = widget.notice!.targetAudiences.toSet();
      // Map departmentId to Department enum
      if (widget.notice!.departmentId != null) {
        _selectedDepartment = Department.values.firstWhere(
          (d) => d.name == widget.notice!.departmentId,
          orElse: () => Department.unknown,
        );
        if (_selectedDepartment == Department.unknown) {
          _selectedDepartment = null;
        }
      }
      _selectedStaffIds = widget.notice!.selectedStaffIds ?? [];
      _selectedStudentIds = widget.notice!.selectedStudentIds ?? [];
    }
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final user = await _authService.getCurrentUser();
      // Fetch all users from users collection (added by admin)
      final allUsers = await _authService.getAllUsers();
      
      // Filter staff and students by role
      final staff = allUsers.where((u) => u.role == UserRole.staff).toList();
      final students = allUsers.where((u) => u.role == UserRole.student).toList();

      print('Loaded ${staff.length} staff and ${students.length} students from users collection');

      setState(() {
        _currentUserId = user?.id;
        _currentUserName = user?.fullName;
        _allStaff = staff;
        _allStudents = students;
      });
    } catch (e) {
      print('Error in _loadData: $e');
      _showSnackBar('Error loading data', Colors.red);
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

  /// CREATE or UPDATE Operation
  Future<void> _saveNotice() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedType == NoticeType.departmentLevel &&
        _selectedDepartment == null) {
      _showSnackBar('Please select a department', Colors.orange);
      return;
    }

    if (_selectedAudiences.isEmpty) {
      _showSnackBar('Please select at least one target audience', Colors.orange);
      return;
    }

    if (_selectedAudiences.contains(TargetAudience.selectedStaff) &&
        _selectedStaffIds.isEmpty) {
      _showSnackBar('Please select at least one staff member', Colors.orange);
      return;
    }

    if (_selectedAudiences.contains(TargetAudience.selectedStudents) &&
        _selectedStudentIds.isEmpty) {
      _showSnackBar('Please select at least one student', Colors.orange);
      return;
    }

    // Ensure user is loaded
    if (_currentUserId == null || _currentUserId!.isEmpty) {
      final user = await _authService.getCurrentUser();
      if (user == null) {
        _showSnackBar('User session expired. Please login again.', Colors.red);
        return;
      }
      _currentUserId = user.id;
      _currentUserName = user.fullName;
    }

    setState(() => _isLoading = true);

    try {
      final notice = NoticeModel(
        noticeId: _isEditing
            ? widget.notice!.noticeId
            : _dbService.generateId(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        type: _selectedType,
        targetAudiences: _selectedAudiences.toList(),
        departmentId: _selectedType == NoticeType.departmentLevel
            ? _selectedDepartment?.name
            : null,
        createdBy: _isEditing
            ? widget.notice!.createdBy
            : _currentUserId ?? 'unknown',
        createdByName: _isEditing
            ? widget.notice!.createdByName
            : (_currentUserName ?? 'Unknown'),
        createdAt: _isEditing ? widget.notice!.createdAt : DateTime.now(),
        isActive: true,
        selectedStaffIds: _selectedAudiences.contains(TargetAudience.selectedStaff)
            ? _selectedStaffIds
            : null,
        selectedStudentIds: _selectedAudiences.contains(TargetAudience.selectedStudents)
            ? _selectedStudentIds
            : null,
      );

      bool success;
      if (_isEditing) {
        success = await _dbService.updateNotice(notice);
      } else {
        success = await _dbService.createNotice(notice);
      }

      setState(() => _isLoading = false);

      if (success) {
        _showSnackBar(
          _isEditing
              ? 'Notice updated successfully'
              : 'Notice created successfully',
          Colors.green,
        );
        if (mounted) Navigator.pop(context, true);
      } else {
        _showSnackBar('Failed to save notice', Colors.red);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Error: $e', Colors.red);
    }
  }

  /// Extract department name from email address
  /// e.g., priyanka.it@uni.com -> Information Technology
  /// sanketsuthar.ce@uni.com -> Computer Engineering
  String _getDepartmentFromEmail(String email) {
    final emailLower = email.toLowerCase();
    
    // Check for department code in email (before @)
    final localPart = emailLower.split('@').first;
    
    if (localPart.contains('.it') || localPart.endsWith('it')) {
      return 'Information Technology';
    } else if (localPart.contains('.ce') || localPart.endsWith('ce')) {
      return 'Computer Engineering';
    } else if (localPart.contains('.cs') || localPart.endsWith('cs')) {
      return 'Computer Science';
    } else if (localPart.contains('.aiml') || localPart.endsWith('aiml') || 
               localPart.contains('.ai') || localPart.endsWith('ai')) {
      return 'AI & Machine Learning';
    } else if (localPart.contains('.ec') || localPart.endsWith('ec')) {
      return 'Electronics & Communication';
    } else if (localPart.contains('.me') || localPart.endsWith('me')) {
      return 'Mechanical Engineering';
    } else if (localPart.contains('.ee') || localPart.endsWith('ee')) {
      return 'Electrical Engineering';
    } else if (localPart.contains('.civil') || localPart.endsWith('civil')) {
      return 'Civil Engineering';
    }
    
    return 'Other';
  }

  /// Group staff by department (extracted from email)
  Map<String, List<UserModel>> _getStaffByDepartment() {
    final Map<String, List<UserModel>> grouped = {};
    for (final staff in _allStaff) {
      // Extract department from email
      final dept = _getDepartmentFromEmail(staff.email);
      grouped.putIfAbsent(dept, () => []);
      grouped[dept]!.add(staff);
    }
    // Sort departments alphabetically
    final sortedKeys = grouped.keys.toList()..sort();
    return {for (var key in sortedKeys) key: grouped[key]!};
  }

  /// Group students by department (extracted from email)
  Map<String, List<UserModel>> _getStudentsByDepartment() {
    final Map<String, List<UserModel>> grouped = {};
    for (final student in _allStudents) {
      // Extract department from email
      final dept = _getDepartmentFromEmail(student.email);
      grouped.putIfAbsent(dept, () => []);
      grouped[dept]!.add(student);
    }
    // Sort departments alphabetically
    final sortedKeys = grouped.keys.toList()..sort();
    return {for (var key in sortedKeys) key: grouped[key]!};
  }

  void _showStaffSelectionDialog() {
    final staffByDept = _getStaffByDepartment();
    final expandedDepts = <String>{};

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(Icons.people, color: Color(0xFF38A169)),
              const SizedBox(width: 8),
              const Expanded(child: Text('Select Staff Members')),
              Text(
                '${_selectedStaffIds.length} selected',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: staffByDept.isEmpty
                ? const Center(child: Text('No staff available'))
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: staffByDept.length,
                    itemBuilder: (context, index) {
                      final dept = staffByDept.keys.elementAt(index);
                      final staffList = staffByDept[dept]!;
                      final isExpanded = expandedDepts.contains(dept);
                      final selectedInDept = staffList
                          .where((s) => _selectedStaffIds.contains(s.id))
                          .length;
                      final allSelectedInDept = selectedInDept == staffList.length;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Column(
                          children: [
                            // Department Header with select all
                            InkWell(
                              onTap: () {
                                setDialogState(() {
                                  if (isExpanded) {
                                    expandedDepts.remove(dept);
                                  } else {
                                    expandedDepts.add(dept);
                                  }
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF38A169).withOpacity(0.1),
                                  borderRadius: BorderRadius.vertical(
                                    top: const Radius.circular(8),
                                    bottom: isExpanded 
                                        ? Radius.zero 
                                        : const Radius.circular(8),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isExpanded
                                          ? Icons.keyboard_arrow_down
                                          : Icons.keyboard_arrow_right,
                                      color: const Color(0xFF38A169),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '$dept ($selectedInDept/${staffList.length})',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF2D3748),
                                        ),
                                      ),
                                    ),
                                    // Select all in department
                                    Checkbox(
                                      value: allSelectedInDept,
                                      tristate: selectedInDept > 0 && !allSelectedInDept,
                                      onChanged: (value) {
                                        setDialogState(() {
                                          if (allSelectedInDept) {
                                            // Deselect all in department
                                            for (final s in staffList) {
                                              _selectedStaffIds.remove(s.id);
                                            }
                                          } else {
                                            // Select all in department
                                            for (final s in staffList) {
                                              if (!_selectedStaffIds.contains(s.id)) {
                                                _selectedStaffIds.add(s.id);
                                              }
                                            }
                                          }
                                        });
                                      },
                                      activeColor: const Color(0xFF38A169),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Staff list (expanded)
                            if (isExpanded)
                              ...staffList.map((staff) {
                                final isSelected = _selectedStaffIds.contains(staff.id);
                                return CheckboxListTile(
                                  title: Text(staff.fullName),
                                  subtitle: Text(
                                    staff.email,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  value: isSelected,
                                  onChanged: (value) {
                                    setDialogState(() {
                                      if (value == true) {
                                        _selectedStaffIds.add(staff.id);
                                      } else {
                                        _selectedStaffIds.remove(staff.id);
                                      }
                                    });
                                  },
                                  activeColor: const Color(0xFF38A169),
                                  dense: true,
                                );
                              }),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setDialogState(() {
                  _selectedStaffIds.clear();
                });
              },
              child: const Text('Clear All'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF38A169),
              ),
              child: const Text('Done', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    ).then((_) => setState(() {}));
  }

  void _showStudentSelectionDialog() {
    final studentsByDept = _getStudentsByDepartment();
    final expandedDepts = <String>{};

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(Icons.school, color: Color(0xFF3182CE)),
              const SizedBox(width: 8),
              const Expanded(child: Text('Select Students')),
              Text(
                '${_selectedStudentIds.length} selected',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: studentsByDept.isEmpty
                ? const Center(child: Text('No students available'))
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: studentsByDept.length,
                    itemBuilder: (context, index) {
                      final dept = studentsByDept.keys.elementAt(index);
                      final studentList = studentsByDept[dept]!;
                      final isExpanded = expandedDepts.contains(dept);
                      final selectedInDept = studentList
                          .where((s) => _selectedStudentIds.contains(s.id))
                          .length;
                      final allSelectedInDept = selectedInDept == studentList.length;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Column(
                          children: [
                            // Department Header with select all
                            InkWell(
                              onTap: () {
                                setDialogState(() {
                                  if (isExpanded) {
                                    expandedDepts.remove(dept);
                                  } else {
                                    expandedDepts.add(dept);
                                  }
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3182CE).withOpacity(0.1),
                                  borderRadius: BorderRadius.vertical(
                                    top: const Radius.circular(8),
                                    bottom: isExpanded 
                                        ? Radius.zero 
                                        : const Radius.circular(8),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isExpanded
                                          ? Icons.keyboard_arrow_down
                                          : Icons.keyboard_arrow_right,
                                      color: const Color(0xFF3182CE),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '$dept ($selectedInDept/${studentList.length})',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF2D3748),
                                        ),
                                      ),
                                    ),
                                    // Select all in department
                                    Checkbox(
                                      value: allSelectedInDept,
                                      tristate: selectedInDept > 0 && !allSelectedInDept,
                                      onChanged: (value) {
                                        setDialogState(() {
                                          if (allSelectedInDept) {
                                            // Deselect all in department
                                            for (final s in studentList) {
                                              _selectedStudentIds.remove(s.id);
                                            }
                                          } else {
                                            // Select all in department
                                            for (final s in studentList) {
                                              if (!_selectedStudentIds.contains(s.id)) {
                                                _selectedStudentIds.add(s.id);
                                              }
                                            }
                                          }
                                        });
                                      },
                                      activeColor: const Color(0xFF3182CE),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Student list (expanded)
                            if (isExpanded)
                              ...studentList.map((student) {
                                final isSelected = _selectedStudentIds.contains(student.id);
                                return CheckboxListTile(
                                  title: Text(student.fullName),
                                  subtitle: Text(
                                    student.email,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  value: isSelected,
                                  onChanged: (value) {
                                    setDialogState(() {
                                      if (value == true) {
                                        _selectedStudentIds.add(student.id);
                                      } else {
                                        _selectedStudentIds.remove(student.id);
                                      }
                                    });
                                  },
                                  activeColor: const Color(0xFF3182CE),
                                  dense: true,
                                );
                              }),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setDialogState(() {
                  _selectedStudentIds.clear();
                });
              },
              child: const Text('Clear All'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3182CE),
              ),
              child: const Text('Done', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    ).then((_) => setState(() {}));
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
        title: Text(
          _isEditing ? 'Edit Notice' : 'Create Notice',
          style: const TextStyle(
            color: Color(0xFF2D3748),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Field
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Notice Title *',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _titleController,
                        decoration: _inputDecoration('Enter notice title'),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Title is required'
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Description Field
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Description *',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: _inputDecoration(
                          'Enter notice description',
                        ),
                        maxLines: 5,
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Description is required'
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Notice Type
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Notice Level *',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: NoticeType.values.map((type) {
                          final isSelected = _selectedType == type;
                          return ChoiceChip(
                            label: Text(_getTypeLabel(type)),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _selectedType = type);
                              }
                            },
                            selectedColor: _getTypeColor(type).withOpacity(0.2),
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? _getTypeColor(type)
                                  : Colors.grey.shade700,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Department Selection (only for department level)
              if (_selectedType == NoticeType.departmentLevel)
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Department *',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<Department>(
                          initialValue: _selectedDepartment,
                          decoration: _inputDecoration('Select department'),
                          items: _availableDepartments.map((dept) {
                            return DropdownMenuItem(
                              value: dept,
                              child: Text(
                                '${dept.shortName} - ${dept.displayName}',
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedDepartment = value);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              if (_selectedType == NoticeType.departmentLevel)
                const SizedBox(height: 12),

              // Target Audience (Multi-select)
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Target Audience *',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D3748),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '(Select multiple)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Everyone option
                      _buildAudienceCheckTile(
                        TargetAudience.everyone,
                        'Everyone',
                        'All staff and students',
                        Icons.public,
                        Colors.purple,
                      ),
                      const Divider(),
                      // Staff options
                      _buildAudienceCheckTile(
                        TargetAudience.allStaff,
                        'All Staff',
                        'All staff members',
                        Icons.badge,
                        const Color(0xFF38A169),
                        enabled: !_selectedAudiences.contains(TargetAudience.everyone),
                      ),
                      _buildAudienceCheckTile(
                        TargetAudience.selectedStaff,
                        'Selected Staff',
                        'Choose specific staff members',
                        Icons.person_search,
                        const Color(0xFF38A169),
                        enabled: !_selectedAudiences.contains(TargetAudience.everyone) &&
                            !_selectedAudiences.contains(TargetAudience.allStaff),
                      ),
                      const Divider(),
                      // Student options
                      _buildAudienceCheckTile(
                        TargetAudience.allStudents,
                        'All Students',
                        'All students',
                        Icons.school,
                        const Color(0xFF3182CE),
                        enabled: !_selectedAudiences.contains(TargetAudience.everyone),
                      ),
                      _buildAudienceCheckTile(
                        TargetAudience.selectedStudents,
                        'Selected Students',
                        'Choose specific students',
                        Icons.person_pin,
                        const Color(0xFF3182CE),
                        enabled: !_selectedAudiences.contains(TargetAudience.everyone) &&
                            !_selectedAudiences.contains(TargetAudience.allStudents),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Staff Selection (only for selected staff audience)
              if (_selectedAudiences.contains(TargetAudience.selectedStaff))
                _buildSelectionCard(
                  title: 'Selected Staff',
                  count: _selectedStaffIds.length,
                  icon: Icons.people,
                  color: const Color(0xFF38A169),
                  onSelect: _showStaffSelectionDialog,
                  selectedItems: _selectedStaffIds.map((id) {
                    final staff = _allStaff.firstWhere(
                      (s) => s.id == id,
                      orElse: () => UserModel(
                        id: id,
                        fullName: 'Unknown',
                        email: '',
                        role: UserRole.staff,
                        createdAt: DateTime.now(),
                      ),
                    );
                    return MapEntry(id, '${staff.fullName} (${staff.department.displayName})');
                  }).toList(),
                  onRemove: (id) {
                    setState(() => _selectedStaffIds.remove(id));
                  },
                ),

              // Student Selection (only for selected students audience)
              if (_selectedAudiences.contains(TargetAudience.selectedStudents))
                _buildSelectionCard(
                  title: 'Selected Students',
                  count: _selectedStudentIds.length,
                  icon: Icons.school,
                  color: const Color(0xFF3182CE),
                  onSelect: _showStudentSelectionDialog,
                  selectedItems: _selectedStudentIds.map((id) {
                    final student = _allStudents.firstWhere(
                      (s) => s.id == id,
                      orElse: () => UserModel(
                        id: id,
                        fullName: 'Unknown',
                        email: '',
                        role: UserRole.student,
                        createdAt: DateTime.now(),
                      ),
                    );
                    return MapEntry(id, '${student.fullName} (${student.department.displayName})');
                  }).toList(),
                  onRemove: (id) {
                    setState(() => _selectedStudentIds.remove(id));
                  },
                ),

              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveNotice,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF38A169),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _isEditing ? 'Update Notice' : 'Post Notice',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAudienceCheckTile(
    TargetAudience audience,
    String title,
    String subtitle,
    IconData icon,
    Color color, {
    bool enabled = true,
  }) {
    final isSelected = _selectedAudiences.contains(audience);
    
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: CheckboxListTile(
        title: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        value: isSelected,
        onChanged: enabled
            ? (value) {
                setState(() {
                  if (value == true) {
                    // If selecting "Everyone", clear other selections
                    if (audience == TargetAudience.everyone) {
                      _selectedAudiences.clear();
                    }
                    // If selecting "All Staff", remove "Selected Staff"
                    if (audience == TargetAudience.allStaff) {
                      _selectedAudiences.remove(TargetAudience.selectedStaff);
                      _selectedStaffIds.clear();
                    }
                    // If selecting "All Students", remove "Selected Students"
                    if (audience == TargetAudience.allStudents) {
                      _selectedAudiences.remove(TargetAudience.selectedStudents);
                      _selectedStudentIds.clear();
                    }
                    _selectedAudiences.add(audience);
                  } else {
                    _selectedAudiences.remove(audience);
                    // Clear related selections
                    if (audience == TargetAudience.selectedStaff) {
                      _selectedStaffIds.clear();
                    }
                    if (audience == TargetAudience.selectedStudents) {
                      _selectedStudentIds.clear();
                    }
                  }
                });
              }
            : null,
        activeColor: color,
        dense: true,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildSelectionCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required VoidCallback onSelect,
    required List<MapEntry<String, String>> selectedItems,
    required Function(String) onRemove,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  '$title ($count)',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: onSelect,
                  icon: Icon(Icons.edit, color: color, size: 18),
                  label: Text('Edit', style: TextStyle(color: color)),
                ),
              ],
            ),
            if (selectedItems.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: selectedItems.map((item) {
                  return Chip(
                    label: Text(
                      item.value,
                      style: const TextStyle(fontSize: 12),
                    ),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => onRemove(item.key),
                    backgroundColor: color.withOpacity(0.1),
                    side: BorderSide(color: color.withOpacity(0.3)),
                  );
                }).toList(),
              ),
            ] else ...[
              const SizedBox(height: 8),
              Text(
                'No $title selected. Tap Edit to select.',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF38A169), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  String _getTypeLabel(NoticeType type) {
    switch (type) {
      case NoticeType.departmentLevel:
        return 'Department';
      case NoticeType.instituteLevel:
        return 'Institute';
      case NoticeType.universityLevel:
        return 'University';
    }
  }

  Color _getTypeColor(NoticeType type) {
    switch (type) {
      case NoticeType.departmentLevel:
        return const Color(0xFF3182CE);
      case NoticeType.instituteLevel:
        return const Color(0xFF38A169);
      case NoticeType.universityLevel:
        return const Color(0xFFE53E3E);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
