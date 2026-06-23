import 'package:flutter/material.dart';
import 'package:trueschoolapp/app/theme/app_colors.dart';
import 'package:trueschoolapp/features/exam_prep/data/models/exam_prep_model.dart';
import 'package:trueschoolapp/features/exam_prep/data/services/exam_prep_service.dart';
import 'package:trueschoolapp/features/exam_prep/presentation/pages/create_exam_prep_page.dart';

// ── Fallback data matching web frontend EXAM_DATA ────────────────────────────
final _fallbackExams = [
  _WebExam(id: 'ex1', subject: 'Mathematics', examType: 'Unit Test 4', date: '2026-04-05', daysLeft: 9, syllabus: ['Quadratic Equations', 'Trigonometry', 'Probability'], readinessPercent: 62),
  _WebExam(id: 'ex2', subject: 'Physics', examType: 'Mid-Term', date: '2026-04-10', daysLeft: 14, syllabus: ['Thermodynamics', 'Optics', 'Waves'], readinessPercent: 45),
  _WebExam(id: 'ex3', subject: 'Chemistry', examType: 'Unit Test 4', date: '2026-04-08', daysLeft: 12, syllabus: ['Organic Reactions', 'Electrochemistry'], readinessPercent: 30),
];

final _fallbackTasks = [
  RevisionTask(id: 'rt1', subject: 'Mathematics', topic: 'Quadratic Formula Practice', duration: '30 min', done: false, priority: 'high'),
  RevisionTask(id: 'rt2', subject: 'Physics', topic: 'Thermodynamics MCQ Set', duration: '45 min', done: false, priority: 'high'),
  RevisionTask(id: 'rt3', subject: 'Mathematics', topic: 'Trigonometry Identities', duration: '20 min', done: true, priority: 'medium'),
  RevisionTask(id: 'rt4', subject: 'Chemistry', topic: 'Organic Reaction Mechanisms', duration: '40 min', done: false, priority: 'high'),
  RevisionTask(id: 'rt5', subject: 'Physics', topic: 'Optics Ray Diagrams', duration: '25 min', done: false, priority: 'medium'),
  RevisionTask(id: 'rt6', subject: 'Mathematics', topic: 'Probability Problems', duration: '30 min', done: true, priority: 'low'),
];

class ExamPrepPage extends StatefulWidget {
  const ExamPrepPage({super.key});

  @override
  State<ExamPrepPage> createState() => _ExamPrepPageState();
}

