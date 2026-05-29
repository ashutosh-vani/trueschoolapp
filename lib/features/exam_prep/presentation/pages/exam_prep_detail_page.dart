import 'package:flutter/material.dart';
import 'package:trueschoolapp/app/theme/app_colors.dart';
import 'package:trueschoolapp/features/exam_prep/data/models/exam_prep_model.dart';
import 'package:trueschoolapp/features/exam_prep/data/services/exam_prep_service.dart';

/// Fallback data matching the web frontend's EXAM_DATA constant
final _fallbackExams = [
  {'id': 'ex1', 'subject': 'Mathematics', 'examType': 'Unit Test 4', 'date': '2026-04-05', 'daysLeft': 9, 'syllabus': ['Quadratic Equations', 'Trigonometry', 'Probability'], 'readinessPercent': 62},
  {'id': 'ex2', 'subject': 'Physics', 'examType': 'Mid-Term', 'date': '2026-04-10', 'daysLeft': 14, 'syllabus': ['Thermodynamics', 'Optics', 'Waves'], 'readinessPercent': 45},
  {'id': 'ex3', 'subject': 'Chemistry', 'examType': 'Unit Test 4', 'date': '2026-04-08', 'daysLeft': 12, 'syllabus': ['Organic Reactions', 'Electrochemistry'], 'readinessPercent': 30},
];

final _fallbackTasks = [
  {'id': 'rt1', 'subject': 'Mathematics', 'topic': 'Quadratic Formula Practice', 'duration': '30 min', 'done': false, 'priority': 'high'},
  {'id': 'rt2', 'subject': 'Physics', 'topic': 'Thermodynamics MCQ Set', 'duration': '45 min', 'done': false, 'priority': 'high'},
  {'id': 'rt3', 'subject': 'Mathematics', 'topic': 'Trigonometry Identities', 'duration': '20 min', 'done': true, 'priority': 'medium'},
  {'id': 'rt4', 'subject': 'Chemistry', 'topic': 'Organic Reaction Mechanisms', 'duration': '40 min', 'done': false, 'priority': 'high'},
  {'id': 'rt5', 'subject': 'Physics', 'topic': 'Optics Ray Diagrams', 'duration': '25 min', 'done': false, 'priority': 'medium'},
  {'id': 'rt6', 'subject': 'Mathematics', 'topic': 'Probability Problems', 'duration': '30 min', 'done': true, 'priority': 'low'},
];

class ExamPrepDetailPage extends StatefulWidget {
  final String planId;
  final String studentClass;
  final String board;

  const ExamPrepDetailPage({
    super.key,
    required this.planId,
    required this.studentClass,
    required this.board,
  });

  @override
  State<ExamPrepDetailPage> createState() => _ExamPrepDetailPageState();
}

class _ExamPrepDetailPageState extends State<ExamPrepDetailPage> {
  bool _isLoading = true;
  List<_ExamCard> _exams = [];
  List<RevisionTask> _tasks = [];
  int _studyStreak = 5;
  double _studyHoursThisWeek = 12;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    // Load exams
    final examsRaw = await ExamPrepService.getExamPreps();
    // Load revision tasks
    final tasks = await ExamPrepService.getRevisionTasks();
    // Load study stats
    final stats = await ExamPrepService.getStudyStats();

