import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/subject.dart';
import '../providers/subject_provider.dart';
import 'history_page.dart';

class SubjectsPage extends StatefulWidget {
  const SubjectsPage({super.key});

  @override
  State<SubjectsPage> createState() => _SubjectsPageState();
}

class _SubjectsPageState extends State<SubjectsPage> {
  late List<Duration> _animationDelays;
  final List<List<Color>> _cardGradients = [
    [Colors.red.shade400, Colors.orange.shade400],
    [Colors.blue.shade400, Colors.green.shade400],
    [Colors.purple.shade400, Colors.pink.shade400],
    [Colors.teal.shade400, Colors.cyan.shade400],
    [const Color.fromARGB(255, 130, 119, 17), const Color.fromARGB(255, 171, 139, 31)],
    [Colors.indigo.shade400, Colors.lightBlue.shade400],
  ];ix

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SubjectProvider>().loadSubjects();
    });
    // Prepare animation delays for grid items
    _animationDelays = List.generate(20, (index) => Duration(milliseconds: index * 100));
  }

  @override
  Widget build(BuildContext context) {
    final subjectProvider = context.watch<SubjectProvider>();
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
                  "My Subjects",
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Keep track of your studies 📚",
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          // 🔹 Subject Grid / Empty State
          Expanded(
            child: subjects.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.book_outlined,
                          size: 80,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No subjects yet.\nTap + to add one!",
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
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: subjects.length,
                    itemBuilder: (context, index) {
                      final subject = subjects[index];
                      final delay = _animationDelays[index % _animationDelays.length];

                      return TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOut,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: Opacity(
                              opacity: value,
                              child: child,
                            ),
                          );
                        },
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => HistoryPage(subject: subject),
                              ),
                            );
                          },
                          child: Card(
                            elevation: 8,
                            shadowColor: Theme.of(context).colorScheme.shadow.withOpacity(0.2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: _cardGradients[index % _cardGradients.length],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: Colors.white.withOpacity(0.2),
                                        child: Icon(
                                          Icons.book,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        subject.name,
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (subject.category != null && subject.category!.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 1),
                                          child: Text(
                                            subject.category!,
                                            style: GoogleFonts.poppins(
                                              fontSize: 8,
                                              color: Colors.white.withOpacity(0.8),
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.edit, size: 18, color: Colors.white),
                                        onPressed: () => _showSubjectDialog(subject: subject),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete, size: 18, color: Colors.white),
                                        onPressed: () => _deleteSubject(subject.id!),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),

      // 🔹 Floating Add Button
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSubjectDialog(),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.add, size: 32),
      ),
    );
  }

  void _showSubjectDialog({Subject? subject}) {
    final isEditing = subject != null;
    final nameController =
        TextEditingController(text: isEditing ? subject.name : '');
    final goalController = TextEditingController(
        text: isEditing ? (subject.weeklyGoalMinutes / 60).toStringAsFixed(1) : '0');
    final categoryController =
        TextEditingController(text: isEditing ? subject.category ?? '' : '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isEditing ? 'Edit Subject' : 'Add Subject'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Subject Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: goalController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Weekly Goal (hours)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: categoryController,
              decoration: const InputDecoration(
                labelText: 'Category (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              final name = nameController.text.trim();
              final goalMinutes = (double.tryParse(goalController.text) ?? 0) * 60;
              final category = categoryController.text.trim().isEmpty ? null : categoryController.text.trim();
              if (name.isNotEmpty) {
                if (isEditing) {
                  final updatedSubject =
                      Subject(id: subject!.id, name: name, weeklyGoalMinutes: goalMinutes.toInt(), category: category);
                  await context
                      .read<SubjectProvider>()
                      .updateSubject(updatedSubject);
                } else {
                  final newSubject = Subject(name: name, weeklyGoalMinutes: goalMinutes.toInt(), category: category);
                  await context.read<SubjectProvider>().addSubject(newSubject);
                }
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteSubject(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Subject'),
        content:
            const Text('Are you sure you want to delete this subject?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              await context.read<SubjectProvider>().deleteSubject(id);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
