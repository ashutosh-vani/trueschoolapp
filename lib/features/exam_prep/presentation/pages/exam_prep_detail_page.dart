import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:trueschoolapp/app/theme/app_colors.dart';
import 'package:trueschoolapp/features/exam_prep/data/models/exam_prep_model.dart';
import 'package:trueschoolapp/features/exam_prep/data/services/exam_prep_service.dart';
import 'package:trueschoolapp/features/exam_prep/presentation/pages/create_exam_prep_page.dart';
import 'package:trueschoolapp/features/learning_gaps/data/models/learning_gap_model.dart';
import 'package:trueschoolapp/features/learning_gaps/data/services/learning_gap_service.dart';
import 'package:trueschoolapp/features/learning_gaps/data/learning_gap_fallback.dart';
import 'package:trueschoolapp/features/learning_gaps/presentation/pages/gap_remediation_page.dart';
import 'package:trueschoolapp/features/learning_gaps/presentation/pages/gap_quiz_page.dart';
import 'package:trueschoolapp/features/ai_tutor/presentation/pages/ai_tutor_page.dart';

// ── Fallback data (mirrors web EXAM_DATA) ─────────────────────────────────────
final _fallbackDetail = _DetailState(
  studentClass: 'Class 6',
  board: 'ICSE',
  mode: 'normal',
  readiness: _ReadinessData(
    overallPercent: 60,
    predictedScoreRange: '50-70 marks',
    subjects: [_SubjectReadiness(subject: 'Maths', percent: 60)],
  ),
  aiTips: [
    'You have your Maths exam in 2 days, focus on practicing MCQs.',
    'Your current confidence level in Maths is medium, which indicates you should revise key concepts and practice important questions.',
  ],
  todayTasks: [
    _Task(id: 'st1', subject: 'Maths', topic: 'Key Concepts Revision', taskType: 'revise', durationMinutes: 15),
    _Task(id: 'st2', subject: 'Maths', topic: 'Important Questions Practice', taskType: 'importantq', durationMinutes: 15),
  ],
  upcomingExams: [
    _UpcomingExamData(id: 'ue1', subject: 'Maths', examType: 'MCQ', date: '2026-05-30', daysLeft: 0, readinessPercent: 60, confidenceLevel: 'medium'),
  ],
  fullPlan: [
    _DayPlanData(dayNumber: 1, date: '2026-05-28', label: 'REVISION', totalMinutes: 30, tasks: [
      _Task(id: 'fp1', subject: 'Maths', topic: 'Maths — Key Concepts Revision', taskType: 'revise', durationMinutes: 15),
      _Task(id: 'fp2', subject: 'Maths', topic: 'Maths — Important Questions Practice', taskType: 'importantq', durationMinutes: 15),
    ]),
    _DayPlanData(dayNumber: 2, date: '2026-05-29', label: 'LAST_DAY', totalMinutes: 30, tasks: [
      _Task(id: 'fp3', subject: 'Maths', topic: 'Maths — Notes Review', taskType: 'notes', durationMinutes: 15),
      _Task(id: 'fp4', subject: 'Maths', topic: 'Maths — MCQs Quick Practice', taskType: 'importantq', durationMinutes: 15),
    ]),
  ],
  notesSubjects: [
    _NotesData(subject: 'Maths', noteTypes: ['Short notes', 'Key concepts', 'Formulas']),
  ],
  practiceSubjects: [
    _PracticeData(subject: 'Maths', practiceTypes: ['MCQ', 'Short Answer', 'Adaptive']),
  ],
);

// ── Main Page ─────────────────────────────────────────────────────────────────

/// Detail page for an exam prep plan.
/// Opened from ExamPrepListPage when the user taps a plan card.
/// Receives the plan metadata (id, class, board, status, subjects).
class ExamPrepDetailPage extends StatefulWidget {
  final String planId;
  final String studentClass;
  final String board;
  final String status;
  final List<String> subjects;

  const ExamPrepDetailPage({
    super.key,
    required this.planId,
    required this.studentClass,
    required this.board,
    this.status = 'active',
    this.subjects = const [],
  });

  @override
  State<ExamPrepDetailPage> createState() => _ExamPrepDetailPageState();
}

