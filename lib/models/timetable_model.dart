/// Timetable Model for CRUD Operations
/// Database Schema:
/// Collection: timetable
/// Fields: timetableId, courseId, day, startTime, endTime, room, staffId
library;

enum DayOfWeek {
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
  sunday,
}

class TimetableEntry {
  final String entryId;
  final String courseId;
  final String courseName;
  final String courseCode;
  final DayOfWeek day;
  final String startTime;
  final String endTime;
  final String room;
  final String staffId;
  final String staffName;
  final String departmentId;
  final int semester;

  TimetableEntry({
    required this.entryId,
    required this.courseId,
    required this.courseName,
    required this.courseCode,
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.room,
    required this.staffId,
    required this.staffName,
    required this.departmentId,
    required this.semester,
  });

  Map<String, dynamic> toJson() => {
    'entryId': entryId,
    'courseId': courseId,
    'courseName': courseName,
    'courseCode': courseCode,
    'day': day.name,
    'startTime': startTime,
    'endTime': endTime,
    'room': room,
    'staffId': staffId,
    'staffName': staffName,
    'departmentId': departmentId,
    'semester': semester,
  };

  factory TimetableEntry.fromJson(Map<String, dynamic> json) => TimetableEntry(
    entryId: json['entryId'] ?? '',
    courseId: json['courseId'] ?? '',
    courseName: json['courseName'] ?? '',
    courseCode: json['courseCode'] ?? '',
    day: DayOfWeek.values.firstWhere(
      (d) => d.name == json['day'],
      orElse: () => DayOfWeek.monday,
    ),
    startTime: json['startTime'] ?? '',
    endTime: json['endTime'] ?? '',
    room: json['room'] ?? '',
    staffId: json['staffId'] ?? '',
    staffName: json['staffName'] ?? '',
    departmentId: json['departmentId'] ?? '',
    semester: json['semester'] ?? 1,
  );

  String get dayLabel {
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

  String get timeSlot => '$startTime - $endTime';
}
