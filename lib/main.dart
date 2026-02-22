import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daily Productivity App',
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home: const HomePage(),
    );
  }
}

//Home Page with Bottom Navigation
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const HabitsScreen(),
    const TasksScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.deepPurple,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.checklist), label: 'Habits'),
          BottomNavigationBarItem(icon: Icon(Icons.task), label: 'Tasks'),
        ],
      ),
    );
  }
}

//Dashboard Screen
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<String> subjects = [];
  List<DateTime> examDates = [];
  List<Map<String, dynamic>> tasks = [];
  List<Map<String, dynamic>> habits = [];

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    final prefs = await SharedPreferences.getInstance();
    // Exams
    subjects = prefs.getStringList('subjects') ?? ['Mathematics'];
    List<String>? savedDates = prefs.getStringList('examDates');
    examDates = savedDates != null
        ? savedDates.map((s) => DateTime.fromMillisecondsSinceEpoch(int.parse(s))).toList()
        : [DateTime.now().add(const Duration(days: 5))];

    // Habits
    List<String>? habitTitles = prefs.getStringList('habitsTitles');
    List<String>? habitStatus = prefs.getStringList('habitsStatus');
    habits = [];
    if (habitTitles != null && habitStatus != null) {
      for (int i = 0; i < habitTitles.length; i++) {
        habits.add({"title": habitTitles[i], "done": habitStatus[i] == "true"});
      }
    } else {
      habits = [
        {"title": "Drink Water", "done": false},
        {"title": "Read 20 min", "done": false},
      ];
    }

    // Tasks
    List<String>? taskTitles = prefs.getStringList('tasksTitles');
    List<String>? taskStatus = prefs.getStringList('tasksStatus');
    tasks = [];
    if (taskTitles != null && taskStatus != null) {
      for (int i = 0; i < taskTitles.length; i++) {
        tasks.add({"title": taskTitles[i], "done": taskStatus[i] == "true"});
      }
    }

    setState(() {});
  }

  Future<void> _saveExams() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('subjects', subjects);
    await prefs.setStringList(
        'examDates', examDates.map((d) => d.millisecondsSinceEpoch.toString()).toList());
  }

  Future<void> _saveHabits() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        'habitsTitles', habits.map((h) => h['title'] as String).toList());
    await prefs.setStringList(
        'habitsStatus', habits.map((h) => (h['done'] as bool).toString()).toList());
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('tasksTitles', tasks.map((t) => t['title'] as String).toList());
    await prefs.setStringList(
        'tasksStatus', tasks.map((t) => (t['done'] as bool).toString()).toList());
  }

  //Exam Edit Dialog
  Future<void> _editExamDialog(int index) async {
    TextEditingController subjectController =
        TextEditingController(text: subjects[index]);
    DateTime tempDate = examDates[index];

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Edit Exam"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: subjectController,
                  decoration: const InputDecoration(labelText: "Subject Name"),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Text("Exam Date: "),
                    Text("${tempDate.day}/${tempDate.month}/${tempDate.year}",
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const Spacer(),
                    TextButton(
                        onPressed: () async {
                          DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: tempDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2100));
                          if (picked != null) {
                            setDialogState(() => tempDate = picked);
                          }
                        },
                        child: const Text("Change")),
                  ],
                )
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () {
                    subjects[index] = subjectController.text;
                    examDates[index] = tempDate;
                    _saveExams();
                    setState(() {});
                    Navigator.pop(context);
                  },
                  child: const Text("Save"))
            ],
          );
        });
      },
    );
  }

  //Exam Card Color
  Color _examCardColor(int daysLeft) {
    if (daysLeft <= 1) return Colors.redAccent.withOpacity(0.4);
    if (daysLeft <= 3) return Colors.orangeAccent.withOpacity(0.3);
    return Colors.white.withOpacity(0.15);
  }

  @override
  Widget build(BuildContext context) {
    int completedHabits = habits.where((h) => h['done'] as bool).length;
    int completedTasks = tasks.where((t) => t['done'] as bool).length;
    double habitProgress = habits.isEmpty ? 0 : completedHabits / habits.length;
    double taskProgress = tasks.isEmpty ? 0 : completedTasks / tasks.length;
    double overallProgress = (habitProgress + taskProgress) / 2;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6A5AE0), Color(0xFF8E7BFF), Color(0xFF5F9CFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: ListView(
              children: [
                const SizedBox(height: 20),
                const Text("Dashboard",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 30),

                // Circular Progress
                _progressCard(overallProgress),

                const SizedBox(height: 20),

                // Assignments Card (example, dynamic later)
                _infoCard(
                    title: "Assignments",
                    content:
                        "${tasks.where((t) => !(t['done'] as bool)).length} Active • ${tasks.where((t) => t['done'] as bool).length} Done"),

                const SizedBox(height: 20),
                const Text("Upcoming Tests",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),

                // Exams List
                ...List.generate(subjects.length, (index) {
                  int daysLeft =
                      examDates[index].difference(DateTime.now()).inDays;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: GestureDetector(
                      onTap: () => _editExamDialog(index),
                      child: _examCard(subjects[index], daysLeft),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            subjects.add("New Subject");
            examDates.add(DateTime.now().add(const Duration(days: 7)));
            _saveExams();
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  //Widgets
  Widget _examCard(String subjectName, int daysLeft) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: _examCardColor(daysLeft),
          borderRadius: BorderRadius.circular(25)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Upcoming Test",
              style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Text("$subjectName • $daysLeft days left",
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _progressCard(double progress) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(25)),
      child: Row(
        children: [
          SizedBox(
            height: 90,
            width: 90,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                Text("${(progress * 100).toInt()}%",
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold))
              ],
            ),
          ),
          const SizedBox(width: 20),
          const Expanded(
              child: Text("Today's Overall Progress\n(Habits + Tasks)",
                  style: TextStyle(color: Colors.white, fontSize: 16))),
        ],
      ),
    );
  }

  Widget _infoCard({required String title, required String content}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(25)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 6),
          Text(content,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

//Habits Screen
class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  List<Map<String, dynamic>> habits = [];

  @override
  void initState() {
    super.initState();
    _loadHabits();
  }

  Future<void> _loadHabits() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? titles = prefs.getStringList('habitsTitles');
    List<String>? status = prefs.getStringList('habitsStatus');
    habits = [];
    if (titles != null && status != null) {
      for (int i = 0; i < titles.length; i++) {
        habits.add({"title": titles[i], "done": status[i] == "true"});
      }
    } else {
      habits = [
        {"title": "Drink Water", "done": false},
        {"title": "Read 20 min", "done": false},
      ];
    }
    setState(() {});
  }

  Future<void> _saveHabits() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('habitsTitles', habits.map((h) => h['title'] as String).toList());
    await prefs.setStringList(
        'habitsStatus', habits.map((h) => (h['done'] as bool).toString()).toList());
  }

  void _addHabit() {
    setState(() {
      habits.add({"title": "New Habit", "done": false});
    });
    _saveHabits();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6A5AE0), Color(0xFF8E7BFF), Color(0xFF5F9CFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: ListView(
              children: [
                const SizedBox(height: 20),
                const Text("Habits",
                    style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                ...List.generate(habits.length, (index) {
                  return Card(
                    color: Colors.white.withOpacity(0.15),
                    child: ListTile(
                      title: Text(habits[index]['title'],
                          style: const TextStyle(color: Colors.white)),
                      trailing: Checkbox(
                        value: habits[index]['done'],
                        onChanged: (value) {
                          setState(() => habits[index]['done'] = value);
                          _saveHabits();
                        },
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addHabit,
        child: const Icon(Icons.add),
      ),
    );
  }
}

//Tasks Screen
class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  List<Map<String, dynamic>> tasks = [];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? titles = prefs.getStringList('tasksTitles');
    List<String>? status = prefs.getStringList('tasksStatus');
    tasks = [];
    if (titles != null && status != null) {
      for (int i = 0; i < titles.length; i++) {
        tasks.add({"title": titles[i], "done": status[i] == "true"});
      }
    }
    setState(() {});
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('tasksTitles', tasks.map((t) => t['title'] as String).toList());
    await prefs.setStringList('tasksStatus', tasks.map((t) => (t['done'] as bool).toString()).toList());
  }

  void _addTask() {
    setState(() => tasks.add({"title": "New Task", "done": false}));
    _saveTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6A5AE0), Color(0xFF8E7BFF), Color(0xFF5F9CFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: ListView(
              children: [
                const SizedBox(height: 20),
                const Text("Tasks",
                    style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                ...List.generate(tasks.length, (index) {
                  return Card(
                    color: Colors.white.withOpacity(0.15),
                    child: ListTile(
                      title: Text(tasks[index]['title'],
                          style: const TextStyle(color: Colors.white)),
                      trailing: Checkbox(
                        value: tasks[index]['done'],
                        onChanged: (value) {
                          setState(() => tasks[index]['done'] = value);
                          _saveTasks();
                        },
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTask,
        child: const Icon(Icons.add),
      ),
    );
  }
}
