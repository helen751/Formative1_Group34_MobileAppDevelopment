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

// creating the model for a task
class ProjectTask {
  const ProjectTask({
    this.id,
    required this.title,
    required this.description,
    required this.assignee,
    required this.dueDate,
    this.isCompleted = false,
  });

  final int? id;
  final String title;
  final String description;
  final String assignee;
  final DateTime dueDate;
  final bool isCompleted;

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

  // converting the task into a map for SQLite
  Map<String, Object?> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'assignee': assignee,
      'due_date': dueDate.toIso8601String(),
      'is_completed': isCompleted ? 1 : 0,
    };
  }

  // converting SQLite data back into a task
  factory ProjectTask.fromMap(Map<String, Object?> map) {
    return ProjectTask(
      id: map['id'] as int,
      title: map['title'] as String,
      description: map['description'] as String? ?? '',
      assignee: map['assignee'] as String,
      dueDate: DateTime.parse(map['due_date'] as String),
      isCompleted: map['is_completed'] == 1,
    );
  }

  // creating a new copy of a task with updated values
  ProjectTask copyWith({
    int? id,
    String? title,
    String? description,
    String? assignee,
    DateTime? dueDate,
    bool? isCompleted,
  }) {
    return ProjectTask(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      assignee: assignee ?? this.assignee,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}