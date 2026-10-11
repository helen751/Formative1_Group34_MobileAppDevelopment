import 'package:flutter/material.dart';

import '../theme/devtrack_theme.dart';

// creating the status options for a task
enum SlaStatus {
  onTrack('On Track', DevTrackColors.onTrack),
  atRisk('At Risk', DevTrackColors.atRisk),
  overdue('Overdue', DevTrackColors.overdue),
  completed('Completed', DevTrackColors.completed);

  const SlaStatus(this.label, this.color);

  final String label;
  final Color color;
}

// creating the priority options for a task
enum TaskPriority {
  low('Low', DevTrackColors.onTrack),
  medium('Medium', DevTrackColors.atRisk),
  high('High', DevTrackColors.overdue);

  const TaskPriority(this.label, this.color);

  final String label;
  final Color color;
}

// creating the work stages a task moves through
enum TaskStage {
  toDo('To Do'),
  inProgress('In Progress'),
  done('Done');

  const TaskStage(this.label);

  final String label;
}

// the areas of work a task can belong to
const taskCategories = [
  'UI/UX Design',
  'Mobile Development',
  'Backend (Local)',
  'Quality Assurance',
  'Documentation',
  'General',
];

// creating the model for a task
class ProjectTask {
  const ProjectTask({
    this.id,
    required this.title,
    required this.description,
    required this.assignee,
    required this.dueDate,
    this.category = 'General',
    this.isCompleted = false,
    this.priority = TaskPriority.medium,
    this.stage = TaskStage.toDo,
  });

  final int? id;
  final String title;
  final String description;
  final String assignee;
  final DateTime dueDate;
  final String category;
  final bool isCompleted;
  final TaskPriority priority;

  // to do, in progress or done
  final TaskStage stage;

  // getting the number of hours left
  int? get dueInHours {
    if (isCompleted) {
      return null;
    }

    return dueDate.difference(DateTime.now()).inHours;
  }

  // getting the current status of the task
  SlaStatus get status {
    if (isCompleted) {
      return SlaStatus.completed;
    }

    final hours = dueInHours ?? 0;

    if (hours < 0) {
      return SlaStatus.overdue;
    } else if (hours <= 24) {
      return SlaStatus.atRisk;
    } else {
      return SlaStatus.onTrack;
    }
  }

  // creating the text that shows when the task is due
  String get dueLabel {
    if (isCompleted) {
      return 'Completed';
    }

    final difference = dueDate.difference(DateTime.now());

    if (difference.isNegative) {
      final overdueHours = difference.inHours.abs();

      if (overdueHours < 24) {
        return '$overdueHours hours overdue';
      }

      return '${difference.inDays.abs()} days overdue';
    }

    if (difference.inHours < 24) {
      return 'Due in ${difference.inHours}h';
    }

    return 'Due in ${difference.inDays} days';
  }

  // showing the due date like "10 Dec 2026"
  String get dueDateLabel {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    return '${dueDate.day} ${months[dueDate.month - 1]} ${dueDate.year}';
  }

  // converting the task into a map for SQLite
  Map<String, Object?> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'assignee': assignee,
      'due_date': dueDate.toIso8601String(),
      'category': category,
      'is_completed': isCompleted ? 1 : 0,
      'priority': priority.name,
      'stage': _savedStage.name,
    };
  }

  // getting the stage to save
  TaskStage get _savedStage {
    if (isCompleted) {
      return TaskStage.done;
    }

    return stage == TaskStage.done ? TaskStage.toDo : stage;
  }

  // converting SQLite data back into a task
  factory ProjectTask.fromMap(Map<String, Object?> map) {
    final isCompleted = map['is_completed'] == 1;

    return ProjectTask(
      id: map['id'] as int,
      title: map['title'] as String,
      description: map['description'] as String? ?? '',
      assignee: map['assignee'] as String,
      dueDate: DateTime.parse(map['due_date'] as String),
      category: map['category'] as String? ?? 'General',
      isCompleted: isCompleted,
      priority: TaskPriority.values.asNameMap()[map['priority']] ??
          TaskPriority.medium,
      stage: isCompleted
          ? TaskStage.done
          : _openStage(map['stage'] as String?),
    );
  }

  // getting the stage of an open task
  static TaskStage _openStage(String? name) {
    final stage = TaskStage.values.asNameMap()[name] ?? TaskStage.toDo;

    return stage == TaskStage.done ? TaskStage.toDo : stage;
  }

  // creating a new copy of a task with updated values
  ProjectTask copyWith({
    int? id,
    String? title,
    String? description,
    String? assignee,
    DateTime? dueDate,
    String? category,
    bool? isCompleted,
    TaskPriority? priority,
    TaskStage? stage,
  }) {
    return ProjectTask(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      assignee: assignee ?? this.assignee,
      dueDate: dueDate ?? this.dueDate,
      category: category ?? this.category,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
      stage: stage ?? this.stage,
    );
  }
}