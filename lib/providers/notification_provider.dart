import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../database_helper.dart';
import '../models/notification_reminder.dart';

class NotificationProvider with ChangeNotifier {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  List<NotificationReminder> _reminders = [];
  bool _notificationsEnabled = true;

  List<NotificationReminder> get reminders => _reminders;
  bool get notificationsEnabled => _notificationsEnabled;

  NotificationProvider() {
    _initializeNotifications();
    _loadReminders();
  }

  Future<void> _initializeNotifications() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
      },
    );

    // Request permissions
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  Future<void> _loadReminders() async {
    final data = await _dbHelper.rawQuery('SELECT * FROM notification_reminders');
    _reminders = data.map((item) => NotificationReminder.fromMap(item)).toList();
    notifyListeners();
  }

  Future<void> addReminder(NotificationReminder reminder) async {
    final id = await _dbHelper.rawInsert('''
      INSERT INTO notification_reminders (title, body, time, enabled)
      VALUES (?, ?, ?, ?)
    ''', [reminder.title, reminder.body, reminder.time, reminder.enabled ? 1 : 0]);

    reminder.id = id;
    _reminders.add(reminder);
    notifyListeners();

    if (reminder.enabled) {
      await _scheduleReminder(reminder);
    }
  }

  Future<void> updateReminder(NotificationReminder reminder) async {
    if (reminder.id != null) {
      await _dbHelper.rawUpdate('''
        UPDATE notification_reminders
        SET title = ?, body = ?, time = ?, enabled = ?
        WHERE id = ?
      ''', [reminder.title, reminder.body, reminder.time, reminder.enabled ? 1 : 0, reminder.id]);

      final index = _reminders.indexWhere((r) => r.id == reminder.id);
      if (index != -1) {
        _reminders[index] = reminder;
        notifyListeners();
      }

      await _cancelReminder(reminder.id!);
      if (reminder.enabled) {
        await _scheduleReminder(reminder);
      }
    }
  }

  Future<void> deleteReminder(int id) async {
    await _dbHelper.rawDelete('DELETE FROM notification_reminders WHERE id = ?', [id]);
    _reminders.removeWhere((reminder) => reminder.id == id);
    await _cancelReminder(id);
    notifyListeners();
  }

  Future<void> _scheduleReminder(NotificationReminder reminder) async {
    final timeParts = reminder.time.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'study_reminder_channel',
      'Study Reminders',
      channelDescription: 'Reminders for study sessions',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails();

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      reminder.id!,
      reminder.title,
      reminder.body,
      scheduledDate,
      platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      // The following parameter name changed in newer versions of flutter_local_notifications
      // Use 'uiLocalNotificationDateInterpretation' or 'matchDateTimeComponents' accordingly
      // For compatibility, comment out the next line if it causes errors
      // uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> _cancelReminder(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }

  Future<void> showDailySummaryNotification(double todayStudied, double goal) async {
    if (!_notificationsEnabled) return;

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'daily_summary_channel',
      'Daily Summary',
      channelDescription: 'Daily study summary notifications',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      showWhen: false,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails();

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    final message = 'You studied ${todayStudied.toStringAsFixed(1)}h today, goal ${goal.toStringAsFixed(1)}h';

    await _flutterLocalNotificationsPlugin.show(
      999, // Unique ID for daily summary
      'Daily Study Summary',
      message,
      platformChannelSpecifics,
    );
  }

  Future<void> showPomodoroBreakNotification() async {
    if (!_notificationsEnabled) return;

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'pomodoro_channel',
      'Pomodoro Timer',
      channelDescription: 'Pomodoro timer notifications',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails();

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      1000, // Unique ID for pomodoro break
      'Break Time!',
      'Your Pomodoro break is over. Time to get back to studying!',
      platformChannelSpecifics,
    );
  }

  void setNotificationsEnabled(bool enabled) {
    _notificationsEnabled = enabled;
    notifyListeners();
  }
}