class _ExamPrepDetailPageState extends State<ExamPrepDetailPage>
    with SingleTickerProviderStateMixin {
  // Tabs: 0=Today, 1=Full Plan, 2=Notes, 3=Practice
  late final TabController _tabController;
  static const _tabs = ['Today', 'Full Plan', 'Notes', 'Practice'];

  bool _isLoading = true;
  late _DetailState _data;
  bool _isLastDayMode = false;

  List<LearningGap> _allGaps = [];
  List<Quiz> _allQuizzes = [];

  void _openNotes(String subject) {
    LearningGap? targetGap;

    // 1. Try real API gaps
    targetGap = _allGaps.where((g) => g.subject.toLowerCase() == subject.toLowerCase() || 
                                     (subject.toLowerCase().startsWith('math') && g.subject.toLowerCase().startsWith('math'))).firstOrNull;

    // 2. Try fallback gaps
    targetGap ??= kFallbackGaps.where((g) => g.subject.toLowerCase() == subject.toLowerCase() ||
                                            (subject.toLowerCase().startsWith('math') && g.subject.toLowerCase().startsWith('math'))).firstOrNull;

    // 3. Fallback to first gap
    targetGap ??= _allGaps.firstOrNull ?? (kFallbackGaps.isNotEmpty ? kFallbackGaps.first : null);

    if (targetGap != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GapRemediationPage(gap: targetGap!),
        ),
      );
    }
  }

  void _openPractice(String subject) {
    String? targetQuizId;

    // 1. Try real API quizzes
    final apiQuiz = _allQuizzes.where((q) => q.subject.toLowerCase() == subject.toLowerCase() ||
                                            (subject.toLowerCase().startsWith('math') && q.subject.toLowerCase().startsWith('math'))).firstOrNull;
    if (apiQuiz != null) {
      targetQuizId = apiQuiz.id;
    }

    // 2. Try fallback quizzes
    if (targetQuizId == null) {
      final fbQuiz = kFallbackQuizzes.where((q) => q.subject.toLowerCase() == subject.toLowerCase() ||
                                                  (subject.toLowerCase().startsWith('math') && q.subject.toLowerCase().startsWith('math'))).firstOrNull;
      if (fbQuiz != null) {
        targetQuizId = fbQuiz.id;
      }
    }

    // 3. Default fallback
    targetQuizId ??= _allQuizzes.firstOrNull?.id ?? 'quiz001';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GapQuizPage(quizId: targetQuizId!),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Data loading ──────────────────────────────────────────────────────────

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        ExamPrepService.getExamPrepDetail(widget.planId),
        ExamPrepService.getFullPlan(widget.planId),
        ExamPrepService.getNotes(widget.planId),
        ExamPrepService.getPractice(widget.planId),
        LearningGapService.getLearningGaps(),
        LearningGapService.getQuizList(),
      ]);

      final detail = results[0] as ExamPrepDetail?;
      final fullPlanRaw = results[1] as List<DayPlan>;
      final notesRaw = results[2] as List<SubjectNotes>;
      final practiceRaw = results[3] as List<SubjectPractice>;
      final gapsRaw = results[4] as List<LearningGap>;
      final quizzesRaw = results[5] as List<Quiz>;

      if (!mounted) return;

      _allGaps = gapsRaw;
      _allQuizzes = quizzesRaw;

      if (detail != null) {
        // Build from real API data
        final readiness = _ReadinessData(
          overallPercent: detail.readinessReport.overallPercent,
          predictedScoreRange: detail.readinessReport.predictedScoreRange,
          subjects: detail.readinessReport.subjects
              .map((s) => _SubjectReadiness(
                  subject: s.subject, percent: s.readinessPercent))
              .toList(),
        );

        final todayTasks = detail.todayTasks
            .map((t) => _Task(
                  id: t.id,
                  subject: t.subject,
                  topic: t.topic,
                  taskType: t.taskType,
                  durationMinutes: t.durationMinutes,
                  done: t.done,
                ))
            .toList();

        final upcomingExams = detail.upcomingExams
            .map((e) => _UpcomingExamData(
                  id: e.id,
                  subject: e.subject,
                  examType: e.examType,
                  date: e.date,
                  daysLeft: e.daysLeft,
                  readinessPercent: e.readinessPercent,
                  confidenceLevel: e.confidenceLevel,
                ))
            .toList();

        final fullPlan = fullPlanRaw.isNotEmpty
            ? fullPlanRaw
                .map((d) => _DayPlanData(
                      dayNumber: d.dayNumber,
                      date: d.date,
                      label: d.label,
                      totalMinutes: d.totalMinutes,
                      tasks: d.tasks
                          .map((t) => _Task(
                                id: t.id,
                                subject: t.subject,
                                topic: t.topic,
                                taskType: t.taskType,
                                durationMinutes: t.durationMinutes,
                                done: t.done,
                              ))
                          .toList(),
                    ))
                .toList()
            : _fallbackDetail.fullPlan;

        final notes = notesRaw.isNotEmpty
            ? notesRaw
                .map((n) => _NotesData(
                      subject: n.subject,
                      noteTypes: n.noteTypes,
                    ))
                .toList()
            : _buildDefaultNotes(widget.subjects);

        final practice = practiceRaw.isNotEmpty
            ? practiceRaw
                .map((p) => _PracticeData(
                      subject: p.subject,
                      practiceTypes: p.practiceTypes,
                    ))
                .toList()
            : _buildDefaultPractice(widget.subjects);

        setState(() {
          _data = _DetailState(
            studentClass: detail.studentClass.isNotEmpty
                ? detail.studentClass
                : widget.studentClass,
            board: detail.board.isNotEmpty ? detail.board : widget.board,
            mode: detail.mode,
            readiness: readiness,
            aiTips: detail.aiTips.isNotEmpty
                ? detail.aiTips
                : _fallbackDetail.aiTips,
            todayTasks: todayTasks.isNotEmpty
                ? todayTasks
                : _fallbackDetail.todayTasks,
            upcomingExams: upcomingExams.isNotEmpty
                ? upcomingExams
                : _fallbackDetail.upcomingExams,
            fullPlan: fullPlan,
            notesSubjects: notes,
            practiceSubjects: practice,
          );
          _isLastDayMode = detail.mode == 'last_day';
          _isLoading = false;
        });
      } else {
        // Use fallback, but inject class/board from plan card
        setState(() {
          _data = _fallbackDetail.copyWith(
            studentClass: widget.studentClass,
            board: widget.board,
            notesSubjects: _buildDefaultNotes(widget.subjects),
            practiceSubjects: _buildDefaultPractice(widget.subjects),
          );
          _isLastDayMode = widget.status == 'completed';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _data = _fallbackDetail.copyWith(
          studentClass: widget.studentClass,
          board: widget.board,
          notesSubjects: _buildDefaultNotes(widget.subjects),
          practiceSubjects: _buildDefaultPractice(widget.subjects),
        );
        _isLastDayMode = false;
        _isLoading = false;
      });
    }
  }

  List<_NotesData> _buildDefaultNotes(List<String> subjects) {
    final subs = subjects.isNotEmpty ? subjects : ['Maths'];
    return subs
        .map((s) => _NotesData(
              subject: s,
              noteTypes: ['Short notes', 'Key concepts', 'Formulas'],
            ))
        .toList();
  }

  List<_PracticeData> _buildDefaultPractice(List<String> subjects) {
    final subs = subjects.isNotEmpty ? subjects : ['Maths'];
    return subs
        .map((s) => _PracticeData(
              subject: s,
              practiceTypes: ['MCQ', 'Short Answer', 'Adaptive'],
            ))
        .toList();
  }

  // ── Mode toggle ───────────────────────────────────────────────────────────

  Future<void> _toggleLastDayMode() async {
    final newMode = _isLastDayMode ? 'normal' : 'last_day';
    setState(() => _isLastDayMode = !_isLastDayMode);
    await ExamPrepService.toggleMode(widget.planId, newMode);
  }

  // ── Task toggle ───────────────────────────────────────────────────────────

  void _toggleTodayTask(_Task task) {
    setState(() => task.done = !task.done);
    ExamPrepService.toggleTask(widget.planId, task.id);
  }

  void _toggleFullPlanTask(_Task task) {
    setState(() => task.done = !task.done);
    ExamPrepService.toggleFullPlanTask(widget.planId, task.id);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _buildHeader(),
                  _buildTabBar(),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildTodayTab(),
                        _buildFullPlanTab(),
                        _buildNotesTab(),
                        _buildPracticeTab(),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Back
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.arrow_back, size: 22, color: AppColors.textPrimary),
            ),
          ),
          const SizedBox(width: 8),
          // Title block
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Exam Preparation',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${_data.studentClass} · ${_data.board}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Last-Day Mode badge
          GestureDetector(
            onTap: _toggleLastDayMode,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _isLastDayMode
                    ? const Color(0xFFFFE4E4)
                    : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 13,
                    color: _isLastDayMode
                        ? const Color(0xFFDC2626)
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Last-Day\nMode',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _isLastDayMode
                          ? const Color(0xFFDC2626)
                          : AppColors.textSecondary,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Refresh
          IconButton(
            onPressed: _loadAll,
            icon: const Icon(Icons.refresh_rounded, size: 20, color: AppColors.textSecondary),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          // Settings
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateExamPrepPage()),
              ).then((_) => _loadAll());
            },
            icon: const Icon(Icons.settings_outlined, size: 20, color: AppColors.textSecondary),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  // ── Tab bar ───────────────────────────────────────────────────────────────

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle:
            const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        indicator: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(8),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
        dividerColor: Colors.transparent,
        tabs: _tabs
            .map((t) => Tab(
                  height: 36,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_tabIcon(t), size: 14),
                        const SizedBox(width: 5),
                        Text(t),
                      ],
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }

  IconData _tabIcon(String tab) {
    switch (tab) {
      case 'Today':
        return Icons.calendar_today_rounded;
      case 'Full Plan':
        return Icons.calendar_month_rounded;
      case 'Notes':
        return Icons.menu_book_rounded;
      case 'Practice':
        return Icons.play_circle_outline_rounded;
      default:
        return Icons.circle;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TODAY TAB
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildTodayTab() {
    final isCompleted = widget.status == 'completed';
    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Completed banner OR Last-Day mode card
          if (isCompleted) ...[
            _buildCompletedBanner(),
            const SizedBox(height: 12),
          ],
          // Readiness report
          _buildReadinessReport(),
          const SizedBox(height: 12),
          // Last-Day Mode indicator
          if (_isLastDayMode) ...[
            _buildLastDayCard(),
            const SizedBox(height: 12),
          ],
          // AI tips
          ..._data.aiTips.map((tip) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildAiTipCard(tip),
              )),
          if (_data.aiTips.isNotEmpty) const SizedBox(height: 2),
          // Today's Study Plan
          _buildTodayStudyPlan(),
          const SizedBox(height: 12),
          // Upcoming Exams
          _buildUpcomingExams(),
          const SizedBox(height: 12),
          // Ask Lumi CTA
          _buildAskVinCard(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Completed banner ──────────────────────────────────────────────────────

  Widget _buildCompletedBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF86EFAC)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🎉 All exams completed!',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF16A34A),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Ready to prep for new exams?',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF15803D),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateExamPrepPage()),
              ).then((_) => Navigator.pop(context, true));
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh_rounded, size: 14, color: Colors.white),
                  SizedBox(width: 6),
                  Text(
                    'Start Over',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Readiness report ──────────────────────────────────────────────────────

  Widget _buildReadinessReport() {
    final r = _data.readiness;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFF22C55E),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'READINESS REPORT',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Circular + predicted score
          Row(
            children: [
              _CircularProgress(percent: r.overallPercent),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('🎯 ',
                            style: TextStyle(fontSize: 14)),
                        const Text(
                          'Predicted Score Range',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      r.predictedScoreRange.isNotEmpty
                          ? r.predictedScoreRange
                          : '—',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Per-subject bars
          ...r.subjects.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildSubjectBar(s.subject, s.percent),
              )),
        ],
      ),
    );
  }

  Widget _buildSubjectBar(String subject, int percent) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              subject,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '$percent%',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.warning,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent / 100.0,
            minHeight: 8,
            backgroundColor: const Color(0xFFF3F4F6),
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppColors.warning),
          ),
        ),
      ],
    );
  }

  // ── Last-Day Mode card ────────────────────────────────────────────────────

  Widget _buildLastDayCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded,
              color: const Color(0xFFDC2626), size: 22),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Last-Day Mode',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFDC2626),
                ),
              ),
              const Text(
                'Ultra-short revision only',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFFEF4444),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── AI tip card ───────────────────────────────────────────────────────────

  Widget _buildAiTipCard(String tip) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF0F0F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🤖', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tip,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Today's Study Plan ────────────────────────────────────────────────────

  Widget _buildTodayStudyPlan() {
    final doneCount = _data.todayTasks.where((t) => t.done).length;
    final totalMins = _data.todayTasks.fold<int>(
        0, (sum, t) => sum + t.durationMinutes);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('📅', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Today's Study Plan",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Total: $totalMins mins · $doneCount/${_data.todayTasks.length} done',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (_isLastDayMode)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE4E4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Last-Day Mode',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFDC2626),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          ..._data.todayTasks.map((task) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildStudyTaskRow(task, onToggle: () => _toggleTodayTask(task)),
              )),
        ],
      ),
    );
  }

  // ── Study task row (shared by Today and Full Plan) ────────────────────────

  Widget _buildStudyTaskRow(_Task task, {VoidCallback? onToggle}) {
    return Opacity(
      opacity: task.done ? 0.5 : 1.0,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Checkbox
          GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: task.done ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color:
                      task.done ? AppColors.primary : Colors.grey.shade300,
                  width: 1.5,
                ),
              ),
              child: task.done
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          // Badge
          _taskTypeBadge(task.taskType),
          const SizedBox(width: 6),
          // Subject
          Text(
            task.subject,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          // Duration
          Text(
            '${task.durationMinutes}m',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _openPractice(task.subject),
            child: const Icon(Icons.quiz_outlined,
                size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => _openNotes(task.subject),
            child: const Icon(Icons.menu_book_outlined,
                size: 16, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildStudyTaskRowWithTopic(_Task task, {VoidCallback? onToggle}) {
    return Opacity(
      opacity: task.done ? 0.5 : 1.0,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Checkbox
          GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 22,
              height: 22,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                color: task.done ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color:
                      task.done ? AppColors.primary : Colors.grey.shade300,
                  width: 1.5,
                ),
              ),
              child: task.done
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _taskTypeBadge(task.taskType),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        task.subject,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  task.topic,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    decoration:
                        task.done ? TextDecoration.lineThrough : null,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${task.durationMinutes} min',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _taskTypeBadge(String taskType) {
    Color fg;
    Color bg;
    String label;
    switch (taskType.toLowerCase()) {
      case 'revise':
        fg = const Color(0xFF16A34A);
        bg = const Color(0xFFDCFCE7);
        label = 'REVISE';
        break;
      case 'importantq':
        fg = const Color(0xFFEF4444);
        bg = const Color(0xFFFFE4E4);
        label = 'IMPORTANTQ';
        break;
      case 'notes':
        fg = const Color(0xFFD97706);
        bg = const Color(0xFFFEF3C7);
        label = 'NOTES';
        break;
      case 'practice':
        fg = AppColors.primary;
        bg = AppColors.primary.withValues(alpha: 0.1);
        label = 'PRACTICE';
        break;
      case 'last_day':
        fg = const Color(0xFFDC2626);
        bg = const Color(0xFFFFE4E4);
        label = 'LAST DAY';
        break;
      default:
        fg = AppColors.textSecondary;
        bg = const Color(0xFFF3F4F6);
        label = taskType.toUpperCase();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: fg,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  // ── Upcoming Exams (Today tab) ────────────────────────────────────────────

  Widget _buildUpcomingExams() {
    if (_data.upcomingExams.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text('📅', style: TextStyle(fontSize: 18)),
            SizedBox(width: 6),
            Text(
              'Upcoming Exams',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ..._data.upcomingExams.map((exam) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildUpcomingExamCard(exam),
            )),
      ],
    );
  }

  Widget _buildUpcomingExamCard(_UpcomingExamData exam) {
    final gradient = _subjectGradient(exam.subject);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exam.examType.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white70,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      exam.subject,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${exam.date} · ${exam.daysLeft} days left',
                      style: const TextStyle(
                          fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              // Confidence emoji
              Text(
                _confidenceEmoji(exam.confidenceLevel),
                style: const TextStyle(fontSize: 28),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${exam.readinessPercent}% ready',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: exam.readinessPercent / 100.0,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  String _confidenceEmoji(String level) {
    switch (level.toLowerCase()) {
      case 'high':
        return '😎';
      case 'low':
        return '😰';
      default:
        return '😐';
    }
  }

  // ── Ask Lumi CTA ──────────────────────────────────────────────────────────

  Widget _buildAskVinCard() {
    return Container(
      padding: const EdgeInsets.all(18),
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
                Text(
                  'Need help with revision?',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Ask Lumi to quiz you or explain a concept.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AiTutorPage()),
              );
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text(
              'Ask Lumi',
              style:
                  TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // FULL PLAN TAB
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildFullPlanTab() {
    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Text('📅', style: TextStyle(fontSize: 18)),
                  SizedBox(width: 6),
                  Text(
                    'Full Study Plan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Text(
                '${_data.fullPlan.length} day${_data.fullPlan.length == 1 ? '' : 's'}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Day sections
          ..._data.fullPlan.map((day) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildDaySection(day),
              )),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildDaySection(_DayPlanData day) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Day header
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Text(
                'Day ${day.dayNumber} — ${day.date}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              _dayLabelBadge(day.label),
              const Spacer(),
              Text(
                '${day.totalMinutes} min',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        // Task cards for this day
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: List.generate(day.tasks.length, (i) {
              final task = day.tasks[i];
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    child: _buildFullPlanTaskRow(task),
                  ),
                  if (i < day.tasks.length - 1)
                    Divider(height: 1, color: Colors.grey.shade100),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildFullPlanTaskRow(_Task task) {
    return Row(
      children: [
        // Checkbox
        GestureDetector(
          onTap: () => _toggleFullPlanTask(task),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 22,
            height: 22,
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
        const SizedBox(width: 10),
        _taskTypeBadge(task.taskType),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            task.topic,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
              decoration: task.done ? TextDecoration.lineThrough : null,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${task.durationMinutes} min',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  Widget _dayLabelBadge(String label) {
    Color fg;
    Color bg;
    switch (label.toUpperCase()) {
      case 'LAST_DAY':
        fg = const Color(0xFFDC2626);
        bg = const Color(0xFFFFE4E4);
        break;
      case 'REVISION':
        fg = AppColors.primary;
        bg = AppColors.primary.withValues(alpha: 0.1);
        break;
      default:
        fg = const Color(0xFF16A34A);
        bg = const Color(0xFFDCFCE7);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: fg,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // NOTES TAB
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildNotesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Notes & Revision',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _data.notesSubjects.isNotEmpty
              ? _data.notesSubjects.first.noteTypes.join(' · ')
              : 'Short notes · Key concepts · Formulas',
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        ..._data.notesSubjects.map((n) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildNotesCard(n),
            )),
        if (_data.notesSubjects.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 32),
            child: Center(
              child: Text(
                'No notes available yet.',
                style:
                    TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
            ),
          ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildNotesCard(_NotesData notes) {
    return GestureDetector(
      onTap: () => _openNotes(notes.subject),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF695BE6), Color(0xFF8E82F3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notes.subject,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notes.noteTypes.join(' · '),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward,
                color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PRACTICE TAB
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildPracticeTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Practice Mode',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _data.practiceSubjects.isNotEmpty
              ? _data.practiceSubjects.first.practiceTypes.join(' · ')
              : 'MCQ · Short Answer · Adaptive',
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        ..._data.practiceSubjects.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildPracticeCard(p),
            )),
        if (_data.practiceSubjects.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 32),
            child: Center(
              child: Text(
                'No practice sets available yet.',
                style:
                    TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
            ),
          ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildPracticeCard(_PracticeData practice) {
    return GestureDetector(
      onTap: () => _openPractice(practice.subject),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF695BE6), Color(0xFF8E82F3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    practice.subject,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    practice.practiceTypes.join(' · '),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.play_arrow_rounded,
                color: Colors.white, size: 22),
          ],
        ),
      ),
    );
  }

  // ── Gradient helper ───────────────────────────────────────────────────────

  List<Color> _subjectGradient(String subject) {
    switch (subject.toLowerCase()) {
      case 'mathematics':
      case 'maths':
        return const [Color(0xFF695BE6), Color(0xFF8E82F3)];
      case 'physics':
        return const [Color(0xFF60A5FA), Color(0xFF6366F1)];
      case 'chemistry':
        return const [Color(0xFFFB923C), Color(0xFFF59E0B)];
      case 'biology':
        return const [Color(0xFF34D399), Color(0xFF10B981)];
      case 'english':
        return const [Color(0xFF34D399), Color(0xFF14B8A6)];
      default:
        return const [Color(0xFF695BE6), Color(0xFF8E82F3)];
    }
  }
}

// ── Circular progress painter ─────────────────────────────────────────────────

class _CircularProgress extends StatelessWidget {
  final int percent;

  const _CircularProgress({required this.percent});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 80,
      child: CustomPaint(
        painter: _CirclePainter(percent / 100.0),
        child: Center(
          child: Text(
            '$percent%',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _CirclePainter extends CustomPainter {
  final double progress;
  _CirclePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;

    // Track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0xFFE5E7EB)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8,
    );

    // Progress arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_CirclePainter old) => old.progress != progress;
}

// ── Internal view models ───────────────────────────────────────────────────────

class _ReadinessData {
  final int overallPercent;
  final String predictedScoreRange;
  final List<_SubjectReadiness> subjects;

  _ReadinessData({
    required this.overallPercent,
    required this.predictedScoreRange,
    required this.subjects,
  });
}

class _SubjectReadiness {
  final String subject;
  final int percent;
  _SubjectReadiness({required this.subject, required this.percent});
}

class _Task {
  final String id;
  final String subject;
  final String topic;
  final String taskType;
  final int durationMinutes;
  bool done;

  _Task({
    required this.id,
    required this.subject,
    required this.topic,
    required this.taskType,
    required this.durationMinutes,
    this.done = false,
  });
}

class _UpcomingExamData {
  final String id;
  final String subject;
  final String examType;
  final String date;
  final int daysLeft;
  final int readinessPercent;
  final String confidenceLevel;

  _UpcomingExamData({
    required this.id,
    required this.subject,
    required this.examType,
    required this.date,
    required this.daysLeft,
    required this.readinessPercent,
    required this.confidenceLevel,
  });
}

class _DayPlanData {
  final int dayNumber;
  final String date;
  final String label;
  final int totalMinutes;
  final List<_Task> tasks;

  _DayPlanData({
    required this.dayNumber,
    required this.date,
    required this.label,
    required this.totalMinutes,
    required this.tasks,
  });
}

class _NotesData {
  final String subject;
  final List<String> noteTypes;
  _NotesData({required this.subject, required this.noteTypes});
}

class _PracticeData {
  final String subject;
  final List<String> practiceTypes;
  _PracticeData({required this.subject, required this.practiceTypes});
}

class _DetailState {
  final String studentClass;
  final String board;
  final String mode;
  final _ReadinessData readiness;
  final List<String> aiTips;
  final List<_Task> todayTasks;
  final List<_UpcomingExamData> upcomingExams;
  final List<_DayPlanData> fullPlan;
  final List<_NotesData> notesSubjects;
  final List<_PracticeData> practiceSubjects;

  _DetailState({
    required this.studentClass,
    required this.board,
    required this.mode,
    required this.readiness,
    required this.aiTips,
    required this.todayTasks,
    required this.upcomingExams,
    required this.fullPlan,
    required this.notesSubjects,
    required this.practiceSubjects,
  });

  _DetailState copyWith({
    String? studentClass,
    String? board,
    String? mode,
    _ReadinessData? readiness,
    List<String>? aiTips,
    List<_Task>? todayTasks,
    List<_UpcomingExamData>? upcomingExams,
    List<_DayPlanData>? fullPlan,
    List<_NotesData>? notesSubjects,
    List<_PracticeData>? practiceSubjects,
  }) =>
      _DetailState(
        studentClass: studentClass ?? this.studentClass,
        board: board ?? this.board,
        mode: mode ?? this.mode,
        readiness: readiness ?? this.readiness,
        aiTips: aiTips ?? this.aiTips,
        todayTasks: todayTasks ?? this.todayTasks,
        upcomingExams: upcomingExams ?? this.upcomingExams,
        fullPlan: fullPlan ?? this.fullPlan,
        notesSubjects: notesSubjects ?? this.notesSubjects,
        practiceSubjects: practiceSubjects ?? this.practiceSubjects,
      );
}
