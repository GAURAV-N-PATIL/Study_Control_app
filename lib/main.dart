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
  String subjectName = "Mathematics";
  DateTime examDate = DateTime.now().add(const Duration(days: 5));

  @override
  void initState() {
    super.initState();
    _loadExamData();
  }

  Future<void> _loadExamData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      subjectName = prefs.getString('subjectName') ?? 'Mathematics';
      int? savedDate = prefs.getInt('examDate');
      examDate = savedDate != null
          ? DateTime.fromMillisecondsSinceEpoch(savedDate)
          : DateTime.now().add(const Duration(days: 5));
    });
  }

  Future<void> _saveExamData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('subjectName', subjectName);
    await prefs.setInt('examDate', examDate.millisecondsSinceEpoch);
  }

  @override
  Widget build(BuildContext context) {
    // Calculate days left for upcoming exam
    int daysLeft = examDate.difference(DateTime.now()).inDays;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF6A5AE0),
              Color(0xFF8E7BFF),
              Color(0xFF5F9CFF),
            ],
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

                // Dashboard Title
                const Text(
                  "Dashboard",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 30),

                // Upcoming Exam Card (tap-enabled)
                _examCard(),

                const SizedBox(height: 20),

                // Example: Today's Progress Card
                _progressCard(0.65), // replace 0.65 with your dynamic value later

                const SizedBox(height: 20),

                // Example: Assignments Card
                _infoCard(
                  title: "Assignments",
                  content: "3 Active • 1 Overdue",
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _examCard() {
    int daysLeft = examDate.difference(DateTime.now()).inDays;

    return GestureDetector(
      onTap: _editExamDialog, // opens the edit popup
      child: Container(
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
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
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
      ),
    );
  }

  Future<void> _editExamDialog() async {
    TextEditingController subjectController =
        TextEditingController(text: subjectName);

    DateTime tempDate = examDate;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
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
                    subjectName = subjectController.text;
                    examDate = tempDate;
                    _saveExamData();
                    setState(() {}); // refresh dashboard
                    Navigator.pop(context);
                  },
                  child: const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }
}