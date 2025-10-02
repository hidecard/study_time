class Goal {
  int? id;
  int targetMinutes; // e.g. 600 for 10 hours
  String period; // e.g. 'week', 'month'

  Goal({this.id, required this.targetMinutes, required this.period});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'target_minutes': targetMinutes,
      'period': period,
    };
  }

  factory Goal.fromMap(Map<String, dynamic> map) {
    return Goal(
      id: map['id'],
      targetMinutes: map['target_minutes'],
      period: map['period'],
    );
  }
}
