import 'package:flutter/material.dart';
import '../../models/notice_model.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import 'notice_detail_screen.dart';

/// Student Notice List Screen - READ Operation
/// Displays notices for students filtered by department, institute, and university level
/// Only shows notices targeted to the logged-in student
class StudentNoticeListScreen extends StatefulWidget {
  final String? studentId;
  final String? departmentId;
  final String? departmentName;

  const StudentNoticeListScreen({
    super.key,
    this.studentId,
    this.departmentId,
    this.departmentName,
  });

  @override
  State<StudentNoticeListScreen> createState() => _StudentNoticeListScreenState();
}

class _StudentNoticeListScreenState extends State<StudentNoticeListScreen>
    with SingleTickerProviderStateMixin {
  final _dbService = DatabaseService();
  final _authService = AuthService();
  late TabController _tabController;
  
  String? _currentStudentId;
  // ignore: unused_field
  List<NoticeModel> _allNotices = [];
  List<NoticeModel> _departmentNotices = [];
  List<NoticeModel> _instituteNotices = [];
  List<NoticeModel> _universityNotices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _currentStudentId = widget.studentId;
    _loadNotices();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadNotices() async {
    setState(() => _isLoading = true);
    try {
      // Get current user if studentId not provided
      if (_currentStudentId == null) {
        final user = await _authService.getCurrentUser();
        _currentStudentId = user?.id;
      }
      
      final notices = await _dbService.getNoticesForStudent(
        studentId: _currentStudentId,
        departmentId: widget.departmentId,
      );
      
      setState(() {
        _allNotices = notices;
        _departmentNotices = notices.where((n) => n.type == NoticeType.departmentLevel).toList();
        _instituteNotices = notices.where((n) => n.type == NoticeType.instituteLevel).toList();
        _universityNotices = notices.where((n) => n.type == NoticeType.universityLevel).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Error loading notices', Colors.red);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8EDF5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF3182CE)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notices',
          style: TextStyle(color: Color(0xFF2D3748), fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF3182CE),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF3182CE),
          tabs: [
            Tab(text: 'Department (${_departmentNotices.length})'),
            Tab(text: 'Institute (${_instituteNotices.length})'),
            Tab(text: 'University (${_universityNotices.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF3182CE)))
          : RefreshIndicator(
              onRefresh: _loadNotices,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildNoticeList(_departmentNotices, 'No department notices'),
                  _buildNoticeList(_instituteNotices, 'No institute notices'),
                  _buildNoticeList(_universityNotices, 'No university notices'),
                ],
              ),
            ),
    );
  }

  Widget _buildNoticeList(List<NoticeModel> notices, String emptyMessage) {
    if (notices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(emptyMessage, style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: notices.length,
      itemBuilder: (context, index) => _buildNoticeCard(notices[index]),
    );
  }

  Widget _buildNoticeCard(NoticeModel notice) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => NoticeDetailScreen(notice: notice),
          ),
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getTypeColor(notice.type).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      notice.typeLabel,
                      style: TextStyle(
                        color: _getTypeColor(notice.type),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(notice.createdAt),
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                notice.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                notice.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.person, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(
                    'By ${notice.createdByName}',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
