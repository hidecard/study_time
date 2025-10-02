import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database_helper.dart';
import '../models/subject.dart';
import '../providers/subject_provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  double _todayStudied = 0.0;
  double _weeklyTotal = 0.0;
  double _weeklyGoal = 0.0;
  int _currentStreak = 0;
  String _nextReminder = 'No reminder set';

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final dbHelper = DatabaseHelper();

    // Today's study time
    final todayData = await dbHelper.rawQuery('''
      SELECT SUM(duration) as total
      FROM study_records
      WHERE date(start_time) = date('now')
    ''');
    _todayStudied = (todayData.first['total'] as int? ?? 0) / 60.0;

    // Weekly total
    final weeklyData = await dbHelper.queryWeeklySummary();
    _weeklyTotal = weeklyData.fold<double>(0.0, (sum, item) => sum + (item['total_duration'] as int) / 60.0);

    // Weekly goal: sum of all subject weekly goals
    final subjects = context.read<SubjectProvider>().subjects;
    _weeklyGoal = subjects.fold<double>(0.0, (sum, subject) => sum + subject.weeklyGoalMinutes / 60.0);

    // Calculate current streak
    final streakData = await dbHelper.rawQuery('''
      SELECT DISTINCT date(start_time) as study_date
      FROM study_records
      ORDER BY study_date DESC
    ''');
    final studyDates = streakData.map((row) => DateTime.parse(row['study_date'] as String)).toList();
    _currentStreak = _calculateStreak(studyDates);

    setState(() {});
  }

  int _calculateStreak(List<DateTime> studyDates) {
    if (studyDates.isEmpty) return 0;
    int streak = 1;
    for (int i = 0; i < studyDates.length - 1; i++) {
      final current = studyDates[i];
      final next = studyDates[i + 1];
      final difference = current.difference(next).inDays;
      if (difference == 1) {
        streak++;
      } else if (difference > 1) {
        break;
      }
    }
    return streak;
  }

  String formatDuration(double hours) {
    int totalMinutes = (hours * 60).round();
    int fullHours = totalMinutes ~/ 60;
    int minutes = totalMinutes % 60;
    if (minutes == 0) {
      return '$fullHours hour${fullHours != 1 ? 's' : ''}';
    } else {
      return '$fullHours hour${fullHours != 1 ? 's' : ''} $minutes min';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF87CEEB), Color(0xFFE0F7FA)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Good morning!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ready to study today? 📚',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 40),
                // Today's study
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, size: 40, color: Color(0xFF87CEEB)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Today studied',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              formatDuration(_todayStudied),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Weekly progress
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'This week total',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            '${_weeklyTotal.toStringAsFixed(1)}h / ${_weeklyGoal.toStringAsFixed(1)}h goal',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: LinearProgressIndicator(
                              value: _weeklyGoal > 0 ? (_weeklyTotal / _weeklyGoal).clamp(0.0, 1.0) : 0.0,
                              backgroundColor: Colors.grey.shade200,
                              color: const Color(0xFF87CEEB),
                              minHeight: 8,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Streak
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.local_fire_department, size: 40, color: Colors.orange),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Current Streak',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              '🔥 $_currentStreak day${_currentStreak != 1 ? 's' : ''}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Next reminder
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.notifications, size: 40, color: Color(0xFF87CEEB)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Next reminder',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              _nextReminder,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
