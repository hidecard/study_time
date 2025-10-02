import 'package:flutter/material.dart';
import '../database_helper.dart';
import '../models/subject.dart';

class SubjectProvider with ChangeNotifier {
  List<Subject> _subjects = [];
  final DatabaseHelper _dbHelper = DatabaseHelper();

  List<Subject> get subjects => _subjects;

  Future<void> loadSubjects() async {
    final data = await _dbHelper.queryAllSubjects();
    _subjects = data.map((item) => Subject.fromMap(item)).toList();
    notifyListeners();
  }

  Future<void> addSubject(Subject subject) async {
    await _dbHelper.insertSubject(subject.toMap());
    await loadSubjects();
  }

  Future<void> updateSubject(Subject subject) async {
    if (subject.id != null) {
      await _dbHelper.updateSubject(subject.id!, subject.toMap());
      await loadSubjects();
    }
  }

  Future<void> deleteSubject(int id) async {
    await _dbHelper.deleteSubject(id);
    await loadSubjects();
  }
}
