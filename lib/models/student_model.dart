/// Extended Student Model for CRUD Operations
/// Database Schema:
/// Collection: students
/// Fields: studentId, userId, rollNumber, departmentId, semester, enrolledCourses
library;

class StudentProfile {
  final String studentId;
  final String userId;
  final String fullName;
  final String email;
  final String rollNumber;
  final String departmentId;
  final String departmentName;
  final int currentSemester;
  final List<String> enrolledCourseIds;
  final DateTime enrollmentDate;
  final bool isActive;

  StudentProfile({
    required this.studentId,
    required this.userId,
    required this.fullName,
    required this.email,
    required this.rollNumber,
    required this.departmentId,
    required this.departmentName,
    required this.currentSemester,
    required this.enrolledCourseIds,
    required this.enrollmentDate,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() => {
    'studentId': studentId,
    'userId': userId,
    'fullName': fullName,
    'email': email,
    'rollNumber': rollNumber,
    'departmentId': departmentId,
    'departmentName': departmentName,
    'currentSemester': currentSemester,
    'enrolledCourseIds': enrolledCourseIds,
    'enrollmentDate': enrollmentDate.toIso8601String(),
    'isActive': isActive,
  };

  factory StudentProfile.fromJson(Map<String, dynamic> json) => StudentProfile(
    studentId: json['studentId'] ?? '',
    userId: json['userId'] ?? '',
    fullName: json['fullName'] ?? '',
    email: json['email'] ?? '',
    rollNumber: json['rollNumber'] ?? '',
    departmentId: json['departmentId'] ?? '',
    departmentName: json['departmentName'] ?? '',
    currentSemester: json['currentSemester'] ?? 1,
    enrolledCourseIds: json['enrolledCourseIds'] != null 
        ? List<String>.from(json['enrolledCourseIds']) 
        : [],
    enrollmentDate: json['enrollmentDate'] != null 
        ? DateTime.parse(json['enrollmentDate']) 
        : DateTime.now(),
    isActive: json['isActive'] ?? true,
  );

  StudentProfile copyWith({
    String? studentId,
    String? userId,
    String? fullName,
    String? email,
    String? rollNumber,
    String? departmentId,
    String? departmentName,
    int? currentSemester,
    List<String>? enrolledCourseIds,
    DateTime? enrollmentDate,
    bool? isActive,
  }) {
    return StudentProfile(
      studentId: studentId ?? this.studentId,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      rollNumber: rollNumber ?? this.rollNumber,
      departmentId: departmentId ?? this.departmentId,
      departmentName: departmentName ?? this.departmentName,
      currentSemester: currentSemester ?? this.currentSemester,
      enrolledCourseIds: enrolledCourseIds ?? this.enrolledCourseIds,
      enrollmentDate: enrollmentDate ?? this.enrollmentDate,
      isActive: isActive ?? this.isActive,
    );
  }
}

/// Department Model
class DepartmentModel {
  final String departmentId;
  final String departmentName;
  final String departmentCode;
  final String instituteId;
  final String instituteName;

  DepartmentModel({
    required this.departmentId,
    required this.departmentName,
    required this.departmentCode,
    required this.instituteId,
    required this.instituteName,
  });

  Map<String, dynamic> toJson() => {
    'departmentId': departmentId,
    'departmentName': departmentName,
    'departmentCode': departmentCode,
    'instituteId': instituteId,
    'instituteName': instituteName,
  };

  factory DepartmentModel.fromJson(Map<String, dynamic> json) => DepartmentModel(
    departmentId: json['departmentId'] ?? '',
    departmentName: json['departmentName'] ?? '',
    departmentCode: json['departmentCode'] ?? '',
    instituteId: json['instituteId'] ?? '',
    instituteName: json['instituteName'] ?? '',
  );
}
