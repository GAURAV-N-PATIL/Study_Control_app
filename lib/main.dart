import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
void main() {
  runApp(const StudyControlApp());
}

class StudyControlApp extends StatelessWidget {
  const StudyControlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Study Control',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.purple,
      ),
      home: const MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    Center(child: Text("Habits")),
    Center(child: Text("Tasks")),
    Center(child: Text("Subjects")),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.check_circle_outline),
            selectedIcon: Icon(Icons.check_circle),
            label: 'Habits',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Subjects',
          ),
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

class _DashboardScreenState extends State<DashboardScreen> {
  // List of subjects + exam dates
  List<String> subjects = [];
  List<DateTime> examDates = [];

  // Example habit/task progress (0.0–1.0)
  double progress = 0.65;

  @override
  void initState() {
    super.initState();
    _loadExamData();
  }

  // Load subjects & exams from SharedPreferences
  Future<void> _loadExamData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      subjects = prefs.getStringList('subjects') ?? ['Mathematics'];
      List<String>? savedDates = prefs.getStringList('examDates');
      if (savedDates != null) {
        examDates =
            savedDates.map((s) => DateTime.fromMillisecondsSinceEpoch(int.parse(s))).toList();
      } else {
        examDates = [DateTime.now().add(const Duration(days: 5))];
      }
    });
  }

  // Save subjects & exams
  Future<void> _saveExamData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('subjects', subjects);
    await prefs.setStringList(
        'examDates', examDates.map((d) => d.millisecondsSinceEpoch.toString()).toList());
  }

  // Popup dialog to edit a subject
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
                    Text(
                      "${tempDate.day}/${tempDate.month}/${tempDate.year}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: tempDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            tempDate = picked;
                          });
                        }
                      },
                      child: const Text("Change"),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  subjects[index] = subjectController.text;
                  examDates[index] = tempDate;
                  _saveExamData();
                  setState(() {});
                  Navigator.pop(context);
                },
                child: const Text("Save"),
              ),
            ],
          );
        });
      },
    );
  }

  // Add new subject
  void _addNewExam() {
    setState(() {
      subjects.add("New Subject");
      examDates.add(DateTime.now().add(const Duration(days: 7)));
    });
    _saveExamData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewExam,
        child: const Icon(Icons.add),
      ),
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
                const Text(
                  "Dashboard",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),

                // Circular Progress Card
                _progressCard(progress),

                const SizedBox(height: 20),

                // Assignments Card (dummy example)
                _infoCard(title: "Assignments", content: "3 Active • 1 Overdue"),

                const SizedBox(height: 20),

                const Text(
                  "Upcoming Tests",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),

                // List of subjects / exam cards
                ...List.generate(subjects.length, (index) {
                  int daysLeft = examDates[index].difference(DateTime.now()).inDays;
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
    );
  }

  // Exam card widget
  Widget _examCard(String subjectName, int daysLeft) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Upcoming Test",
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            "$subjectName • $daysLeft days left",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Circular progress card
  Widget _progressCard(double progress) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(25),
      ),
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
                Text(
                  "${(progress * 100).toInt()}%",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          const Expanded(
            child: Text(
              "Today's Overall Progress\n(Habits + Tasks)",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  // Info card for assignments or other summary
  Widget _infoCard({required String title, required String content}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 6),
          Text(content,
              style: const TextStyle(
                  color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
