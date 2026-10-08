import 'package:sqflite/sqflite.dart';

import '../models/project_task.dart';
import 'database_helper.dart';

/// The user the dashboard treats as signed in (greeting and "My tasks").
/// Temporary until login saves the real user.
const currentUserFirstName = 'Derrick';

/// Project name shown on the dashboard progress card.
const projectName = 'DevTrack';

class DatabaseSeeder {
  // adding default data when the tables are empty
  static Future<void> seedDatabase() async {
    await _addDefaultUsers();
    await _addDefaultTasks();
    await _addDefaultNotifications();
  }

  // what the default users had before they got passwords
  static const String _oldLockedPasswordHash = '!';

  // the default team members and their passwords
  // (passwords are saved as plain text)
  static const _defaultUsers = [
    (
      fullName: 'Emmanuel',
      email: 'emmanuel@devtrack.app',
      password: 'Emmanuel@2026',
      role: 'Auth Developer',
    ),
    (
      fullName: 'Derrick Nshuti',
      email: 'derrick@devtrack.app',
      password: 'Derrick@2026',
      role: 'Project Lead',
    ),
    (
      fullName: 'Christian',
      email: 'christian@devtrack.app',
      password: 'Christian@2026',
      role: 'Task Module Developer',
    ),
    (
      fullName: 'Helen',
      email: 'helen@devtrack.app',
      password: 'Helen@2026',
      role: 'Database & Stats',
    ),
  ];

  // adding the default team members
  static Future<void> _addDefaultUsers() async {
    final database = await DatabaseHelper.instance.database;

    // checking if users already exist
    final result = await database.rawQuery(
      'SELECT COUNT(*) FROM ${DatabaseHelper.userTable}',
    );

    final userCount = Sqflite.firstIntValue(result) ?? 0;

    // saving each default user
    if (userCount == 0) {
      for (final user in _defaultUsers) {
        await DatabaseHelper.instance.insertUser(
          fullName: user.fullName,
          email: user.email,
          password: user.password,
          role: user.role,
        );
      }

      return;
    }

    // old installs: giving the default users their passwords
    for (final user in _defaultUsers) {
      final savedUser =
          await DatabaseHelper.instance.getUserByEmail(user.email);

      if (savedUser != null &&
          savedUser['password'] == _oldLockedPasswordHash) {
        await DatabaseHelper.instance.updateUserPassword(
          email: user.email,
          password: user.password,
        );
      }
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
        description: 'Design the login screen for the application',
        assignee: 'Emmanuel',
        dueDate: now.subtract(
          const Duration(days: 1),
        ),
      ),
      ProjectTask(
        title: 'Register form validation',
        description: 'Add validation to the registration form',
        assignee: 'Emmanuel',
        dueDate: now,
        isCompleted: true,
      ),
      ProjectTask(
        title: 'Dashboard UI',
        description: 'Create the dashboard user interface',
        assignee: 'Derrick',
        dueDate: now.add(
          const Duration(days: 3),
        ),
      ),
      ProjectTask(
        title: 'Team members page',
        description: 'Create the team members page',
        assignee: 'Derrick',
        dueDate: now.add(
          const Duration(days: 7),
        ),
      ),
      ProjectTask(
        title: 'Set up SQLite tables',
        description: 'Create the local database tables',
        assignee: 'Helen',
        dueDate: now.add(
          const Duration(hours: 20),
        ),
      ),
      ProjectTask(
        title: 'Build create/edit task form',
        description: 'Create the form for adding and editing tasks',
        assignee: 'Christian',
        dueDate: now.add(
          const Duration(days: 2),
        ),
      ),
      ProjectTask(
        title: 'Task details layout',
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