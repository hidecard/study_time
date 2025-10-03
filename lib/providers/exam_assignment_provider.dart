import 'package:flutter/material.dart';
import '../database_helper.dart';
import '../models/exam_assignment.dart';

class ExamAssignmentProvider with ChangeNotifier {
  List<ExamAssignment> _examsAssignments = [];
  final DatabaseHelper _dbHelper = DatabaseHelper();

  List<ExamAssignment> get examsAssignments => _examsAssignments;

  Future<void> loadExamsAssignments() async {
    final data = await _dbHelper.queryAllExamAssignments();
    _examsAssignments = data.map((item) => ExamAssignment.fromMap(item)).toList();
    notifyListeners();
  }

  Future<void> addExamAssignment(ExamAssignment examAssignment) async {
    await _dbHelper.insertExamAssignment(examAssignment.toMap());
    await loadExamsAssignments();
  }

  Future<void> updateExamAssignment(ExamAssignment examAssignment) async {
    if (examAssignment.id != null) {
      await _dbHelper.updateExamAssignment(examAssignment.id!, examAssignment.toMap());
      await loadExamsAssignments();
    }
  }

  Future<void> deleteExamAssignment(int id) async {
    await _dbHelper.deleteExamAssignment(id);
    await loadExamsAssignments();
  }

  List<ExamAssignment> getUpcomingExamsAssignments() {
    return _examsAssignments.where((ea) => ea.isUpcoming).toList()
      ..sort((a, b) => a.daysUntil.compareTo(b.daysUntil));
  }

  List<ExamAssignment> getExamsAssignmentsForSubject(int subjectId) {
    return _examsAssignments.where((ea) => ea.subjectId == subjectId).toList();
  }
}
