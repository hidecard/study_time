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
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'study_time.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE subjects (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
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
}
