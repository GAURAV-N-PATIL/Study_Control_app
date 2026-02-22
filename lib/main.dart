import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().initNotifications();
  runApp(const StudyControlApp());
}

class StudyControlApp extends StatefulWidget {
  const StudyControlApp({Key? key}) : super(key: key);

  @override
  State<StudyControlApp> createState() => _StudyControlAppState();
}

class _StudyControlAppState extends State<StudyControlApp> {
  bool isDarkMode = false;
  Color primaryColor = const Color(0xFFE8D5F2);

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkMode = prefs.getBool('dark_mode') ?? false;
      final colorValue = prefs.getInt('primary_color') ?? 0xFFE8D5F2;
      primaryColor = Color(colorValue);
    });
  }

  void _toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkMode = !isDarkMode;
    });
    await prefs.setBool('dark_mode', isDarkMode);
  }

  void _changePrimaryColor(Color newColor) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      primaryColor = newColor;
    });
    await prefs.setInt('primary_color', newColor.value);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Study Control',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFFAF8FF),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      debugShowCheckedModeBanner: false,
      home: MainScreen(
        onThemeToggle: _toggleTheme,
        onColorChange: _changePrimaryColor,
        isDarkMode: isDarkMode,
        primaryColor: primaryColor,
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  final VoidCallback onThemeToggle;
  final Function(Color) onColorChange;
  final bool isDarkMode;
  final Color primaryColor;

  const MainScreen({
    Key? key,
    required this.onThemeToggle,
    required this.onColorChange,
    required this.isDarkMode,
    required this.primaryColor,
  }) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      DashboardScreen(
        onTabChange: _onTabChange,
        primaryColor: widget.primaryColor,
        isDarkMode: widget.isDarkMode,
      ),
      TaskScreenWithSearch(
        primaryColor: widget.primaryColor,
        isDarkMode: widget.isDarkMode,
      ),
      AssignmentsScreenWithSearch(
        primaryColor: widget.primaryColor,
        isDarkMode: widget.isDarkMode,
      ),
      CalendarViewScreen(
        primaryColor: widget.primaryColor,
        isDarkMode: widget.isDarkMode,
      ),
      StudyGoalsScreen(
        primaryColor: widget.primaryColor,
        isDarkMode: widget.isDarkMode,
      ),
      PomodoroTimerScreen(
        primaryColor: widget.primaryColor,
        isDarkMode: widget.isDarkMode,
      ),
      StatisticsScreen(
        primaryColor: widget.primaryColor,
        isDarkMode: widget.isDarkMode,
      ),
      SettingsScreen(
        onThemeToggle: widget.onThemeToggle,
        onColorChange: widget.onColorChange,
        isDarkMode: widget.isDarkMode,
        primaryColor: widget.primaryColor,
      ),
    ];
  }

  void _onTabChange(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          widget.isDarkMode ? const Color(0xFF121212) : const Color(0xFFFAF8FF),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 8,
        selectedItemColor: widget.primaryColor,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle_rounded),
            label: 'Tasks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_rounded),
            label: 'Assignment',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_rounded),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.target_rounded),
            label: 'Goals',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.timer_rounded),
            label: 'Pomodoro',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_rounded),
            label: 'Stats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

// NOTIFICATION SERVICE
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  Future<void> initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
      },
    );

    // Request permissions
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationPermission();

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  Future<void> showNotification(
    int id,
    String title,
    String body,
  ) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'channel_id',
      'Study Reminders',
      channelDescription: 'Reminders for your study tasks',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
      payload: 'item x',
    );
  }

  Future<void> scheduleReminder(
    int id,
    String title,
    String body,
    DateTime scheduledTime,
  ) async {
    try {
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'channel_id',
            'Study Reminders',
            channelDescription: 'Reminders for your study tasks',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      print('Error scheduling notification: $e');
    }
  }

  Future<void> cancelReminder(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }
}

// Need to add these imports at the top:
// import 'package:timezone/data/latest.dart' as tz;
// import 'package:timezone/timezone.dart' as tz;

// DASHBOARD SCREEN
class DashboardScreen extends StatefulWidget {
  final Function(int) onTabChange;
  final Color primaryColor;
  final bool isDarkMode;

