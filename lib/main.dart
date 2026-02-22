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

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final List<Widget> _screens = [
    const DashboardScreen(),
    const HabitsScreen(),
    const TasksScreen(),
    const AssignmentsScreen(),
  ];

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

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
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Assignments'),
        ],
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  List<Map<String, dynamic>> exams = [];
  double progress = 0;
  late AnimationController progressController;

  @override
  void initState() {
    super.initState();
    progressController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _loadExams();
  }

  Future<void> _loadExams() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? subjects = prefs.getStringList('examSubjects');
    List<String>? dates = prefs.getStringList('examDates');
    exams = [];
    if (subjects != null && dates != null) {
      for (int i = 0; i < subjects.length; i++) {
        exams.add({"subject": subjects[i], "date": DateTime.fromMillisecondsSinceEpoch(int.parse(dates[i]))});
      }
    }
    setState(() {});
  }

  Future<void> _saveExams() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('examSubjects', exams.map((e) => e['subject'].toString()).toList());
    await prefs.setStringList('examDates', exams.map((e) => (e['date'] as DateTime).millisecondsSinceEpoch.toString()).toList());
  }

  Future<void> _editExamDialog(int index) async {
    TextEditingController controller = TextEditingController(text: exams[index]['subject']);
    DateTime tempDate = exams[index]['date'];
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setDialogState) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: controller, decoration: const InputDecoration(labelText: "Subject")),
              const SizedBox(height: 20),
              Row(children: [
                Text("Date: ${tempDate.day}/${tempDate.month}/${tempDate.year}"),
                const Spacer(),
                TextButton(
                    onPressed: () async {
                      DateTime? picked = await showDatePicker(context: context, initialDate: tempDate, firstDate: DateTime.now(), lastDate: DateTime(2100));
                      if (picked != null) setDialogState(() => tempDate = picked);
                    },
                    child: const Text("Change"))
              ]),
              const SizedBox(height: 20),
              ElevatedButton(
                  onPressed: () {
                    exams[index]['subject'] = controller.text;
                    exams[index]['date'] = tempDate;
                    _saveExams();
                    Navigator.pop(context);
                    setState(() {});
                  },
                  child: const Text("Save"))
            ]),
          ),
        );
      }),
    );
  }

  Widget _examCard(String subject, DateTime date) {
    int daysLeft = date.difference(DateTime.now()).inDays;
    Color color = daysLeft <= 1 ? Colors.redAccent.withOpacity(0.3) : daysLeft <= 3 ? Colors.orangeAccent.withOpacity(0.2) : Colors.white;
    return Dismissible(
      key: UniqueKey(),
      onDismissed: (_) {
        exams.removeWhere((e) => e['subject'] == subject);
        _saveExams();
        setState(() {});
      },
      background: Container(color: Colors.redAccent, alignment: Alignment.centerLeft, padding: const EdgeInsets.only(left: 20), child: const Icon(Icons.delete, color: Colors.white)),
      child: InkWell(
        onTap: () => _editExamDialog(exams.indexWhere((e) => e['subject'] == subject)),
        child: AnimatedContainer(duration: const Duration(milliseconds: 300), padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(subject, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)), Text("$daysLeft days left", style: const TextStyle(color: Colors.black54))])),
      ),
    );
  }

  Widget _progressCard() {
    return AnimatedBuilder(
      animation: progressController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)]),
          child: Row(children: [
            SizedBox(
              height: 80,
              width: 80,
              child: Stack(alignment: Alignment.center, children: [
                CircularProgressIndicator(value: progressController.value * progress, strokeWidth: 8, backgroundColor: Colors.grey[300], valueColor: const AlwaysStoppedAnimation<Color>(Colors.deepPurple)),
                Text("${(progressController.value * progress * 100).toInt()}%", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold))
              ]),
            ),
            const SizedBox(width: 20),
            const Expanded(child: Text("Today's Progress", style: TextStyle(color: Colors.black, fontSize: 16)))
          ]),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFD1C4E9), Color(0xFFB39DDB)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: ListView(children: [
              const SizedBox(height: 20),
              const Text("Dashboard", style: TextStyle(color: Colors.black87, fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              _progressCard(),
              const SizedBox(height: 20),
              ...exams.map((e) => Padding(padding: const EdgeInsets.only(bottom: 15), child: _examCard(e['subject'], e['date'])))
            ]),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
          onPressed: () {
            exams.add({"subject": "New Subject", "date": DateTime.now().add(const Duration(days: 7))});
            _saveExams();
            setState(() {});
          },
          child: const Icon(Icons.add)),
    );
  }
}

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
    await prefs.setStringList('habitsTitles', habits.map((h) => h['title'].toString()).toList());
    await prefs.setStringList('habitsStatus', habits.map((h) => h['done'].toString()).toList());
  }

  void _addHabit() {
    habits.add({"title": "New Habit", "done": false});
    _saveHabits();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
          decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFE1BEE7), Color(0xFFF8BBD0)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
          child: SafeArea(
              child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: ListView(children: [
                    const SizedBox(height: 20),
                    const Text("Habits", style: TextStyle(color: Colors.black87, fontSize: 28, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    ...habits.map((h) => Dismissible(
                        key: UniqueKey(),
                        onDismissed: (_) {
                          habits.remove(h);
                          _saveHabits();
                          setState(() {});
                        },
                        background: Container(color: Colors.redAccent, alignment: Alignment.centerLeft, padding: const EdgeInsets.only(left: 20), child: const Icon(Icons.delete, color: Colors.white)),
                        child: Card(
                            color: Colors.white,
                            elevation: 3,
                            child: ListTile(
                              title: Text(h['title'], style: const TextStyle(color: Colors.black)),
                              trailing: Checkbox(
                                value: h['done'],
                                onChanged: (val) {
                                  h['done'] = val;
                                  _saveHabits();
                                  setState(() {});
                                },
                              ),
                            ))))
                  ])))),
      floatingActionButton: FloatingActionButton(onPressed: _addHabit, child: const Icon(Icons.add)),
    );
  }
}

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
    await prefs.setStringList('tasksTitles', tasks.map((t) => t['title'].toString()).toList());
    await prefs.setStringList('tasksStatus', tasks.map((t) => t['done'].toString()).toList());
  }

  void _addTask() {
    tasks.add({"title": "New Task", "done": false});
    _saveTasks();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
          decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFB2DFDB), Color(0xFF80CBC4)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
          child: SafeArea(
              child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: ListView(children: [
                    const SizedBox(height: 20),
                    const Text("Tasks", style: TextStyle(color: Colors.black87, fontSize: 28, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    ...tasks.map((t) => Dismissible(
                        key: UniqueKey(),
                        onDismissed: (_) {
                          tasks.remove(t);
                          _saveTasks();
                          setState(() {});
                        },
                        background: Container(color: Colors.redAccent, alignment: Alignment.centerLeft, padding: const EdgeInsets.only(left: 20), child: const Icon(Icons.delete, color: Colors.white)),
                        child: Card(
                            color: Colors.white,
                            elevation: 3,
                            child: ListTile(
                              title: Text(t['title'], style: const TextStyle(color: Colors.black)),
                              trailing: Checkbox(
                                value: t['done'],
                                onChanged: (val) {
                                  t['done'] = val;
                                  _saveTasks();
                                  setState(() {});
                                },
                              ),
                            ))))
                  ])))),
      floatingActionButton: FloatingActionButton(onPressed: _addTask, child: const Icon(Icons.add)),
    );
  }
}

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
    await prefs.setStringList('assignmentsTitles', assignments.map((a) => a['title'].toString()).toList());
    await prefs.setStringList('assignmentsDates', assignments.map((a) => (a['deadline'] as DateTime).millisecondsSinceEpoch.toString()).toList());
  }

  void _addAssignment() {
    assignments.add({"title": "New Assignment", "deadline": DateTime.now().add(const Duration(days: 7))});
    _saveAssignments();
    setState(() {});
  }

  Future<void> _editAssignmentDialog(int index) async {
    TextEditingController controller = TextEditingController(text: assignments[index]['title']);
    DateTime tempDate = assignments[index]['deadline'];
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setDialogState) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: controller, decoration: const InputDecoration(labelText: "Title")),
              const SizedBox(height: 20),
              Row(children: [
                Text("Deadline: ${tempDate.day}/${tempDate.month}/${tempDate.year}"),
                const Spacer(),
                TextButton(
                    onPressed: () async {
                      DateTime? picked = await showDatePicker(context: context, initialDate: tempDate, firstDate: DateTime.now(), lastDate: DateTime(2100));
                      if (picked != null) setDialogState(() => tempDate = picked);
                    },
                    child: const Text("Change"))
              ]),
              const SizedBox(height: 20),
              ElevatedButton(
                  onPressed: () {
                    assignments[index]['title'] = controller.text;
                    assignments[index]['deadline'] = tempDate;
                    _saveAssignments();
                    Navigator.pop(context);
                    setState(() {});
                  },
                  child: const Text("Save"))
            ]),
          ),
        );
      }),
    );
  }

  Widget _assignmentCard(String title, DateTime deadline) {
    int daysLeft = deadline.difference(DateTime.now()).inDays;
    return Dismissible(
      key: UniqueKey(),
      onDismissed: (_) {
        assignments.removeWhere((a) => a['title'] == title);
        _saveAssignments();
        setState(() {});
      },
      background: Container(color: Colors.redAccent, alignment: Alignment.centerLeft, padding: const EdgeInsets.only(left: 20), child: const Icon(Icons.delete, color: Colors.white)),
      child: InkWell(
        onTap: () => _editAssignmentDialog(assignments.indexWhere((a) => a['title'] == title)),
        child: Card(
          color: Colors.white,
          elevation: 3,
          child: ListTile(
            title: Text(title, style: const TextStyle(color: Colors.black)),
            subtitle: Text("$daysLeft days left"),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
          decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFB39DDB), Color(0xFFD1C4E9)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
          child: SafeArea(
              child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: ListView(children: [
                    const SizedBox(height: 20),
                    const Text("Assignments", style: TextStyle(color: Colors.black87, fontSize: 28, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    ...assignments.map((a) => Padding(padding: const EdgeInsets.only(bottom: 15), child: _assignmentCard(a['title'], a['deadline'])))
                  ])))),
      floatingActionButton: FloatingActionButton(onPressed: _addAssignment, child: const Icon(Icons.add)),
    );
  }
}