    if (!mounted) return;
    setState(() {
      // Exams: use API data, fallback to static
      if (examsRaw.isNotEmpty) {
        _exams = examsRaw.map((p) => _ExamCard(
          id: p.id,
          subject: p.subjects.isNotEmpty ? p.subjects.first : '',
          examType: 'Exam',
          date: p.createdAt,
          daysLeft: p.daysLeft ?? 0,
          syllabus: p.subjects,
          readinessPercent: p.progressPercent ?? 0,
        )).toList();
      } else {
        _exams = _fallbackExams.map((e) => _ExamCard(
          id: e['id'] as String,
          subject: e['subject'] as String,
          examType: e['examType'] as String,
          date: e['date'] as String,
          daysLeft: e['daysLeft'] as int,
          syllabus: (e['syllabus'] as List).cast<String>(),
          readinessPercent: e['readinessPercent'] as int,
        )).toList();
      }

      // Tasks: use API data, fallback to static
      if (tasks.isNotEmpty) {
        _tasks = tasks;
      } else {
        _tasks = _fallbackTasks.map((t) => RevisionTask.fromJson(t)).toList();
      }

      // Stats
      if (stats != null) {
        _studyStreak = stats.studyStreak;
        _studyHoursThisWeek = stats.totalStudyHoursThisWeek;
      }

      _isLoading = false;
    });
  }

  Future<void> _toggleTask(RevisionTask task) async {
    setState(() => task.done = !task.done);
    // Persist
    if (task.id.startsWith('rt')) {
      await ExamPrepService.toggleRevisionTask(task.id);
    }
  }

  int get _doneCount => _tasks.where((t) => t.done).length;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadAll,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatsRow(),
                      const SizedBox(height: 20),
                      _buildUpcomingExams(),
                      const SizedBox(height: 20),
                      _buildRevisionPlan(),
                      const SizedBox(height: 20),
                      _buildAskVinCard(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back, color: AppColors.textPrimary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Exam Preparation',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                Text(
                  '${_exams.length} exams coming up',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats Row ────────────────────────────────────────────────────────────────
  Widget _buildStatsRow() {
    final stats = [
      _StatItem(icon: Icons.local_fire_department, value: '$_studyStreak days', label: 'Study Streak', color: Colors.orange),
      _StatItem(icon: Icons.schedule, value: '${_studyHoursThisWeek}h', label: 'Hours This Week', color: AppColors.primary),
      _StatItem(icon: Icons.task_alt, value: '$_doneCount/${_tasks.length}', label: 'Tasks Done', color: AppColors.success),
    ];

    return Row(
      children: stats.map((s) => Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFF1F1F1)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: Column(
            children: [
              Icon(s.icon, color: s.color, size: 24),
              const SizedBox(height: 6),
              Text(s.value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
              const SizedBox(height: 2),
              Text(s.label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
            ],
          ),
        ),
      )).toList(),
    );
  }

  // ── Upcoming Exams ───────────────────────────────────────────────────────────
  Widget _buildUpcomingExams() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Upcoming Exams',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 12),
        ..._exams.map((exam) => _buildExamCard(exam)),
      ],
    );
  }

  Widget _buildExamCard(_ExamCard exam) {
    final gradients = _examGradient(exam.subject);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradients, begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: gradients.first.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exam.examType.toUpperCase(),
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white70, letterSpacing: 1),
                      ),
                      const SizedBox(height: 2),
                      Text(exam.subject, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
                      const SizedBox(height: 4),
                      Text(
                        '${exam.date} · ${exam.daysLeft} days left',
                        style: const TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${exam.readinessPercent}%',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                    const Text('Ready', style: TextStyle(fontSize: 10, color: Colors.white70)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: exam.readinessPercent / 100.0,
                minHeight: 7,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(height: 10),
            // Syllabus chips
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: exam.syllabus.map((s) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(s, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.white)),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  List<Color> _examGradient(String subject) {
    switch (subject.toLowerCase()) {
      case 'mathematics': return const [Color(0xFF695BE6), Color(0xFF8E82F3)];
      case 'physics':     return const [Color(0xFF60A5FA), Color(0xFF6366F1)];
      case 'chemistry':   return const [Color(0xFFFB923C), Color(0xFFF59E0B)];
      case 'biology':     return const [Color(0xFF34D399), Color(0xFF10B981)];
      case 'english':     return const [Color(0xFF34D399), Color(0xFF14B8A6)];
      default:            return const [Color(0xFF695BE6), Color(0xFF8E82F3)];
    }
  }

  // ── Today's Revision Plan ────────────────────────────────────────────────────
  Widget _buildRevisionPlan() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Today's Revision Plan",
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF1F1F1)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: Column(
            children: List.generate(_tasks.length, (i) {
              final task = _tasks[i];
              return Column(
                children: [
                  _buildTaskItem(task),
                  if (i < _tasks.length - 1) Divider(height: 24, color: Colors.grey.shade100),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildTaskItem(RevisionTask task) {
    return Opacity(
      opacity: task.done ? 0.5 : 1.0,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Checkbox
          GestureDetector(
            onTap: () => _toggleTask(task),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 22,
              height: 22,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                color: task.done ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: task.done ? AppColors.primary : Colors.grey.shade300,
                  width: 1.5,
                ),
              ),
              child: task.done
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
          ),
          const SizedBox(width: 14),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _priorityBadge(task.priority),
                    const SizedBox(width: 8),
                    Text(
                      task.subject,
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  task.topic,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    decoration: task.done ? TextDecoration.lineThrough : null,
                  ),
                ),
              ],
            ),
          ),
          // Duration
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.schedule, size: 13, color: Colors.grey.shade400),
              const SizedBox(width: 4),
              Text(task.duration, style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _priorityBadge(String priority) {
    Color color;
    Color bgColor;
    switch (priority) {
      case 'high':
        color = const Color(0xFFDC2626);
        bgColor = const Color(0xFFFEF2F2);
        break;
      case 'medium':
        color = const Color(0xFFD97706);
        bgColor = const Color(0xFFFFFBEB);
        break;
      default:
        color = const Color(0xFF16A34A);
        bgColor = const Color(0xFFF0FDF4);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        priority.toUpperCase(),
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: color, letterSpacing: 0.5),
      ),
    );
  }

  // ── Ask Vin CTA ──────────────────────────────────────────────────────────────
  Widget _buildAskVinCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF695BE6), Color(0xFF8E82F3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Need help with revision?',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                SizedBox(height: 4),
                Text('Ask Vin to quiz you on any topic or explain a concept.',
                    style: TextStyle(fontSize: 12, color: Colors.white70, height: 1.4)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () {
              // Navigate to AI tutor
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              elevation: 4,
            ),
            child: const Text('Ask Vin', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

// ── Data classes ───────────────────────────────────────────────────────────────
class _ExamCard {
  final String id;
  final String subject;
  final String examType;
  final String date;
  final int daysLeft;
  final List<String> syllabus;
  final int readinessPercent;

  _ExamCard({
    required this.id,
    required this.subject,
    required this.examType,
    required this.date,
    required this.daysLeft,
    required this.syllabus,
    required this.readinessPercent,
  });
}

class _StatItem {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  _StatItem({required this.icon, required this.value, required this.label, required this.color});
}
