class StudyRecord {
  int? id;
  int subjectId;
  String startTime;
  String endTime;
  int duration; // in minutes
  String? description;

  StudyRecord({
    this.id,
    required this.subjectId,
    required this.startTime,
    required this.endTime,
    required this.duration,
    this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subject_id': subjectId,
      'start_time': startTime,
      'end_time': endTime,
      'duration': duration,
      'description': description,
    };
  }

  factory StudyRecord.fromMap(Map<String, dynamic> map) {
    return StudyRecord(
      id: map['id'],
      subjectId: map['subject_id'],
      startTime: map['start_time'],
      endTime: map['end_time'],
      duration: map['duration'],
      description: map['description'],
    );
  }
}
