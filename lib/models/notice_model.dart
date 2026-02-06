/// Notice Model for CRUD Operations
/// Database Schema:
/// Collection: notices
/// Fields: noticeId, title, description, type, targetAudiences, 
///         departmentId, createdBy, createdAt, isActive, selectedStaffIds, selectedStudentIds
library;

enum NoticeType {
  departmentLevel,
  instituteLevel,
  universityLevel,
}

enum TargetAudience {
  allStudents,
  selectedStudents,
  allStaff,
  selectedStaff,
  everyone,
}

class NoticeModel {
  final String noticeId;
  final String title;
  final String description;
  final NoticeType type;
  final List<TargetAudience> targetAudiences; // Changed to List for multi-selection
  final String? departmentId;
  final String createdBy;
  final String createdByName;
  final DateTime createdAt;
  final bool isActive;
  final List<String>? selectedStaffIds;
  final List<String>? selectedStudentIds; // New field for selected students

  NoticeModel({
    required this.noticeId,
    required this.title,
    required this.description,
    required this.type,
    required this.targetAudiences,
    this.departmentId,
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
    this.isActive = true,
    this.selectedStaffIds,
    this.selectedStudentIds,
  });

  Map<String, dynamic> toJson() => {
    'noticeId': noticeId,
    'title': title,
    'description': description,
    'type': type.name,
    'targetAudiences': targetAudiences.map((a) => a.name).toList(),
    'departmentId': departmentId,
    'createdBy': createdBy,
    'createdByName': createdByName,
    'createdAt': createdAt.toIso8601String(),
    'isActive': isActive,
    'selectedStaffIds': selectedStaffIds,
    'selectedStudentIds': selectedStudentIds,
  };

  factory NoticeModel.fromJson(Map<String, dynamic> json) {
    // Handle both old single targetAudience and new targetAudiences list
    List<TargetAudience> audiences = [];
    if (json['targetAudiences'] != null) {
      audiences = (json['targetAudiences'] as List).map((a) {
        return TargetAudience.values.firstWhere(
          (t) => t.name == a,
          orElse: () => TargetAudience.allStudents,
        );
      }).toList();
    } else if (json['targetAudience'] != null) {
      // Backward compatibility with old data
      final oldAudience = json['targetAudience'] as String;
      switch (oldAudience) {
        case 'students':
          audiences = [TargetAudience.allStudents];
          break;
        case 'staff':
          audiences = [TargetAudience.allStaff];
          break;
        case 'selectedStaff':
          audiences = [TargetAudience.selectedStaff];
          break;
        case 'all':
          audiences = [TargetAudience.everyone];
          break;
        default:
          audiences = [TargetAudience.allStudents];
      }
    }
    
    return NoticeModel(
      noticeId: json['noticeId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      type: NoticeType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => NoticeType.departmentLevel,
      ),
      targetAudiences: audiences.isEmpty ? [TargetAudience.allStudents] : audiences,
      departmentId: json['departmentId'],
      createdBy: json['createdBy'] ?? '',
      createdByName: json['createdByName'] ?? 'Unknown',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      isActive: json['isActive'] ?? true,
      selectedStaffIds: json['selectedStaffIds'] != null 
          ? List<String>.from(json['selectedStaffIds']) 
          : null,
      selectedStudentIds: json['selectedStudentIds'] != null 
          ? List<String>.from(json['selectedStudentIds']) 
          : null,
    );
  }

  NoticeModel copyWith({
    String? noticeId,
    String? title,
    String? description,
    NoticeType? type,
    List<TargetAudience>? targetAudiences,
    String? departmentId,
    String? createdBy,
    String? createdByName,
    DateTime? createdAt,
    bool? isActive,
    List<String>? selectedStaffIds,
    List<String>? selectedStudentIds,
  }) {
    return NoticeModel(
      noticeId: noticeId ?? this.noticeId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      targetAudiences: targetAudiences ?? this.targetAudiences,
      departmentId: departmentId ?? this.departmentId,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      selectedStaffIds: selectedStaffIds ?? this.selectedStaffIds,
      selectedStudentIds: selectedStudentIds ?? this.selectedStudentIds,
    );
  }

  String get typeLabel {
    switch (type) {
      case NoticeType.departmentLevel:
        return 'Department';
      case NoticeType.instituteLevel:
        return 'Institute';
      case NoticeType.universityLevel:
        return 'University';
    }
  }

  String get audienceLabel {
    if (targetAudiences.contains(TargetAudience.everyone)) {
      return 'Everyone';
    }
    final labels = <String>[];
    if (targetAudiences.contains(TargetAudience.allStudents)) {
      labels.add('All Students');
    }
    if (targetAudiences.contains(TargetAudience.selectedStudents)) {
      labels.add('Selected Students');
    }
    if (targetAudiences.contains(TargetAudience.allStaff)) {
      labels.add('All Staff');
    }
    if (targetAudiences.contains(TargetAudience.selectedStaff)) {
      labels.add('Selected Staff');
    }
    return labels.isEmpty ? 'None' : labels.join(', ');
  }
  
  /// Check if this notice should be visible to a specific staff member
  bool isVisibleToStaff(String staffId) {
    if (targetAudiences.contains(TargetAudience.everyone)) return true;
    if (targetAudiences.contains(TargetAudience.allStaff)) return true;
    if (targetAudiences.contains(TargetAudience.selectedStaff)) {
      return selectedStaffIds?.contains(staffId) ?? false;
    }
    return false;
  }
  
  /// Check if this notice should be visible to a specific student
  bool isVisibleToStudent(String studentId, String? studentDepartmentId) {
    if (targetAudiences.contains(TargetAudience.everyone)) return true;
    if (targetAudiences.contains(TargetAudience.allStudents)) {
      // For department-level notices, check department match
      if (type == NoticeType.departmentLevel && departmentId != null) {
        return studentDepartmentId == departmentId;
      }
      return true;
    }
    if (targetAudiences.contains(TargetAudience.selectedStudents)) {
      return selectedStudentIds?.contains(studentId) ?? false;
    }
    return false;
  }
}
