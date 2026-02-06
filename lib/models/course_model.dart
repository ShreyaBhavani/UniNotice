/// Course Model for CRUD Operations
/// Database Schema:
/// Collection: courses
/// Fields: courseId, courseName, courseCode, semester, departmentId, 
///         staffId, credits, description
library;

class CourseModel {
  final String courseId;
  final String courseName;
  final String courseCode;
  final int semester;
  final String departmentId;
  final String departmentName;
  final String staffId;
  final String staffName;
  final int credits;
  final String description;
  final List<String> enrolledStudents;
  final bool isActive;
  final DateTime createdAt;

  CourseModel({
    required this.courseId,
    required this.courseName,
    required this.courseCode,
    required this.semester,
    required this.departmentId,
    required this.departmentName,
    required this.staffId,
    required this.staffName,
    required this.credits,
    required this.description,
    required this.enrolledStudents,
    this.isActive = true,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'courseId': courseId,
    'courseName': courseName,
    'courseCode': courseCode,
    'semester': semester,
    'departmentId': departmentId,
    'departmentName': departmentName,
    'staffId': staffId,
    'staffName': staffName,
    'credits': credits,
    'description': description,
    'enrolledStudents': enrolledStudents,
    'isActive': isActive,
    'createdAt': createdAt.toIso8601String(),
  };

  factory CourseModel.fromJson(Map<String, dynamic> json) => CourseModel(
    courseId: json['courseId'] ?? '',
    courseName: json['courseName'] ?? '',
    courseCode: json['courseCode'] ?? '',
    semester: json['semester'] ?? 1,
    departmentId: json['departmentId'] ?? '',
    departmentName: json['departmentName'] ?? '',
    staffId: json['staffId'] ?? '',
    staffName: json['staffName'] ?? '',
    credits: json['credits'] ?? 0,
    description: json['description'] ?? '',
    enrolledStudents: json['enrolledStudents'] != null 
        ? List<String>.from(json['enrolledStudents']) 
        : [],
    isActive: json['isActive'] ?? true,
    createdAt: json['createdAt'] != null 
        ? DateTime.parse(json['createdAt']) 
        : DateTime.now(),
  );

  CourseModel copyWith({
    String? courseId,
    String? courseName,
    String? courseCode,
    int? semester,
    String? departmentId,
    String? departmentName,
    String? staffId,
    String? staffName,
    int? credits,
    String? description,
    List<String>? enrolledStudents,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return CourseModel(
      courseId: courseId ?? this.courseId,
      courseName: courseName ?? this.courseName,
      courseCode: courseCode ?? this.courseCode,
      semester: semester ?? this.semester,
      departmentId: departmentId ?? this.departmentId,
      departmentName: departmentName ?? this.departmentName,
      staffId: staffId ?? this.staffId,
      staffName: staffName ?? this.staffName,
      credits: credits ?? this.credits,
      description: description ?? this.description,
      enrolledStudents: enrolledStudents ?? this.enrolledStudents,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
