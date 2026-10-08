import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/project_task.dart';
import 'create_task_page.dart';

class TaskDetailsPage extends StatefulWidget {
  const TaskDetailsPage({
    super.key,
    required this.task,
  });

  final ProjectTask task;

  @override
  State<TaskDetailsPage> createState() {
    return _TaskDetailsPageState();
  }
}

class _TaskDetailsPageState extends State<TaskDetailsPage> {
  late ProjectTask task;
  bool isUpdating = false;

  @override
  void initState() {
    super.initState();

    // storing the selected task
    task = widget.task;
  }

  // updating the task status
  Future<void> updateStatus() async {
    if (task.id == null) {
      return;
    }

    setState(() {
      isUpdating = true;
    });

    final newCompletedStatus = !task.isCompleted;

    await DatabaseHelper.instance.updateTaskCompletion(
      task.id!,
      newCompletedStatus,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      task = task.copyWith(
        isCompleted: newCompletedStatus,
      );

      isUpdating = false;
    });

    final message = newCompletedStatus
        ? 'Task marked as completed'
        : 'Task reopened';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  // opening the delete confirmation
  Future<void> confirmDelete() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete task'),
          content: Text(
            'Do you want to delete "${task.title}"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text(
                'Delete',
                style: TextStyle(
                  color: Colors.red,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || task.id == null) {
      return;
    }

    await DatabaseHelper.instance.deleteTask(task.id!);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Task deleted'),
      ),
    );

    // returning true so the dashboard can reload
    Navigator.pop(context, true);
  }

  // opening the edit page
  Future<void> openEditPage() async {
    final updated = await Navigator.push<ProjectTask>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateTaskPage(task: task),
      ),
    );

    if (updated == null || !mounted) {
      return;
    }

    setState(() {
      task = updated;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Task updated'),
      ),
    );
  }

  // formatting the due date
  String formatDueDate() {
    final date = task.dueDate;

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day/$month/$year at $hour:$minute';
  }

  // creating one detail row
  Widget detailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 18,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = task.status;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
        actions: [
          // editing the task
          IconButton(
            onPressed: openEditPage,
            tooltip: 'Edit task',
            icon: const Icon(Icons.edit),
          ),

          // deleting the task
          IconButton(
            onPressed: confirmDelete,
            tooltip: 'Delete task',
            icon: const Icon(
              Icons.delete_outline,
              color: Colors.red,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // showing the task status
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: status.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: status.color,
                ),
              ),
              child: Text(
                status.label,
                style: TextStyle(
                  color: status.color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // showing the task title
            Text(
              task.title,
              style: const TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            // showing the task description
            Text(
              task.description.isEmpty
                  ? 'No description was added.'
                  : task.description,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 30),

            const Divider(),

            const SizedBox(height: 20),

            detailRow(
              icon: Icons.person_outline,
              label: 'Assigned to',
              value: task.assignee,
            ),

            detailRow(
              icon: Icons.calendar_today_outlined,
              label: 'Due date',
              value: formatDueDate(),
            ),

            detailRow(
              icon: Icons.schedule,
              label: 'Deadline',
              value: task.dueLabel,
            ),

            detailRow(
              icon: Icons.flag_outlined,
              label: 'Status',
              value: status.label,
            ),

            const SizedBox(height: 15),

            // updating the task status
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isUpdating ? null : updateStatus,
                icon: isUpdating
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
                    : Icon(
                  task.isCompleted
                      ? Icons.restart_alt
                      : Icons.check_circle_outline,
                ),
                label: Text(
                  task.isCompleted
                      ? 'Reopen Task'
                      : 'Mark as Completed',
                ),
              ),
            ),

            const SizedBox(height: 12),

            // opening the edit page
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: openEditPage,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit Task'),
              ),
            ),

            const SizedBox(height: 12),

            // deleting the task
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: confirmDelete,
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                ),
                label: const Text(
                  'Delete Task',
                  style: TextStyle(
                    color: Colors.red,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}