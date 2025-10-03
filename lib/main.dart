import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/subject_provider.dart';
import 'providers/study_record_provider.dart';
import 'providers/goal_provider.dart';
import 'providers/user_preferences_provider.dart';
import 'providers/notification_provider.dart';
import 'pages/home_page.dart' as dashboard;
import 'pages/subjects_page.dart';
import 'pages/summary_page.dart';
import 'pages/calendar_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SubjectProvider()),
        ChangeNotifierProvider(create: (_) => StudyRecordProvider()),
        ChangeNotifierProvider(create: (_) => GoalProvider()),
        ChangeNotifierProvider(create: (_) => UserPreferencesProvider()..loadPreferences()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: Consumer<UserPreferencesProvider>(
        builder: (context, userPrefs, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Study Time Tracker',
            theme: userPrefs.getThemeData(),
            themeMode: userPrefs.darkModeEnabled ? ThemeMode.dark : ThemeMode.light,
            home: const HomePage(),
          );
        },
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  static final List<Widget> _pages = <Widget>[
    const dashboard.DashboardPage(), // Dashboard
    const SubjectsPage(),
    const SummaryPage(),
    const CalendarPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],

      // 🔹 Custom Bottom Navigation Bar
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(22),
            topRight: Radius.circular(22),
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -3),
            )
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home, size: 28),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.book_outlined),
              activeIcon: Icon(Icons.book, size: 28),
              label: 'Subjects',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              activeIcon: Icon(Icons.bar_chart, size: 28),
              label: 'Summary',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_outlined),
              activeIcon: Icon(Icons.calendar_today, size: 28),
              label: 'Calendar',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: const Color(0xFF9C27B0), // purple
          unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
