class Subject {
  int? id;
  String name;
  int weeklyGoalMinutes;

  Subject({this.id, required this.name, this.weeklyGoalMinutes = 0});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'weekly_goal_minutes': weeklyGoalMinutes,
    };
  }

  factory Subject.fromMap(Map<String, dynamic> map) {
    return Subject(
      id: map['id'],
      name: map['name'],
      weeklyGoalMinutes: map['weekly_goal_minutes'] ?? 0,
    );
  }
}
