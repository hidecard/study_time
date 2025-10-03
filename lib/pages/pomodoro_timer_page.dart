import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:circular_countdown_timer/circular_countdown_timer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';
import '../models/subject.dart';
import '../models/study_record.dart';
import '../providers/subject_provider.dart';
import '../providers/study_record_provider.dart';
import '../providers/notification_provider.dart';

class PomodoroTimerPage extends StatefulWidget {
  final Subject? subject;

  const PomodoroTimerPage({super.key, this.subject});

  @override
  State<PomodoroTimerPage> createState() => _PomodoroTimerPageState();
}

class _PomodoroTimerPageState extends State<PomodoroTimerPage> {
  final CountDownController _controller = CountDownController();
  final ConfettiController _confettiController = ConfettiController(duration: const Duration(seconds: 2));

  bool _isStudyMode = true;
  int _studyDuration = 25; // minutes
  int _breakDuration = 5; // minutes
  int _currentDuration = 25;
  String _currentMode = 'Study';
  bool _isRunning = false;
  bool _isPaused = false;
  DateTime? _startTime;
  int _completedPomodoros = 0;

  @override
  void initState() {
    super.initState();
    _currentDuration = _studyDuration;
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _toggleTimer() {
    if (_isRunning) {
      _controller.pause();
      setState(() {
        _isPaused = true;
      });
    } else {
      if (_startTime == null) {
        _startTime = DateTime.now();
      }
      _controller.resume();
      setState(() {
        _isPaused = false;
      });
    }
    setState(() {
      _isRunning = !_isRunning;
    });
  }

  void _resetTimer() {
    _controller.reset();
    setState(() {
      _isRunning = false;
      _isPaused = false;
      _startTime = null;
    });
  }

  void _onTimerComplete() async {
    // Play confetti
    _confettiController.play();

    // Show completion dialog
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_isStudyMode ? 'Study Session Complete!' : 'Break Time Over!'),
        content: Text(_isStudyMode
            ? 'Great job! Take a well-deserved break.'
            : 'Break time is over. Ready for another study session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (_isStudyMode) {
      // Study session completed
      _completedPomodoros++;
      await _saveStudyRecord();

      // Switch to break mode
      setState(() {
        _isStudyMode = false;
        _currentMode = 'Break';
        _currentDuration = _breakDuration;
      });
    } else {
      // Break completed, switch back to study
      setState(() {
        _isStudyMode = true;
        _currentMode = 'Study';
        _currentDuration = _studyDuration;
      });
    }

    // Auto-start next session
    _resetTimer();
    Future.delayed(const Duration(seconds: 1), () {
      _toggleTimer();
    });

    // Send notification
    final notificationProvider = context.read<NotificationProvider>();
    if (_isStudyMode) {
      await notificationProvider.showPomodoroBreakNotification();
    }
  }

  Future<void> _saveStudyRecord() async {
    if (widget.subject != null && _startTime != null) {
      final endTime = DateTime.now();
      final duration = endTime.difference(_startTime!).inMinutes;

      final record = StudyRecord(
        subjectId: widget.subject!.id!,
        startTime: _startTime!.toIso8601String(),
        endTime: endTime.toIso8601String(),
        duration: duration,
        description: 'Pomodoro Study Session',
      );

      await context.read<StudyRecordProvider>().addRecord(record);
    }
  }

  void _showSettingsDialog() {
    int studyMins = _studyDuration;
    int breakMins = _breakDuration;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Timer Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Study Duration (minutes)'),
              keyboardType: TextInputType.number,
              controller: TextEditingController(text: studyMins.toString()),
              onChanged: (value) => studyMins = int.tryParse(value) ?? 25,
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(labelText: 'Break Duration (minutes)'),
              keyboardType: TextInputType.number,
              controller: TextEditingController(text: breakMins.toString()),
              onChanged: (value) => breakMins = int.tryParse(value) ?? 5,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _studyDuration = studyMins;
                _breakDuration = breakMins;
                if (_isStudyMode) {
                  _currentDuration = _studyDuration;
                } else {
                  _currentDuration = _breakDuration;
                }
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.subject != null ? '${widget.subject!.name} Timer' : 'Pomodoro Timer',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettingsDialog,
          ),
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _currentMode,
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: _isStudyMode ? Colors.red : Colors.green,
                  ),
                ),
                const SizedBox(height: 40),
                CircularCountDownTimer(
                  duration: _currentDuration * 60,
                  initialDuration: 0,
                  controller: _controller,
                  width: MediaQuery.of(context).size.width / 2,
                  height: MediaQuery.of(context).size.width / 2,
                  ringColor: Colors.grey[300]!,
                  ringGradient: null,
                  fillColor: _isStudyMode ? Colors.red : Colors.green,
                  fillGradient: null,
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  backgroundGradient: null,
                  strokeWidth: 20.0,
                  strokeCap: StrokeCap.round,
                  textStyle: GoogleFonts.poppins(
                    fontSize: 33.0,
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                  textFormat: CountdownTextFormat.MM_SS,
                  isReverse: true,
                  isReverseAnimation: false,
                  isTimerTextShown: true,
                  autoStart: false,
                  onStart: () {
                    debugPrint('Countdown Started');
                  },
                  onComplete: _onTimerComplete,
                  onChange: (String timeStamp) {
                    debugPrint('Countdown Changed $timeStamp');
                  },
                  timeFormatterFunction: (defaultFormatterFunction, duration) {
                    if (duration.inSeconds == 0) {
                      return "Start";
                    } else {
                      return Function.apply(defaultFormatterFunction, [duration]);
                    }
                  },
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _toggleTimer,
                      icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
                      label: Text(_isRunning ? 'Pause' : 'Start'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: _resetTimer,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reset'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Completed Pomodoros: $_completedPomodoros',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple
              ],
            ),
          ),
        ],
      ),
    );
  }
}
