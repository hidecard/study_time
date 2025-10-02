import 'package:flutter/material.dart';
import '../database_helper.dart';
import '../models/study_record.dart';

class StudyRecordProvider with ChangeNotifier {
  List<StudyRecord> _records = [];
  final DatabaseHelper _dbHelper = DatabaseHelper();

  List<StudyRecord> get records => _records;

  Future<void> loadRecordsBySubject(int subjectId) async {
    final data = await _dbHelper.queryStudyRecordsBySubject(subjectId);
    _records = data.map((item) => StudyRecord.fromMap(item)).toList();
    notifyListeners();
  }

  Future<void> addRecord(StudyRecord record) async {
    await _dbHelper.insertStudyRecord(record.toMap());
    await loadRecordsBySubject(record.subjectId);
  }

  Future<void> updateRecord(StudyRecord record) async {
    if (record.id != null) {
      await _dbHelper.updateStudyRecord(record.id!, record.toMap());
      await loadRecordsBySubject(record.subjectId);
    }
  }

  Future<void> deleteRecord(int id, int subjectId) async {
    await _dbHelper.deleteStudyRecord(id);
    await loadRecordsBySubject(subjectId);
  }
}
