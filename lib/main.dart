import 'package:flutter/material.dart';

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
  Widget build(BuildContext context) {
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

                const Text(
                  "Dashboard",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 30),

                GestureDetector(
                  onTap: _editExamDialog,
                  child: _examCard(daysLeft),
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _examCard(int daysLeft) {
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
    );
  }

  Future<void> _editExamDialog() async {
    TextEditingController subjectController =
        TextEditingController(text: subjectName);

    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: examDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        examDate = pickedDate;
      });
    }

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Exam"),
          content: TextField(
            controller: subjectController,
            decoration: const InputDecoration(
              labelText: "Subject Name",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  subjectName = subjectController.text;
                });
                Navigator.pop(context);
              },
              child: const Text("Save"),
            )
          ],
        );
      },
    );
  }
}