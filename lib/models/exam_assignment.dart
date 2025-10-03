class ExamAssignment {
  int? id;
  int subjectId;
  String title;
  String date; // YYYY-MM-DD format
  String type; // 'exam' or 'assignment'
  String? description;

  ExamAssignment({
    this.id,
    required this.subjectId,
    required this.title,
    required this.date,
    required this.type,
    this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subject_id': subjectId,
      'title': title,
      'date': date,
      'type': type,
      'description': description,
    };
  }

  factory ExamAssignment.fromMap(Map<String, dynamic> map) {
    return ExamAssignment(
      id: map['id'],
      subjectId: map['subject_id'],
      title: map['title'],
      date: map['date'],
      type: map['type'],
      description: map['description'],
    );
  }

  int get daysUntil {
    final examDate = DateTime.parse(date);
    final now = DateTime.now();
    return examDate.difference(now).inDays;
  }

  bool get isUpcoming => daysUntil >= 0;
  bool get isOverdue => daysUntil < 0;
}
