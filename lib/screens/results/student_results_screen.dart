import 'package:flutter/material.dart';
import '../../models/result_model.dart';
import '../../services/database_service.dart';

/// Student Results Screen - READ Operation
class StudentResultsScreen extends StatefulWidget {
  final String? studentId;

  const StudentResultsScreen({super.key, this.studentId});

  @override
  State<StudentResultsScreen> createState() => _StudentResultsScreenState();
}

class _StudentResultsScreenState extends State<StudentResultsScreen> {
  final _dbService = DatabaseService();
  List<ResultModel> _results = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  Future<void> _loadResults() async {
    setState(() => _isLoading = true);
    try {
      final studentId = widget.studentId ?? '';
      var results = await _dbService.getResultsForStudent(studentId);

      setState(() {
        _results = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
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
          'My Results',
          style: TextStyle(
            color: Color(0xFF2D3748),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF3182CE)),
            )
          : RefreshIndicator(
              onRefresh: _loadResults,
              child: _results.isEmpty
                  ? _buildEmptyState()
                  : _buildResultsList(),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assessment_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No results available yet',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Results will appear here once added by staff',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    // Calculate overall statistics
    double totalPercentage = 0;
    for (var result in _results) {
      totalPercentage += result.overallPercentage;
    }
    double avgPercentage = _results.isEmpty
        ? 0
        : totalPercentage / _results.length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Overall Summary Card
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF3182CE),
                  const Color(0xFF3182CE).withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Text(
                  'Overall Performance',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  '${avgPercentage.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_results.length} Courses',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Results List
        ...List.generate(
          _results.length,
          (index) => _buildResultCard(_results[index]),
        ),
      ],
    );
  }

  Widget _buildResultCard(ResultModel result) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: _getGradeColor(result.finalGrade).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              result.finalGrade ?? '-',
              style: TextStyle(
                color: _getGradeColor(result.finalGrade),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ),
        title: Text(
          result.courseName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              result.courseCode,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: result.overallPercentage / 100,
              backgroundColor: Colors.grey.shade200,
              color: _getGradeColor(result.finalGrade),
            ),
            const SizedBox(height: 4),
            Text(
              '${result.overallPercentage.toStringAsFixed(1)}%',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
        children: [
          // Assignments Section
          if (result.assignments.isNotEmpty) ...[
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Assignments',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
            const SizedBox(height: 8),
            ...result.assignments.map(
              (a) => _buildGradeItem(
                a.assignmentName,
                '${a.obtainedMarks}/${a.maxMarks}',
                a.obtainedMarks / a.maxMarks,
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Exams Section
          if (result.exams.isNotEmpty) ...[
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Exams',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
            const SizedBox(height: 8),
            ...result.exams.map(
              (e) => _buildGradeItem(
                e.examName,
                '${e.obtainedMarks}/${e.maxMarks}',
                e.obtainedMarks / e.maxMarks,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGradeItem(String name, String score, double progress) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(name, style: const TextStyle(fontSize: 13)),
          ),
          Expanded(
            flex: 2,
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade200,
              color: const Color(0xFF38A169),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            score,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Color _getGradeColor(String? grade) {
    if (grade == null) return Colors.grey;
    switch (grade.toUpperCase()) {
      case 'A+':
      case 'A':
        return const Color(0xFF38A169);
      case 'A-':
      case 'B+':
      case 'B':
        return const Color(0xFF3182CE);
      case 'B-':
      case 'C+':
      case 'C':
        return const Color(0xFFD69E2E);
      case 'C-':
      case 'D':
        return const Color(0xFFDD6B20);
      default:
        return const Color(0xFFE53E3E);
    }
  }
}
