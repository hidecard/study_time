import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../database_helper.dart';
import '../models/subject.dart';
import '../models/goal.dart';
import '../models/exam_assignment.dart';
import '../providers/goal_provider.dart';
import '../providers/exam_assignment_provider.dart';

class SummaryPage extends StatefulWidget {
  const SummaryPage({super.key});

  @override
  State<SummaryPage> createState() => _SummaryPageState();
}

class _SummaryPageState extends State<SummaryPage> with TickerProviderStateMixin {
  List<Map<String, dynamic>> _summary = [];
  List<Subject> _subjects = [];
  String _period = 'week';
  String? _selectedCategory;
  late TabController _tabController;
  bool _showExamsTab = false;

  String formatDuration(double hours) {
    int totalMinutes = (hours * 60).round();
    int fullHours = totalMinutes ~/ 60;
    int minutes = totalMinutes % 60;
    if (minutes == 0) {
      return '$fullHours hour${fullHours != 1 ? 's' : ''}';
    } else {
      return '$fullHours hour${fullHours != 1 ? 's' : ''} $minutes Minuts';
    }
  }

  List<Color> get _chartColors => [
    Colors.redAccent,
    Colors.blueAccent,
    Colors.greenAccent,
    Colors.orangeAccent,
    Colors.purpleAccent,
    Colors.tealAccent,
    Colors.pinkAccent,
    Colors.yellowAccent,
  ];

  Goal? _goal;
  double _progressPercent = 0.0;

  List<String> get _categories => _subjects.map((s) => s.category).where((c) => c != null).cast<String>().toSet().toList();

  List<Map<String, dynamic>> get _filteredSummary {
    if (_selectedCategory == null) return _summary;
    final filteredSubjects = _subjects.where((s) => s.category == _selectedCategory).toList();
    return _summary.where((item) => filteredSubjects.any((s) => s.id == item['subject_id'])).toList();
  }

