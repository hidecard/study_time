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
        title: Text('${widget.subject.name} History'),
      ),
      body: records.isEmpty
          ? const Center(child: Text('No study records yet. Add one!'))
          : ListView.builder(
              itemCount: records.length,
              itemBuilder: (context, index) {
                final record = records[index];
                final start = DateTime.parse(record.startTime);
                final end = DateTime.parse(record.endTime);
                final durationHours = record.duration / 60;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  elevation: 2,
                  child: ListTile(
                    title: Text('${DateFormat('yyyy-MM-dd HH:mm').format(start)} - ${DateFormat('HH:mm').format(end)}'),
                    subtitle: Text('Duration: ${durationHours.toStringAsFixed(1)} hours\n${record.description ?? ''}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deleteRecord(record.id!),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddRecordDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddRecordDialog() {
    DateTime? startTime;
    DateTime? endTime;
    final descriptionController = TextEditingController();
    final durationController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Study Record'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(startTime == null ? 'Select Start Time' : DateFormat('yyyy-MM-dd HH:mm').format(startTime!)),
                trailing: const Icon(Icons.calendar_today),
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
                          durationController.text = '$duration minutes';
                        }
                      });
                    }
                  }
                },
              ),
              ListTile(
                title: Text(endTime == null ? 'Select End Time' : DateFormat('yyyy-MM-dd HH:mm').format(endTime!)),
                trailing: const Icon(Icons.calendar_today),
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
                          durationController.text = '$duration minutes';
                        }
                      });
                    }
                  }
                },
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description (optional)'),
              ),
              TextField(
                controller: durationController,
                decoration: const InputDecoration(labelText: 'Duration (calculated)'),
                readOnly: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (startTime != null && endTime != null && endTime!.isAfter(startTime!)) {
                  final duration = endTime!.difference(startTime!).inMinutes;
                  final record = StudyRecord(
                    subjectId: widget.subject.id!,
                    startTime: startTime!.toIso8601String(),
                    endTime: endTime!.toIso8601String(),
                    duration: duration,
                    description: descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim(),
                  );
                  await context.read<StudyRecordProvider>().addRecord(record);
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invalid times. End time must be after start time.')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteRecord(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Record'),
        content: const Text('Are you sure you want to delete this record?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
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
