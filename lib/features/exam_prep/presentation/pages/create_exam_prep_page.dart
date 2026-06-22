import 'package:flutter/material.dart';
import 'package:trueschoolapp/app/theme/app_colors.dart';
import 'package:trueschoolapp/features/exam_prep/data/models/exam_prep_model.dart';
import 'package:trueschoolapp/features/exam_prep/data/services/exam_prep_service.dart';
import 'package:trueschoolapp/features/exam_prep/data/services/local_exam_prep_storage.dart';
import 'package:trueschoolapp/features/learning_gaps/presentation/pages/gap_quiz_page.dart';

class CreateExamPrepPage extends StatefulWidget {
  const CreateExamPrepPage({super.key});

  @override
  State<CreateExamPrepPage> createState() => _CreateExamPrepPageState();
}

class _CreateExamPrepPageState extends State<CreateExamPrepPage> {
  int _currentStep = 0;
  static const int _totalSteps = 8;

  // Step 1 — Class & Board
  String? _selectedClass;
  String? _selectedBoard;

  // Step 2 — Subjects
  final List<String> _allSubjects = [
    'Maths', 'Science', 'English', 'Social', 'Hindi',
    'Physics', 'Chemistry', 'Biology', 'History', 'Geography',
  ];
  final Set<String> _selectedSubjects = {};

  // Step 3 — Exam Dates (subject → date string)
  final Map<String, DateTime?> _examDates = {};

  // Step 4 — Syllabus type (subject → 'full'|'select')
  final Map<String, String> _syllabusType = {};
  final Map<String, TextEditingController> _topicsControllers = {};

  // Step 5 — Exam Pattern (subject → pattern key)
  final Map<String, String> _examPattern = {};

  // Step 6 — Daily study time
  String? _dailyStudyTime;

  // Step 7 — Confidence (subject → 'low'|'medium'|'high')
  final Map<String, String> _confidence = {};

  // Step 8 — Quiz choice
  bool? _startQuiz;

  bool _isSubmitting = false;

  @override
  void dispose() {
    for (final c in _topicsControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  List<String> get _subjects => _selectedSubjects.toList();

  bool get _canContinue {
    switch (_currentStep) {
      case 0:
        return _selectedClass != null && _selectedBoard != null;
      case 1:
        return _selectedSubjects.isNotEmpty;
      case 2:
        return _subjects.every((s) => _examDates[s] != null);
      case 3:
        return _subjects.every((s) {
          final type = _syllabusType[s] ?? 'full';
          if (type == 'select') {
            return (_topicsControllers[s]?.text.trim().isNotEmpty ?? false);
          }
          return true;
        });
      case 4:
        return _subjects.every((s) => _examPattern[s] != null);
      case 5:
        return _dailyStudyTime != null;
      case 6:
        return _subjects.every((s) => _confidence[s] != null);
      case 7:
        return _startQuiz != null;
      default:
        return false;
    }
  }

  void _next() {
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
    } else {
      _submit();
    }
  }

  void _back() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);

    final subjectList = _subjects.map((name) {
      final date = _examDates[name];
      return {
        'name': name,
        'examDate': date != null
            ? '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}'
            : null,
        'syllabusType': _syllabusType[name] ?? 'full',
        'customTopics': _topicsControllers[name]?.text.trim() ?? '',
        'examPattern': _examPattern[name],
        'confidenceLevel': _confidence[name] ?? 'medium',
      };
    }).toList();

    // 1. Try the backend first
    final request = CreateExamPrepRequest(
      studentClass: _selectedClass!,
      board: _selectedBoard!,
      subjects: subjectList.map((s) => ExamPrepSubject(
        name: '${s['name']}',
        examDate: s['examDate'],
        syllabusType: '${s['syllabusType']}',
        customTopics: s['customTopics'],
        examPattern: s['examPattern'],
        confidenceLevel: '${s['confidenceLevel']}',
      )).toList(),
      dailyStudyTime: _dailyStudyTime!,
      startQuiz: _startQuiz ?? false,
    );

