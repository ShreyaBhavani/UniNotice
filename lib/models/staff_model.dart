/// Staff Model for CRUD Operations
/// Database Schema:
/// Collection: staff
/// Fields: staffId, userId, employeeId, departmentId, assignedCourses
library;

class StaffProfile {
  final String staffId;
  final String userId;
  final String fullName;
  final String email;
  final String employeeId;
  final String departmentId;
  final String departmentName;
  final String designation;
  final List<String> assignedCourseIds;
  final DateTime joiningDate;
  final bool isActive;

  StaffProfile({
    required this.staffId,
    required this.userId,
    required this.fullName,
    required this.email,
    required this.employeeId,
    required this.departmentId,
    required this.departmentName,
    required this.designation,
    required this.assignedCourseIds,
    required this.joiningDate,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() => {
    'staffId': staffId,
    'userId': userId,
    'fullName': fullName,
    'email': email,
    'employeeId': employeeId,
    'departmentId': departmentId,
    'departmentName': departmentName,
    'designation': designation,
    'assignedCourseIds': assignedCourseIds,
    'joiningDate': joiningDate.toIso8601String(),
    'isActive': isActive,
  };

  factory StaffProfile.fromJson(Map<String, dynamic> json) => StaffProfile(
    staffId: json['staffId'] ?? '',
    userId: json['userId'] ?? '',
    fullName: json['fullName'] ?? '',
    email: json['email'] ?? '',
    employeeId: json['employeeId'] ?? '',
    departmentId: json['departmentId'] ?? '',
    departmentName: json['departmentName'] ?? '',
    designation: json['designation'] ?? '',
    assignedCourseIds: json['assignedCourseIds'] != null 
        ? List<String>.from(json['assignedCourseIds']) 
        : [],
    joiningDate: json['joiningDate'] != null 
        ? DateTime.parse(json['joiningDate']) 
        : DateTime.now(),
    isActive: json['isActive'] ?? true,
  );

  StaffProfile copyWith({
    String? staffId,
    String? userId,
    String? fullName,
    String? email,
    String? employeeId,
    String? departmentId,
    String? departmentName,
    String? designation,
    List<String>? assignedCourseIds,
    DateTime? joiningDate,
    bool? isActive,
  }) {
    return StaffProfile(
      staffId: staffId ?? this.staffId,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      employeeId: employeeId ?? this.employeeId,
      departmentId: departmentId ?? this.departmentId,
      departmentName: departmentName ?? this.departmentName,
      designation: designation ?? this.designation,
      assignedCourseIds: assignedCourseIds ?? this.assignedCourseIds,
      joiningDate: joiningDate ?? this.joiningDate,
      isActive: isActive ?? this.isActive,
    );
  }
}
