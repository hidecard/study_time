import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import '../database_helper.dart';
import '../models/study_record.dart';
import '../models/subject.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<StudyRecord>> _events = {};
  List<StudyRecord> _selectedEvents = [];
  List<Subject> _subjects = [];

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final dbHelper = DatabaseHelper();
    final records = await dbHelper.queryAllStudyRecords();
    final subjectsData = await dbHelper.queryAllSubjects();
    final subjects = subjectsData.map((item) => Subject.fromMap(item)).toList();

    Map<DateTime, List<StudyRecord>> events = {};
    for (var record in records) {
      final studyRecord = StudyRecord.fromMap(record);
      final startDateTime = DateTime.parse(studyRecord.startTime);
      final date = DateTime(
        startDateTime.year,
        startDateTime.month,
        startDateTime.day,
      );
      if (events[date] == null) {
        events[date] = [];
      }
      events[date]!.add(studyRecord);
    }

    setState(() {
      _events = events;
    });
  }

  List<StudyRecord> _getEventsForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
        _selectedEvents = _getEventsForDay(selectedDay);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFF87CEEB),
            ),
            child: const Text(
              "Study Calendar",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),

          // Calendar
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            eventLoader: _getEventsForDay,
            onDaySelected: _onDaySelected,
            onFormatChanged: (format) {
              if (_calendarFormat != format) {
                setState(() {
                  _calendarFormat = format;
                });
              }
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            calendarStyle: const CalendarStyle(
              selectedDecoration: BoxDecoration(
                color: Color(0xFF87CEEB),
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Selected Day Events
          Expanded(
            child: _selectedEvents.isEmpty
                ? Center(
                    child: Text(
                      _selectedDay == null
                          ? 'Select a day to view study records'
                          : 'No study records on ${_selectedDay!.toLocal().toString().split(' ')[0]}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _selectedEvents.length,
                    itemBuilder: (context, index) {
                      final record = _selectedEvents[index];
                      final startTime = DateTime.parse(record.startTime).toLocal();
                      final endTime = DateTime.parse(record.endTime).toLocal();
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(record.description?.isNotEmpty == true ? record.description! : 'Study Session'),
                          subtitle: Text(
                            'Duration: ${(record.duration / 60).toStringAsFixed(1)} hours\n'
                            'Time: ${startTime.toString().split(' ')[1].substring(0, 5)} - ${endTime.toString().split(' ')[1].substring(0, 5)}',
                          ),
                          leading: const Icon(Icons.book),
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
