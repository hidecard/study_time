class TimetableSlot {
  int? id;
  int dayOfWeek; // 1 = Monday, 7 = Sunday
  String startTime; // HH:MM format
  String endTime; // HH:MM format
  int? subjectId;

  TimetableSlot({
    this.id,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.subjectId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'day_of_week': dayOfWeek,
      'start_time': startTime,
      'end_time': endTime,
      'subject_id': subjectId,
    };
  }

  factory TimetableSlot.fromMap(Map<String, dynamic> map) {
    return TimetableSlot(
      id: map['id'],
      dayOfWeek: map['day_of_week'],
      startTime: map['start_time'],
      endTime: map['end_time'],
      subjectId: map['subject_id'],
    );
  }

  int get durationMinutes {
    final start = _parseTime(startTime);
    final end = _parseTime(endTime);
    return end.difference(start).inMinutes;
  }

  DateTime _parseTime(String time) {
    final parts = time.split(':');
    return DateTime(0, 1, 1, int.parse(parts[0]), int.parse(parts[1]));
  }
}