    // Try backend (may 404 — that's fine)
    await ExamPrepService.createExamPrep(request);

    // 2. Always save locally so it shows on the exam prep screen
    await LocalExamPrepStorage.savePlan(
      studentClass: _selectedClass!,
      board: _selectedBoard!,
      subjects: subjectList,
      dailyStudyTime: _dailyStudyTime!,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (_startQuiz == true) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const GapQuizPage(quizId: 'quiz001'),
        ),
      );
    } else {
      // Pop back to exam prep page — it will reload and show the new plan
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildProgressBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: _buildStep(),
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: _back,
            child: const Icon(Icons.arrow_back, color: AppColors.textPrimary, size: 22),
          ),
          const Spacer(),
          Text(
            'Step ${_currentStep + 1} of $_totalSteps',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 22), // balance the back arrow
        ],
      ),
    );
  }

  // ── Progress bar ─────────────────────────────────────────────────────────────
  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: (_currentStep + 1) / _totalSteps,
          minHeight: 6,
          backgroundColor: AppColors.primary.withValues(alpha: 0.12),
          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      ),
    );
  }

  // ── Step router ──────────────────────────────────────────────────────────────
  Widget _buildStep() {
    switch (_currentStep) {
      case 0: return _buildStep1();
      case 1: return _buildStep2();
      case 2: return _buildStep3();
      case 3: return _buildStep4();
      case 4: return _buildStep5();
      case 5: return _buildStep6();
      case 6: return _buildStep7();
      case 7: return _buildStep8();
      default: return const SizedBox();
    }
  }

  // ── Shared step header ───────────────────────────────────────────────────────
  Widget _stepHeader(String emoji, String title, String subtitle) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 48)),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 28),
      ],
    );
  }

  // ── Chip selector ────────────────────────────────────────────────────────────
  Widget _chipSelector({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 2 : 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  // ── STEP 1: Class & Board ────────────────────────────────────────────────────
  Widget _buildStep1() {
    final classes = ['Class 6', 'Class 7', 'Class 8', 'Class 9', 'Class 10'];
    final boards = ['CBSE', 'ICSE', 'State Board'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeader('🏫', "Let's get started!", 'Which class are you in and which board do you follow?'),
        const Text('CLASS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 1)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: classes.map((c) => _chipSelector(
            label: c,
            selected: _selectedClass == c,
            onTap: () => setState(() => _selectedClass = c),
          )).toList(),
        ),
        const SizedBox(height: 24),
        const Text('BOARD', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 1)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: boards.map((b) => _chipSelector(
            label: b,
            selected: _selectedBoard == b,
            onTap: () => setState(() => _selectedBoard = b),
          )).toList(),
        ),
      ],
    );
  }

  // ── STEP 2: Subjects ─────────────────────────────────────────────────────────
  Widget _buildStep2() {
    final visibleSubjects = _selectedClass != null &&
            (int.tryParse(_selectedClass!.replaceAll('Class ', '') ) ?? 0) >= 9
        ? _allSubjects
        : _allSubjects.take(5).toList();

    final allSelected = visibleSubjects.every((s) => _selectedSubjects.contains(s));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeader('📚', 'Which subjects do you have exams for?', 'Select all that apply'),
        // Select All
        GestureDetector(
          onTap: () {
            setState(() {
              if (allSelected) {
                _selectedSubjects.removeAll(visibleSubjects);
              } else {
                _selectedSubjects.addAll(visibleSubjects);
              }
            });
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: allSelected ? AppColors.primary : AppColors.primary.withValues(alpha: 0.4),
                width: 1.5,
                style: BorderStyle.solid,
              ),
            ),
            child: Center(
              child: Text(
                'Select All',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...visibleSubjects.map((subject) {
          final selected = _selectedSubjects.contains(subject);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  if (selected) {
                    _selectedSubjects.remove(subject);
                  } else {
                    _selectedSubjects.add(subject);
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: selected ? AppColors.primary : AppColors.textSecondary,
                          width: 1.5,
                        ),
                      ),
                      child: selected
                          ? const Icon(Icons.check, color: Colors.white, size: 14)
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Text(
                      subject,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // ── STEP 3: Exam Dates ───────────────────────────────────────────────────────
  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeader('📅', 'When are your exams?', 'Set a date for each subject'),
        ..._subjects.map((subject) => _buildDateCard(subject)),
      ],
    );
  }

  Widget _buildDateCard(String subject) {
    final date = _examDates[subject];
    final today = DateTime.now();
    final daysLeft = date?.difference(today).inDays;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              subject,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => _pickDate(subject),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: date != null ? AppColors.primary : AppColors.border,
                    width: date != null ? 2 : 1.5,
                  ),
                ),
                child: Text(
                  date != null
                      ? '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}'
                      : '',
                  style: TextStyle(
                    fontSize: 15,
                    color: date != null ? AppColors.textPrimary : AppColors.textHint,
                  ),
                ),
              ),
            ),
            if (daysLeft != null) ...[
              const SizedBox(height: 8),
              Text(
                '👉 $daysLeft day${daysLeft == 1 ? '' : 's'} left',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFF59E0B),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate(String subject) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _examDates[subject] ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _examDates[subject] = picked);
    }
  }

  // ── STEP 4: Syllabus Coverage ────────────────────────────────────────────────
  Widget _buildStep4() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeader('📖', 'What topics are included?', 'Choose syllabus coverage per subject'),
        ..._subjects.map((subject) => _buildSyllabusCard(subject)),
      ],
    );
  }

  Widget _buildSyllabusCard(String subject) {
    final type = _syllabusType[subject] ?? 'full';
    _topicsControllers.putIfAbsent(subject, () => TextEditingController());

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subject, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _syllabusToggle(subject, 'full', 'Full Syllabus', type == 'full'),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _syllabusToggle(subject, 'select', 'Select Topics', type == 'select'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (type == 'full')
              Text(
                '✅ AI will use the full ${_selectedBoard ?? ''} ${_selectedClass ?? ''} $subject syllabus',
                style: const TextStyle(fontSize: 13, color: AppColors.success, fontWeight: FontWeight.w500),
              )
            else
              TextField(
                controller: _topicsControllers[subject],
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Enter topics separated by commas',
                  hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 13),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _syllabusToggle(String subject, String value, String label, bool selected) {
    return GestureDetector(
      onTap: () => setState(() => _syllabusType[subject] = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 2 : 1.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  // ── STEP 5: Exam Pattern ─────────────────────────────────────────────────────
  Widget _buildStep5() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeader('✏️', "What's your exam pattern?", 'Select the format for each subject'),
        ..._subjects.map((subject) => _buildPatternCard(subject)),
      ],
    );
  }

  Widget _buildPatternCard(String subject) {
    final patterns = [
      {'key': 'mcq', 'label': 'MCQ Based'},
      {'key': 'mixed', 'label': 'Mixed (MCQ + Short\n+ Long)'},
      {'key': 'descriptive', 'label': 'Descriptive'},
      {'key': 'board', 'label': 'Board Pattern\n(Auto-fill)'},
    ];
    final selected = _examPattern[subject];

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subject, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.2,
              children: patterns.map((p) {
                final isSelected = selected == p['key'];
                return GestureDetector(
                  onTap: () => setState(() => _examPattern[subject] = p['key']!),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary.withValues(alpha: 0.08) : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.border,
                        width: isSelected ? 2 : 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        p['label']!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? AppColors.primary : AppColors.textPrimary,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ── STEP 6: Daily Study Time ─────────────────────────────────────────────────
  Widget _buildStep6() {
    final options = [
      {'key': '30min', 'label': '30 mins'},
      {'key': '1hr', 'label': '1 hour'},
      {'key': '2hr', 'label': '2 hours'},
      {'key': '3hr+', 'label': '3+ hours'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeader('⏱️', 'How much time can you study daily?', "We'll build your plan around this"),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.4,
          children: options.map((o) {
            final isSelected = _dailyStudyTime == o['key'];
            return GestureDetector(
              onTap: () => setState(() => _dailyStudyTime = o['key']),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary.withValues(alpha: 0.08) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                    width: isSelected ? 2 : 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    o['label']!,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── STEP 7: Confidence ───────────────────────────────────────────────────────
  Widget _buildStep7() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeader('😊', 'How confident are you?', 'Rate your confidence in each subject'),
        ..._subjects.map((subject) => _buildConfidenceCard(subject)),
      ],
    );
  }

  Widget _buildConfidenceCard(String subject) {
    final levels = [
      {'key': 'low', 'emoji': '😰', 'label': 'Low'},
      {'key': 'medium', 'emoji': '😐', 'label': 'Medium'},
      {'key': 'high', 'emoji': '😎', 'label': 'High'},
    ];
    final selected = _confidence[subject];

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subject, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            Row(
              children: levels.map((l) {
                final isSelected = selected == l['key'];
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTap: () => setState(() => _confidence[subject] = l['key']!),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary.withValues(alpha: 0.08) : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.border,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(l['emoji']!, style: const TextStyle(fontSize: 24)),
                            const SizedBox(height: 4),
                            Text(
                              l['label']!,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ── STEP 8: Quick Check Quiz ─────────────────────────────────────────────────
  Widget _buildStep8() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeader('🧠', 'Quick check before we start?',
            'A 5-question quiz per subject helps us calibrate\nyour plan more accurately'),
        _buildQuizOption(
          value: true,
          title: 'Yes, start the quiz',
          subtitle: '5 questions per subject · Takes ~2 mins ·\nImproves your plan accuracy',
        ),
        const SizedBox(height: 12),
        _buildQuizOption(
          value: false,
          title: 'Skip for now',
          subtitle: "We'll use your confidence ratings to build the plan",
        ),
      ],
    );
  }

  Widget _buildQuizOption({
    required bool value,
    required String title,
    required String subtitle,
  }) {
    final isSelected = _startQuiz == value;
    return GestureDetector(
      onTap: () => setState(() => _startQuiz = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1.5,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 22,
              height: 22,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.primary : Colors.transparent,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.circle, color: Colors.white, size: 10)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Footer ───────────────────────────────────────────────────────────────────
  Widget _buildFooter() {
    final isLastStep = _currentStep == _totalSteps - 1;

    // Determine button label/icon for last step based on quiz choice
    Widget buttonChild;
    if (_isSubmitting) {
      buttonChild = const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 12),
          Text(
            'Generating your plan...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      );
    } else if (isLastStep && _startQuiz == true) {
      buttonChild = const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.quiz_outlined, color: Colors.white, size: 20),
          SizedBox(width: 10),
          Text(
            'Start Self-Assessment ✨',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      );
    } else if (isLastStep) {
      // Skip for now OR nothing selected yet
      buttonChild = const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('✦', style: TextStyle(fontSize: 16, color: Colors.white)),
          SizedBox(width: 8),
          Text(
            'Create My Study Plan ✨',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      );
    } else {
      buttonChild = const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Continue',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 8),
          Icon(Icons.arrow_forward, color: Colors.white, size: 18),
        ],
      );
    }

    final buttonEnabled = _canContinue && !_isSubmitting;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      color: AppColors.background,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: buttonEnabled ? _next : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonEnabled
                    ? AppColors.primary
                    : AppColors.primary.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28)),
                elevation: 0,
              ),
              child: buttonChild,
            ),
          ),
          if (_currentStep > 0) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _isSubmitting ? null : _back,
              child: Text(
                '← Back',
                style: TextStyle(
                  fontSize: 14,
                  color: _isSubmitting
                      ? AppColors.textSecondary.withValues(alpha: 0.4)
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
