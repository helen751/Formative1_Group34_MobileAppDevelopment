import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/project_task.dart';
import '../models/devtrack_models.dart';

class DatabaseHelper {
  // creating one database helper
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  static const String databaseName = 'devtrack.db';
  static const int databaseVersion = 5;

  static const String userTable = 'users';
  static const String taskTable = 'tasks';
  static const String notificationTable = 'notifications';

  Database? _database;

  // getting the database
  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _openDatabase();

    return _database!;
  }

  // opening the database
  Future<Database> _openDatabase() async {
    final databaseFolder = await getDatabasesPath();

    final databasePath = join(
      databaseFolder,
      databaseName,
    );

    return openDatabase(
      databasePath,
      version: databaseVersion,
      onConfigure: _configureDatabase,
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );
  }

  // allowing relationships between tables
  Future<void> _configureDatabase(Database database) async {
    await database.execute('PRAGMA foreign_keys = ON');
  }

  // creating all the database tables
  Future<void> _createDatabase(
      Database database,
      int version,
      ) async {
    await _createUserTable(database);
    await _createTaskTable(database);
    await _createNotificationTable(database);
  }

  // creating the users table
  Future<void> _createUserTable(Database database) async {
    await database.execute('''
      CREATE TABLE IF NOT EXISTS $userTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        full_name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        role TEXT NOT NULL DEFAULT 'Member',
        created_at TEXT NOT NULL
      )
    ''');
  }

  // creating the tasks table
  Future<void> _createTaskTable(Database database) async {
    await database.execute('''
      CREATE TABLE IF NOT EXISTS $taskTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        assignee TEXT NOT NULL,
        due_date TEXT NOT NULL,
        is_completed INTEGER NOT NULL DEFAULT 0,
        priority TEXT NOT NULL DEFAULT 'medium',
        stage TEXT NOT NULL DEFAULT 'toDo',
        created_at TEXT NOT NULL
      )
    ''');
  }

  // creating the notifications table
  Future<void> _createNotificationTable(
      Database database,
      ) async {
    await database.execute('''
    CREATE TABLE IF NOT EXISTS $notificationTable (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER,
      task_id INTEGER,
      title TEXT NOT NULL,
      subtitle TEXT NOT NULL,
      time_label TEXT NOT NULL,
      kind TEXT NOT NULL,
      unread INTEGER NOT NULL DEFAULT 1,
      created_at TEXT NOT NULL,
      FOREIGN KEY (user_id) REFERENCES $userTable (id),
      FOREIGN KEY (task_id) REFERENCES $taskTable (id)
    )
  ''');
  }

  // updating an old database
  Future<void> _upgradeDatabase(
      Database database,
      int oldVersion,
      int newVersion,
      ) async {
    if (oldVersion < 2) {
      await _createUserTable(database);
      await _createNotificationTable(database);
    }

    if (oldVersion < 3) {
      final columns = await database.rawQuery(
        'PRAGMA table_info($taskTable)',
      );

      final hasCreatedAt = columns.any((column) {
        return column['name'] == 'created_at';
      });

      if (!hasCreatedAt) {
        await database.execute(
          'ALTER TABLE $taskTable ADD COLUMN created_at TEXT',
        );

        await database.update(
          taskTable,
          {
            'created_at': DateTime.now().toIso8601String(),
          },
          where: 'created_at IS NULL',
        );
      }
    }
    if (oldVersion < 4) {
      final columns = await database.rawQuery(
        'PRAGMA table_info($notificationTable)',
      );

      final hasTaskId = columns.any((column) {
        return column['name'] == 'task_id';
      });

      if (!hasTaskId) {
        await database.execute(
          '''
      ALTER TABLE $notificationTable
      ADD COLUMN task_id INTEGER
      ''',
        );
      }
    }

    if (oldVersion < 5) {
      final columns = await database.rawQuery(
        'PRAGMA table_info($taskTable)',
      );

      final columnNames = columns.map((column) {
        return column['name'];
      }).toSet();

      // adding priority and stage columns
      if (!columnNames.contains('priority')) {
        await database.execute(
          "ALTER TABLE $taskTable ADD COLUMN priority TEXT NOT NULL DEFAULT 'medium'",
        );
      }

      if (!columnNames.contains('stage')) {
        await database.execute(
          "ALTER TABLE $taskTable ADD COLUMN stage TEXT NOT NULL DEFAULT 'toDo'",
        );
      }
    }
  }

  // adding a new user
  Future<int> insertUser({
    required String fullName,
    required String email,
    required String passwordHash,
    String role = 'Member',
  }) async {
    final db = await database;

    return db.insert(
      userTable,
      {
        'full_name': fullName.trim(),
        'email': email.toLowerCase().trim(),
        'password_hash': passwordHash,
        'role': role,
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  // getting all the users
  Future<List<Map<String, Object?>>> getUsers() async {
    final db = await database;

    return db.query(
      userTable,
      orderBy: 'full_name ASC',
    );
  }

  // getting all the team members
  Future<List<Member>> getMembers() async {
    final users = await getUsers();

    return users.map(Member.fromMap).toList();
  }

  // getting one user by email
  Future<Map<String, Object?>?> getUserByEmail(
      String email,
      ) async {
    final db = await database;

    final users = await db.query(
      userTable,
      where: 'email = ?',
      whereArgs: [
        email.toLowerCase().trim(),
      ],
      limit: 1,
    );

    if (users.isEmpty) {
      return null;
    }

    return users.first;
  }

  // updating a user
  Future<int> updateUser({
    required int id,
    required String fullName,
    required String email,
    required String role,
  }) async {
    final db = await database;

    return db.update(
      userTable,
      {
        'full_name': fullName.trim(),
        'email': email.toLowerCase().trim(),
        'role': role,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // deleting a user
  Future<int> deleteUser(int id) async {
    final db = await database;

    return db.delete(
      userTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // adding a new task
  Future<int> insertTask(ProjectTask task) async {
    final db = await database;

    final taskData = task.toMap();

    taskData.remove('id');

    taskData['created_at'] = DateTime.now().toIso8601String();

    return db.insert(
      taskTable,
      taskData,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // getting all the tasks
  Future<List<ProjectTask>> getTasks() async {
    final db = await database;

    final taskMaps = await db.query(
      taskTable,
      orderBy: 'due_date ASC',
    );

    return taskMaps.map((taskMap) {
      return ProjectTask.fromMap(taskMap);
    }).toList();
  }

  // getting one task
  Future<ProjectTask?> getTask(int id) async {
    final db = await database;

    final taskMaps = await db.query(
      taskTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (taskMaps.isEmpty) {
      return null;
    }

    return ProjectTask.fromMap(taskMaps.first);
  }

  // getting tasks for one team member
  Future<List<ProjectTask>> getTasksByAssignee(
      String assignee,
      ) async {
    final db = await database;

    final taskMaps = await db.query(
      taskTable,
      where: 'assignee = ?',
      whereArgs: [assignee],
      orderBy: 'due_date ASC',
    );

    return taskMaps.map((taskMap) {
      return ProjectTask.fromMap(taskMap);
    }).toList();
  }

  // updating a task
  Future<int> updateTask(ProjectTask task) async {
    if (task.id == null) {
      throw Exception('The task does not have an ID');
    }

    final db = await database;

    final taskData = task.toMap();

    taskData.remove('id');

    return db.update(
      taskTable,
      taskData,
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  // marking a task as completed
  Future<int> completeTask(int id) async {
    final db = await database;

    return db.update(
      taskTable,
      {
        'is_completed': 1,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // updating the completed status of a task
  Future<int> updateTaskCompletion(
      int id,
      bool isCompleted,
      ) async {
    final db = await database;

    return db.update(
      taskTable,
      {
        'is_completed': isCompleted ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // deleting a task
  Future<int> deleteTask(int id) async {
    final db = await database;

    return db.delete(
      taskTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // adding a notification
  Future<int> insertNotification({
    int? userId,
    int? taskId,
    required String title,
    required String subtitle,
    required String timeLabel,
    required String kind,
    bool unread = true,
  }) async {
    final db = await database;

    return db.insert(
      notificationTable,
      {
        'user_id': userId,
        'task_id': taskId,
        'title': title,
        'subtitle': subtitle,
        'time_label': timeLabel,
        'kind': kind,
        'unread': unread ? 1 : 0,
        'created_at': DateTime.now().toIso8601String(),
      },
    );
  }

  // checking if a task notification already exists
  Future<bool> taskNotificationExists(
      int taskId,
      String kind,
      ) async {
    final db = await database;

    final result = await db.query(
      notificationTable,
      where: 'task_id = ? AND kind = ?',
      whereArgs: [
        taskId,
        kind,
      ],
      limit: 1,
    );

    return result.isNotEmpty;
  }

  // getting all the notifications
// getting all the notifications
  Future<List<AppNotification>> getNotifications() async {
    final db = await database;

    final notificationMaps = await db.query(
      notificationTable,
      orderBy: 'created_at DESC',
    );

    return notificationMaps.map((notificationMap) {
      return AppNotification.fromMap(notificationMap);
    }).toList();
  }

  // getting notifications for one user
  Future<List<Map<String, Object?>>> getUserNotifications(
      int userId,
      ) async {
    final db = await database;

    return db.query(
      notificationTable,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
  }

  // counting unread notifications
  Future<int> getUnreadNotificationCount() async {
    final db = await database;

    final result = await db.rawQuery(
      '''
    SELECT COUNT(*)
    FROM $notificationTable
    WHERE unread = 1
    ''',
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  // marking a notification as read
  Future<int> markNotificationAsRead(int id) async {
    final db = await database;

    return db.update(
      notificationTable,
      {
        'unread': 0,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // marking all notifications as read
  Future<int> markAllNotificationsAsRead() async {
    final db = await database;

    return db.update(
      notificationTable,
      {
        'unread': 0,
      },
    );
  }

  // deleting a notification
  Future<int> deleteNotification(int id) async {
    final db = await database;

    return db.delete(
      notificationTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }



  // closing the database
  Future<void> closeDatabase() async {
    final db = await database;

    await db.close();

    _database = null;
  }
}