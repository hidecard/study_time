import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/subject.dart';
import '../models/study_record.dart';
import '../providers/study_record_provider.dart';

class HistoryPage extends StatefulWidget {
  final Subject subject;

  const HistoryPage({super.key, required this.subject});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StudyRecordProvider>().loadRecordsBySubject(widget.subject.id!);
    });
  }

  @override
  Widget build(BuildContext context) {
    final recordProvider = context.watch<StudyRecordProvider>();
    final records = recordProvider.records;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.subject.name} History',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF87CEEB), // sky blue
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onPrimary),
        elevation: 4,
      ),
      body: records.isEmpty
          ? const Center(
              child: Text(
                'No study records yet.\nTap + to add one!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: records.length,
              itemBuilder: (context, index) {
                final record = records[index];
                final start = DateTime.parse(record.startTime);
                final end = DateTime.parse(record.endTime);
                final durationHours = record.duration / 60;

                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Text(
                        DateFormat('d').format(start),
                        style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
                      ),
                    ),
                    title: Text(
                      '${DateFormat('MMM dd, yyyy').format(start)}',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                    ),
                    subtitle: Text(
                      '${DateFormat('HH:mm').format(start)} - ${DateFormat('HH:mm').format(end)}\n'
                      '⏱ ${formatDuration(durationHours)}\n'
                      '${record.description ?? ''}',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, size: 24, color: Colors.redAccent),
                      onPressed: () => _deleteRecord(record.id!),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        onPressed: () => _showAddRecordSheet(),
        icon: const Icon(Icons.add),
        label: const Text("Add Record"),
      ),
    );
  }

  void _showAddRecordSheet() {
    DateTime? startTime;
    DateTime? endTime;
    final descriptionController = TextEditingController();
    final durationController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 16,
          left: 16,
          right: 16,
        ),
        child: StatefulBuilder(
          builder: (context, setState) => SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Add Study Record",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  tileColor: Colors.grey[100],
                  title: Text(startTime == null
                      ? 'Select Start Time'
                      : DateFormat('yyyy-MM-dd HH:mm').format(startTime!)),
                  trailing: const Icon(Icons.calendar_today, size: 24, color: Colors.blueAccent),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (time != null) {
                        setState(() {
                          startTime = DateTime(picked.year, picked.month, picked.day, time.hour, time.minute);
                          if (startTime != null && endTime != null) {
                            final duration = endTime!.difference(startTime!).inMinutes;
                            durationController.text = formatDuration(duration / 60.0);
                          }
                        });
                      }
                    }
                  },
                ),
                const SizedBox(height: 12),
                ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  tileColor: Colors.grey[100],
                  title: Text(endTime == null
                      ? 'Select End Time'
                      : DateFormat('yyyy-MM-dd HH:mm').format(endTime!)),
                  trailing: const Icon(Icons.calendar_today, size: 24, color: Colors.blueAccent),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (time != null) {
                        setState(() {
                          endTime = DateTime(picked.year, picked.month, picked.day, time.hour, time.minute);
                          if (startTime != null && endTime != null) {
                            final duration = endTime!.difference(startTime!).inMinutes;
                            durationController.text = formatDuration(duration / 60.0);
                          }
                        });
                      }
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description (optional)',
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: durationController,
                  decoration: InputDecoration(
                    labelText: 'Duration (calculated)',
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceVariant,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  readOnly: true,
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B6BFF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      if (startTime != null && endTime != null && endTime!.isAfter(startTime!)) {
                        final duration = endTime!.difference(startTime!).inMinutes;
                        final record = StudyRecord(
                          subjectId: widget.subject.id!,
                          startTime: startTime!.toIso8601String(),
                          endTime: endTime!.toIso8601String(),
                          duration: duration,
                          description: descriptionController.text.trim().isEmpty
                              ? null
                              : descriptionController.text.trim(),
                        );
                        await context.read<StudyRecordProvider>().addRecord(record);
                        Navigator.pop(context);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Invalid times. End time must be after start time.')),
                        );
                      }
                    },
                    icon: const Icon(Icons.save, size: 20),
                    label: const Text("Save"),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _deleteRecord(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Record'),
        content: const Text('Are you sure you want to delete this record?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              await context.read<StudyRecordProvider>().deleteRecord(id, widget.subject.id!);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
