/// Attendance Model for CRUD Operations
/// Database Schema:
/// Collection: attendance
/// Fields: attendanceId, courseId, date, staffId, records
library;

class AttendanceRecord {
  final String studentId;
  final String studentName;
  final bool isPresent;

  AttendanceRecord({
    required this.studentId,
    required this.studentName,
    required this.isPresent,
  });

  Map<String, dynamic> toJson() => {
    'studentId': studentId,
    'studentName': studentName,
    'isPresent': isPresent,
  };

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) => AttendanceRecord(
    studentId: json['studentId'] ?? '',
    studentName: json['studentName'] ?? '',
    isPresent: json['isPresent'] ?? false,
  );
}

class AttendanceModel {
  final String attendanceId;
  final String courseId;
  final String courseName;
  final String staffId;
  final String staffName;
  final DateTime date;
  final String lectureTime;
  final List<AttendanceRecord> records;
  final DateTime createdAt;

  AttendanceModel({
    required this.attendanceId,
    required this.courseId,
    required this.courseName,
    required this.staffId,
    required this.staffName,
    required this.date,
    required this.lectureTime,
    required this.records,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'attendanceId': attendanceId,
    'courseId': courseId,
    'courseName': courseName,
    'staffId': staffId,
    'staffName': staffName,
    'date': date.toIso8601String(),
    'lectureTime': lectureTime,
    'records': records.map((r) => r.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
  };

  factory AttendanceModel.fromJson(Map<String, dynamic> json) => AttendanceModel(
    attendanceId: json['attendanceId'] ?? '',
    courseId: json['courseId'] ?? '',
    courseName: json['courseName'] ?? '',
    staffId: json['staffId'] ?? '',
    staffName: json['staffName'] ?? '',
    date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
    lectureTime: json['lectureTime'] ?? '',
    records: json['records'] != null
        ? (json['records'] as List).map((r) => AttendanceRecord.fromJson(r)).toList()
        : [],
    createdAt: json['createdAt'] != null 
        ? DateTime.parse(json['createdAt']) 
        : DateTime.now(),
  );

  int get presentCount => records.where((r) => r.isPresent).length;
  int get absentCount => records.where((r) => !r.isPresent).length;
  double get attendancePercentage => 
      records.isEmpty ? 0 : (presentCount / records.length) * 100;
}

/// Student Attendance Summary
class StudentAttendanceSummary {
  final String courseId;
  final String courseName;
  final int totalClasses;
  final int attendedClasses;

  StudentAttendanceSummary({
    required this.courseId,
    required this.courseName,
    required this.totalClasses,
    required this.attendedClasses,
  });

  double get percentage => totalClasses == 0 ? 0 : (attendedClasses / totalClasses) * 100;
}
