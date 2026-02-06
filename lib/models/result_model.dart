/// Result/Grades Model for CRUD Operations
/// Database Schema:
/// Collection: results
/// Fields: resultId, studentId, courseId, semester, assignments, exams, finalGrade
library;

class AssignmentGrade {
  final String assignmentId;
  final String assignmentName;
  final double maxMarks;
  final double obtainedMarks;
  final DateTime submittedAt;
  final String? feedback;

  AssignmentGrade({
    required this.assignmentId,
    required this.assignmentName,
    required this.maxMarks,
    required this.obtainedMarks,
    required this.submittedAt,
    this.feedback,
  });

  Map<String, dynamic> toJson() => {
    'assignmentId': assignmentId,
    'assignmentName': assignmentName,
    'maxMarks': maxMarks,
    'obtainedMarks': obtainedMarks,
    'submittedAt': submittedAt.toIso8601String(),
    'feedback': feedback,
  };

  factory AssignmentGrade.fromJson(Map<String, dynamic> json) => AssignmentGrade(
    assignmentId: json['assignmentId'] ?? '',
    assignmentName: json['assignmentName'] ?? '',
    maxMarks: (json['maxMarks'] ?? 0).toDouble(),
    obtainedMarks: (json['obtainedMarks'] ?? 0).toDouble(),
    submittedAt: json['submittedAt'] != null 
        ? DateTime.parse(json['submittedAt']) 
        : DateTime.now(),
    feedback: json['feedback'],
  );

  double get percentage => maxMarks == 0 ? 0 : (obtainedMarks / maxMarks) * 100;
}

class ExamResult {
  final String examId;
  final String examName;
  final String examType; // midterm, final, quiz
  final double maxMarks;
  final double obtainedMarks;
  final DateTime examDate;

  ExamResult({
    required this.examId,
    required this.examName,
    required this.examType,
    required this.maxMarks,
    required this.obtainedMarks,
    required this.examDate,
  });

  Map<String, dynamic> toJson() => {
    'examId': examId,
    'examName': examName,
    'examType': examType,
    'maxMarks': maxMarks,
    'obtainedMarks': obtainedMarks,
    'examDate': examDate.toIso8601String(),
  };

  factory ExamResult.fromJson(Map<String, dynamic> json) => ExamResult(
    examId: json['examId'] ?? '',
    examName: json['examName'] ?? '',
    examType: json['examType'] ?? 'exam',
    maxMarks: (json['maxMarks'] ?? 0).toDouble(),
    obtainedMarks: (json['obtainedMarks'] ?? 0).toDouble(),
    examDate: json['examDate'] != null 
        ? DateTime.parse(json['examDate']) 
        : DateTime.now(),
  );

  double get percentage => maxMarks == 0 ? 0 : (obtainedMarks / maxMarks) * 100;
}

class ResultModel {
  final String resultId;
  final String studentId;
  final String studentName;
  final String courseId;
  final String courseName;
  final String courseCode;
  final int semester;
  final List<AssignmentGrade> assignments;
  final List<ExamResult> exams;
  final String? finalGrade;
  final double? cgpa;
  final DateTime updatedAt;

  ResultModel({
    required this.resultId,
    required this.studentId,
    required this.studentName,
    required this.courseId,
    required this.courseName,
    required this.courseCode,
    required this.semester,
    required this.assignments,
    required this.exams,
    this.finalGrade,
    this.cgpa,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'resultId': resultId,
    'studentId': studentId,
    'studentName': studentName,
    'courseId': courseId,
    'courseName': courseName,
    'courseCode': courseCode,
    'semester': semester,
    'assignments': assignments.map((a) => a.toJson()).toList(),
    'exams': exams.map((e) => e.toJson()).toList(),
    'finalGrade': finalGrade,
    'cgpa': cgpa,
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory ResultModel.fromJson(Map<String, dynamic> json) => ResultModel(
    resultId: json['resultId'] ?? '',
    studentId: json['studentId'] ?? '',
    studentName: json['studentName'] ?? '',
    courseId: json['courseId'] ?? '',
    courseName: json['courseName'] ?? '',
    courseCode: json['courseCode'] ?? '',
    semester: json['semester'] ?? 1,
    assignments: json['assignments'] != null
        ? (json['assignments'] as List).map((a) => AssignmentGrade.fromJson(a)).toList()
        : [],
    exams: json['exams'] != null
        ? (json['exams'] as List).map((e) => ExamResult.fromJson(e)).toList()
        : [],
    finalGrade: json['finalGrade'],
    cgpa: json['cgpa']?.toDouble(),
    updatedAt: json['updatedAt'] != null 
        ? DateTime.parse(json['updatedAt']) 
        : DateTime.now(),
  );

  double get totalAssignmentMarks => 
      assignments.fold(0, (sum, a) => sum + a.obtainedMarks);
  double get maxAssignmentMarks => 
      assignments.fold(0, (sum, a) => sum + a.maxMarks);
  double get totalExamMarks => 
      exams.fold(0, (sum, e) => sum + e.obtainedMarks);
  double get maxExamMarks => 
      exams.fold(0, (sum, e) => sum + e.maxMarks);
  
  double get overallPercentage {
    double totalObtained = totalAssignmentMarks + totalExamMarks;
    double totalMax = maxAssignmentMarks + maxExamMarks;
    return totalMax == 0 ? 0 : (totalObtained / totalMax) * 100;
  }
}
