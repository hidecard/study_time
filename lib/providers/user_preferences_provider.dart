import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserPreferencesProvider with ChangeNotifier {
  String _userName = 'Student';
  String _selectedTheme = 'default';
  bool _notificationsEnabled = true;
  TimeOfDay? _studyReminderTime;
  bool _darkModeEnabled = false;
  double _textScaleFactor = 1.0;
  bool _voiceOverEnabled = false;
  List<String> _achievements = [];
  String _lastQuoteDate = '';
  String _dailyQuote = '';

  // Getters
  String get userName => _userName;
  String get selectedTheme => _selectedTheme;
  bool get notificationsEnabled => _notificationsEnabled;
  TimeOfDay? get studyReminderTime => _studyReminderTime;
  bool get darkModeEnabled => _darkModeEnabled;
  double get textScaleFactor => _textScaleFactor;
  bool get voiceOverEnabled => _voiceOverEnabled;
  List<String> get achievements => _achievements;
  String get dailyQuote => _dailyQuote;

  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _userName = prefs.getString('userName') ?? 'Student';
    _selectedTheme = prefs.getString('selectedTheme') ?? 'default';
    _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;

    final reminderHour = prefs.getInt('reminderHour');
    final reminderMinute = prefs.getInt('reminderMinute');
    if (reminderHour != null && reminderMinute != null) {
      _studyReminderTime = TimeOfDay(hour: reminderHour, minute: reminderMinute);
    }

    _darkModeEnabled = prefs.getBool('darkModeEnabled') ?? false;
    _textScaleFactor = prefs.getDouble('textScaleFactor') ?? 1.0;
    _voiceOverEnabled = prefs.getBool('voiceOverEnabled') ?? false;
    _achievements = prefs.getStringList('achievements') ?? [];
    _lastQuoteDate = prefs.getString('lastQuoteDate') ?? '';
    _dailyQuote = prefs.getString('dailyQuote') ?? getMotivationalQuote();

    notifyListeners();
  }

  Future<void> setUserName(String name) async {
    _userName = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', name);
    notifyListeners();
  }

  Future<void> setSelectedTheme(String theme) async {
    _selectedTheme = theme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedTheme', theme);
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', enabled);
    notifyListeners();
  }

  Future<void> setStudyReminderTime(TimeOfDay? time) async {
    _studyReminderTime = time;
    final prefs = await SharedPreferences.getInstance();
    if (time != null) {
      await prefs.setInt('reminderHour', time.hour);
      await prefs.setInt('reminderMinute', time.minute);
    } else {
      await prefs.remove('reminderHour');
      await prefs.remove('reminderMinute');
    }
    notifyListeners();
  }

  Future<void> setDarkModeEnabled(bool enabled) async {
    _darkModeEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkModeEnabled', enabled);
    notifyListeners();
  }

  Future<void> setTextScaleFactor(double factor) async {
    _textScaleFactor = factor;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('textScaleFactor', factor);
    notifyListeners();
  }

  Future<void> setVoiceOverEnabled(bool enabled) async {
    _voiceOverEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('voiceOverEnabled', enabled);
    notifyListeners();
  }

  Future<void> addAchievement(String achievement) async {
    if (!_achievements.contains(achievement)) {
      _achievements.add(achievement);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('achievements', _achievements);
      notifyListeners();
    }
  }

  Future<void> checkAndAwardAchievements(double totalStudyHours, int currentStreak, int totalSessions) async {
    final newAchievements = <String>[];

    // Study hour achievements
    if (totalStudyHours >= 1 && !_achievements.contains('First Hour Studied')) {
      newAchievements.add('First Hour Studied');
    }
    if (totalStudyHours >= 10 && !_achievements.contains('10 Hours Studied')) {
      newAchievements.add('10 Hours Studied');
    }
    if (totalStudyHours >= 50 && !_achievements.contains('50 Hours Studied')) {
      newAchievements.add('50 Hours Studied');
    }
    if (totalStudyHours >= 100 && !_achievements.contains('Century Club (100 Hours)')) {
      newAchievements.add('Century Club (100 Hours)');
    }

    // Streak achievements
    if (currentStreak >= 3 && !_achievements.contains('3-Day Streak')) {
      newAchievements.add('3-Day Streak');
    }
    if (currentStreak >= 7 && !_achievements.contains('Week Warrior (7 Days)')) {
      newAchievements.add('Week Warrior (7 Days)');
    }
    if (currentStreak >= 30 && !_achievements.contains('Monthly Master (30 Days)')) {
      newAchievements.add('Monthly Master (30 Days)');
    }

    // Session achievements
    if (totalSessions >= 10 && !_achievements.contains('10 Sessions Completed')) {
      newAchievements.add('10 Sessions Completed');
    }
    if (totalSessions >= 50 && !_achievements.contains('50 Sessions Completed')) {
      newAchievements.add('50 Sessions Completed');
    }
    if (totalSessions >= 100 && !_achievements.contains('Century Sessions (100)')) {
      newAchievements.add('Century Sessions (100)');
    }

    // Add new achievements
    for (final achievement in newAchievements) {
      await addAchievement(achievement);
    }
  }

  Future<void> updateDailyQuote() async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    if (_lastQuoteDate != today) {
      _lastQuoteDate = today;
      _dailyQuote = getMotivationalQuote();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('lastQuoteDate', today);
      await prefs.setString('dailyQuote', _dailyQuote);
      notifyListeners();
    }
  }

  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  String getMotivationalQuote() {
    final quotes = [
      "The only way to do great work is to love what you do. - Steve Jobs",
      "Believe you can and you're halfway there. - Theodore Roosevelt",
      "The future belongs to those who believe in the beauty of their dreams. - Eleanor Roosevelt",
      "You miss 100% of the shots you don't take. - Wayne Gretzky",
      "The best way to predict the future is to create it. - Peter Drucker",
      "Success is not final, failure is not fatal: It is the courage to continue that counts. - Winston Churchill",
      "The only limit to our realization of tomorrow will be our doubts of today. - Franklin D. Roosevelt",
      "Don't watch the clock; do what it does. Keep going. - Sam Levenson",
      "The secret of getting ahead is getting started. - Mark Twain",
      "Your time is limited, so don't waste it living someone else's life. - Steve Jobs",
      "Study is not just about learning facts, it's about training your mind to think. - Albert Einstein",
      "The beautiful thing about learning is that no one can take it away from you. - B.B. King",
      "Education is the most powerful weapon which you can use to change the world. - Nelson Mandela",
      "The more that you read, the more things you will know. The more that you learn, the more places you'll go. - Dr. Seuss",
      "Learning never exhausts the mind. - Leonardo da Vinci",
    ];
    return quotes[DateTime.now().day % quotes.length];
  }

  ThemeData getThemeData() {
    final baseTheme = _darkModeEnabled ? ThemeData.dark() : ThemeData.light();

    switch (_selectedTheme) {
      case 'purple':
        return baseTheme.copyWith(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.purple,
            brightness: _darkModeEnabled ? Brightness.dark : Brightness.light,
          ),
        );
      case 'blue':
        return baseTheme.copyWith(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: _darkModeEnabled ? Brightness.dark : Brightness.light,
          ),
        );
      case 'green':
        return baseTheme.copyWith(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.green,
            brightness: _darkModeEnabled ? Brightness.dark : Brightness.light,
          ),
        );
      default:
        return baseTheme.copyWith(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6366F1),
            brightness: _darkModeEnabled ? Brightness.dark : Brightness.light,
          ),
        );
    }
  }
}