  List<Subject> get _filteredSubjects {
    if (_selectedCategory == null) return _subjects;
    return _subjects.where((s) => s.category == _selectedCategory).toList();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {
        if (_tabController.index < 3) {
          _period = ['week', 'month', 'year'][_tabController.index];
          _showExamsTab = false;
        } else {
          _showExamsTab = true;
        }
      });
      if (!_showExamsTab) {
        _loadSummary();
        _loadGoal();
      }
    });
    _loadSummary();
    _loadGoal();
  }

  Future<void> _loadGoal() async {
    final goalProvider = Provider.of<GoalProvider>(context, listen: false);
    await goalProvider.loadGoal(_period);
    setState(() {
      _goal = goalProvider.goal;
      _progressPercent = 0.0;
      if (_goal != null && _summary.isNotEmpty) {
        int totalDuration = 0;
        if (_period == 'week') {
          totalDuration = _summary.fold<int>(0, (sum, item) => sum + ((item['total_duration'] as int?) ?? 0));
        } else if (_period == 'month') {
          totalDuration = _summary.fold<int>(0, (sum, item) => sum + ((item['total_duration'] as int?) ?? 0));
        } else if (_period == 'year') {
          totalDuration = _summary.fold<int>(0, (sum, item) => sum + ((item['total_duration'] as int?) ?? 0));
        }
        _progressPercent = (totalDuration / _goal!.targetMinutes).clamp(0.0, 1.0);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSummary() async {
    final dbHelper = DatabaseHelper();
    List<Map<String, dynamic>> summary;
    if (_period == 'week') {
      summary = await dbHelper.queryWeeklySummary();
    } else {
      final whereClause = _period == 'month'
          ? "strftime('%Y-%m', start_time) = strftime('%Y-%m', 'now')"
          : "strftime('%Y', start_time) = strftime('%Y', 'now')";
      summary = await dbHelper.rawQuery('''
        SELECT subject_id, COUNT(*) as session_count, SUM(duration) as total_duration
        FROM study_records
        WHERE $whereClause
        GROUP BY subject_id
        ORDER BY total_duration DESC
      ''');
    }
    final subjectsData = await dbHelper.queryAllSubjects();
    setState(() {
      _summary = summary;
      _subjects = subjectsData.map((item) => Subject.fromMap(item)).toList();
    });
  }

  void _setGoal() {
    final controller = TextEditingController(text: _goal?.targetMinutes.toString() ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Set $_period Goal (minutes)'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Target minutes'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final minutes = int.tryParse(controller.text);
              if (minutes != null && minutes > 0) {
                final goal = Goal(targetMinutes: minutes, period: _period);
                await Provider.of<GoalProvider>(context, listen: false).setGoal(goal);
                Navigator.pop(context);
                _loadGoal();
              }
            },
            child: const Text('Set'),
          ),
        ],
      ),
    );
  }

  void _addExamAssignment() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    String selectedType = 'exam';
    int? selectedSubjectId = _subjects.isNotEmpty ? _subjects.first.id : null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Exam/Assignment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: const [
                    DropdownMenuItem(value: 'exam', child: Text('Exam')),
                    DropdownMenuItem(value: 'assignment', child: Text('Assignment')),
                  ],
                  onChanged: (value) => setState(() => selectedType = value!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: selectedSubjectId,
                  decoration: const InputDecoration(labelText: 'Subject'),
                  items: _subjects.map((subject) => DropdownMenuItem(
                    value: subject.id,
                    child: Text(subject.name),
                  )).toList(),
                  onChanged: (value) => setState(() => selectedSubjectId = value),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text('Date: ${selectedDate.toLocal().toString().split(' ')[0]}'),
                    const Spacer(),
                    TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setState(() => selectedDate = picked);
                        }
                      },
                      child: const Text('Select Date'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Description (optional)'),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty && selectedSubjectId != null) {
                  final examAssignment = ExamAssignment(
                    subjectId: selectedSubjectId!,
                    title: titleController.text,
                    date: selectedDate.toLocal().toString().split(' ')[0],
                    type: selectedType,
                    description: descriptionController.text.isEmpty ? null : descriptionController.text,
                  );
                  Provider.of<ExamAssignmentProvider>(context, listen: false).addExamAssignment(examAssignment);
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: _showExamsTab ? FloatingActionButton(
        onPressed: _addExamAssignment,
        child: const Icon(Icons.add),
      ) : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Modern Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
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
                  "Study Summary",
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Track your progress 📊",
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          // Tab Bar
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: Theme.of(context).colorScheme.primary,
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              unselectedLabelStyle: GoogleFonts.poppins(),
              tabs: const [
                Tab(text: 'Weekly'),
                Tab(text: 'Monthly'),
                Tab(text: 'Yearly'),
                Tab(text: 'Exams'),
              ],
            ),
          ),
          // Category Filter
          if (_categories.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Text(
                    'Filter by Category:',
                    style: GoogleFonts.poppins(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _selectedCategory,
                    hint: Text(
                      'All',
                      style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface),
                    ),
                    dropdownColor: Theme.of(context).colorScheme.surface,
                    style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('All'),
                      ),
                      ..._categories.map((category) => DropdownMenuItem<String>(
                            value: category,
                            child: Text(category),
                          )),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    },
                  ),
                ],
              ),
            ),

          // Body
          Expanded(
            child: _showExamsTab
                ? _buildExamsTab()
                : _filteredSummary.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bar_chart_outlined,
                          size: 80,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No study records this $_period${_selectedCategory != null ? ' for $_selectedCategory' : ''}.\nStart learning 📚",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      // 🔹 Bar Chart Section
                      Expanded(
                        flex: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 4,
                            color: Theme.of(context).colorScheme.surface,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: _filteredSummary.length <= 5
                                  ? PieChart(
                                      PieChartData(
                                        sectionsSpace: 4,
                                        centerSpaceRadius: 40,
                                        borderData: FlBorderData(show: false),
                                        sections: _filteredSummary.asMap().entries.map((entry) {
                                          final index = entry.key;
                                          final item = entry.value;
                                          final hours = item['total_duration'] / 60.0;
                                          final subject = _filteredSubjects.firstWhere(
                                            (s) => s.id == item['subject_id'],
                                            orElse: () => Subject(id: 0, name: 'Deleted'),
                                          );
                                          return PieChartSectionData(
                                            value: hours,
                                            title: subject.name,
                                            color: _chartColors[index % _chartColors.length],
                                            radius: 60,
                                titleStyle: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                                          );
                                        }).toList(),
                                      ),
                                    )
                                  : BarChart(
                                      BarChartData(
                                        barGroups: _filteredSummary.asMap().entries.map((entry) {
                                          final index = entry.key;
                                          final item = entry.value;
                                          final hours = item['total_duration'] / 60.0;
                                          return BarChartGroupData(
                                            x: index,
                                            barRods: [
                                              BarChartRodData(
                                                toY: hours,
                                                color: _chartColors[index % _chartColors.length],
                                                width: 20,
                                              ),
                                            ],
                                          );
                                        }).toList(),
                                        titlesData: FlTitlesData(
                                          bottomTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: true,
                                              getTitlesWidget: (value, meta) {
                                                final index = value.toInt();
                                                if (index >= 0 && index < _filteredSummary.length) {
                                                  final subject = _filteredSubjects.firstWhere(
                                                    (s) => s.id == _filteredSummary[index]['subject_id'],
                                                    orElse: () => Subject(id: 0, name: 'Deleted'),
                                                  );
                                                  return Text(
                                                    subject.name,
                                                    style: const TextStyle(fontSize: 10),
                                                  );
                                                }
                                                return const Text('');
                                              },
                                            ),
                                          ),
                                          leftTitles: AxisTitles(
                                            sideTitles: SideTitles(showTitles: true),
                                          ),
                                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                        ),
                                        borderData: FlBorderData(show: false),
                                        gridData: FlGridData(show: true),
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),

                      // 🔹 List Section
                      Expanded(
                        flex: 5,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredSummary.length,
                          itemBuilder: (context, index) {
                            final item = _filteredSummary[index];
                            final subject = _filteredSubjects.firstWhere(
                              (s) => s.id == item['subject_id'],
                              orElse: () => Subject(id: 0, name: 'Deleted'),
                            );
                            final sessions = item['session_count'];
                            final hours = item['total_duration'] / 60.0;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context).colorScheme.shadow.withOpacity(0.05),
                                    blurRadius: 6,
                                    offset: const Offset(2, 3),
                                  )
                                ],
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: _chartColors[index % _chartColors.length],
                                  child: const Icon(Icons.book, color: Colors.white),
                                ),
                                title: Text(
                                  subject.name,
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    RichText(
                                      text: TextSpan(
                                        text: "$sessions sessions • ",
                                        style: GoogleFonts.poppins(
                                          color: _chartColors[index % _chartColors.length],
                                        ),
                                        children: [
                                          TextSpan(
                                            text: formatDuration(hours),
                                            style: GoogleFonts.poppins(
                                              color: _chartColors[index % _chartColors.length],
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (_period == 'week' && subject.weeklyGoalMinutes > 0)
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 4),
                                          LinearProgressIndicator(
                                            value: (item['total_duration'] / subject.weeklyGoalMinutes).clamp(0.0, 1.0),
                                            backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                                            color: _chartColors[index % _chartColors.length],
                                            minHeight: 4,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Goal: ${(subject.weeklyGoalMinutes / 60).toStringAsFixed(1)} hours - ${(100 * (item['total_duration'] / subject.weeklyGoalMinutes).clamp(0.0, 1.0)).toStringAsFixed(1)}%',
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildExamsTab() {
    final examAssignmentProvider = Provider.of<ExamAssignmentProvider>(context);
    final upcoming = examAssignmentProvider.getUpcomingExamsAssignments();

    return upcoming.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.assignment_outlined,
                  size: 80,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'No upcoming exams or assignments',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: upcoming.length,
            itemBuilder: (context, index) {
              final item = upcoming[index];
              final subject = _subjects.firstWhere(
                (s) => s.id == item.subjectId,
                orElse: () => Subject(id: 0, name: 'Unknown Subject'),
              );

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.shadow.withOpacity(0.05),
                      blurRadius: 6,
                      offset: const Offset(2, 3),
                    )
                  ],
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: item.type == 'exam' ? Colors.redAccent : Colors.blueAccent,
                    child: Icon(
                      item.type == 'exam' ? Icons.school : Icons.assignment,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    item.title,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${subject.name} • ${item.type.capitalize()} on ${item.date}',
                        style: GoogleFonts.poppins(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.daysUntil == 0
                            ? 'Today!'
                            : item.daysUntil == 1
                                ? 'Tomorrow'
                                : '${item.daysUntil} days left',
                        style: GoogleFonts.poppins(
                          color: item.daysUntil <= 1 ? Colors.redAccent : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      examAssignmentProvider.deleteExamAssignment(item.id!);
                    },
                  ),
                ),
              );
            },
          );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}
