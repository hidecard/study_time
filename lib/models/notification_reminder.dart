class NotificationReminder {
  int? id;
  String title;
  String body;
  String time; // HH:mm format
  bool enabled;

  NotificationReminder({
    this.id,
    required this.title,
    required this.body,
    required this.time,
    this.enabled = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'time': time,
      'enabled': enabled ? 1 : 0,
    };
  }

  factory NotificationReminder.fromMap(Map<String, dynamic> map) {
    return NotificationReminder(
      id: map['id'],
      title: map['title'],
      body: map['body'],
      time: map['time'],
      enabled: map['enabled'] == 1,
    );
  }
}
