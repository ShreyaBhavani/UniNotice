import 'package:flutter/material.dart';
import '../../models/notice_model.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import 'notice_detail_screen.dart';
import 'add_edit_notice_screen.dart';

/// Staff Notice List Screen - Full CRUD Operations
/// CREATE: Add new notice
/// READ: View all notices
/// UPDATE: Edit existing notices
/// DELETE: Remove notices
class StaffNoticeListScreen extends StatefulWidget {
  final String? staffId;
  
  const StaffNoticeListScreen({super.key, this.staffId});

  @override
  State<StaffNoticeListScreen> createState() => _StaffNoticeListScreenState();
}

class _StaffNoticeListScreenState extends State<StaffNoticeListScreen> {
  final _dbService = DatabaseService();
  final _authService = AuthService();
  
  List<NoticeModel> _notices = [];
  List<NoticeModel> _myNotices = [];
  bool _isLoading = true;
  String? _currentUserId;
  bool _showMyNoticesOnly = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final user = await _authService.getCurrentUser();
      final notices = await _dbService.getAllNotices();
      
      setState(() {
        _currentUserId = user?.id;
        _notices = notices;
        _myNotices = notices.where((n) => n.createdBy == user?.id).toList();
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

  /// DELETE Operation with confirmation
  Future<void> _deleteNotice(NoticeModel notice) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Delete Notice', style: TextStyle(color: Color(0xFF2D3748))),
          ],
        ),
        content: Text('Are you sure you want to delete "${notice.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _dbService.deleteNotice(notice.noticeId);
      if (success) {
        _showSnackBar('Notice deleted successfully', Colors.green);
        _loadData();
      } else {
        _showSnackBar('Failed to delete notice', Colors.red);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayNotices = _showMyNoticesOnly ? _myNotices : _notices;

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
          'Manage Notices',
          style: TextStyle(color: Color(0xFF2D3748), fontWeight: FontWeight.bold),
        ),
        actions: [
          // Toggle filter
          IconButton(
            icon: Icon(
              _showMyNoticesOnly ? Icons.filter_alt : Icons.filter_alt_outlined,
              color: const Color(0xFF38A169),
            ),
            onPressed: () {
              setState(() => _showMyNoticesOnly = !_showMyNoticesOnly);
            },
            tooltip: _showMyNoticesOnly ? 'Show all notices' : 'Show my notices only',
          ),
        ],
      ),
      // CREATE: Floating action button to add new notice
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditNoticeScreen()),
          );
          if (result == true) {
            _loadData();
          }
        },
        backgroundColor: const Color(0xFF38A169),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Notice', style: TextStyle(color: Colors.white)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF38A169)))
          : RefreshIndicator(
              onRefresh: _loadData,
              child: displayNotices.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: displayNotices.length,
                      itemBuilder: (context, index) => _buildNoticeCard(displayNotices[index]),
                    ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            _showMyNoticesOnly ? 'No notices posted by you' : 'No notices available',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text('Tap + to create a new notice', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildNoticeCard(NoticeModel notice) {
    final isMyNotice = notice.createdBy == _currentUserId;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        // READ: View notice details
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => NoticeDetailScreen(notice: notice)),
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
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      notice.audienceLabel,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (isMyNotice) ...[
                    // UPDATE: Edit button
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20, color: Color(0xFF38A169)),
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddEditNoticeScreen(notice: notice),
                          ),
                        );
                        if (result == true) {
                          _loadData();
                        }
                      },
                      tooltip: 'Edit',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 12),
                    // DELETE: Delete button
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                      onPressed: () => _deleteNotice(notice),
                      tooltip: 'Delete',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
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
                  const Spacer(),
                  Text(
                    _formatDate(notice.createdAt),
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
