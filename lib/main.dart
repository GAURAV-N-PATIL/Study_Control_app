import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Productivity App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController progressController;
  final List<Widget> _screens = [
    const DashboardScreen(),
    const HabitsScreen(),
    const TasksScreen(),
    const AssignmentsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    progressController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    progressController.reset();
    progressController.forward();
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
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.checklist), label: 'Habits'),
          BottomNavigationBarItem(icon: Icon(Icons.task), label: 'Tasks'),
          BottomNavigationBarItem(
              icon: Icon(Icons.assignment), label: 'Assignments'),
        ],
      ),
    );
  }
}

// ------------------- DASHBOARD -------------------
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> habits = [];
  List<Map<String, dynamic>> tasks = [];
  List<Map<String, dynamic>> assignments = [];
  List<Map<String, dynamic>> exams = [];
  late AnimationController progressController;
  double progress = 0;

  @override
  void initState() {
    super.initState();
    progressController =
        AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    final prefs = await SharedPreferences.getInstance();

    List<String>? habitTitles = prefs.getStringList('habitsTitles');
    List<String>? habitStatus = prefs.getStringList('habitsStatus');
    habits = [];
    if (habitTitles != null && habitStatus != null) {
      for (int i = 0; i < habitTitles.length; i++) {
        habits.add({"title": habitTitles[i], "done": habitStatus[i] == "true"});
      }
    }

    List<String>? taskTitles = prefs.getStringList('tasksTitles');
    List<String>? taskStatus = prefs.getStringList('tasksStatus');
    tasks = [];
    if (taskTitles != null && taskStatus != null) {
      for (int i = 0; i < taskTitles.length; i++) {
        tasks.add({"title": taskTitles[i], "done": taskStatus[i] == "true"});
      }
    }

    List<String>? assignmentTitles = prefs.getStringList('assignmentsTitles');
    List<String>? assignmentDates = prefs.getStringList('assignmentsDates');
    assignments = [];
    if (assignmentTitles != null && assignmentDates != null) {
      for (int i = 0; i < assignmentTitles.length; i++) {
        assignments.add({
          "title": assignmentTitles[i],
          "deadline":
              DateTime.fromMillisecondsSinceEpoch(int.parse(assignmentDates[i]))
        });
      }
    }

    List<String>? examSubjects = prefs.getStringList('examSubjects');
    List<String>? examDates = prefs.getStringList('examDates');
    exams = [];
    if (examSubjects != null && examDates != null) {
      for (int i = 0; i < examSubjects.length; i++) {
        exams.add({
          "subject": examSubjects[i],
          "date": DateTime.fromMillisecondsSinceEpoch(int.parse(examDates[i]))
        });
      }
    }

    _calculateProgress();
  }

  void _calculateProgress() {
    int completedHabits = habits.where((h) => h['done'] == true).length;
    int completedTasks = tasks.where((t) => t['done'] == true).length;
    double habitProgress = habits.isEmpty ? 0 : completedHabits / habits.length;
    double taskProgress = tasks.isEmpty ? 0 : completedTasks / tasks.length;
    setState(() {
      progress = (habitProgress + taskProgress) / 2;
    });
    progressController.forward();
  }

  Color _examCardColor(int daysLeft) {
    if (daysLeft <= 1) return Colors.redAccent.withOpacity(0.4);
    if (daysLeft <= 3) return Colors.orangeAccent.withOpacity(0.3);
    return Colors.white.withOpacity(0.15);
  }

  Future<void> _editExamDialog(int index) async {
    TextEditingController controller =
        TextEditingController(text: exams[index]['subject']);
    DateTime tempDate = exams[index]['date'];
    await showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(labelText: "Subject"),
                  ),
                  const SizedBox(height: 20),
                  Row(children: [
                    Text(
                        "Date: ${tempDate.day}/${tempDate.month}/${tempDate.year}"),
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
                        child: const Text("Change"))
                  ]),
                  const SizedBox(height: 20),
                  ElevatedButton(
                      onPressed: () async {
                        exams[index]['subject'] = controller.text;
                        exams[index]['date'] = tempDate;
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setStringList(
                            'examSubjects', exams.map((e) => e['subject']).toList());
                        await prefs.setStringList(
                            'examDates',
                            exams
                                .map((e) =>
                                    (e['date'] as DateTime).millisecondsSinceEpoch
                                        .toString())
                                .toList());
                        Navigator.pop(context);
                        setState(() {});
                      },
                      child: const Text("Save"))
                ]),
              ),
            );
          });
        });
  }

  Widget _examCard(String subject, DateTime date) {
    int daysLeft = date.difference(DateTime.now()).inDays;
    return Dismissible(
      key: UniqueKey(),
      onDismissed: (_) async {
        exams.removeWhere((e) => e['subject'] == subject);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList(
            'examSubjects', exams.map((e) => e['subject']).toList());
        await prefs.setStringList(
            'examDates',
            exams
                .map((e) =>
                    (e['date'] as DateTime).millisecondsSinceEpoch.toString())
                .toList());
        setState(() {});
      },
      background: Container(
        color: Colors.redAccent,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: InkWell(
        onTap: () => _editExamDialog(exams.indexWhere((e) => e['subject'] == subject)),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _examCardColor(daysLeft),
            borderRadius: BorderRadius.circular(25),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
          ),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Upcoming Test",
                    style: TextStyle(color: Colors.black54, fontSize: 14)),
                const SizedBox(height: 8),
                Text("$subject • $daysLeft days left",
                    style: const TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.bold))
              ]),
        ),
      ),
    );
  }

  Widget _progressCard() {
    return AnimatedBuilder(
        animation: progressController,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)]),
            child: Row(children: [
              SizedBox(
                height: 90,
                width: 90,
                child: Stack(alignment: Alignment.center, children: [
                  CircularProgressIndicator(
                    value: progressController.value * progress,
                    strokeWidth: 8,
                    backgroundColor: Colors.grey[300],
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                  ),
                  Text("${((progressController.value * progress) * 100).toInt()}%",
                      style: const TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold))
                ]),
              ),
              const SizedBox(width: 20),
              const Expanded(
                  child: Text("Today's Overall Progress\n(Habits + Tasks)",
                      style: TextStyle(color: Colors.black, fontSize: 16))),
            ]),
          );
        });
  }

  Widget _infoCard(String title, String content) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(color: Colors.black54, fontSize: 14)),
        const SizedBox(height: 6),
        Text(content,
            style: const TextStyle(
                color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold))
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
          gradient: LinearGradient(
              colors: [Color(0xFFD1C4E9), Color(0xFFB39DDB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight)),
      child: SafeArea(
          child: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            const SizedBox(height: 20),
            const Text("Dashboard",
                style: TextStyle(
                    color: Colors.black87,
                    fontSize: 28,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            _progressCard(),
            const SizedBox(height: 20),
            _infoCard(
                "Assignments",
                "${assignments.length} Total • ${tasks.where((t) => t['done'] == true).length} Completed"),
            const SizedBox(height: 20),
            const Text("Upcoming Exams",
                style: TextStyle(
                    color: Colors.black87,
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            ...exams.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: _examCard(e['subject'], e['date']),
                )),
          ],
        ),
      )),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          exams.add({"subject": "New Subject", "date": DateTime.now().add(const Duration(days: 7))});
          final prefs = await SharedPreferences.getInstance();
          await prefs.setStringList(
              'examSubjects', exams.map((e) => e['subject']).toList());
          await prefs.setStringList(
              'examDates',
              exams
                  .map((e) =>
                      (e['date'] as DateTime).millisecondsSinceEpoch.toString())
                  .toList());
          setState(() {});
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ------------------- HABITS SCREEN -------------------
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
    }
    setState(() {});
  }

  Future<void> _saveHabits() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        'habitsTitles', habits.map((h) => h['title'] as String).toList());
    await prefs.setStringList(
        'habitsStatus', habits.map((h) => (h['done'] as bool).toString()).toList());
  }

  void _addHabit() {
    setState(() => habits.add({"title": "New Habit", "done": false}));
    _saveHabits();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
          gradient: LinearGradient(
              colors: [Color(0xFFFFCDD2), Color(0xFFFFAB91)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight)),
      child: SafeArea(
          child: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(children: [
          const SizedBox(height: 20),
          const Text("Habits",
              style: TextStyle(
                  color: Colors.black87, fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          ...habits.map((habit) {
            return Dismissible(
              key: UniqueKey(),
              onDismissed: (_) {
                habits.remove(habit);
                _saveHabits();
                setState(() {});
              },
              background: Container(
                  color: Colors.redAccent,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: 20),
                  child: const Icon(Icons.delete, color: Colors.white)),
              child: Card(
                color: Colors.white,
                elevation: 4,
                child: ListTile(
                  title: Text(habit['title'], style: const TextStyle(color: Colors.black)),
                  trailing: Checkbox(
                    value: habit['done'],
                    onChanged: (val) {
                      habit['done'] = val;
                      _saveHabits();
                      setState(() {});
                    },
                  ),
                ),
              ),
            );
          }).toList(),
        ]),
      )),
      floatingActionButton: FloatingActionButton(
        onPressed: _addHabit,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ------------------- TASKS SCREEN -------------------
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
    return Container(
      decoration: const BoxDecoration(
          gradient: LinearGradient(
              colors: [Color(0xFF80CBC4), Color(0xFF4DB6AC)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight)),
      child: SafeArea(
          child: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            const SizedBox(height: 20),
            const Text("Tasks",
                style: TextStyle(
                    color: Colors.black87,
                    fontSize: 28,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ...tasks.map((task) {
              return Dismissible(
                key: UniqueKey(),
                onDismissed: (_) {
                  tasks.remove(task);
                  _saveTasks();
                  setState(() {});
                },
                background: Container(
                    color: Colors.redAccent,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 20),
                    child: const Icon(Icons.delete, color: Colors.white)),
                child: Card(
                  color: Colors.white,
                  elevation: 4,
                  child: ListTile(
                    title: Text(task['title'], style: const TextStyle(color: Colors.black)),
                    trailing: Checkbox(
                      value: task['done'],
                      onChanged: (val) {
                        task['done'] = val;
                        _saveTasks();
                        setState(() {});
                      },
                    ),
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      )),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTask,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ------------------- ASSIGNMENTS SCREEN -------------------
class AssignmentsScreen extends StatefulWidget {
  const AssignmentsScreen({super.key});
  @override
  State<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends State<AssignmentsScreen> {
  List<Map<String, dynamic>> assignments = [];

  @override
  void initState() {
    super.initState();
    _loadAssignments();
  }

  Future<void> _loadAssignments() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? titles = prefs.getStringList('assignmentsTitles');
    List<String>? deadlines = prefs.getStringList('assignmentsDates');
    assignments = [];
    if (titles != null && deadlines != null) {
      for (int i = 0; i < titles.length; i++) {
        assignments.add({
          "title": titles[i],
          "deadline": DateTime.fromMillisecondsSinceEpoch(int.parse(deadlines[i]))
        });
      }
    }
    setState(() {});
  }

  Future<void> _saveAssignments() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        'assignmentsTitles', assignments.map((a) => a['title'] as String).toList());
    await prefs.setStringList(
        'assignmentsDates',
        assignments
            .map((a) => (a['deadline'] as DateTime).millisecondsSinceEpoch.toString())
            .toList());
  }

  void _addAssignment() {
    setState(() => assignments.add({
          "title": "New Assignment",
          "deadline": DateTime.now().add(const Duration(days: 7))
        }));
    _saveAssignments();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
          gradient: LinearGradient(
              colors: [Color(0xFFBBDEFB), Color(0xFF90CAF9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight)),
      child: SafeArea(
          child: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(children: [
          const SizedBox(height: 20),
          const Text("Assignments",
              style: TextStyle(
                  color: Colors.black87, fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          ...assignments.map((assignment) {
            int daysLeft = assignment['deadline'].difference(DateTime.now()).inDays;
            return Dismissible(
              key: UniqueKey(),
              onDismissed: (_) {
                assignments.remove(assignment);
                _saveAssignments();
                setState(() {});
              },
              background: Container(
                  color: Colors.redAccent,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: 20),
                  child: const Icon(Icons.delete, color: Colors.white)),
              child: InkWell(
                onTap: () async {
                  TextEditingController controller =
                      TextEditingController(text: assignment['title']);
                  DateTime tempDate = assignment['deadline'];
                  await showDialog(
                      context: context,
                      builder: (context) {
                        return StatefulBuilder(builder: (context, setStateDialog) {
                          return Dialog(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(mainAxisSize: MainAxisSize.min, children: [
                                TextField(
                                  controller: controller,
                                  decoration: const InputDecoration(labelText: "Title"),
                                ),
                                const SizedBox(height: 20),
                                Row(children: [
                                  Text(
                                      "Deadline: ${tempDate.day}/${tempDate.month}/${tempDate.year}"),
                                  const Spacer(),
                                  TextButton(
                                      onPressed: () async {
                                        DateTime? picked = await showDatePicker(
                                            context: context,
                                            initialDate: tempDate,
                                            firstDate: DateTime.now(),
                                            lastDate: DateTime(2100));
                                        if (picked != null) {
                                          setStateDialog(() => tempDate = picked);
                                        }
                                      },
                                      child: const Text("Change"))
                                ]),
                                const SizedBox(height: 20),
                                ElevatedButton(
                                    onPressed: () {
                                      assignment['title'] = controller.text;
                                      assignment['deadline'] = tempDate;
                                      _saveAssignments();
                                      Navigator.pop(context);
                                      setState(() {});
                                    },
                                    child: const Text("Save"))
                              ]),
                            ),
                          );
                        });
                      });
                },
                child: Card(
                  color: Colors.white,
                  elevation: 4,
                  child: ListTile(
                    title: Text(assignment['title'], style: const TextStyle(color: Colors.black)),
                    subtitle: Text("$daysLeft days left"),
                  ),
                ),
              ),
            );
          }).toList()
        ]),
      )),
      floatingActionButton: FloatingActionButton(
        onPressed: _addAssignment,
        child: const Icon(Icons.add),
      ),
    );
  }
}
