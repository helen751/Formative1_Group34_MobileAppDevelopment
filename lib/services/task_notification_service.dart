import '../database/database_helper.dart';
import '../models/project_task.dart';

class TaskNotificationService {
  // checking tasks that need notifications
  static Future<void> checkTaskDeadlines() async {
    final tasks = await DatabaseHelper.instance.getTasks();

    for (final task in tasks) {
      if (task.isCompleted) {
        continue;
      }

      if (task.status == SlaStatus.overdue) {
        await _addNotificationIfMissing(
          task: task,
          kind: 'overdue',
          title: '${task.title} is overdue',
          subtitle: '${task.dueLabel} · ${task.assignee}',
        );
      } else if (task.status == SlaStatus.atRisk) {
        await _addNotificationIfMissing(
          task: task,
          kind: 'atRisk',
          title: '${task.title} is at risk',
          subtitle: '${task.dueLabel} · ${task.assignee}',
        );
      }
    }
  }

  // stopping the same notification from being added again
  static Future<void> _addNotificationIfMissing({
    required ProjectTask task,
    required String kind,
    required String title,
    required String subtitle,
  }) async {
    if (task.id == null) {
      return;
    }

    final exists = await DatabaseHelper.instance
        .taskNotificationExists(
      task.id!,
      kind,
    );

    if (exists) {
      return;
    }

    await DatabaseHelper.instance.insertNotification(
      taskId: task.id,
      title: title,
      subtitle: subtitle,
      timeLabel: 'Just now',
      kind: kind,
    );
  }
}