import 'package:flutter/material.dart';
import '../../models/notice_model.dart';

/// Notice Detail Screen - Shows full notice content
class NoticeDetailScreen extends StatelessWidget {
  final NoticeModel notice;

  const NoticeDetailScreen({super.key, required this.notice});

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
          'Notice Details',
          style: TextStyle(color: Color(0xFF2D3748), fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type Badge
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getTypeColor(notice.type).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _getTypeColor(notice.type)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getTypeIcon(notice.type),
                            size: 16,
                            color: _getTypeColor(notice.type),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            notice.typeLabel,
                            style: TextStyle(
                              color: _getTypeColor(notice.type),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        notice.audienceLabel,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Title
                Text(
                  notice.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
                const SizedBox(height: 16),

                // Description
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(
                    notice.description,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: Color(0xFF4A5568),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Meta Information
                const Divider(),
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(
                      child: _metaItem(
                        Icons.person_outline,
                        'Posted by',
                        notice.createdByName,
                      ),
                    ),
                    Expanded(
                      child: _metaItem(
                        Icons.calendar_today,
                        'Date',
                        _formatFullDate(notice.createdAt),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _metaItem(
                        Icons.access_time,
                        'Time',
                        _formatTime(notice.createdAt),
                      ),
                    ),
                    if (notice.departmentId != null)
                      Expanded(
                        child: _metaItem(
                          Icons.business,
                          'Department',
                          notice.departmentId!,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _metaItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade500),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2D3748),
              ),
            ),
          ],
        ),
      ],
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

  IconData _getTypeIcon(NoticeType type) {
    switch (type) {
      case NoticeType.departmentLevel:
        return Icons.account_balance;
      case NoticeType.instituteLevel:
        return Icons.school;
      case NoticeType.universityLevel:
        return Icons.public;
    }
  }

  String _formatFullDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : date.hour;
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} $period';
  }
}
