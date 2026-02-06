import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notice_model.dart';
import '../models/attendance_model.dart';
import '../models/course_model.dart';
import '../models/timetable_model.dart';
import '../models/result_model.dart';
import '../models/student_model.dart';
import '../models/staff_model.dart';

/// Database Service for CRUD Operations using Cloud Firestore
/// Implements Create, Read, Update, Delete for all modules
///
/// Firestore Structure: Collection → Document → Fields
/// Benefits: Scalable querying, structured data, fine-grained security rules
class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Singleton pattern
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  // ==================== NOTICE CRUD OPERATIONS ====================
  // Collection: notices

  /// CREATE: Add new notice to database
  Future<bool> createNotice(NoticeModel notice) async {
    try {
      await _firestore
          .collection('notices')
          .doc(notice.noticeId)
          .set(notice.toJson());
      return true;
    } catch (e) {
      print('Error creating notice: $e');
      return false;
    }
  }

  /// READ: Get all notices
  Future<List<NoticeModel>> getAllNotices() async {
    try {
      // Simple query without compound index requirement
      final snapshot = await _firestore.collection('notices').get();

      final notices = snapshot.docs
          .map((doc) => NoticeModel.fromJson(doc.data()))
          .where((n) => n.isActive)
          .toList();

      // Sort by createdAt descending
      notices.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return notices;
    } catch (e) {
      print('Error fetching notices: $e');
      return [];
    }
  }

  /// READ: Get notices for student (by department, type, and studentId for selected students)
  Future<List<NoticeModel>> getNoticesForStudent({
    String? studentId,
    String? departmentId,
    NoticeType? type,
  }) async {
    try {
      final allNotices = await getAllNotices();
      return allNotices.where((notice) {
        // Filter by type if specified
        if (type != null && notice.type != type) {
          return false;
        }
        
        // Use the model's visibility check
        return notice.isVisibleToStudent(studentId ?? '', departmentId);
      }).toList();
    } catch (e) {
      print('Error fetching student notices: $e');
      return [];
    }
  }

  /// READ: Get notices for staff
  Future<List<NoticeModel>> getNoticesForStaff(String staffId) async {
    try {
      final allNotices = await getAllNotices();
      return allNotices.where((notice) {
        return notice.isVisibleToStaff(staffId);
      }).toList();
    } catch (e) {
      print('Error fetching staff notices: $e');
      return [];
    }
  }

  /// UPDATE: Update existing notice
  Future<bool> updateNotice(NoticeModel notice) async {
    try {
      await _firestore
          .collection('notices')
          .doc(notice.noticeId)
          .update(notice.toJson());
      return true;
    } catch (e) {
      print('Error updating notice: $e');
      return false;
    }
  }

  /// DELETE: Delete notice (soft delete - set isActive to false)
  Future<bool> deleteNotice(String noticeId) async {
    try {
      await _firestore.collection('notices').doc(noticeId).update({
        'isActive': false,
      });
      return true;
    } catch (e) {
      print('Error deleting notice: $e');
      return false;
    }
  }

  // ==================== ATTENDANCE CRUD OPERATIONS ====================
  // Collection: attendance

  /// CREATE: Mark attendance for a lecture
  Future<bool> createAttendance(AttendanceModel attendance) async {
    try {
      await _firestore
          .collection('attendance')
          .doc(attendance.attendanceId)
          .set(attendance.toJson());
      return true;
    } catch (e) {
      print('Error creating attendance: $e');
      return false;
    }
  }

  /// READ: Get attendance records by course
  Future<List<AttendanceModel>> getAttendanceByCourse(String courseId) async {
    try {
      final snapshot = await _firestore
          .collection('attendance')
          .where('courseId', isEqualTo: courseId)
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => AttendanceModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Error fetching attendance: $e');
      return [];
    }
  }

  /// READ: Get attendance records by staff
  Future<List<AttendanceModel>> getAttendanceByStaff(String staffId) async {
    try {
      final snapshot = await _firestore
          .collection('attendance')
          .where('staffId', isEqualTo: staffId)
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => AttendanceModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Error fetching staff attendance: $e');
      return [];
    }
  }

  /// READ: Get student attendance summary
  Future<List<StudentAttendanceSummary>> getStudentAttendanceSummary(
    String studentId,
  ) async {
    try {
      final snapshot = await _firestore.collection('attendance').get();
      final attendanceRecords = snapshot.docs
          .map((doc) => AttendanceModel.fromJson(doc.data()))
          .toList();

      // Group by course and calculate attendance
      Map<String, StudentAttendanceSummary> summaryMap = {};
      for (var attendance in attendanceRecords) {
        final studentRecord = attendance.records
            .where((r) => r.studentId == studentId)
            .toList();

        if (studentRecord.isNotEmpty) {
          if (!summaryMap.containsKey(attendance.courseId)) {
            summaryMap[attendance.courseId] = StudentAttendanceSummary(
              courseId: attendance.courseId,
              courseName: attendance.courseName,
              totalClasses: 0,
              attendedClasses: 0,
            );
          }

          final current = summaryMap[attendance.courseId]!;
          summaryMap[attendance.courseId] = StudentAttendanceSummary(
            courseId: current.courseId,
            courseName: current.courseName,
            totalClasses: current.totalClasses + 1,
            attendedClasses:
                current.attendedClasses +
                (studentRecord.first.isPresent ? 1 : 0),
          );
        }
      }
      return summaryMap.values.toList();
    } catch (e) {
      print('Error fetching student attendance summary: $e');
      return [];
    }
  }

  /// UPDATE: Update attendance record
  Future<bool> updateAttendance(AttendanceModel attendance) async {
    try {
      await _firestore
          .collection('attendance')
          .doc(attendance.attendanceId)
          .update(attendance.toJson());
      return true;
    } catch (e) {
      print('Error updating attendance: $e');
      return false;
    }
  }

  /// DELETE: Delete attendance record
  Future<bool> deleteAttendance(String attendanceId) async {
    try {
      await _firestore.collection('attendance').doc(attendanceId).delete();
      return true;
    } catch (e) {
      print('Error deleting attendance: $e');
      return false;
    }
  }

  // ==================== COURSE CRUD OPERATIONS ====================
  // Collection: courses

  /// CREATE: Add new course
  Future<bool> createCourse(CourseModel course) async {
    try {
      await _firestore
          .collection('courses')
          .doc(course.courseId)
          .set(course.toJson());
      return true;
    } catch (e) {
      print('Error creating course: $e');
      return false;
    }
  }

  /// READ: Get all courses
  Future<List<CourseModel>> getAllCourses() async {
    try {
      final snapshot = await _firestore
          .collection('courses')
          .where('isActive', isEqualTo: true)
          .get();

      // Filter out old sample courses (with IDs like 'course_ds', 'course_dbms', etc.)
      return snapshot.docs
          .map((doc) => CourseModel.fromJson(doc.data()))
          .where((course) => !course.courseId.startsWith('course_'))
          .toList();
    } catch (e) {
      print('Error fetching courses: $e');
      return [];
    }
  }

  /// READ: Get courses for student (by semester and department)
  Future<List<CourseModel>> getCoursesForStudent({
    required String departmentId,
    required int semester,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('courses')
          .where('isActive', isEqualTo: true)
          .where('departmentId', isEqualTo: departmentId)
          .where('semester', isEqualTo: semester)
          .get();

        // Filter out old sample courses
        return snapshot.docs
          .map((doc) => CourseModel.fromJson(doc.data()))
          .where((course) => !course.courseId.startsWith('course_'))
          .toList();
    } catch (e) {
      print('Error fetching student courses: $e');
      return [];
    }
  }

  /// READ: Get courses for staff
  Future<List<CourseModel>> getCoursesForStaff(String staffId) async {
    try {
      final snapshot = await _firestore
          .collection('courses')
          .where('isActive', isEqualTo: true)
          .where('staffId', isEqualTo: staffId)
          .get();

      return snapshot.docs
          .map((doc) => CourseModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Error fetching staff courses: $e');
      return [];
    }
  }

  /// UPDATE: Update course
  Future<bool> updateCourse(CourseModel course) async {
    try {
      await _firestore
          .collection('courses')
          .doc(course.courseId)
          .update(course.toJson());
      return true;
    } catch (e) {
      print('Error updating course: $e');
      return false;
    }
  }

  /// DELETE: Delete course (soft delete)
  Future<bool> deleteCourse(String courseId) async {
    try {
      await _firestore.collection('courses').doc(courseId).update({
        'isActive': false,
      });
      return true;
    } catch (e) {
      print('Error deleting course: $e');
      return false;
    }
  }

  // ==================== TIMETABLE CRUD OPERATIONS ====================
  // Collection: timetable

  /// CREATE: Add timetable entry
  Future<bool> createTimetableEntry(TimetableEntry entry) async {
    try {
      await _firestore
          .collection('timetable')
          .doc(entry.entryId)
          .set(entry.toJson());
      return true;
    } catch (e) {
      print('Error creating timetable entry: $e');
      return false;
    }
  }

  /// READ: Get timetable for student
  Future<List<TimetableEntry>> getTimetableForStudent({
    required String departmentId,
    required int semester,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('timetable')
          .where('departmentId', isEqualTo: departmentId)
          .where('semester', isEqualTo: semester)
          .get();

      final entries = snapshot.docs
          .map((doc) => TimetableEntry.fromJson(doc.data()))
          .toList();

      // Sort by day and time
      entries.sort((a, b) {
        int dayCompare = a.day.index.compareTo(b.day.index);
        if (dayCompare != 0) return dayCompare;
        return a.startTime.compareTo(b.startTime);
      });

      return entries;
    } catch (e) {
      print('Error fetching student timetable: $e');
      return [];
    }
  }

  /// READ: Get timetable for staff
  Future<List<TimetableEntry>> getTimetableForStaff(String staffId) async {
    try {
      final snapshot = await _firestore
          .collection('timetable')
          .where('staffId', isEqualTo: staffId)
          .get();

      final entries = snapshot.docs
          .map((doc) => TimetableEntry.fromJson(doc.data()))
          .toList();

      // Sort by day and time
      entries.sort((a, b) {
        int dayCompare = a.day.index.compareTo(b.day.index);
        if (dayCompare != 0) return dayCompare;
        return a.startTime.compareTo(b.startTime);
      });

      return entries;
    } catch (e) {
      print('Error fetching staff timetable: $e');
      return [];
    }
  }

  /// UPDATE: Update timetable entry
  Future<bool> updateTimetableEntry(TimetableEntry entry) async {
    try {
      await _firestore
          .collection('timetable')
          .doc(entry.entryId)
          .update(entry.toJson());
      return true;
    } catch (e) {
      print('Error updating timetable entry: $e');
      return false;
    }
  }

  /// DELETE: Delete timetable entry
  Future<bool> deleteTimetableEntry(String entryId) async {
    try {
      await _firestore.collection('timetable').doc(entryId).delete();
      return true;
    } catch (e) {
      print('Error deleting timetable entry: $e');
      return false;
    }
  }

  // ==================== RESULTS/GRADES CRUD OPERATIONS ====================
  // Collection: results

  /// CREATE: Add result/grade
  Future<bool> createResult(ResultModel result) async {
    try {
      await _firestore
          .collection('results')
          .doc(result.resultId)
          .set(result.toJson());
      return true;
    } catch (e) {
      print('Error creating result: $e');
      return false;
    }
  }

  /// READ: Get results for student
  Future<List<ResultModel>> getResultsForStudent(String studentId) async {
    try {
      final snapshot = await _firestore
          .collection('results')
          .where('studentId', isEqualTo: studentId)
          .orderBy('updatedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ResultModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Error fetching student results: $e');
      return [];
    }
  }

  /// READ: Get results for course (staff view)
  Future<List<ResultModel>> getResultsForCourse(String courseId) async {
    try {
      final snapshot = await _firestore
          .collection('results')
          .where('courseId', isEqualTo: courseId)
          .orderBy('studentName')
          .get();

      return snapshot.docs
          .map((doc) => ResultModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Error fetching course results: $e');
      return [];
    }
  }

  /// UPDATE: Update result/add grades
  Future<bool> updateResult(ResultModel result) async {
    try {
      await _firestore
          .collection('results')
          .doc(result.resultId)
          .update(result.toJson());
      return true;
    } catch (e) {
      print('Error updating result: $e');
      return false;
    }
  }

  /// DELETE: Delete result
  Future<bool> deleteResult(String resultId) async {
    try {
      await _firestore.collection('results').doc(resultId).delete();
      return true;
    } catch (e) {
      print('Error deleting result: $e');
      return false;
    }
  }

  // ==================== STUDENT PROFILE CRUD ====================
  // Collection: students

  /// CREATE: Create student profile
  Future<bool> createStudentProfile(StudentProfile profile) async {
    try {
      await _firestore
          .collection('students')
          .doc(profile.studentId)
          .set(profile.toJson());
      return true;
    } catch (e) {
      print('Error creating student profile: $e');
      return false;
    }
  }

  /// READ: Get student profile by userId
  Future<StudentProfile?> getStudentProfile(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('students')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return StudentProfile.fromJson(snapshot.docs.first.data());
      }
      return null;
    } catch (e) {
      print('Error fetching student profile: $e');
      return null;
    }
  }

  /// READ: Get all students
  Future<List<StudentProfile>> getAllStudents() async {
    try {
      final snapshot = await _firestore
          .collection('students')
          .get();

      print('Found ${snapshot.docs.length} students in Firestore');
      
      final students = snapshot.docs
          .map((doc) => StudentProfile.fromJson(doc.data()))
          .where((s) => s.isActive)
          .toList();
      
      print('Returning ${students.length} active students');
      return students;
    } catch (e) {
      print('Error fetching all students: $e');
      return [];
    }
  }

  /// READ: Get students by course
  Future<List<StudentProfile>> getStudentsByCourse(String courseId) async {
    try {
      final snapshot = await _firestore
          .collection('students')
          .where('isActive', isEqualTo: true)
          .where('enrolledCourseIds', arrayContains: courseId)
          .get();

      return snapshot.docs
          .map((doc) => StudentProfile.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Error fetching students by course: $e');
      return [];
    }
  }

  /// UPDATE: Update student profile
  Future<bool> updateStudentProfile(StudentProfile profile) async {
    try {
      await _firestore
          .collection('students')
          .doc(profile.studentId)
          .update(profile.toJson());
      return true;
    } catch (e) {
      print('Error updating student profile: $e');
      return false;
    }
  }

  /// DELETE: Delete student profile (soft delete)
  Future<bool> deleteStudentProfile(String studentId) async {
    try {
      await _firestore.collection('students').doc(studentId).update({
        'isActive': false,
      });
      return true;
    } catch (e) {
      print('Error deleting student profile: $e');
      return false;
    }
  }

  // ==================== STAFF PROFILE CRUD ====================
  // Collection: staffProfiles

  /// CREATE: Create staff profile
  Future<bool> createStaffProfile(StaffProfile profile) async {
    try {
      await _firestore
          .collection('staffProfiles')
          .doc(profile.staffId)
          .set(profile.toJson());
      return true;
    } catch (e) {
      print('Error creating staff profile: $e');
      return false;
    }
  }

  /// READ: Get staff profile by userId
  Future<StaffProfile?> getStaffProfile(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('staffProfiles')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return StaffProfile.fromJson(snapshot.docs.first.data());
      }
      return null;
    } catch (e) {
      print('Error fetching staff profile: $e');
      return null;
    }
  }

  /// READ: Get all staff
  Future<List<StaffProfile>> getAllStaff() async {
    try {
      // First, get all user IDs with 'staff' role from users collection
      final usersSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'staff')
          .get();

      final staffUserIds = usersSnapshot.docs.map((doc) => doc['id'] as String).toSet();
      print('Found ${staffUserIds.length} staff users in users collection: $staffUserIds');

      // Now fetch only staffProfiles that correspond to these users
      final snapshot = await _firestore
          .collection('staffProfiles')
          .get();

      print('Found ${snapshot.docs.length} staff profiles in Firestore');
      
      final staff = snapshot.docs
          .map((doc) {
            final data = doc.data();
            print('StaffProfile data: userId=${data['userId']}, staffId=${data['staffId']}, fullName=${data['fullName']}');
            return StaffProfile.fromJson(data);
          })
          .where((s) {
            final matches = s.isActive && (staffUserIds.contains(s.userId) || staffUserIds.contains(s.staffId));
            if (!matches) {
              print('Filtering out: ${s.fullName} (userId=${s.userId}, staffId=${s.staffId})');
            }
            return matches;
          })
          .toList();
      
      print('Returning ${staff.length} active staff created by admin');
      return staff;
    } catch (e) {
      print('Error fetching all staff: $e');
      return [];
    }
  }

  /// UPDATE: Update staff profile
  Future<bool> updateStaffProfile(StaffProfile profile) async {
    try {
      await _firestore
          .collection('staffProfiles')
          .doc(profile.staffId)
          .update(profile.toJson());
      return true;
    } catch (e) {
      print('Error updating staff profile: $e');
      return false;
    }
  }

  /// DELETE: Delete staff profile (soft delete)
  Future<bool> deleteStaffProfile(String staffId) async {
    try {
      await _firestore.collection('staffProfiles').doc(staffId).update({
        'isActive': false,
      });
      return true;
    } catch (e) {
      print('Error deleting staff profile: $e');
      return false;
    }
  }

  // ==================== DEPARTMENT CRUD ====================
  // Collection: departments

  /// CREATE: Create department
  Future<bool> createDepartment(DepartmentModel department) async {
    try {
      await _firestore
          .collection('departments')
          .doc(department.departmentId)
          .set(department.toJson());
      return true;
    } catch (e) {
      print('Error creating department: $e');
      return false;
    }
  }

  /// READ: Get all departments
  Future<List<DepartmentModel>> getAllDepartments() async {
    try {
      final snapshot = await _firestore.collection('departments').get();
      return snapshot.docs
          .map((doc) => DepartmentModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Error fetching departments: $e');
      return [];
    }
  }

  // ==================== UTILITY METHODS ====================

  /// Generate unique ID using Firestore
  String generateId() {
    return _firestore.collection('_').doc().id;
  }

  /// Initialize sample data (for testing)
  Future<void> initializeSampleData() async {
    try {
      // Check if departments exist
      final departmentsSnapshot = await _firestore
          .collection('departments')
          .get();
      
      // Only create departments if they don't exist
      if (departmentsSnapshot.docs.isEmpty) {
        // Create sample departments
        final departments = [
          DepartmentModel(
            departmentId: 'dept_cs',
            departmentName: 'Computer Science',
            departmentCode: 'CS',
            instituteId: 'inst_tech',
            instituteName: 'Institute of Technology',
          ),
          DepartmentModel(
            departmentId: 'dept_it',
            departmentName: 'Information Technology',
            departmentCode: 'IT',
            instituteId: 'inst_tech',
            instituteName: 'Institute of Technology',
          ),
          DepartmentModel(
            departmentId: 'dept_ce',
          departmentName: 'Computer Engineering',
          departmentCode: 'CE',
          instituteId: 'inst_tech',
          instituteName: 'Institute of Technology',
        ),
        DepartmentModel(
          departmentId: 'dept_aiml',
          departmentName: 'AI & Machine Learning',
          departmentCode: 'AIML',
          instituteId: 'inst_tech',
          instituteName: 'Institute of Technology',
        ),
      ];

        for (var dept in departments) {
          await createDepartment(dept);
        }
      }

      // Courses are added by admin through the app, not as sample data
      
      // Create sample timetable entries if not exist
      final timetableSnapshot = await _firestore.collection('timetable').get();
      if (timetableSnapshot.docs.isEmpty) {
        final timetableEntries = [
        TimetableEntry(
          entryId: 'tt_1',
          courseId: 'course_ds',
          courseName: 'Data Structures',
          courseCode: 'CS301',
          day: DayOfWeek.monday,
          startTime: '09:00',
          endTime: '10:00',
          room: 'Room 101',
          staffId: '',
          staffName: 'TBA',
          departmentId: 'dept_cs',
          semester: 3,
        ),
        TimetableEntry(
          entryId: 'tt_2',
          courseId: 'course_dbms',
          courseName: 'Database Management',
          courseCode: 'CS302',
          day: DayOfWeek.monday,
          startTime: '11:00',
          endTime: '12:00',
          room: 'Room 102',
          staffId: '',
          staffName: 'TBA',
          departmentId: 'dept_cs',
          semester: 3,
        ),
        TimetableEntry(
          entryId: 'tt_3',
          courseId: 'course_os',
          courseName: 'Operating Systems',
          courseCode: 'CS303',
          day: DayOfWeek.tuesday,
          startTime: '10:00',
          endTime: '11:00',
          room: 'Room 103',
          staffId: '',
          staffName: 'TBA',
          departmentId: 'dept_cs',
          semester: 3,
        ),
      ];

        for (var entry in timetableEntries) {
          await createTimetableEntry(entry);
        }
      }

      // Create sample notices if not exist
      final noticesSnapshot = await _firestore.collection('notices').get();
      if (noticesSnapshot.docs.isEmpty) {
        final notices = [
        NoticeModel(
          noticeId: 'notice_1',
          title: 'Exam Schedule Released',
          description:
              'Final examinations will commence from February 15, 2026. All students are advised to check the detailed schedule on the notice board.',
          type: NoticeType.universityLevel,
          targetAudiences: [TargetAudience.everyone],
          createdBy: 'admin',
          createdByName: 'Admin',
          createdAt: DateTime.now(),
        ),
        NoticeModel(
          noticeId: 'notice_2',
          title: 'Workshop on AI',
          description:
              'Department of Computer Science is organizing a workshop on Artificial Intelligence on February 5, 2026. All CS students are encouraged to participate.',
          type: NoticeType.departmentLevel,
          targetAudiences: [TargetAudience.allStudents],
          departmentId: 'dept_cs',
          createdBy: 'admin',
          createdByName: 'Admin',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        NoticeModel(
          noticeId: 'notice_3',
          title: 'Holiday Notice',
          description:
              'Republic Day holiday on January 26, 2026. College will remain closed.',
          type: NoticeType.instituteLevel,
          targetAudiences: [TargetAudience.everyone],
          createdBy: 'admin',
          createdByName: 'Admin',
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
        ];

        for (var notice in notices) {
          await createNotice(notice);
        }
      }

      // Staff and students are added by admin through the app, not as sample data

      print('Sample data initialized successfully in Firestore');
    } catch (e) {
      print('Error initializing sample data: $e');
    }
  }

  /// CREATE STAFF PROFILES FOR EXISTING STAFF USERS (Migration Helper)
  Future<void> createStaffProfilesForExistingStaff() async {
    try {
      print('Starting migration of existing staff users to staff profiles...');
      
      // Get all users with staff role
      final usersSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'staff')
          .get();

      print('Found ${usersSnapshot.docs.length} staff users');

      for (var userDoc in usersSnapshot.docs) {
        final userData = userDoc.data();
        final userId = userData['id'] as String;
        final fullName = userData['fullName'] ?? 'Staff Member';
        final email = userData['email'] ?? '';
        final department = userData['department'] ?? 'unknown';

        // Check if staff profile already exists for this user
        final existingProfile = await _firestore
            .collection('staffProfiles')
            .where('userId', isEqualTo: userId)
            .limit(1)
            .get();

        if (existingProfile.docs.isEmpty) {
          // Create staff profile
          await _firestore.collection('staffProfiles').add({
            'staffId': userId,
            'userId': userId,
            'fullName': fullName,
            'email': email,
            'employeeId': 'EMP_${userId.substring(0, 8).toUpperCase()}',
            'departmentId': department,
            'departmentName': _getDepartmentDisplayName(department),
            'designation': 'Staff',
            'assignedCourseIds': [],
            'joiningDate': DateTime.now().toIso8601String(),
            'isActive': true,
            'createdAt': FieldValue.serverTimestamp(),
          });
          print('Created staff profile for: $fullName ($userId)');
        }
      }

      print('Migration complete!');
    } catch (e) {
      print('Error creating staff profiles: $e');
    }
  }

  String _getDepartmentDisplayName(String departmentCode) {
    switch (departmentCode) {
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
}


