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
    if (_summary.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text('${_period.toUpperCase()} Summary'),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Weekly'),
              Tab(text: 'Monthly'),
              Tab(text: 'Yearly'),
            ],
          ),
        ),
        body: Center(child: Text('No study records this $_period.')),
      );
    }

    final pieSections = _summary.map((item) {
      final hours = item['total_duration'] / 60.0;
      final subject = _subjects.firstWhere(
        (s) => s.id == item['subject_id'],
        orElse: () => Subject(id: 0, name: 'Deleted'),
      );
      return PieChartSectionData(
        value: hours,
        title: '${subject.name}\n${hours.toStringAsFixed(1)}h',
        color: [Colors.lightBlue, Colors.orange][item['subject_id'] % 2],
        radius: 50,
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('${_period.toUpperCase()} Summary'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Weekly'),
            Tab(text: 'Monthly'),
            Tab(text: 'Yearly'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Card(
              margin: const EdgeInsets.all(8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: PieChart(
                  PieChartData(
                    sections: pieSections,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _summary.length,
              itemBuilder: (context, index) {
                final item = _summary[index];
                final subject = _subjects.firstWhere(
                  (s) => s.id == item['subject_id'],
                  orElse: () => Subject(id: 0, name: 'Deleted'),
                );
                final sessions = item['session_count'];
                final hours = item['total_duration'] / 60.0;
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    title: Text(subject.name),
                    subtitle: Text('$sessions sessions, ${hours.toStringAsFixed(1)} hours'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
