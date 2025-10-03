import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../database_helper.dart';
import '../models/subject.dart';
import '../providers/subject_provider.dart';
import '../providers/user_preferences_provider.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  double _todayStudied = 0.0;
  double _weeklyTotal = 0.0;
  double _weeklyGoal = 0.0;
  int _currentStreak = 0;
  String _nextReminder = 'No reminder set';

  String _greeting = '';
  String _dailyQuote = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _loadUserPreferences();
  }

  Future<void> _loadUserPreferences() async {
    final userPrefs = context.read<UserPreferencesProvider>();
    await userPrefs.loadPreferences();
    setState(() {
      _greeting = userPrefs.getGreeting() + ', ' + userPrefs.userName + ' 👋';
      _dailyQuote = userPrefs.dailyQuote;
      _isLoading = false;
    });
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

    // Check for achievements
    final totalStudyHours = await dbHelper.rawQuery('SELECT SUM(duration) as total FROM study_records');
    final totalHours = (totalStudyHours.first['total'] as int? ?? 0) / 60.0;
    final totalSessions = await dbHelper.rawQuery('SELECT COUNT(*) as count FROM study_records');
    final sessionsCount = totalSessions.first['count'] as int? ?? 0;
    await context.read<UserPreferencesProvider>().checkAndAwardAchievements(totalHours, _currentStreak, sessionsCount);

    setState(() {});
  }

  int _calculateStreak(List<DateTime> studyDates) {
    if (studyDates.isEmpty) return 0;
    int streak = 1;
    DateTime previousDate = studyDates[0];
    for (int i = 1; i < studyDates.length; i++) {
      final difference = previousDate.difference(studyDates[i]).inDays;
      if (difference == 1) {
        streak++;
        previousDate = studyDates[i];
      } else if (difference > 1) {
        break;
      }
    }
    return streak;
  }

  @override
  Widget build(BuildContext context) {
    final userPrefs = context.watch<UserPreferencesProvider>();

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔹 Modern Header
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.deepPurpleAccent,
                        Colors.pinkAccent,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(28),
                      bottomRight: Radius.circular(28),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.shadow.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _greeting,
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '"$_dailyQuote"',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),

                // 🔹 Dashboard Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                'Today',
                                '${_todayStudied.toStringAsFixed(1)}h',
                                Icons.today,
                                Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildStatCard(
                                'This Week',
                                '${_weeklyTotal.toStringAsFixed(1)}h',
                                Icons.calendar_view_week,
                                Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                'Weekly Goal',
                                '${_weeklyGoal.toStringAsFixed(1)}h',
                                Icons.flag,
                                Colors.orange,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildStatCard(
                                'Streak',
                                '$_currentStreak days',
                                Icons.local_fire_department,
                                Colors.red,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        if (userPrefs.achievements.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Recent Achievements',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: userPrefs.achievements.take(3).map((achievement) {
                                  return Chip(
                                    label: Text(achievement),
                                    avatar: const Icon(Icons.emoji_events),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: color.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}
