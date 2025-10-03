# Study Time Tracker App - Code Flow and Documentation

## Overview
The Study Time Tracker is a Flutter application designed to help users track their study sessions across different subjects. It features a local SQLite database for data persistence, provider-based state management, and a modern Material Design UI.

## Architecture
- **Models**: Data classes for Subject, StudyRecord, Goal
- **Providers**: State management using Provider pattern for Subjects, StudyRecords, Goals
- **Database**: SQLite database with CRUD operations
- **Pages**: UI screens for different app functionalities
- **Main**: App entry point with routing and theme setup

## Pages Documentation

### 1. Main.dart (Entry Point)
**Purpose**: Initializes the Flutter app with providers, theme, and navigation structure.

**Code Flow**:
1. `main()` function calls `runApp(MyApp())`
2. `MyApp` widget sets up `MultiProvider` with SubjectProvider, StudyRecordProvider, GoalProvider
3. MaterialApp configured with theme, dark theme, and HomePage as initial route
4. HomePage contains bottom navigation bar with 3 tabs: Subjects, Summary, Calendar

**Key Components**:
- MultiProvider for state management
- MaterialApp with custom theme using Google Fonts (Poppins)
- BottomNavigationBar with custom styling

### 2. HomePage (Dashboard)
**Purpose**: Displays personalized dashboard with study metrics, greeting, and quick stats.

**Code Flow**:
1. `initState()` calls `_loadDashboardData()`
2. `_loadDashboardData()` queries database for:
   - Today's total study time
   - Weekly total study time
   - Weekly goals from all subjects
   - Current study streak
3. `build()` renders gradient background with cards showing:
   - Today's study time
   - Weekly progress with goal
   - Current streak
   - Next reminder (placeholder)

**Key Features**:
- Gradient background (red to teal)
- Card-based layout with shadows
- Real-time data from SQLite queries
- Streak calculation algorithm

### 3. SubjectsPage
**Purpose**: Manages subjects with CRUD operations, displays subjects in animated grid.

**Code Flow**:
1. `initState()` loads subjects via SubjectProvider
2. `build()` renders:
   - Gradient header with title and subtitle
   - GridView of subject cards with animations
   - Floating action button for adding subjects
3. Subject cards show name, category, edit/delete buttons
4. Tapping card navigates to HistoryPage
5. Dialogs for add/edit/delete operations

**Key Features**:
- Animated grid with staggered animations
- Gradient cards with different color schemes
- CRUD operations with confirmation dialogs
- Navigation to subject-specific history

### 4. HistoryPage
**Purpose**: Shows study records for a specific subject with add/delete functionality.

**Code Flow**:
1. Receives Subject as parameter
2. `initState()` loads records for the subject via StudyRecordProvider
3. `build()` renders:
   - AppBar with gradient background (matching SubjectsPage style)
   - ListView of study records or empty state
   - Floating action button for adding records
4. Bottom sheet for adding new records with date/time pickers
5. Delete confirmation dialogs

**Key Features**:
- Date/time picker integration
- Duration calculation from start/end times
- Rich text display with formatted information
- Modal bottom sheet for record creation

### 5. CalendarPage
**Purpose**: Calendar view showing study sessions as events on dates.

**Code Flow**:
1. `initState()` calls `_loadEvents()`
2. `_loadEvents()` queries all study records and subjects, groups records by date
3. `build()` renders:
   - Header with title
   - TableCalendar widget with event markers
   - Expanded area showing selected day's events or empty message
4. Day selection updates `_selectedEvents` and refreshes UI
5. Events displayed as cards with duration, time, description

**Key Features**:
- TableCalendar integration with custom styling
- Event loading and date grouping
- Day selection handling
- Formatted duration display (hours/minutes)

### 6. SummaryPage
**Purpose**: Analytics dashboard with charts, progress bars, and filtering.

**Code Flow**:
1. `initState()` sets up TabController and loads initial data
2. `_loadSummary()` queries weekly summary grouped by subject
3. `_loadGoal()` loads goal for current period
4. `build()` renders:
   - TabBar for period selection (week/month/year)
   - Pie chart of study time distribution
   - List of subjects with progress bars
   - Category filter dropdown
5. Tab changes trigger data reload

**Key Features**:
- FlChart integration for pie charts
- Period-based filtering (week/month/year)
- Progress indicators for goals
- Category-based filtering

## Models

### Subject
- id: int?
- name: String
- weeklyGoalMinutes: int
- category: String?

### StudyRecord
- id: int?
- subjectId: int
- startTime: String (ISO8601)
- endTime: String (ISO8601)
- duration: int (minutes)
- description: String?

### Goal
- id: int?
- targetMinutes: int
- period: String ('week', 'month', 'year')

## Providers

### SubjectProvider
- Manages list of subjects
- CRUD operations: loadSubjects, addSubject, updateSubject, deleteSubject
- Delete cascades to study records

### StudyRecordProvider
- Manages study records for specific subject
- Operations: loadRecordsBySubject, addRecord, updateRecord, deleteRecord

### GoalProvider
- Manages study goals by period
- Operations: loadGoal, setGoal, deleteGoal

## Database Helper

### DatabaseHelper (Singleton)
- SQLite database with tables: subjects, study_records, goals
- CRUD methods for each table
- Raw queries for analytics (weekly summary, streaks)
- Migration support (onUpgrade)

## Key Features Implemented

1. **Local Data Persistence**: SQLite database with full CRUD
2. **State Management**: Provider pattern for reactive UI
3. **Modern UI**: Material Design 3, gradients, animations
4. **Calendar Integration**: TableCalendar for date visualization
5. **Charts**: FlChart for data visualization
6. **Time Tracking**: Date/time pickers, duration calculation
7. **Goal Setting**: Weekly goals with progress tracking
8. **Responsive Design**: Adaptive layouts and themes

## Dependencies
- sqflite: SQLite database
- provider: State management
- table_calendar: Calendar widget
- fl_chart: Charts and graphs
- google_fonts: Typography
- intl: Date/time formatting
- path_provider: File system access

## Navigation Flow
HomePage (Bottom Nav) → SubjectsPage | SummaryPage | CalendarPage
SubjectsPage → HistoryPage (per subject)
HistoryPage → Add Record (bottom sheet)
