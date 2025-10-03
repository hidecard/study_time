import 'package:flutter/material.dart';
import '../database_helper.dart';
import '../models/timetable_slot.dart';

class TimetableProvider with ChangeNotifier {
  List<TimetableSlot> _slots = [];
  final DatabaseHelper _dbHelper = DatabaseHelper();

  List<TimetableSlot> get slots => _slots;

  Future<void> loadTimetable() async {
    final data = await _dbHelper.queryAllTimetableSlots();
    _slots = data.map((item) => TimetableSlot.fromMap(item)).toList();
    notifyListeners();
  }

  Future<void> addSlot(TimetableSlot slot) async {
    await _dbHelper.insertTimetableSlot(slot.toMap());
    await loadTimetable();
  }

  Future<void> updateSlot(TimetableSlot slot) async {
    if (slot.id != null) {
      await _dbHelper.updateTimetableSlot(slot.id!, slot.toMap());
      await loadTimetable();
    }
  }

  Future<void> deleteSlot(int id) async {
    await _dbHelper.deleteTimetableSlot(id);
    await loadTimetable();
  }

  List<TimetableSlot> getSlotsForDay(int dayOfWeek) {
    return _slots.where((slot) => slot.dayOfWeek == dayOfWeek).toList();
  }

  double getPlannedHoursForWeek() {
    return _slots.fold(0.0, (sum, slot) => sum + slot.durationMinutes / 60.0);
  }

  double getPlannedHoursForDay(int dayOfWeek) {
    return getSlotsForDay(dayOfWeek).fold(0.0, (sum, slot) => sum + slot.durationMinutes / 60.0);
  }
}