  const DashboardScreen({
    Key? key,
    required this.onTabChange,
    required this.primaryColor,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  double _taskProgress = 0.0;
  int _completedTasks = 0;
  int _totalTasks = 0;
  List<Task> _highPriorityTasks = [];
  List<ExamAssignment> _exams = [];
  int _totalAssignments = 0;
  int _completedAssignments = 0;
  int _pendingAssignments = 0;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _loadAllData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _loadTaskProgress();
    _loadHighPriorityTasks();
    _loadExams();
    _loadAssignmentStats();
    _animationController.forward();
  }

  Future<void> _loadTaskProgress() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _completedTasks = prefs.getInt('completed_tasks') ?? 0;
      _totalTasks = prefs.getInt('total_tasks') ?? 5;
      _taskProgress = _totalTasks > 0 ? _completedTasks / _totalTasks : 0.0;
    });
  }

  Future<void> _loadHighPriorityTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = prefs.getStringList('tasks') ?? [];
    final tasks = tasksJson.map((json) => Task.fromJson(jsonDecode(json))).toList();

    setState(() {
      _highPriorityTasks =
          tasks.where((t) => t.priority == 'High' && !t.isCompleted).take(3).toList();
    });
  }

  Future<void> _loadExams() async {
    final prefs = await SharedPreferences.getInstance();
    final examsJson = prefs.getStringList('exams') ?? [];
    final exams =
        examsJson.map((json) => ExamAssignment.fromJson(jsonDecode(json))).toList();

    final activeExams = exams.where((e) {
      final daysRemaining = _getDaysRemaining(e.dueDate);
      return daysRemaining >= -1;
    }).toList();

    setState(() {
      _exams = activeExams.take(3).toList();
    });
  }

  Future<void> _loadAssignmentStats() async {
    final prefs = await SharedPreferences.getInstance();
    final assignmentsJson = prefs.getStringList('assignments') ?? [];
    final assignments = assignmentsJson
        .map((json) => Assignment.fromJson(jsonDecode(json)))
        .toList();

    final nonExamAssignments = assignments.where((a) => !a.isExam).toList();

    setState(() {
      _totalAssignments = nonExamAssignments.length;
      _completedAssignments =
          nonExamAssignments.where((a) => a.status == 'Completed').length;
      _pendingAssignments = _totalAssignments - _completedAssignments;
    });
  }

  int _getDaysRemaining(String dateString) {
    try {
      final parts = dateString.split('/');
      if (parts.length == 3) {
        final month = int.parse(parts[0]);
        final day = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        final date = DateTime(year, month, day);
        final now = DateTime.now();
        return date.difference(now).inDays;
      }
    } catch (e) {
      // Handle error silently
    }
    return 0;
  }

  String _getDaysRemainingText(int days) {
    if (days == 0) {
      return 'Today';
    } else if (days == 1) {
      return 'Tomorrow';
    } else if (days < 0) {
      return 'Overdue';
    } else if (days <= 7) {
      return '$days days left';
    } else if (days <= 30) {
      final weeks = (days / 7).floor();
      return '$weeks week${weeks > 1 ? 's' : ''} left';
    } else {
      final months = (days / 30).floor();
      return '$months month${months > 1 ? 's' : ''} left';
    }
  }

  void _editExam(BuildContext context, int index) {
    final TextEditingController nameController =
        TextEditingController(text: _exams[index].name);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: widget.isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFFAF8FF),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Edit Exam',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  hintText: 'Exam name',
                  filled: true,
                  fillColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.grey.shade300,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () async {
                      if (nameController.text.isNotEmpty) {
                        final prefs = await SharedPreferences.getInstance();
                        _exams[index].name = nameController.text;

                        final examsJson =
                            _exams.map((e) => jsonEncode(e.toJson())).toList();
                        await prefs.setStringList('exams', examsJson);

                        setState(() {});
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.primaryColor,
                    ),
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dashboard',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.w300,
                            letterSpacing: 0.5,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Track your learning journey',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTaskProgressCard(),
                    const SizedBox(height: 24),
                    _buildTodayTasksSection(),
                    const SizedBox(height: 24),
                    _buildUpcomingExamsSection(),
                    const SizedBox(height: 24),
                    _buildAssignmentsOverviewSection(),
                    const SizedBox(height: 24),
                    _buildQuickLinksSection(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskProgressCard() {
    return Container(
      decoration: BoxDecoration(
        color: widget.primaryColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.primaryColor.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daily Progress',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$_completedTasks of $_totalTasks tasks',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 0.9 + (_animationController.value * 0.1),
                    child: SizedBox(
                      width: 70,
                      height: 70,
                      child: CircularProgressIndicator(
                        value: _taskProgress,
                        strokeWidth: 5,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          widget.primaryColor,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${(_taskProgress * 100).toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                'Done',
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              value: _taskProgress,
              minHeight: 10,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(
                widget.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayTasksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Today\'s Tasks',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: _highPriorityTasks.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      'No high priority tasks',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                )
              : Column(
                  children: _highPriorityTasks.asMap().entries.map((entry) {
                    Task task = entry.value;
                    return Column(
                      children: [
                        _buildTaskItem(task),
                        if (entry.key < _highPriorityTasks.length - 1)
                          const Divider(height: 16),
                      ],
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildTaskItem(Task task) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: task.isCompleted ? Colors.green : Colors.grey.shade300,
            border: Border.all(
              color: task.isCompleted ? Colors.green : Colors.grey.shade400,
              width: 2,
            ),
          ),
          child: task.isCompleted
              ? const Icon(Icons.check, size: 14, color: Colors.white)
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task.title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      decoration: task.isCompleted
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                task.time,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: task.isCompleted
                ? Colors.green.withOpacity(0.15)
                : Colors.orange.withOpacity(0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            task.isCompleted ? 'Done' : 'Pending',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: task.isCompleted ? Colors.green : Colors.orange,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingExamsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upcoming Exams',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        if (_exams.isEmpty)
          Container(
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.blue.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Text(
                'No exams scheduled',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          )
        else
          ..._exams.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildExamCard(entry.value, entry.key),
            );
          }).toList(),
      ],
    );
  }

  Widget _buildExamCard(ExamAssignment exam, int index) {
    final daysRemaining = _getDaysRemaining(exam.dueDate);
    final daysText = _getDaysRemainingText(daysRemaining);
    final isCompleted = exam.status == 'Completed';

    Color getDaysColor() {
      if (daysRemaining < 0) return Colors.red;
      if (daysRemaining <= 3) return Colors.orange;
      return Colors.blue;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.blue.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted
                  ? Colors.green.withOpacity(0.15)
                  : Colors.blue.withOpacity(0.15),
            ),
            child: const Center(child: Text('📚', style: TextStyle(fontSize: 24))),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(exam.name, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(exam.subject, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: getDaysColor().withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    daysText,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: getDaysColor(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                _editExam(context, index);
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 18),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentsOverviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Assignments Overview',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildAssignmentStat('Total', '$_totalAssignments', Colors.blue),
              _buildAssignmentStat(
                  'Pending', '$_pendingAssignments', Colors.orange),
              _buildAssignmentStat(
                  'Completed', '$_completedAssignments', Colors.green),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAssignmentStat(String label, String count, Color color) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.15),
          ),
          child: Center(
            child: Text(
              count,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }

  Widget _buildQuickLinksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Links',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => widget.onTabChange(2),
                child: _buildQuickLinkCard(
                  icon: Icons.assignment,
                  label: 'Assignments',
                  color: Colors.blue,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => widget.onTabChange(1),
                child: _buildQuickLinkCard(
                  icon: Icons.check_circle,
                  label: 'Tasks',
                  color: Colors.green,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => widget.onTabChange(5),
                child: _buildQuickLinkCard(
                  icon: Icons.timer,
                  label: 'Pomodoro',
                  color: Colors.red,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickLinkCard({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}

// TASK SCREEN WITH SEARCH & FILTER
class TaskScreenWithSearch extends StatefulWidget {
  final Color primaryColor;
  final bool isDarkMode;

  const TaskScreenWithSearch({
    Key? key,
    required this.primaryColor,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  State<TaskScreenWithSearch> createState() => _TaskScreenWithSearchState();
}

class _TaskScreenWithSearchState extends State<TaskScreenWithSearch> {
  List<Task> tasks = [];
  List<Task> filteredTasks = [];
  String searchQuery = '';
  String selectedPriorityFilter = 'All';
  bool showCompletedOnly = false;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = prefs.getStringList('tasks') ?? [];
    setState(() {
      tasks = tasksJson
          .map((json) => Task.fromJson(jsonDecode(json)))
          .toList();
    });
    _filterTasks();
  }

  void _filterTasks() {
    setState(() {
      filteredTasks = tasks.where((task) {
        final matchesSearch =
            task.title.toLowerCase().contains(searchQuery.toLowerCase());
        final matchesPriority = selectedPriorityFilter == 'All' ||
            task.priority == selectedPriorityFilter;
        final matchesStatus = !showCompletedOnly || task.isCompleted;

        return matchesSearch && matchesPriority && matchesStatus;
      }).toList();
    });
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson =
        tasks.map((task) => jsonEncode(task.toJson())).toList();
    await prefs.setStringList('tasks', tasksJson);
    _updateTaskProgress();
  }

  void _updateTaskProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final completedCount = tasks.where((t) => t.isCompleted).length;
    await prefs.setInt('completed_tasks', completedCount);
    await prefs.setInt('total_tasks', tasks.length);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'Tasks',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w300,
              ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                onChanged: (value) {
                  searchQuery = value;
                  _filterTasks();
                },
                decoration: InputDecoration(
                  hintText: 'Search tasks...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            // Filters
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All', 'All'),
                    _buildFilterChip('High', 'High'),
                    _buildFilterChip('Medium', 'Medium'),
                    _buildFilterChip('Low', 'Low'),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Completed'),
                      selected: showCompletedOnly,
                      onSelected: (value) {
                        setState(() {
                          showCompletedOnly = value;
                        });
                        _filterTasks();
                      },
                      backgroundColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
                      selectedColor: widget.primaryColor,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Task list
            Expanded(
              child: filteredTasks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No tasks found',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredTasks.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: TaskCard(
                            task: filteredTasks[index],
                            onToggle: () {
                              setState(() {
                                filteredTasks[index].isCompleted =
                                    !filteredTasks[index].isCompleted;
                                final originalIdx = tasks.indexOf(filteredTasks[index]);
                                if (originalIdx != -1) {
                                  tasks[originalIdx].isCompleted =
                                      filteredTasks[index].isCompleted;
                                }
                              });
                              _saveTasks();
                            },
                            onEdit: () => _editTask(context, index),
                            onDelete: () {
                              final taskToDelete = filteredTasks[index];
                              setState(() {
                                tasks.removeWhere((t) =>
                                    t.title == taskToDelete.title);
                                filteredTasks.removeAt(index);
                              });
                              _saveTasks();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Task deleted'),
                                  action: SnackBarAction(
                                    label: 'Undo',
                                    onPressed: () {
                                      setState(() {
                                        tasks.add(taskToDelete);
                                      });
                                      _saveTasks();
                                      _filterTasks();
                                    },
                                  ),
                                ),
                              );
                            },
                            primaryColor: widget.primaryColor,
                            isDarkMode: widget.isDarkMode,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: widget.primaryColor,
        onPressed: () => _addTask(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selectedPriorityFilter == value,
        onSelected: (isSelected) {
          setState(() {
            selectedPriorityFilter = isSelected ? value : 'All';
          });
          _filterTasks();
        },
        backgroundColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
        selectedColor: widget.primaryColor,
      ),
    );
  }

  void _addTask(BuildContext context) {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController timeController = TextEditingController();
    String selectedPriority = 'Medium';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: widget.isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFFAF8FF),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Add New Task',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    hintText: 'Task title',
                    filled: true,
                    fillColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: timeController,
                  decoration: InputDecoration(
                    hintText: 'Time (HH:MM)',
                    filled: true,
                    fillColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(8),
                    color: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButton<String>(
                    value: selectedPriority,
                    isExpanded: true,
                    underline: const SizedBox(),
                    items: ['Low', 'Medium', 'High']
                        .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedPriority = value ?? 'Medium';
                      });
                    },
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        if (titleController.text.isNotEmpty &&
                            timeController.text.isNotEmpty) {
                          this.setState(() {
                            tasks.add(
                              Task(
                                title: titleController.text,
                                time: timeController.text,
                                isCompleted: false,
                                priority: selectedPriority,
                              ),
                            );
                          });
                          _saveTasks();
                          _filterTasks();
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.primaryColor,
                      ),
                      child: const Text('Add'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _editTask(BuildContext context, int index) {
    final TextEditingController titleController =
        TextEditingController(text: filteredTasks[index].title);
    final TextEditingController timeController =
        TextEditingController(text: filteredTasks[index].time);
    String selectedPriority = filteredTasks[index].priority;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: widget.isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFFAF8FF),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Edit Task',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    hintText: 'Task title',
                    filled: true,
                    fillColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: timeController,
                  decoration: InputDecoration(
                    hintText: 'Time (HH:MM)',
                    filled: true,
                    fillColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(8),
                    color: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButton<String>(
                    value: selectedPriority,
                    isExpanded: true,
                    underline: const SizedBox(),
                    items: ['Low', 'Medium', 'High']
                        .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedPriority = value ?? 'Medium';
                      });
                    },
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        if (titleController.text.isNotEmpty &&
                            timeController.text.isNotEmpty) {
                          this.setState(() {
                            final idx = tasks.indexOf(filteredTasks[index]);
                            if (idx != -1) {
                              tasks[idx].title = titleController.text;
                              tasks[idx].time = timeController.text;
                              tasks[idx].priority = selectedPriority;
                            }
                            filteredTasks[index].title = titleController.text;
                            filteredTasks[index].time = timeController.text;
                            filteredTasks[index].priority = selectedPriority;
                          });
                          _saveTasks();
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.primaryColor,
                      ),
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// TASK CARD
class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Color primaryColor;
  final bool isDarkMode;

  const TaskCard({
    Key? key,
    required this.task,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
    required this.primaryColor,
    required this.isDarkMode,
  }) : super(key: key);

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'High':
        return Colors.red;
      case 'Medium':
        return Colors.orange;
      case 'Low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          GestureDetector(
            onTap: onToggle,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                border: Border.all(
                  color: task.isCompleted ? Colors.green : Colors.grey.shade400,
                  width: 2,
                ),
                shape: BoxShape.circle,
                color: task.isCompleted ? Colors.green : null,
              ),
              child: task.isCompleted
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  task.time,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getPriorityColor(task.priority).withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              task.priority[0],
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _getPriorityColor(task.priority),
              ),
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                onTap: onEdit,
                child: const Row(
                  children: [
                    Icon(Icons.edit, size: 18),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              PopupMenuItem(
                onTap: onDelete,
                child: const Row(
                  children: [
                    Icon(Icons.delete, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// TASK MODEL
class Task {
  String title;
  String time;
  bool isCompleted;
  String priority;

  Task({
    required this.title,
    required this.time,
    required this.isCompleted,
    required this.priority,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'time': time,
      'isCompleted': isCompleted,
      'priority': priority,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      title: json['title'] ?? '',
      time: json['time'] ?? '',
      isCompleted: json['isCompleted'] ?? false,
      priority: json['priority'] ?? 'Medium',
    );
  }
}

// ASSIGNMENTS SCREEN WITH SEARCH
class AssignmentsScreenWithSearch extends StatefulWidget {
  final Color primaryColor;
  final bool isDarkMode;

  const AssignmentsScreenWithSearch({
    Key? key,
    required this.primaryColor,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  State<AssignmentsScreenWithSearch> createState() =>
      _AssignmentsScreenWithSearchState();
}

class _AssignmentsScreenWithSearchState
    extends State<AssignmentsScreenWithSearch> {
  List<Assignment> assignments = [];
  List<Assignment> filteredAssignments = [];
  String searchQuery = '';
  String selectedStatusFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadAssignments();
  }

  Future<void> _loadAssignments() async {
    final prefs = await SharedPreferences.getInstance();
    final assignmentsJson = prefs.getStringList('assignments') ?? [];
    setState(() {
      assignments = assignmentsJson
          .map((json) => Assignment.fromJson(jsonDecode(json)))
          .toList();
    });
    _filterAssignments();
  }

  void _filterAssignments() {
    setState(() {
      filteredAssignments = assignments.where((assignment) {
        final matchesSearch =
            assignment.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
                assignment.subject
                    .toLowerCase()
                    .contains(searchQuery.toLowerCase());
        final matchesStatus = selectedStatusFilter == 'All' ||
            assignment.status == selectedStatusFilter;

        return matchesSearch && matchesStatus && !assignment.isExam;
      }).toList();
    });
  }

  Future<void> _saveAssignments() async {
    final prefs = await SharedPreferences.getInstance();
    final assignmentsJson =
        assignments.map((a) => jsonEncode(a.toJson())).toList();
    await prefs.setStringList('assignments', assignmentsJson);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'Assignments',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w300,
              ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                onChanged: (value) {
                  searchQuery = value;
                  _filterAssignments();
                },
                decoration: InputDecoration(
                  hintText: 'Search assignments...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            // Filters
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All', 'All'),
                    _buildFilterChip('Not started yet', 'Not started yet'),
                    _buildFilterChip('In Progress', 'In Progress'),
                    _buildFilterChip('Completed', 'Completed'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Assignment list
            Expanded(
              child: filteredAssignments.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No assignments found',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredAssignments.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: AssignmentCard(
                            assignment: filteredAssignments[index],
                            onEdit: () => _editAssignment(context, index),
                            onDelete: () {
                              setState(() {
                                assignments.removeWhere((a) =>
                                    a.name == filteredAssignments[index].name);
                                filteredAssignments.removeAt(index);
                              });
                              _saveAssignments();
                            },
                            primaryColor: widget.primaryColor,
                            isDarkMode: widget.isDarkMode,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: widget.primaryColor,
        onPressed: () => _addAssignment(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selectedStatusFilter == value,
        onSelected: (isSelected) {
          setState(() {
            selectedStatusFilter = isSelected ? value : 'All';
          });
          _filterAssignments();
        },
        backgroundColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
        selectedColor: widget.primaryColor,
      ),
    );
  }

  void _addAssignment(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController subjectController = TextEditingController();
    final TextEditingController dueDateController = TextEditingController();
    String selectedStatus = 'Not started yet';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: widget.isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFFAF8FF),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Add New Assignment',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      hintText: 'Assignment name',
                      filled: true,
                      fillColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: subjectController,
                    decoration: InputDecoration(
                      hintText: 'Subject',
                      filled: true,
                      fillColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: dueDateController,
                    readOnly: true,
                    decoration: InputDecoration(
                      hintText: 'Due Date (MM/DD/YYYY)',
                      filled: true,
                      fillColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      suffixIcon: const Icon(Icons.calendar_today),
                    ),
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        dueDateController.text =
                            '${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year}';
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(12),
                      color: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
                    ),
                    child: DropdownButton<String>(
                      value: selectedStatus,
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: ['Not started yet', 'In Progress', 'Completed']
                          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedStatus = value ?? 'Not started yet';
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          if (nameController.text.isNotEmpty &&
                              subjectController.text.isNotEmpty &&
                              dueDateController.text.isNotEmpty) {
                            this.setState(() {
                              assignments.add(
                                Assignment(
                                  name: nameController.text,
                                  subject: subjectController.text,
                                  dueDate: dueDateController.text,
                                  status: selectedStatus,
                                  isExam: false,
                                ),
                              );
                            });
                            _saveAssignments();
                            _filterAssignments();
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.primaryColor,
                        ),
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _editAssignment(BuildContext context, int index) {
    final assignment = filteredAssignments[index];
    final TextEditingController nameController =
        TextEditingController(text: assignment.name);
    final TextEditingController subjectController =
        TextEditingController(text: assignment.subject);
    final TextEditingController dueDateController =
        TextEditingController(text: assignment.dueDate);
    String selectedStatus = assignment.status;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: widget.isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFFAF8FF),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Edit Assignment',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      hintText: 'Assignment name',
                      filled: true,
                      fillColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: subjectController,
                    decoration: InputDecoration(
                      hintText: 'Subject',
                      filled: true,
                      fillColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: dueDateController,
                    readOnly: true,
                    decoration: InputDecoration(
                      hintText: 'Due Date (MM/DD/YYYY)',
                      filled: true,
                      fillColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      suffixIcon: const Icon(Icons.calendar_today),
                    ),
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        dueDateController.text =
                            '${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year}';
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(12),
                      color: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
                    ),
                    child: DropdownButton<String>(
                      value: selectedStatus,
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: ['Not started yet', 'In Progress', 'Completed']
                          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedStatus = value ?? 'Not started yet';
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          if (nameController.text.isNotEmpty &&
                              subjectController.text.isNotEmpty &&
                              dueDateController.text.isNotEmpty) {
                            this.setState(() {
                              final idx = assignments.indexOf(assignment);
                              if (idx != -1) {
                                assignments[idx].name = nameController.text;
                                assignments[idx].subject =
                                    subjectController.text;
                                assignments[idx].dueDate =
                                    dueDateController.text;
                                assignments[idx].status = selectedStatus;
                              }
                            });
                            _saveAssignments();
                            _filterAssignments();
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.primaryColor,
                        ),
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ASSIGNMENT CARD
class AssignmentCard extends StatelessWidget {
  final Assignment assignment;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Color primaryColor;
  final bool isDarkMode;

  const AssignmentCard({
    Key? key,
    required this.assignment,
    required this.onEdit,
    required this.onDelete,
    required this.primaryColor,
    required this.isDarkMode,
  }) : super(key: key);

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Not started yet':
        return Colors.orange;
      case 'In Progress':
        return Colors.blue;
      case 'Completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      assignment.name,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      assignment.subject,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
              PopupMenuButton(
                itemBuilder: (context) => [
                  PopupMenuItem(
                    onTap: onEdit,
                    child: const Row(
                      children: [
                        Icon(Icons.edit, size: 18),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    onTap: onDelete,
                    child: const Row(
                      children: [
                        Icon(Icons.delete, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    assignment.dueDate,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(assignment.status).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  assignment.status,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _getStatusColor(assignment.status),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ASSIGNMENT MODEL
class Assignment {
  String name;
  String subject;
  String dueDate;
  String status;
  bool isExam;

  Assignment({
    required this.name,
    required this.subject,
    required this.dueDate,
    required this.status,
    this.isExam = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'subject': subject,
      'dueDate': dueDate,
      'status': status,
      'isExam': isExam,
    };
  }

  factory Assignment.fromJson(Map<String, dynamic> json) {
    return Assignment(
      name: json['name'] ?? '',
      subject: json['subject'] ?? '',
      dueDate: json['dueDate'] ?? '',
      status: json['status'] ?? 'Not started yet',
      isExam: json['isExam'] ?? false,
    );
  }
}

// EXAM ASSIGNMENT MODEL
class ExamAssignment {
  String name;
  String subject;
  String dueDate;
  String status;
  bool isExam;

  ExamAssignment({
    required this.name,
    required this.subject,
    required this.dueDate,
    required this.status,
    this.isExam = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'subject': subject,
      'dueDate': dueDate,
      'status': status,
      'isExam': isExam,
    };
  }

  factory ExamAssignment.fromJson(Map<String, dynamic> json) {
    return ExamAssignment(
      name: json['name'] ?? '',
      subject: json['subject'] ?? '',
      dueDate: json['dueDate'] ?? '',
      status: json['status'] ?? 'Incoming',
      isExam: json['isExam'] ?? true,
    );
  }
}

// CALENDAR VIEW SCREEN
class CalendarViewScreen extends StatefulWidget {
  final Color primaryColor;
  final bool isDarkMode;

  const CalendarViewScreen({
    Key? key,
    required this.primaryColor,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  State<CalendarViewScreen> createState() => _CalendarViewScreenState();
}

class _CalendarViewScreenState extends State<CalendarViewScreen> {
  late DateTime _selectedDay;
  late DateTime _focusedDay;
  Map<DateTime, List<Task>> _tasksByDate = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _focusedDay = DateTime.now();
    _loadTasksByDate();
  }

  Future<void> _loadTasksByDate() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = prefs.getStringList('tasks') ?? [];
    final tasks = tasksJson
        .map((json) => Task.fromJson(jsonDecode(json)))
        .toList();

    // Group tasks by date (for now, we'll use today's tasks)
    setState(() {
      _tasksByDate = {};
      for (var task in tasks) {
        final key = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);
        if (_tasksByDate[key] == null) {
          _tasksByDate[key] = [];
        }
        _tasksByDate[key]!.add(task);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'Calendar',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w300,
              ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: TableCalendar(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) =>
                        isSameDay(_selectedDay, day),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                      _loadTasksByDate();
                    },
                    calendarStyle: CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: widget.primaryColor.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: widget.primaryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tasks for ${DateFormat('MMM dd, yyyy').format(_selectedDay)}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    if (_tasksByDate[
                            DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day)] ==
                        null)
                      Container(
                        decoration: BoxDecoration(
                          color: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Center(
                          child: Text(
                            'No tasks for this day',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      )
                    else
                      ..._tasksByDate[
                              DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day)]!
                          .map((task) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            decoration: BoxDecoration(
                              color: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Container(
                                  width: 4,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: widget.primaryColor,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        task.title,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        task.time,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// STUDY GOALS SCREEN
class StudyGoalsScreen extends StatefulWidget {
  final Color primaryColor;
  final bool isDarkMode;

  const StudyGoalsScreen({
    Key? key,
    required this.primaryColor,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  State<StudyGoalsScreen> createState() => _StudyGoalsScreenState();
}

class _StudyGoalsScreenState extends State<StudyGoalsScreen> {
  List<StudyGoal> goals = [];

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    final prefs = await SharedPreferences.getInstance();
    final goalsJson = prefs.getStringList('study_goals') ?? [];
    setState(() {
      goals = goalsJson
          .map((json) => StudyGoal.fromJson(jsonDecode(json)))
          .toList();
    });
  }

  Future<void> _saveGoals() async {
    final prefs = await SharedPreferences.getInstance();
    final goalsJson = goals.map((g) => jsonEncode(g.toJson())).toList();
    await prefs.setStringList('study_goals', goalsJson);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'Study Goals',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w300,
              ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (goals.isEmpty)
                Container(
                  decoration: BoxDecoration(
                    color: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text(
                      'No goals yet',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                )
              else
                ...goals.asMap().entries.map((entry) {
                  int index = entry.key;
                  StudyGoal goal = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildGoalCard(goal, index),
                  );
                }).toList(),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _addGoal(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Goal'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.primaryColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoalCard(StudyGoal goal, int index) {
    final progress = goal.targetValue > 0 ? goal.currentValue / goal.targetValue : 0;

    return Container(
      decoration: BoxDecoration(
        color: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      goal.description,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              PopupMenuButton(
                itemBuilder: (context) => [
                  PopupMenuItem(
                    onTap: () => _editGoal(context, index),
                    child: const Row(
                      children: [
                        Icon(Icons.edit, size: 18),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    onTap: () {
                      setState(() {
                        goals.removeAt(index);
                      });
                      _saveGoals();
                    },
                    child: const Row(
                      children: [
                        Icon(Icons.delete, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      widget.primaryColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${(progress * 100).toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${goal.currentValue}/${goal.targetValue} ${goal.unit}',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }

  void _addGoal(BuildContext context) {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descriptionController =
        TextEditingController();
    final TextEditingController targetController = TextEditingController();
    final TextEditingController unitController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: widget.isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFFAF8FF),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Add New Goal',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    hintText: 'Goal title',
                    filled: true,
                    fillColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    hintText: 'Description',
                    filled: true,
                    fillColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: targetController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Target',
                          filled: true,
                          fillColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: unitController,
                        decoration: InputDecoration(
                          hintText: 'Unit',
                          filled: true,
                          fillColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        if (titleController.text.isNotEmpty &&
                            targetController.text.isNotEmpty) {
                          setState(() {
                            goals.add(
                              StudyGoal(
                                title: titleController.text,
                                description: descriptionController.text,
                                targetValue:
                                    int.parse(targetController.text),
                                currentValue: 0,
                                unit: unitController.text,
                                createdAt: DateTime.now(),
                              ),
                            );
                          });
                          _saveGoals();
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.primaryColor,
                      ),
                      child: const Text('Add'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _editGoal(BuildContext context, int index) {
    final goal = goals[index];
    final TextEditingController titleController =
        TextEditingController(text: goal.title);
    final TextEditingController descriptionController =
        TextEditingController(text: goal.description);
    final TextEditingController currentController =
        TextEditingController(text: goal.currentValue.toString());

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: widget.isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFFAF8FF),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Edit Goal',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    hintText: 'Goal title',
                    filled: true,
                    fillColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    hintText: 'Description',
                    filled: true,
                    fillColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: currentController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Current progress',
                    filled: true,
                    fillColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        if (titleController.text.isNotEmpty &&
                            currentController.text.isNotEmpty) {
                          setState(() {
                            goals[index].title = titleController.text;
                            goals[index].description =
                                descriptionController.text;
                            goals[index].currentValue =
                                int.parse(currentController.text);
                          });
                          _saveGoals();
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.primaryColor,
                      ),
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// STUDY GOAL MODEL
class StudyGoal {
  String title;
  String description;
  int targetValue;
  int currentValue;
  String unit;
  DateTime createdAt;

  StudyGoal({
    required this.title,
    required this.description,
    required this.targetValue,
    required this.currentValue,
    required this.unit,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'targetValue': targetValue,
      'currentValue': currentValue,
      'unit': unit,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory StudyGoal.fromJson(Map<String, dynamic> json) {
    return StudyGoal(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      targetValue: json['targetValue'] ?? 0,
      currentValue: json['currentValue'] ?? 0,
      unit: json['unit'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}

// POMODORO TIMER SCREEN
class PomodoroTimerScreen extends StatefulWidget {
  final Color primaryColor;
  final bool isDarkMode;

  const PomodoroTimerScreen({
    Key? key,
    required this.primaryColor,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  State<PomodoroTimerScreen> createState() => _PomodoroTimerScreenState();
}

class _PomodoroTimerScreenState extends State<PomodoroTimerScreen>
    with TickerProviderStateMixin {
  late AnimationController _timerController;
  int _totalSeconds = 25 * 60; // 25 minutes
  int _remainingSeconds = 25 * 60;
  bool _isRunning = false;
  int _sessionsCompleted = 0;
  String _timerMode = 'work'; // work or break

  @override
  void initState() {
    super.initState();
    _timerController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _loadPomodoroStats();
  }

  @override
  void dispose() {
    _timerController.dispose();
    super.dispose();
  }

  Future<void> _loadPomodoroStats() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _sessionsCompleted = prefs.getInt('pomodoro_sessions') ?? 0;
    });
  }

  Future<void> _savePomodoroStats() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('pomodoro_sessions', _sessionsCompleted);
  }

  void _startTimer() {
    if (_isRunning) return;

    setState(() {
      _isRunning = true;
    });

    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 0) {
        timer.cancel();
        _onTimerComplete();
      } else {
        setState(() {
          _remainingSeconds--;
        });
      }
    });
  }

  void _pauseTimer() {
    setState(() {
      _isRunning = false;
    });
  }

  void _resetTimer() {
    setState(() {
      _isRunning = false;
      _remainingSeconds = _timerMode == 'work' ? 25 * 60 : 5 * 60;
    });
  }

  void _onTimerComplete() {
    if (_timerMode == 'work') {
      setState(() {
        _sessionsCompleted++;
        _timerMode = 'break';
        _totalSeconds = 5 * 60;
        _remainingSeconds = 5 * 60;
      });
      _savePomodoroStats();
      NotificationService().showNotification(
        1,
        'Break Time!',
        'Great work! Take a 5-minute break.',
      );
    } else {
      setState(() {
        _timerMode = 'work';
        _totalSeconds = 25 * 60;
        _remainingSeconds = 25 * 60;
      });
      NotificationService().showNotification(
        2,
        'Back to Work!',
        'Break time is over. Let\'s get focused!',
      );
    }
  }

  String _formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  @override
  Widget build(BuildContext context) {
    final progress = _remainingSeconds / _totalSeconds;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'Pomodoro Timer',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w300,
              ),
        ),
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              margin: const EdgeInsets.all(40),
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.primaryColor.withOpacity(0.1),
                border: Border.all(
                  color: widget.primaryColor.withOpacity(0.3),
                  width: 3,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _timerMode == 'work' ? 'Work' : 'Break',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: widget.primaryColor,
                          fontSize: 16,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatTime(_remainingSeconds),
                    style: TextStyle(
                      fontSize: 60,
                      fontWeight: FontWeight.w700,
                      color: widget.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _isRunning ? _pauseTimer : _startTimer,
                  icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
                  label: Text(_isRunning ? 'Pause' : 'Start'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: _resetTimer,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: widget.primaryColor,
                    side: BorderSide(color: widget.primaryColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sessions Completed',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.primaryColor.withOpacity(0.2),
                        ),
                        child: Center(
                          child: Text(
                            '$_sessionsCompleted',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: widget.primaryColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Keep up the great work!',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'You\'re making excellent progress',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// STATISTICS SCREEN
class StatisticsScreen extends StatefulWidget {
  final Color primaryColor;
  final bool isDarkMode;

  const StatisticsScreen({
    Key? key,
    required this.primaryColor,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  double _taskCompletionRate = 0;
  int _totalTasks = 0;
  int _completedTasks = 0;
  int _totalAssignments = 0;
  int _completedAssignments = 0;
  int _pomodoroSessions = 0;
  Map<String, int> _tasksByPriority = {'High': 0, 'Medium': 0, 'Low': 0};

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    final prefs = await SharedPreferences.getInstance();

    // Load task stats
    _totalTasks = prefs.getInt('total_tasks') ?? 0;
    _completedTasks = prefs.getInt('completed_tasks') ?? 0;

    final tasksJson = prefs.getStringList('tasks') ?? [];
    final tasks =
        tasksJson.map((json) => Task.fromJson(jsonDecode(json))).toList();

    _tasksByPriority = {'High': 0, 'Medium': 0, 'Low': 0};
    for (var task in tasks) {
      _tasksByPriority[task.priority] =
          (_tasksByPriority[task.priority] ?? 0) + 1;
    }

    // Load assignment stats
    final assignmentsJson = prefs.getStringList('assignments') ?? [];
    final assignments = assignmentsJson
        .map((json) => Assignment.fromJson(jsonDecode(json)))
        .toList();

    final nonExamAssignments = assignments.where((a) => !a.isExam).toList();
    _totalAssignments = nonExamAssignments.length;
    _completedAssignments =
        nonExamAssignments.where((a) => a.status == 'Completed').length;

    // Load pomodoro stats
    _pomodoroSessions = prefs.getInt('pomodoro_sessions') ?? 0;

    setState(() {
      _taskCompletionRate =
          _totalTasks > 0 ? _completedTasks / _totalTasks : 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'Statistics',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w300,
              ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Overall Stats
              Text(
                'Overall Stats',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Task Completion',
                      '${(_taskCompletionRate * 100).toStringAsFixed(1)}%',
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Pomodoro',
                      '$_pomodoroSessions',
                      Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Tasks Done',
                      '$_completedTasks/$_totalTasks',
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Assignments',
                      '$_completedAssignments/$_totalAssignments',
                      Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              // Task Priority Breakdown
              Text(
                'Tasks by Priority',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 12,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildPriorityRow('High', _tasksByPriority['High'] ?? 0,
                        Colors.red),
                    const SizedBox(height: 12),
                    _buildPriorityRow('Medium',
                        _tasksByPriority['Medium'] ?? 0, Colors.orange),
                    const SizedBox(height: 12),
                    _buildPriorityRow(
                        'Low', _tasksByPriority['Low'] ?? 0, Colors.green),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityRow(String priority, int count, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              priority,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

// SETTINGS SCREEN
class SettingsScreen extends StatefulWidget {
  final VoidCallback onThemeToggle;
  final Function(Color) onColorChange;
  final bool isDarkMode;
  final Color primaryColor;

  const SettingsScreen({
    Key? key,
    required this.onThemeToggle,
    required this.onColorChange,
    required this.isDarkMode,
    required this.primaryColor,
  }) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final List<Color> _availableColors = [
    const Color(0xFFE8D5F2),
    const Color(0xFF3B82F6),
    const Color(0xFF10B981),
    const Color(0xFFEF4444),
    const Color(0xFFF59E0B),
    const Color(0xFF8B5CF6),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'Settings',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w300,
              ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Theme Toggle
              Container(
                decoration: BoxDecoration(
                  color: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 12,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dark Mode',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Enable dark theme',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                    Switch(
                      value: widget.isDarkMode,
                      onChanged: (_) => widget.onThemeToggle(),
                      activeColor: widget.primaryColor,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Color Picker
              Text(
                'Theme Color',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _availableColors.map((color) {
                  final isSelected = color == widget.primaryColor;
                  return GestureDetector(
                    onTap: () => widget.onColorChange(color),
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(
                                color: Colors.grey,
                                width: 3,
                              )
                            : null,
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 28,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),
              // About
              Container(
                decoration: BoxDecoration(
                  color: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 12,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'About',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Version',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          '1.0.0',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Study Control - Your personal study companion',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Required imports for pubspec.yaml:
// dependencies:
//   flutter:
//     sdk: flutter
//   shared_preferences: ^2.0.0
//   flutter_local_notifications: ^14.0.0
//   timezone: ^0.9.0
//   file_picker: ^5.0.0
//   intl: ^0.18.0
//   table_calendar: ^3.0.0

// Add this import at the top:
// import 'dart:async';