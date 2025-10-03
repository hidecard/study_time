import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    // Force fresh database creation to ensure schema is up to date
    await deleteDatabaseFile();
    _database = await _initDatabase();
    return _database!;
  }

  Future<void> deleteDatabaseFile() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'study_time.db');
    await deleteDatabase(path);
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'study_time.db');
    return await openDatabase(
      path,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE subjects (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        weekly_goal_minutes INTEGER DEFAULT 0,
        category TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE study_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subject_id INTEGER,
        start_time TEXT,
        end_time TEXT,
        duration INTEGER,
        description TEXT,
        FOREIGN KEY(subject_id) REFERENCES subjects(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE goals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        target_minutes INTEGER NOT NULL,
        period TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE notification_reminders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        time TEXT NOT NULL,
        enabled INTEGER DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE timetable_slots (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        day_of_week INTEGER NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT NOT NULL,
        subject_id INTEGER,
        FOREIGN KEY(subject_id) REFERENCES subjects(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE exam_assignments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subject_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        date TEXT NOT NULL,
        type TEXT NOT NULL,
        description TEXT,
        FOREIGN KEY(subject_id) REFERENCES subjects(id)
      )
    ''');

  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE subjects ADD COLUMN weekly_goal_minutes INTEGER DEFAULT 0');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE subjects ADD COLUMN category TEXT');
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE exam_assignments (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          subject_id INTEGER NOT NULL,
          title TEXT NOT NULL,
          date TEXT NOT NULL,
          type TEXT NOT NULL,
          description TEXT,
          FOREIGN KEY(subject_id) REFERENCES subjects(id)
        )
      ''');
    }
  }

  // Subjects CRUD
  Future<int> insertSubject(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.insert('subjects', row);
  }

  Future<List<Map<String, dynamic>>> queryAllSubjects() async {
    Database db = await database;
    return await db.query('subjects');
  }

  Future<int> updateSubject(int id, Map<String, dynamic> row) async {
    Database db = await database;
    return await db.update('subjects', row, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteSubject(int id) async {
    Database db = await database;
    return await db.delete('subjects', where: 'id = ?', whereArgs: [id]);
  }

  // Study Records CRUD
  Future<int> insertStudyRecord(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.insert('study_records', row);
  }

  Future<List<Map<String, dynamic>>> queryAllStudyRecords() async {
    Database db = await database;
    return await db.query('study_records', orderBy: 'start_time DESC');
  }

  Future<List<Map<String, dynamic>>> queryStudyRecordsBySubject(int subjectId) async {
    Database db = await database;
    return await db.query('study_records', where: 'subject_id = ?', whereArgs: [subjectId], orderBy: 'start_time DESC');
  }

  Future<List<Map<String, dynamic>>> queryWeeklySummary() async {
    Database db = await database;
    return await db.rawQuery('''
      SELECT subject_id, COUNT(*) as session_count, SUM(duration) as total_duration
      FROM study_records
      WHERE strftime('%W', start_time) = strftime('%W', 'now')
      GROUP BY subject_id
      ORDER BY total_duration DESC
    ''');
  }

  Future<int> updateStudyRecord(int id, Map<String, dynamic> row) async {
    Database db = await database;
    return await db.update('study_records', row, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteStudyRecord(int id) async {
    Database db = await database;
    return await db.delete('study_records', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteStudyRecordsBySubject(int subjectId) async {
    Database db = await database;
    return await db.delete('study_records', where: 'subject_id = ?', whereArgs: [subjectId]);
  }

  Future<List<Map<String, dynamic>>> rawQuery(String sql) async {
    Database db = await database;
    return await db.rawQuery(sql);
  }

  // Goals CRUD
  Future<int> insertGoal(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.insert('goals', row);
  }

  Future<List<Map<String, dynamic>>> queryGoalByPeriod(String period) async {
    Database db = await database;
    return await db.query('goals', where: 'period = ?', whereArgs: [period]);
  }

  Future<int> updateGoal(int id, Map<String, dynamic> row) async {
    Database db = await database;
    return await db.update('goals', row, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteGoal(int id) async {
    Database db = await database;
    return await db.delete('goals', where: 'id = ?', whereArgs: [id]);
  }

  // Notification Reminders CRUD
  Future<int> insertNotificationReminder(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.insert('notification_reminders', row);
  }

  Future<List<Map<String, dynamic>>> queryAllNotificationReminders() async {
    Database db = await database;
    return await db.query('notification_reminders');
  }

  Future<int> updateNotificationReminder(int id, Map<String, dynamic> row) async {
    Database db = await database;
    return await db.update('notification_reminders', row, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteNotificationReminder(int id) async {
    Database db = await database;
    return await db.delete('notification_reminders', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> rawInsert(String sql, [List<dynamic>? arguments]) async {
    Database db = await database;
    return await db.rawInsert(sql, arguments ?? []);
  }

  Future<int> rawUpdate(String sql, [List<dynamic>? arguments]) async {
    Database db = await database;
    return await db.rawUpdate(sql, arguments ?? []);
  }

  Future<int> rawDelete(String sql, [List<dynamic>? arguments]) async {
    Database db = await database;
    return await db.rawDelete(sql, arguments ?? []);
  }

  // Timetable Slots CRUD
  Future<int> insertTimetableSlot(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.insert('timetable_slots', row);
  }

  Future<List<Map<String, dynamic>>> queryAllTimetableSlots() async {
    Database db = await database;
    return await db.query('timetable_slots', orderBy: 'day_of_week, start_time');
  }

  Future<int> updateTimetableSlot(int id, Map<String, dynamic> row) async {
    Database db = await database;
    return await db.update('timetable_slots', row, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteTimetableSlot(int id) async {
    Database db = await database;
    return await db.delete('timetable_slots', where: 'id = ?', whereArgs: [id]);
  }

  // Exam Assignments CRUD
  Future<int> insertExamAssignment(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.insert('exam_assignments', row);
  }

  Future<List<Map<String, dynamic>>> queryAllExamAssignments() async {
    Database db = await database;
    return await db.query('exam_assignments', orderBy: 'date');
  }

  Future<int> updateExamAssignment(int id, Map<String, dynamic> row) async {
    Database db = await database;
    return await db.update('exam_assignments', row, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteExamAssignment(int id) async {
    Database db = await database;
    return await db.delete('exam_assignments', where: 'id = ?', whereArgs: [id]);
  }
}
