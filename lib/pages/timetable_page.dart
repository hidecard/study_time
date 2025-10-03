import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/subject.dart';
import '../models/timetable_slot.dart';
import '../providers/subject_provider.dart';
import '../providers/timetable_provider.dart';

class TimetablePage extends StatefulWidget {
  const TimetablePage({super.key});

  @override
  State<TimetablePage> createState() => _TimetablePageState();
}

class _TimetablePageState extends State<TimetablePage> {
  final List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final List<String> _timeSlots = [
    '08:00', '09:00', '10:00', '11:00', '12:00',
    '13:00', '14:00', '15:00', '16:00', '17:00',
    '18:00', '19:00', '20:00', '21:00'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SubjectProvider>().loadSubjects();
      context.read<TimetableProvider>().loadTimetable();
    });
  }

  @override
  Widget build(BuildContext context) {
    final subjectProvider = context.watch<SubjectProvider>();
    final timetableProvider = context.watch<TimetableProvider>();
    final subjects = subjectProvider.subjects;

    return Scaffold(
      body: Column(
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
                  "Weekly Timetable",
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Drag subjects to schedule your study time 📅",
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          // 🔹 Subjects Palette
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Available Subjects',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: subjects.map((subject) {
                    return Draggable<Subject>(
                      data: subject,
                      feedback: Material(
                        elevation: 8,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            subject.name,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      childWhenDragging: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey),
                        ),
                        child: Text(
                          subject.name,
                          style: GoogleFonts.poppins(
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          subject.name,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // 🔹 Timetable Grid
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Header Row
                  Row(
                    children: [
                      Container(
                        width: 60,
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          'Time',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      ..._days.map((day) => Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            day,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )),
                    ],
                  ),
                  // Time Slots
                  ..._timeSlots.map((time) => Row(
                    children: [
                      Container(
                        width: 60,
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          time,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      ...List.generate(7, (dayIndex) => Expanded(
                        child: _TimetableCell(
                          dayOfWeek: dayIndex + 1,
                          timeSlot: time,
                          timetableProvider: timetableProvider,
                          subjects: subjects,
                        ),
                      )),
                    ],
                  )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimetableCell extends StatelessWidget {
  final int dayOfWeek;
  final String timeSlot;
  final TimetableProvider timetableProvider;
  final List<Subject> subjects;

  const _TimetableCell({
    required this.dayOfWeek,
    required this.timeSlot,
    required this.timetableProvider,
    required this.subjects,
  });

  @override
  Widget build(BuildContext context) {
    final slots = timetableProvider.slots.where((slot) =>
      slot.dayOfWeek == dayOfWeek &&
      slot.startTime == timeSlot
    ).toList();

    return DragTarget<Subject>(
      onAccept: (subject) async {
        // Create a new slot for the next hour
        final endTime = _getNextHour(timeSlot);
        final newSlot = TimetableSlot(
          dayOfWeek: dayOfWeek,
          startTime: timeSlot,
          endTime: endTime,
          subjectId: subject.id,
        );
        await timetableProvider.addSlot(newSlot);
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          height: 40,
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: slots.isNotEmpty
              ? Colors.blue.withOpacity(0.2)
              : candidateData.isNotEmpty
                ? Colors.blue.withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: candidateData.isNotEmpty
                ? Colors.blue
                : Colors.grey.withOpacity(0.3),
              width: candidateData.isNotEmpty ? 2 : 1,
            ),
          ),
          child: slots.isNotEmpty
            ? GestureDetector(
                onLongPress: () => _showSlotOptions(context, slots.first),
                child: Center(
                  child: Text(
                    subjects.firstWhere(
                      (s) => s.id == slots.first.subjectId,
                      orElse: () => Subject(name: 'Unknown'),
                    ).name,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : const SizedBox(),
        );
      },
    );
  }

  String _getNextHour(String time) {
    final parts = time.split(':');
    final hour = int.parse(parts[0]) + 1;
    return '${hour.toString().padLeft(2, '0')}:00';
  }

  void _showSlotOptions(BuildContext context, TimetableSlot slot) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Remove Slot'),
              onTap: () {
                timetableProvider.deleteSlot(slot.id!);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
