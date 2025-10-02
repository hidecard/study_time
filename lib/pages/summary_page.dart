import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../database_helper.dart';
import '../models/subject.dart';

class SummaryPage extends StatefulWidget {
  const SummaryPage({super.key});

  @override
  State<SummaryPage> createState() => _SummaryPageState();
}

class _SummaryPageState extends State<SummaryPage> with TickerProviderStateMixin {
  List<Map<String, dynamic>> _summary = [];
  List<Subject> _subjects = [];
  String _period = 'week';
  late TabController _tabController;

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

  final List<Color> _chartColors = [
    Colors.blue.shade700,
    Colors.pink.shade700,
    Colors.green.shade700,
    Colors.orange.shade700,
    Colors.purple.shade700,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _period = ['week', 'month', 'year'][_tabController.index];
      });
      _loadSummary();
    });
    _loadSummary();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header like subjects page
          Container(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFF87CEEB), // sky blue
            ),
            child: const Text(
              "Study Summary",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          // Tab Bar
          Container(
            color: const Color(0xFF87CEEB), // sky blue
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white.withOpacity(0.7),
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              tabs: const [
                Tab(text: 'Weekly'),
                Tab(text: 'Monthly'),
                Tab(text: 'Yearly'),
              ],
            ),
          ),
          // Body
          Expanded(
            child: _summary.isEmpty
                ? Center(
                    child: Text(
                      "No study records this $_period.\nStart learning 📚",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        fontWeight: FontWeight.w500,
                      ),
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
                              child: _summary.length <= 5
                                  ? PieChart(
                                      PieChartData(
                                        sectionsSpace: 4,
                                        centerSpaceRadius: 40,
                                        borderData: FlBorderData(show: false),
                                        sections: _summary.asMap().entries.map((entry) {
                                          final index = entry.key;
                                          final item = entry.value;
                                          final hours = item['total_duration'] / 60.0;
                                          final subject = _subjects.firstWhere(
                                            (s) => s.id == item['subject_id'],
                                            orElse: () => Subject(id: 0, name: 'Deleted'),
                                          );
                                          return PieChartSectionData(
                                            value: hours,
                                            title: subject.name,
                                            color: _chartColors[index % _chartColors.length],
                                            radius: 60,
                                            titleStyle: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              color: Colors.black,
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    )
                                  : BarChart(
                                      BarChartData(
                                        barGroups: _summary.asMap().entries.map((entry) {
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
                                                if (index >= 0 && index < _summary.length) {
                                                  final subject = _subjects.firstWhere(
                                                    (s) => s.id == _summary[index]['subject_id'],
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
                          itemCount: _summary.length,
                          itemBuilder: (context, index) {
                            final item = _summary[index];
                            final subject = _subjects.firstWhere(
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
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                subtitle: RichText(
                                  text: TextSpan(
                                    text: "$sessions sessions • ",
                                    style: TextStyle(color: _chartColors[index % _chartColors.length]),
                                    children: [
                                      TextSpan(
                                        text: formatDuration(hours),
                                        style: TextStyle(
                                          color: _chartColors[index % _chartColors.length],
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
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
}
