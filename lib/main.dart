import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';

void main() {
  runApp(const StudyControlApp());
}

class StudyControlApp extends StatelessWidget {
  const StudyControlApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Study Control',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE8D5F2),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFFAF8FF),
        dialogBackgroundColor: const Color(0xFFFAF8FF),
        canvasColor: const Color(0xFFFAF8FF),
      ),
      debugShowCheckedModeBanner: false,
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

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
      DashboardScreen(onTabChange: _onTabChange),
      const TaskScreen(),
      const AssignmentsScreen(),
      const NotesScreen(),
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
      backgroundColor: const Color(0xFFFAF8FF),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 8,
        selectedItemColor: const Color(0xFF6B7280),
        unselectedItemColor: const Color(0xFFC5B3D0),
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
            label: 'Task',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_rounded),
            label: 'Assignment',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.note_rounded),
            label: 'Notes',
          ),
        ],
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  final Function(int) onTabChange;

  const DashboardScreen({Key? key, required this.onTabChange})
      : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  double _taskProgress = 0.0;
  int _completedTasks = 0;
  int _totalTasks = 0;
  List<Task> _highPriorityTasks = [];
  List<ExamAssignment> _exams = [];
  int _totalAssignments = 0;
  int _completedAssignments = 0;
  int _pendingAssignments = 0;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _loadTaskProgress();
    _loadHighPriorityTasks();
    _loadExams();
    _loadAssignmentStats();
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
    final tasks = tasksJson
        .map((json) => Task.fromJson(jsonDecode(json)))
        .toList();

    setState(() {
      _highPriorityTasks =
          tasks.where((t) => t.priority == 'High').take(3).toList();
    });
  }

  Future<void> _loadExams() async {
    final prefs = await SharedPreferences.getInstance();
    final examsJson = prefs.getStringList('exams') ?? [];
    final exams = examsJson
        .map((json) => ExamAssignment.fromJson(jsonDecode(json)))
        .toList();

    final activeExams = exams
        .where((e) {
      final daysRemaining = _getDaysRemaining(e.dueDate);
      return daysRemaining >= 0;
    })
        .toList();

    setState(() {
      _exams = activeExams;
    });
  }

  Future<void> _loadAssignmentStats() async {
    final prefs = await SharedPreferences.getInstance();
    final assignmentsJson = prefs.getStringList('assignments') ?? [];
    final assignments = assignmentsJson
        .map((json) => Assignment.fromJson(jsonDecode(json)))
        .toList();

    final nonExamAssignments = assignments
        .where((a) => !a.isExam)
        .toList();

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
        backgroundColor: const Color(0xFFFAF8FF),
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
                  color: Color(0xFF3F3F3F),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  hintText: 'Exam name',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.grey.shade300,
                      width: 1.5,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.grey.shade300,
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFFD5B8E0),
                      width: 2,
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
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () async {
                      if (nameController.text.isNotEmpty) {
                        final prefs = await SharedPreferences.getInstance();
                        _exams[index].name = nameController.text;

                        final examsJson = _exams
                            .map((e) => jsonEncode(e.toJson()))
                            .toList();
                        await prefs.setStringList('exams', examsJson);

                        setState(() {});
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD5B8E0),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
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

  void _deleteExam(int index) async {
    final prefs = await SharedPreferences.getInstance();
    _exams.removeAt(index);
    final examsJson =
        _exams.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList('exams', examsJson);
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exam deleted successfully'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
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
                    const Text(
                      'Dashboard',
                      style: TextStyle(
                        fontWeight: FontWeight.w300,
                        color: Color(0xFF3F3F3F),
                        fontSize: 36,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Track your learning journey',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
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
        color: const Color(0xFFE8D5F2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFD5B8E0).withOpacity(0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE8D5F2).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
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
                  const Text(
                    'Daily Progress',
                    style: TextStyle(
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF3F3F3F),
                      fontSize: 16,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$_completedTasks of $_totalTasks tasks',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w400,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFF3E8FF).withOpacity(0.6),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 70,
                      height: 70,
                      child: CircularProgressIndicator(
                        value: _taskProgress,
                        strokeWidth: 5,
                        backgroundColor: Colors.grey.shade200,
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(
                          Color(0xFFD5B8E0),
                        ),
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${(_taskProgress * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Color(0xFF3F3F3F),
                          ),
                        ),
                        Text(
                          'Done',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              value: _taskProgress,
              minHeight: 10,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFFD5B8E0),
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
        const Text(
          'Today\'s Tasks',
          style: TextStyle(
            fontWeight: FontWeight.w400,
            color: Color(0xFF3F3F3F),
            fontSize: 18,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
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
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                )
              : Column(
                  children: [
                    ..._highPriorityTasks.asMap().entries.map((entry) {
                      int index = entry.key;
                      Task task = entry.value;
                      return Column(
                        children: [
                          _buildTaskItem(task),
                          if (index < _highPriorityTasks.length - 1)
                            const Divider(height: 16),
                        ],
                      );
                    }).toList(),
                  ],
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
            color: task.isCompleted
                ? const Color(0xFF10B981)
                : const Color(0xFFE5E7EB),
            border: Border.all(
              color: task.isCompleted
                  ? const Color(0xFF10B981)
                  : const Color(0xFFD1D5DB),
              width: 2,
            ),
          ),
          child: task.isCompleted
              ? const Icon(
                  Icons.check,
                  size: 14,
                  color: Colors.white,
                )
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task.title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF3F3F3F),
                  decoration: task.isCompleted
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                task.time,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: task.isCompleted
                ? const Color(0xFFD1FAE5)
                : const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            task.isCompleted ? 'Done' : 'Pending',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: task.isCompleted
                  ? const Color(0xFF047857)
                  : const Color(0xFFB45309),
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
        const Text(
          'Upcoming Exams',
          style: TextStyle(
            fontWeight: FontWeight.w400,
            color: Color(0xFF3F3F3F),
            fontSize: 18,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 12),
        if (_exams.isEmpty)
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF0F9FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFBAE6FD).withOpacity(0.5),
                width: 1.5,
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Text(
                'No exams scheduled',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ),
          )
        else
          ..._exams.asMap().entries.map((entry) {
            int index = entry.key;
            ExamAssignment exam = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildExamCard(exam, index),
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
      if (daysRemaining < 0) return const Color(0xFFDC2626);
      if (daysRemaining <= 3) return const Color(0xFFF59E0B);
      return const Color(0xFF0369A1);
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted
              ? const Color(0xFFD1FAE5).withOpacity(0.5)
              : const Color(0xFFBAE6FD).withOpacity(0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
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
                  ? const Color(0xFFD1FAE5)
                  : const Color(0xFFE0F2FE),
            ),
            child: const Center(
              child: Text('📚', style: TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exam.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3F3F3F),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  exam.subject,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
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
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? const Color(0xFFD1FAE5)
                      : const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  exam.status,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isCompleted
                        ? const Color(0xFF047857)
                        : const Color(0xFF0369A1),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _editExam(context, index);
                  } else if (value == 'delete') {
                    _deleteExam(index);
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
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E8FF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.more_vert, size: 16, color: Color(0xFFD5B8E0)),
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
        const Text(
          'Assignments Overview',
          style: TextStyle(
            fontWeight: FontWeight.w400,
            color: Color(0xFF3F3F3F),
            fontSize: 18,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildAssignmentStat(
                  'Total', '$_totalAssignments', const Color(0xFF3B82F6)),
              _buildAssignmentStat('Pending', '$_pendingAssignments',
                  const Color(0xFFF59E0B)),
              _buildAssignmentStat('Completed', '$_completedAssignments',
                  const Color(0xFF10B981)),
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
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickLinksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Links',
          style: TextStyle(
            fontWeight: FontWeight.w400,
            color: Color(0xFF3F3F3F),
            fontSize: 18,
            letterSpacing: 0.3,
          ),
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
                  color: const Color(0xFF3B82F6),
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
                  color: const Color(0xFF10B981),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => widget.onTabChange(3),
                child: _buildQuickLinkCard(
                  icon: Icons.note,
                  label: 'Notes',
                  color: const Color(0xFF8B5CF6),
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
            color: color.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF3F3F3F),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TaskScreen extends StatefulWidget {
  const TaskScreen({Key? key}) : super(key: key);

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  List<Task> tasks = [];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = prefs.getStringList('tasks') ?? [];
    if (tasksJson.isNotEmpty) {
      setState(() {
        tasks = tasksJson
            .map((json) => Task.fromJson(jsonDecode(json)))
            .toList();
      });
    }
    _updateTaskProgress();
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
      backgroundColor: const Color(0xFFFAF8FF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text(
          'Tasks',
          style: TextStyle(
            fontWeight: FontWeight.w300,
            color: Color(0xFF3F3F3F),
            fontSize: 32,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${tasks.where((t) => !t.isCompleted).length} tasks pending',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 20),
              if (tasks.isEmpty)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text(
                      'No tasks yet',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                )
              else
                ...tasks.asMap().entries.map((entry) {
                  int index = entry.key;
                  Task task = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TaskCard(
                      task: task,
                      onToggle: () {
                        setState(() {
                          tasks[index].isCompleted = !tasks[index].isCompleted;
                        });
                        _saveTasks();
                      },
                      onEdit: () => _editTask(context, index),
                      onDelete: () {
                        setState(() {
                          tasks.removeAt(index);
                        });
                        _saveTasks();
                      },
                    ),
                  );
                }).toList(),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _addTask(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Task'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD5B8E0),
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

  void _addTask(BuildContext context) {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController timeController = TextEditingController();
    String selectedPriority = 'Medium';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: const Color(0xFFFAF8FF),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Add New Task',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3F3F3F),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    hintText: 'Task title',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1.5,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Color(0xFFD5B8E0),
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: timeController,
                  decoration: InputDecoration(
                    hintText: 'Time (HH:MM)',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1.5,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Color(0xFFD5B8E0),
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey.shade300,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButton<String>(
                    value: selectedPriority,
                    isExpanded: true,
                    underline: const SizedBox(),
                    items: ['Low', 'Medium', 'High']
                        .map((p) => DropdownMenuItem(
                              value: p,
                              child: Text(
                                p,
                                style: const TextStyle(
                                  color: Color(0xFF3F3F3F),
                                ),
                              ),
                            ))
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
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
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
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD5B8E0),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
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
        TextEditingController(text: tasks[index].title);
    final TextEditingController timeController =
        TextEditingController(text: tasks[index].time);
    String selectedPriority = tasks[index].priority;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: const Color(0xFFFAF8FF),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Edit Task',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3F3F3F),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    hintText: 'Task title',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1.5,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Color(0xFFD5B8E0),
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: timeController,
                  decoration: InputDecoration(
                    hintText: 'Time (HH:MM)',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1.5,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Color(0xFFD5B8E0),
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey.shade300,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButton<String>(
                    value: selectedPriority,
                    isExpanded: true,
                    underline: const SizedBox(),
                    items: ['Low', 'Medium', 'High']
                        .map((p) => DropdownMenuItem(
                              value: p,
                              child: Text(
                                p,
                                style: const TextStyle(
                                  color: Color(0xFF3F3F3F),
                                ),
                              ),
                            ))
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
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        if (titleController.text.isNotEmpty &&
                            timeController.text.isNotEmpty) {
                          this.setState(() {
                            tasks[index].title = titleController.text;
                            tasks[index].time = timeController.text;
                            tasks[index].priority = selectedPriority;
                          });
                          _saveTasks();
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD5B8E0),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
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

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TaskCard({
    Key? key,
    required this.task,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'High':
        return const Color(0xFFEF4444);
      case 'Medium':
        return const Color(0xFFF59E0B);
      case 'Low':
        return const Color(0xFF10B981);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
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
                  color: task.isCompleted
                      ? const Color(0xFF10B981)
                      : Colors.grey.shade300,
                  width: 2,
                ),
                shape: BoxShape.circle,
                color: task.isCompleted ? const Color(0xFF10B981) : null,
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
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF3F3F3F),
                    decoration: task.isCompleted
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  task.time,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
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

class AssignmentsScreen extends StatefulWidget {
  const AssignmentsScreen({Key? key}) : super(key: key);

  @override
  State<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends State<AssignmentsScreen> {
  List<Assignment> assignments = [];

  @override
  void initState() {
    super.initState();
    _loadAssignments();
  }

  Future<void> _loadAssignments() async {
    final prefs = await SharedPreferences.getInstance();
    final assignmentsJson = prefs.getStringList('assignments') ?? [];
    if (assignmentsJson.isNotEmpty) {
      setState(() {
        assignments = assignmentsJson
            .map((json) => Assignment.fromJson(jsonDecode(json)))
            .toList();
      });
    }
  }

  Future<void> _saveAssignments() async {
    final prefs = await SharedPreferences.getInstance();
    final assignmentsJson =
        assignments.map((a) => jsonEncode(a.toJson())).toList();
    await prefs.setStringList('assignments', assignmentsJson);
  }

  Future<void> _saveExams(List<ExamAssignment> exams) async {
    final prefs = await SharedPreferences.getInstance();
    final examsJson = exams.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList('exams', examsJson);
  }

  @override
  Widget build(BuildContext context) {
    final nonExamAssignments = assignments
        .where((a) => !a.isExam)
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text(
          'Assignments',
          style: TextStyle(
            fontWeight: FontWeight.w300,
            color: Color(0xFF3F3F3F),
            fontSize: 32,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${nonExamAssignments.length} assignments',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 20),
              if (nonExamAssignments.isEmpty)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text(
                      'No assignments yet',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                )
              else
                ...nonExamAssignments.asMap().entries.map((entry) {
                  int index = entry.key;
                  Assignment assignment = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AssignmentCard(
                      assignment: assignment,
                      onEdit: () => _editAssignment(context, index),
                      onDelete: () {
                        setState(() {
                          assignments.removeWhere(
                              (a) => a.name == assignment.name && a.subject == assignment.subject && !a.isExam);
                        });
                        _saveAssignments();
                      },
                    ),
                  );
                }).toList(),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _addAssignment(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Assignment'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD5B8E0),
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

  void _addAssignment(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController subjectController = TextEditingController();
    final TextEditingController dueDateController = TextEditingController();
    String selectedStatus = 'Not started yet';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: const Color(0xFFFAF8FF),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Add New Assignment',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3F3F3F),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    hintText: 'Assignment name',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1.5,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFFD5B8E0),
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: subjectController,
                  decoration: InputDecoration(
                    hintText: 'Subject',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1.5,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFFD5B8E0),
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: dueDateController,
                  readOnly: true,
                  decoration: InputDecoration(
                    hintText: 'Due Date (MM/DD/YYYY)',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1.5,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFFD5B8E0),
                        width: 2,
                      ),
                    ),
                    suffixIcon: const Icon(Icons.calendar_today,
                        color: Color(0xFFD5B8E0)),
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
                    border: Border.all(
                      color: Colors.grey.shade300,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                  ),
                  child: DropdownButton<String>(
                    value: selectedStatus,
                    isExpanded: true,
                    underline: const SizedBox(),
                    items: ['Not started yet', 'In Progress', 'Completed']
                        .map((s) => DropdownMenuItem(
                              value: s,
                              child: Text(
                                s,
                                style: const TextStyle(
                                  color: Color(0xFF3F3F3F),
                                ),
                              ),
                            ))
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
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        if (nameController.text.isNotEmpty &&
                            subjectController.text.isNotEmpty &&
                            dueDateController.text.isNotEmpty) {
                          this.setState(() {
                            bool isExam = nameController.text.toLowerCase().contains('exam');
                            assignments.add(
                              Assignment(
                                name: nameController.text,
                                subject: subjectController.text,
                                dueDate: dueDateController.text,
                                status: selectedStatus,
                                isExam: isExam,
                              ),
                            );

                            if (isExam) {
                              _addExamToList(
                                nameController.text,
                                subjectController.text,
                                dueDateController.text,
                                selectedStatus,
                              );
                            }
                          });
                          _saveAssignments();
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD5B8E0),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
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

  void _addExamToList(String name, String subject, String dueDate, String status) async {
    final prefs = await SharedPreferences.getInstance();
    final examsJson = prefs.getStringList('exams') ?? [];
    final exams = examsJson
        .map((json) => ExamAssignment.fromJson(jsonDecode(json)))
        .toList();

    exams.add(ExamAssignment(
      name: name,
      subject: subject,
      dueDate: dueDate,
      status: status,
      isExam: true,
    ));

    await _saveExams(exams);
  }

  void _editAssignment(BuildContext context, int index) {
    final nonExamAssignments = assignments.where((a) => !a.isExam).toList();
    final assignmentToEdit = nonExamAssignments[index];

    final TextEditingController nameController =
        TextEditingController(text: assignmentToEdit.name);
    final TextEditingController subjectController =
        TextEditingController(text: assignmentToEdit.subject);
    final TextEditingController dueDateController =
        TextEditingController(text: assignmentToEdit.dueDate);
    String selectedStatus = assignmentToEdit.status;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: const Color(0xFFFAF8FF),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Edit Assignment',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3F3F3F),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    hintText: 'Assignment name',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1.5,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFFD5B8E0),
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: subjectController,
                  decoration: InputDecoration(
                    hintText: 'Subject',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1.5,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFFD5B8E0),
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: dueDateController,
                  readOnly: true,
                  decoration: InputDecoration(
                    hintText: 'Due Date (MM/DD/YYYY)',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1.5,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFFD5B8E0),
                        width: 2,
                      ),
                    ),
                    suffixIcon: const Icon(Icons.calendar_today,
                        color: Color(0xFFD5B8E0)),
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
                    border: Border.all(
                      color: Colors.grey.shade300,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                  ),
                  child: DropdownButton<String>(
                    value: selectedStatus,
                    isExpanded: true,
                    underline: const SizedBox(),
                    items: ['Not started yet', 'In Progress', 'Completed']
                        .map((s) => DropdownMenuItem(
                              value: s,
                              child: Text(
                                s,
                                style: const TextStyle(
                                  color: Color(0xFF3F3F3F),
                                ),
                              ),
                            ))
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
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        if (nameController.text.isNotEmpty &&
                            subjectController.text.isNotEmpty &&
                            dueDateController.text.isNotEmpty) {
                          this.setState(() {
                            final idx = assignments.indexOf(assignmentToEdit);
                            if (idx != -1) {
                              assignments[idx].name = nameController.text;
                              assignments[idx].subject = subjectController.text;
                              assignments[idx].dueDate = dueDateController.text;
                              assignments[idx].status = selectedStatus;
                            }
                          });
                          _saveAssignments();
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD5B8E0),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
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

class AssignmentCard extends StatelessWidget {
  final Assignment assignment;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const AssignmentCard({
    Key? key,
    required this.assignment,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Not started yet':
        return const Color(0xFFF59E0B);
      case 'In Progress':
        return const Color(0xFF6366F1);
      case 'Completed':
        return const Color(0xFF10B981);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
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
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF3F3F3F),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      assignment.subject,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
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
                  Icon(Icons.calendar_today,
                      size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    assignment.dueDate,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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

class NotesScreen extends StatefulWidget {
  const NotesScreen({Key? key}) : super(key: key);

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  List<Note> notes = [];

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final notesJson = prefs.getStringList('notes') ?? [];
    if (notesJson.isNotEmpty) {
      setState(() {
        notes = notesJson
            .map((json) => Note.fromJson(jsonDecode(json)))
            .toList();
      });
    }
  }

  Future<void> _saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final notesJson = notes.map((n) => jsonEncode(n.toJson())).toList();
    await prefs.setStringList('notes', notesJson);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text(
          'Notes',
          style: TextStyle(
            fontWeight: FontWeight.w300,
            color: Color(0xFF3F3F3F),
            fontSize: 32,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${notes.length} note${notes.length != 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 20),
              if (notes.isEmpty)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text(
                      'No notes yet',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                )
              else
                ...notes.asMap().entries.map((entry) {
                  int index = entry.key;
                  Note note = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: NoteCard(
                      note: note,
                      onEdit: () => _editNote(context, index),
                      onDelete: () {
                        setState(() {
                          notes.removeAt(index);
                        });
                        _saveNotes();
                      },
                    ),
                  );
                }).toList(),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _addNote(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Note'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD5B8E0),
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

  void _addNote(BuildContext context) {
    final TextEditingController subjectController = TextEditingController();
    final TextEditingController topicController = TextEditingController();
    List<String> files = [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: const Color(0xFFFAF8FF),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Add New Note',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3F3F3F),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: subjectController,
                  decoration: InputDecoration(
                    hintText: 'Subject',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1.5,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFFD5B8E0),
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: topicController,
                  decoration: InputDecoration(
                    hintText: 'Topic',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1.5,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFFD5B8E0),
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color: Colors.grey.shade300,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Files (PDF, PPTX, DOCS)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          GestureDetector(
                            onTap: () async {
                              try {
                                FilePickerResult? result = await FilePicker.platform
                                    .pickFiles(
                                  type: FileType.custom,
                                  allowedExtensions: ['pdf', 'pptx', 'docx', 'doc'],
                                  allowMultiple: true,
                                );

                                if (result != null) {
                                  setState(() {
                                    for (var file in result.files) {
                                      files.add(file.name);
                                    }
                                  });
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error picking file: $e'),
                                  ),
                                );
                              }
                            },
                            child: const Icon(Icons.add,
                                color: Color(0xFFD5B8E0), size: 20),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (files.isEmpty)
                        Text(
                          'No files added',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        )
                      else
                        ...files.asMap().entries.map((entry) {
                          int fileIndex = entry.key;
                          String file = entry.value;
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.description,
                                    size: 16,
                                    color: Color(0xFFD5B8E0)),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    file,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      files.removeAt(fileIndex);
                                    });
                                  },
                                  child: const Icon(Icons.close,
                                      size: 16, color: Colors.red),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        if (subjectController.text.isNotEmpty &&
                            topicController.text.isNotEmpty) {
                          this.setState(() {
                            notes.add(
                              Note(
                                subject: subjectController.text,
                                topic: topicController.text,
                                files: files,
                                dateCreated: DateTime.now(),
                              ),
                            );
                          });
                          _saveNotes();
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD5B8E0),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
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

  void _editNote(BuildContext context, int index) {
    final TextEditingController subjectController =
        TextEditingController(text: notes[index].subject);
    final TextEditingController topicController =
        TextEditingController(text: notes[index].topic);
    List<String> files = List.from(notes[index].files);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: const Color(0xFFFAF8FF),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Edit Note',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3F3F3F),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: subjectController,
                  decoration: InputDecoration(
                    hintText: 'Subject',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1.5,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFFD5B8E0),
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: topicController,
                  decoration: InputDecoration(
                    hintText: 'Topic',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1.5,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFFD5B8E0),
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color: Colors.grey.shade300,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Files (PDF, PPTX, DOCS)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          GestureDetector(
                            onTap: () async {
                              try {
                                FilePickerResult? result = await FilePicker.platform
                                    .pickFiles(
                                  type: FileType.custom,
                                  allowedExtensions: ['pdf', 'pptx', 'docx', 'doc'],
                                  allowMultiple: true,
                                );

                                if (result != null) {
                                  setState(() {
                                    for (var file in result.files) {
                                      if (!files.contains(file.name)) {
                                        files.add(file.name);
                                      }
                                    }
                                  });
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error picking file: $e'),
                                  ),
                                );
                              }
                            },
                            child: const Icon(Icons.add,
                                color: Color(0xFFD5B8E0), size: 20),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (files.isEmpty)
                        Text(
                          'No files added',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        )
                      else
                        ...files.asMap().entries.map((entry) {
                          int fileIndex = entry.key;
                          String file = entry.value;
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.description,
                                    size: 16,
                                    color: Color(0xFFD5B8E0)),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    file,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      files.removeAt(fileIndex);
                                    });
                                  },
                                  child: const Icon(Icons.close,
                                      size: 16, color: Colors.red),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        if (subjectController.text.isNotEmpty &&
                            topicController.text.isNotEmpty) {
                          this.setState(() {
                            notes[index].subject = subjectController.text;
                            notes[index].topic = topicController.text;
                            notes[index].files = files;
                          });
                          _saveNotes();
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD5B8E0),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
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

class NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const NoteCard({
    Key? key,
    required this.note,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
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
                      note.subject,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF3F3F3F),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      note.topic,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
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
          if (note.files.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              children: [
                ...note.files.map((file) {
                  String extension = file.split('.').last.toUpperCase();
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E8FF),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.description,
                            size: 12, color: Color(0xFFD5B8E0)),
                        const SizedBox(width: 4),
                        Text(
                          extension,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFD5B8E0),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class Note {
  String subject;
  String topic;
  List<String> files;
  DateTime dateCreated;

  Note({
    required this.subject,
    required this.topic,
    required this.files,
    required this.dateCreated,
  });

  Map<String, dynamic> toJson() {
    return {
      'subject': subject,
      'topic': topic,
      'files': files,
      'dateCreated': dateCreated.toIso8601String(),
    };
  }

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      subject: json['subject'] ?? '',
      topic: json['topic'] ?? '',
      files: List<String>.from(json['files'] ?? []),
      dateCreated: json['dateCreated'] != null
          ? DateTime.parse(json['dateCreated'])
          : DateTime.now(),
    );
  }
}