class _ExamPrepPageState extends State<ExamPrepPage> {
  bool _isLoading = true;
  List<_WebExam> _exams = [];
  List<RevisionTask> _tasks = [];
  int _studyStreak = 5;
  double _studyHoursThisWeek = 12;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);

    final headers = await ExamPrepService.authHeaders();

    // Run all fetches in parallel
    final results = await Future.wait([
      ExamPrepService.getRawExams(headers),
      ExamPrepService.getRawRevisionTasks(headers),
      ExamPrepService.getStudyStats(),
    ]);

    final apiExams = results[0] as List<Map<String, dynamic>>;
    final apiTasks = results[1] as List<RevisionTask>;
    final stats = results[2] as StudyStats?;

    if (!mounted) return;
    setState(() {
      _exams = apiExams.isNotEmpty ? apiExams.map((j) => _WebExam.fromJson(j)).toList() : _fallbackExams;
      _tasks = apiTasks.isNotEmpty ? apiTasks : List.from(_fallbackTasks);
      if (stats != null) {
        _studyStreak = stats.studyStreak;
        _studyHoursThisWeek = stats.totalStudyHoursThisWeek;
      }
      _isLoading = false;
    });
  }

  Future<void> _toggleTask(RevisionTask task) async {
    // Optimistic update — same as web
    setState(() => task.done = !task.done);
    // Persist — same logic as web: rt* prefix → revision-tasks, else tasks
    if (task.id.startsWith('rt')) {
      await ExamPrepService.toggleRevisionTask(task.id);
    } else {
      await ExamPrepService.toggleTask('', task.id);
    }
  }

  int get _doneCount => _tasks.where((t) => t.done).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadAll,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
          ],
        ),
      ),
    );
  }

  // ── App Bar ──────────────────────────────────────────────────────────────────
  Widget _buildAppBar() {
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
                const Text('Exam Preparation',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                Text('${_exams.length} exams coming up',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () async {
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => const CreateExamPrepPage()),
              );
              if (result == true) _loadAll();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, size: 16, color: Colors.white),
                  SizedBox(width: 4),
                  Text('New Prep', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats Row ────────────────────────────────────────────────────────────────
  Widget _buildStatsRow() {
    final stats = [
      (icon: Icons.local_fire_department, value: '$_studyStreak days', label: 'Study Streak', color: Colors.orange),
      (icon: Icons.schedule, value: '${_studyHoursThisWeek}h', label: 'Hours This Week', color: AppColors.primary),
      (icon: Icons.task_alt, value: '$_doneCount/${_tasks.length}', label: 'Tasks Done', color: AppColors.success),
    ];

    return Row(
      children: stats.map((s) => Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
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
              Text(s.value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
              const SizedBox(height: 2),
              Text(s.label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9, color: AppColors.textSecondary)),
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
        const Text('Upcoming Exams',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        ..._exams.map((exam) => _buildExamCard(exam)),
      ],
    );
  }

  Widget _buildExamCard(_WebExam exam) {
    final colors = _gradientForSubject(exam.subject);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: colors.first.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
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
                      Text(exam.examType.toUpperCase(),
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white70, letterSpacing: 1)),
                      const SizedBox(height: 2),
                      Text(exam.subject,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
                      const SizedBox(height: 4),
                      Text('${exam.date} · ${exam.daysLeft} days left',
                          style: const TextStyle(fontSize: 12, color: Colors.white70)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${exam.readinessPercent}%',
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
                    const Text('Ready', style: TextStyle(fontSize: 10, color: Colors.white70)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
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

  List<Color> _gradientForSubject(String subject) {
    switch (subject.toLowerCase()) {
      case 'mathematics': return const [Color(0xFF695BE6), Color(0xFF8E82F3)];
      case 'physics':     return const [Color(0xFF60A5FA), Color(0xFF6366F1)];
      case 'chemistry':   return const [Color(0xFFFB923C), Color(0xFFF59E0B)];
      case 'biology':     return const [Color(0xFF34D399), Color(0xFF10B981)];
      case 'english':     return const [Color(0xFF34D399), Color(0xFF14B8A6)];
      case 'science':     return const [Color(0xFF60A5FA), Color(0xFF6366F1)];
      default:            return const [Color(0xFF695BE6), Color(0xFF8E82F3)];
    }
  }

  // ── Today's Revision Plan ────────────────────────────────────────────────────
  Widget _buildRevisionPlan() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Today's Revision Plan",
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
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
                  _buildTaskRow(task),
                  if (i < _tasks.length - 1) Divider(height: 24, color: Colors.grey.shade100),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildTaskRow(RevisionTask task) {
    return Opacity(
      opacity: task.done ? 0.5 : 1.0,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
              child: task.done ? const Icon(Icons.check, color: Colors.white, size: 14) : null,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _priorityBadge(task.priority),
                    const SizedBox(width: 8),
                    Text(task.subject, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
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
    Color fg; Color bg;
    switch (priority) {
      case 'high':   fg = const Color(0xFFDC2626); bg = const Color(0xFFFEF2F2); break;
      case 'medium': fg = const Color(0xFFD97706); bg = const Color(0xFFFFFBEB); break;
      default:       fg = const Color(0xFF16A34A); bg = const Color(0xFFF0FDF4);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Text(priority.toUpperCase(),
          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: fg, letterSpacing: 0.5)),
    );
  }

  // ── Ask Lumi CTA ─────────────────────────────────────────────────────────────
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
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                SizedBox(height: 4),
                Text('Ask Lumi to quiz you on any topic or explain a concept.',
                    style: TextStyle(fontSize: 12, color: Colors.white70, height: 1.4)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            child: const Text('Ask Lumi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

// ── Internal model for exam cards ─────────────────────────────────────────────
class _WebExam {
  final String id;
  final String subject;
  final String examType;
  final String date;
  final int daysLeft;
  final List<String> syllabus;
  final int readinessPercent;

  _WebExam({
    required this.id,
    required this.subject,
    required this.examType,
    required this.date,
    required this.daysLeft,
    required this.syllabus,
    required this.readinessPercent,
  });

  factory _WebExam.fromJson(Map<String, dynamic> json) => _WebExam(
        id: json['id'] ?? json['_id'] ?? '',
        subject: json['subject'] ?? '',
        examType: json['examType'] ?? json['exam_type'] ?? 'Exam',
        date: json['date'] ?? json['exam_date'] ?? '',
        daysLeft: json['daysLeft'] ?? json['days_left'] ?? 0,
        syllabus: (json['syllabus'] as List<dynamic>?)?.cast<String>() ?? [],
        readinessPercent: json['readinessPercent'] ?? json['readiness_percent'] ?? 0,
      );
}
