# Study Time Tracker 📚⏱️

A beautiful and intuitive Flutter application to help students track their study sessions, manage subjects, set goals, and visualize progress over time.

## Features ✨

### 📖 Subject Management
- Create and organize study subjects
- Set weekly goals for each subject
- Categorize subjects for better organization
- Edit and delete subjects with confirmation dialogs

### ⏰ Study Session Logging
- Log study sessions with start and end times
- Automatic duration calculation
- Add descriptions to sessions
- View detailed history for each subject

### 📊 Progress Visualization
- Dashboard with today's study time and weekly progress
- Interactive calendar view with study events
- Summary charts (pie/bar) by week, month, or year
- Goal progress tracking with visual indicators
- Streak counter for consecutive study days

### 🎨 Modern UI/UX
- Material Design 3 with custom theming
- Gradient backgrounds and smooth animations
- Responsive design for mobile devices
- Dark mode support (system theme)

### 💾 Local Data Storage
- SQLite database for offline functionality
- No internet connection required
- Data persists between app sessions

## Screenshots 📱

*[Add screenshots here when available]*

## Installation 🚀

### Prerequisites
- Flutter SDK (version 3.0 or higher)
- Dart SDK
- Android Studio or VS Code with Flutter extensions
- Android/iOS device or emulator

### Setup
1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/study_time_tracker.git
   cd study_time_tracker
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

### Build for Production
- **Android APK**:
  ```bash
  flutter build apk --release
  ```

- **iOS** (on macOS):
  ```bash
  flutter build ios --release
  ```

## Usage 📖

### Getting Started
1. **Add Subjects**: Start by creating subjects you want to track
2. **Set Goals**: Define weekly study goals for each subject
3. **Log Sessions**: Record your study sessions with times and descriptions
4. **Track Progress**: View your progress on the dashboard and summary pages

### Navigation
- **Home**: Dashboard with key metrics
- **Subjects**: Manage your study subjects
- **Summary**: View detailed progress charts
- **Calendar**: See study sessions on a calendar

## Architecture 🏗️

### Project Structure
```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── subject.dart
│   ├── study_record.dart
│   └── goal.dart
├── providers/                # State management
│   ├── subject_provider.dart
│   ├── study_record_provider.dart
│   └── goal_provider.dart
├── pages/                    # UI screens
│   ├── home_page.dart
│   ├── subjects_page.dart
│   ├── summary_page.dart
│   ├── calendar_page.dart
│   └── history_page.dart
└── database_helper.dart      # SQLite database operations
```

### Key Technologies
- **Flutter**: Cross-platform UI framework
- **Provider**: State management solution
- **SQLite**: Local database via sqflite package
- **Table Calendar**: Calendar widget for study events
- **FL Chart**: Data visualization charts
- **Google Fonts**: Typography

### Data Models
- **Subject**: Study subjects with goals and categories
- **StudyRecord**: Individual study sessions
- **Goal**: Period-based study goals (week/month/year)

## Dependencies 📦

Key packages used:
- `provider`: State management
- `sqflite`: SQLite database
- `path_provider`: File system paths
- `table_calendar`: Calendar widget
- `fl_chart`: Charts and graphs
- `google_fonts`: Custom fonts
- `intl`: Date/time formatting

See `pubspec.yaml` for complete dependency list.

## Contributing 🤝

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines
- Follow Flutter best practices
- Use Provider for state management
- Maintain consistent code style
- Add tests for new features
- Update documentation as needed

## Testing 🧪

Run tests:
```bash
flutter test
```

Run integration tests:
```bash
flutter drive --target=test_driver/app.dart
```

## License 📄

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments 🙏

- Flutter team for the amazing framework
- Open source community for packages and inspiration
- Students everywhere who need better study tracking! 📚

---

**Made with ❤️ for students by students**
