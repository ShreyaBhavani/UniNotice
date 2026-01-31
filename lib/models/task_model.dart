/// Task Model for Task Manager Module
/// 
/// Firebase Realtime Database Schema:
/// ============================================
/// Collection Name: tasks
/// Document ID: taskId (auto-generated)
/// 
/// Fields (Key-Value Pairs):
/// ┌─────────────────┬────────────┬─────────────────────────────────────────┐
/// │ Field Name      │ Data Type  │ Description                             │
/// ├─────────────────┼────────────┼─────────────────────────────────────────┤
/// │ taskId          │ String     │ Unique identifier (auto-generated)      │
/// │ title           │ String     │ Task title/name                         │
/// │ description     │ String     │ Detailed task description               │
/// │ priority        │ String     │ Priority level (low/medium/high)        │
/// │ status          │ String     │ Task status (pending/inProgress/done)   │
/// │ dueDate         │ String     │ Due date (ISO 8601 format)              │
/// │ createdBy       │ String     │ User ID who created the task            │
/// │ createdByName   │ String     │ Name of the creator                     │
/// │ assignedTo      │ String?    │ User ID task is assigned to (optional)  │
/// │ assignedToName  │ String?    │ Name of assignee (optional)             │
/// │ departmentId    │ String?    │ Department ID (optional)                │
/// │ category        │ String     │ Task category (academic/admin/personal) │
/// │ createdAt       │ String     │ Creation timestamp (ISO 8601)           │
/// │ updatedAt       │ String     │ Last update timestamp (ISO 8601)        │
/// │ completedAt     │ String?    │ Completion timestamp (optional)         │
/// │ isActive        │ bool       │ Soft delete flag                        │
/// └─────────────────┴────────────┴─────────────────────────────────────────┘
/// 
/// Database Path: /tasks/{taskId}
/// 
/// Example JSON Structure:
/// {
///   "tasks": {
///     "task_1706500000000": {
///       "taskId": "task_1706500000000",
///       "title": "Complete Assignment",
///       "description": "Submit the Flutter project",
///       "priority": "high",
///       "status": "pending",
///       "dueDate": "2026-02-05T23:59:00.000",
///       "createdBy": "user_123",
///       "createdByName": "John Doe",
///       "assignedTo": null,
///       "assignedToName": null,
///       "departmentId": "it",
///       "category": "academic",
///       "createdAt": "2026-01-29T10:00:00.000",
///       "updatedAt": "2026-01-29T10:00:00.000",
///       "completedAt": null,
///       "isActive": true
///     }
///   }
/// }
library;

/// Task Priority Levels
enum TaskPriority {
  low,
  medium,
  high;

  String get displayName {
    switch (this) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.high:
        return 'High';
    }
  }

  int get sortOrder {
    switch (this) {
      case TaskPriority.high:
        return 0;
      case TaskPriority.medium:
        return 1;
      case TaskPriority.low:
        return 2;
    }
  }
}

/// Task Status
enum TaskStatus {
  pending,
  inProgress,
  completed;

  String get displayName {
    switch (this) {
      case TaskStatus.pending:
        return 'Pending';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.completed:
        return 'Completed';
    }
  }
}

/// Task Category
enum TaskCategory {
  academic,
  administrative,
  personal;

  String get displayName {
    switch (this) {
      case TaskCategory.academic:
        return 'Academic';
      case TaskCategory.administrative:
        return 'Administrative';
      case TaskCategory.personal:
        return 'Personal';
    }
  }
}

/// Task Model Class
class TaskModel {
  final String taskId;
  final String title;
  final String description;
  final TaskPriority priority;
  final TaskStatus status;
  final DateTime dueDate;
  final String createdBy;
  final String createdByName;
  final String? assignedTo;
  final String? assignedToName;
  final String? departmentId;
  final TaskCategory category;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final bool isActive;

  TaskModel({
    required this.taskId,
    required this.title,
    required this.description,
    required this.priority,
    required this.status,
    required this.dueDate,
    required this.createdBy,
    required this.createdByName,
    this.assignedTo,
    this.assignedToName,
    this.departmentId,
    required this.category,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    this.isActive = true,
  });

  /// Convert TaskModel to JSON for Firebase
  Map<String, dynamic> toJson() => {
        'taskId': taskId,
        'title': title,
        'description': description,
        'priority': priority.name,
        'status': status.name,
        'dueDate': dueDate.toIso8601String(),
        'createdBy': createdBy,
        'createdByName': createdByName,
        'assignedTo': assignedTo,
        'assignedToName': assignedToName,
        'departmentId': departmentId,
        'category': category.name,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'isActive': isActive,
      };

  /// Create TaskModel from Firebase JSON
  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      taskId: json['taskId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      priority: TaskPriority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => TaskPriority.medium,
      ),
      status: TaskStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TaskStatus.pending,
      ),
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'])
          : DateTime.now(),
      createdBy: json['createdBy'] ?? '',
      createdByName: json['createdByName'] ?? '',
      assignedTo: json['assignedTo'],
      assignedToName: json['assignedToName'],
      departmentId: json['departmentId'],
      category: TaskCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => TaskCategory.personal,
      ),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      isActive: json['isActive'] ?? true,
    );
  }

  /// Create a copy with updated fields
  TaskModel copyWith({
    String? taskId,
    String? title,
    String? description,
    TaskPriority? priority,
    TaskStatus? status,
    DateTime? dueDate,
    String? createdBy,
    String? createdByName,
    String? assignedTo,
    String? assignedToName,
    String? departmentId,
    TaskCategory? category,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
    bool? isActive,
  }) {
    return TaskModel(
      taskId: taskId ?? this.taskId,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      dueDate: dueDate ?? this.dueDate,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedToName: assignedToName ?? this.assignedToName,
      departmentId: departmentId ?? this.departmentId,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Check if task is overdue
  bool get isOverdue =>
      status != TaskStatus.completed && DateTime.now().isAfter(dueDate);

  /// Get days until due date (negative if overdue)
  int get daysUntilDue => dueDate.difference(DateTime.now()).inDays;

  /// Generate unique task ID
  static String generateTaskId() => 'task_${DateTime.now().millisecondsSinceEpoch}';
}
