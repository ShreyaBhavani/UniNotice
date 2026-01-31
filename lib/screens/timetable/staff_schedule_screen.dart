import 'package:flutter/material.dart';
import '../../models/timetable_model.dart';
import '../../services/database_service.dart';

/// Staff Schedule Screen - READ Operation
class StaffScheduleScreen extends StatefulWidget {
  final String? staffId;

  const StaffScheduleScreen({super.key, this.staffId});

  @override
  State<StaffScheduleScreen> createState() => _StaffScheduleScreenState();
}

class _StaffScheduleScreenState extends State<StaffScheduleScreen>
    with SingleTickerProviderStateMixin {
  final _dbService = DatabaseService();
  late TabController _tabController;
  
  List<TimetableEntry> _allEntries = [];
  Map<DayOfWeek, List<TimetableEntry>> _groupedEntries = {};
  bool _isLoading = true;

  final List<DayOfWeek> _weekDays = [
    DayOfWeek.monday,
    DayOfWeek.tuesday,
    DayOfWeek.wednesday,
    DayOfWeek.thursday,
    DayOfWeek.friday,
    DayOfWeek.saturday,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _weekDays.length, vsync: this);
    final today = DateTime.now().weekday - 1;
    if (today < _weekDays.length) {
      _tabController.index = today;
    }
    _loadSchedule();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSchedule() async {
    setState(() => _isLoading = true);
    try {
      final staffId = widget.staffId ?? 'demo_staff';
      var entries = await _dbService.getTimetableForStaff(staffId);

      // Use demo data if empty
      if (entries.isEmpty) {
        entries = _createDemoSchedule();
      }

      Map<DayOfWeek, List<TimetableEntry>> grouped = {};
      for (var day in _weekDays) {
        grouped[day] = entries.where((e) => e.day == day).toList()
          ..sort((a, b) => a.startTime.compareTo(b.startTime));
      }

      setState(() {
        _allEntries = entries;
        _groupedEntries = grouped;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  List<TimetableEntry> _createDemoSchedule() {
    final staffId = widget.staffId ?? 'demo_staff';
    
    return [
      TimetableEntry(
        entryId: 'staff_tt_1',
        courseId: 'course_ds',
        courseName: 'Data Structures',
        courseCode: 'CS301',
        day: DayOfWeek.monday,
        startTime: '09:00',
        endTime: '10:00',
        room: 'Room 101',
        staffId: staffId,
        staffName: 'Staff',
        departmentId: 'dept_cs',
        semester: 3,
      ),
      TimetableEntry(
        entryId: 'staff_tt_2',
        courseId: 'course_ds',
        courseName: 'Data Structures',
        courseCode: 'CS301',
        day: DayOfWeek.wednesday,
        startTime: '11:00',
        endTime: '12:00',
        room: 'Room 101',
        staffId: staffId,
        staffName: 'Staff',
        departmentId: 'dept_cs',
        semester: 3,
      ),
      TimetableEntry(
        entryId: 'staff_tt_3',
        courseId: 'course_ds',
        courseName: 'DS Lab',
        courseCode: 'CS301L',
        day: DayOfWeek.thursday,
        startTime: '14:00',
        endTime: '16:00',
        room: 'Lab 1',
        staffId: staffId,
        staffName: 'Staff',
        departmentId: 'dept_cs',
        semester: 3,
      ),
      TimetableEntry(
        entryId: 'staff_tt_4',
        courseId: 'course_algo',
        courseName: 'Algorithm Design',
        courseCode: 'CS401',
        day: DayOfWeek.tuesday,
        startTime: '10:00',
        endTime: '11:00',
        room: 'Room 205',
        staffId: staffId,
        staffName: 'Staff',
        departmentId: 'dept_cs',
        semester: 4,
      ),
      TimetableEntry(
        entryId: 'staff_tt_5',
        courseId: 'course_algo',
        courseName: 'Algorithm Design',
        courseCode: 'CS401',
        day: DayOfWeek.friday,
        startTime: '09:00',
        endTime: '10:00',
        room: 'Room 205',
        staffId: staffId,
        staffName: 'Staff',
        departmentId: 'dept_cs',
        semester: 4,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    // Calculate summary
    int totalClasses = _allEntries.length;
    int todayClasses = _groupedEntries[_weekDays[DateTime.now().weekday - 1]]?.length ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFE8EDF5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF38A169)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Schedule',
          style: TextStyle(color: Color(0xFF2D3748), fontWeight: FontWeight.bold),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              // Summary Cards
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF38A169).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '$todayClasses',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF38A169),
                              ),
                            ),
                            const Text('Today', style: TextStyle(fontSize: 12, color: Color(0xFF38A169))),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3182CE).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '$totalClasses',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF3182CE),
                              ),
                            ),
                            const Text('Weekly', style: TextStyle(fontSize: 12, color: Color(0xFF3182CE))),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: const Color(0xFF38A169),
                unselectedLabelColor: Colors.grey,
                indicatorColor: const Color(0xFF38A169),
                tabs: _weekDays.map((day) => Tab(text: _getDayShort(day))).toList(),
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF38A169)))
          : TabBarView(
              controller: _tabController,
              children: _weekDays.map((day) => _buildDaySchedule(day)).toList(),
            ),
    );
  }

  Widget _buildDaySchedule(DayOfWeek day) {
    final entries = _groupedEntries[day] ?? [];

    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_available, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No classes on ${_getDayLabel(day)}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      itemBuilder: (context, index) => _buildClassCard(entries[index], index),
    );
  }

  Widget _buildClassCard(TimetableEntry entry, int index) {
    final colors = [
      const Color(0xFF38A169),
      const Color(0xFF3182CE),
      const Color(0xFFD69E2E),
      const Color(0xFF805AD5),
    ];
    final color = colors[index % colors.length];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.class_, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.courseName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          entry.courseCode,
                          style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Sem ${entry.semester}',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        entry.timeSlot,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.location_on, size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        entry.room,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDayShort(DayOfWeek day) {
    switch (day) {
      case DayOfWeek.monday: return 'Mon';
      case DayOfWeek.tuesday: return 'Tue';
      case DayOfWeek.wednesday: return 'Wed';
      case DayOfWeek.thursday: return 'Thu';
      case DayOfWeek.friday: return 'Fri';
      case DayOfWeek.saturday: return 'Sat';
      case DayOfWeek.sunday: return 'Sun';
    }
  }

  String _getDayLabel(DayOfWeek day) {
    switch (day) {
      case DayOfWeek.monday: return 'Monday';
      case DayOfWeek.tuesday: return 'Tuesday';
      case DayOfWeek.wednesday: return 'Wednesday';
      case DayOfWeek.thursday: return 'Thursday';
      case DayOfWeek.friday: return 'Friday';
      case DayOfWeek.saturday: return 'Saturday';
      case DayOfWeek.sunday: return 'Sunday';
    }
  }
}
