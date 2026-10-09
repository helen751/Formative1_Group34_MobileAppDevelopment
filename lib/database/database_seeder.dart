import 'package:sqflite/sqflite.dart';

import '../models/project_task.dart';
import 'database_helper.dart';

class DatabaseSeeder {
  // adding default data when the tables are empty
  static Future<void> seedDatabase() async {
    await _addDefaultUsers();
    await _addDefaultTasks();
    await _addDefaultNotifications();
  }

  // the seeded members have no password yet, so this value can never
  // match a real hash and they cannot sign in until one is set
  static const String _lockedPasswordHash = '!';

  // adding the default team members
  static Future<void> _addDefaultUsers() async {
    final database = await DatabaseHelper.instance.database;

    // checking if users already exist
    final result = await database.rawQuery(
      'SELECT COUNT(*) FROM ${DatabaseHelper.userTable}',
    );

    final userCount = Sqflite.firstIntValue(result) ?? 0;

    if (userCount > 0) {
      return;
    }

    const defaultUsers = [
      (
        fullName: 'Emmanuel',
        email: 'emmanuel@devtrack.app',
        role: 'Auth Developer',
      ),
      (
        fullName: 'Derrick Nshuti',
        email: 'derrick@devtrack.app',
        role: 'Project Lead',
      ),
      (
        fullName: 'Christian',
        email: 'christian@devtrack.app',
        role: 'Task Module Developer',
      ),
      (
        fullName: 'Helen',
        email: 'helen@devtrack.app',
        role: 'Database & Stats',
      ),
    ];

    // saving each default user
    for (final user in defaultUsers) {
      await DatabaseHelper.instance.insertUser(
        fullName: user.fullName,
        email: user.email,
        passwordHash: _lockedPasswordHash,
        role: user.role,
      );
    }
  }

  // adding the default tasks
  static Future<void> _addDefaultTasks() async {
    final database = await DatabaseHelper.instance.database;

    // checking if tasks already exist
    final result = await database.rawQuery(
      'SELECT COUNT(*) FROM ${DatabaseHelper.taskTable}',
    );

    final taskCount = Sqflite.firstIntValue(result) ?? 0;

    if (taskCount > 0) {
      return;
    }

    final now = DateTime.now();

    final defaultTasks = <ProjectTask>[
      ProjectTask(
        title: 'Design login screen',
        category: 'UI/UX Design',
        description: 'Design the login screen for the application',
        assignee: 'Emmanuel',
        dueDate: now.subtract(
          const Duration(days: 1),
        ),
      ),
      ProjectTask(
        title: 'Register form validation',
        category: 'Mobile Development',
        description: 'Add validation to the registration form',
        assignee: 'Emmanuel',
        dueDate: now,
        isCompleted: true,
      ),
      ProjectTask(
        title: 'Dashboard UI',
        category: 'UI/UX Design',
        description: 'Create the dashboard user interface',
        assignee: 'Derrick',
        dueDate: now.add(
          const Duration(days: 3),
        ),
      ),
      ProjectTask(
        title: 'Team members page',
        category: 'Mobile Development',
        description: 'Create the team members page',
        assignee: 'Derrick',
        dueDate: now.add(
          const Duration(days: 7),
        ),
      ),
      ProjectTask(
        title: 'Set up SQLite tables',
        category: 'Backend (Local)',
        description: 'Create the local database tables',
        assignee: 'Helen',
        dueDate: now.add(
          const Duration(hours: 20),
        ),
      ),
      ProjectTask(
        title: 'Build create/edit task form',
        category: 'Mobile Development',
        description: 'Create the form for adding and editing tasks',
        assignee: 'Christian',
        dueDate: now.add(
          const Duration(days: 2),
        ),
      ),
      ProjectTask(
        title: 'Task details layout',
        category: 'UI/UX Design',
        description: 'Create the task details page layout',
        assignee: 'Helen',
        dueDate: now.add(
          const Duration(days: 6),
        ),
      ),
    ];

    // saving each default task
    for (final task in defaultTasks) {
      await DatabaseHelper.instance.insertTask(task);
    }
  }

  // adding the default notifications
  static Future<void> _addDefaultNotifications() async {
    final database = await DatabaseHelper.instance.database;

    // checking if notifications already exist
    final result = await database.rawQuery(
      'SELECT COUNT(*) FROM ${DatabaseHelper.notificationTable}',
    );

    final notificationCount =
        Sqflite.firstIntValue(result) ?? 0;

    if (notificationCount > 0) {
      return;
    }

    final defaultNotifications = [
      {
        'title': 'Build create/edit task form is at risk',
        'subtitle': 'Due in 2 days · Christian',
        'timeLabel': 'Yesterday',
        'kind': 'atRisk',
        'unread': true,
      },
      {
        'title': 'Register form validation completed',
        'subtitle': 'Finished by Emmanuel',
        'timeLabel': '2 days ago',
        'kind': 'completed',
        'unread': false,
      },
      {
        'title': 'Dashboard UI assigned to you',
        'subtitle': 'Assigned by Christian',
        'timeLabel': '2 days ago',
        'kind': 'assigned',
        'unread': false,
      },
    ];

    // saving each default notification
    for (final notification in defaultNotifications) {
      await DatabaseHelper.instance.insertNotification(
        title: notification['title'] as String,
        subtitle: notification['subtitle'] as String,
        timeLabel: notification['timeLabel'] as String,
        kind: notification['kind'] as String,
        unread: notification['unread'] as bool,
      );
    }
  }
}