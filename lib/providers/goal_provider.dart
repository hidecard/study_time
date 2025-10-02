import 'package:flutter/material.dart';
import '../database_helper.dart';
import '../models/goal.dart';

class GoalProvider with ChangeNotifier {
  Goal? _goal;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Goal? get goal => _goal;

  Future<void> loadGoal(String period) async {
    final data = await _dbHelper.queryGoalByPeriod(period);
    if (data.isNotEmpty) {
      _goal = Goal.fromMap(data.first);
    } else {
      _goal = null;
    }
    notifyListeners();
  }

  Future<void> setGoal(Goal goal) async {
    if (goal.id == null) {
      await _dbHelper.insertGoal(goal.toMap());
    } else {
      await _dbHelper.updateGoal(goal.id!, goal.toMap());
    }
    await loadGoal(goal.period);
  }

  Future<void> deleteGoal(int id) async {
    await _dbHelper.deleteGoal(id);
    _goal = null;
    notifyListeners();
  }
}
